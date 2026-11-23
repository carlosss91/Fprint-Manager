import 'dart:async';
import 'dart:io';
import 'package:dbus/dbus.dart';

import '../models/fprint_device_info.dart';
import '../models/fingerprint_item.dart';
import 'alias_service.dart';
import 'usb_maintenance_service.dart';

/// Excepción legible para errores del subsistema fprintd / D-Bus.
class FprintException implements Exception {
  final String message;
  final HardwareStatus? status;

  const FprintException(this.message, {this.status});

  @override
  String toString() => message;
}

/// Sesión activa de registro biométrico.
abstract class FprintEnrollmentSession {
  Stream<EnrollmentUpdate> get updates;
  Future<void> cancel();
}

/// Sesión activa de verificación biométrica.
abstract class FprintVerificationSession {
  Stream<VerificationUpdate> get updates;
  Future<void> cancel();
}

/// Contrato agnóstico para interactuar con lectores de huellas en Linux (D-Bus o mocks en test).
abstract class FprintBackend {
  String get username;

  Future<({HardwareStatus status, List<FprintDeviceInfo> devices, String? error})>
      discoverDevices();

  Future<List<FingerprintItem>> listEnrolledFingers(FprintDeviceInfo device);

  Future<bool> updateFingerName(String fingerCode, String newName);

  Future<({bool success, String? error})> deleteFinger(
    FprintDeviceInfo device,
    String fingerCode,
  );

  Future<({bool success, String? error})> deleteAllFingers(
    FprintDeviceInfo device,
  );

  Future<FprintEnrollmentSession> startEnrollment(
    FprintDeviceInfo device,
    String fingerCode,
  );

  Future<FprintVerificationSession> startVerification(
    FprintDeviceInfo device,
    String fingerCode,
  );

  Future<SystemDiagnostics> runDiagnostics();

  Future<void> dispose();
}

/// Implementación universal mediante System D-Bus (net.reactivated.Fprint).
/// Funciona con cualquier lector soportado por libfprint tanto en Linux nativo como en Flatpak.
class DBusFprintBackend implements FprintBackend {
  static const String _busName = 'net.reactivated.Fprint';
  static const String _managerPath = '/net/reactivated/Fprint/Manager';
  static const String _managerInterface = 'net.reactivated.Fprint.Manager';
  static const String _deviceInterface = 'net.reactivated.Fprint.Device';

  DBusClient? _client;

  @override
  String get username =>
      Platform.environment['USER'] ??
      Platform.environment['LOGNAME'] ??
      'user';

  DBusClient _ensureClient() {
    if (_client != null) return _client!;
    final envAddress = Platform.environment['DBUS_SYSTEM_BUS_ADDRESS'];
    if (envAddress != null && envAddress.trim().isNotEmpty) {
      _client = DBusClient(DBusAddress(envAddress));
      return _client!;
    }
    if (FileSystemEntity.typeSync('/run/dbus/system_bus_socket') !=
        FileSystemEntityType.notFound) {
      _client = DBusClient(DBusAddress('unix:path=/run/dbus/system_bus_socket'));
      return _client!;
    }
    _client = DBusClient.system();
    return _client!;
  }

  Future<void> _resetClientOnTransportError() async {
    try {
      await _client?.close();
    } catch (_) {}
    _client = null;
  }

  @override
  Future<({HardwareStatus status, List<FprintDeviceInfo> devices, String? error})>
      discoverDevices() async {
    try {
      final client = _ensureClient();
      final manager = DBusRemoteObject(
        client,
        name: _busName,
        path: DBusObjectPath(_managerPath),
      );

      final result = await manager
          .callMethod(
            _managerInterface,
            'GetDevices',
            const [],
            replySignature: DBusSignature('ao'),
          )
          .timeout(const Duration(seconds: 6));

      final paths = result.returnValues[0].asObjectPathArray().toList();
      if (paths.isEmpty) {
        return (
          status: HardwareStatus.noDeviceFound,
          devices: const <FprintDeviceInfo>[],
          error: 'No se encontró ningún lector de huellas compatible conectado.',
        );
      }

      final devices = <FprintDeviceInfo>[];
      for (final path in paths) {
        final devObj = DBusRemoteObject(client, name: _busName, path: path);
        final props = await devObj.getAllProperties(_deviceInterface);
        final rawName = props['name']?.asString() ?? 'Lector biométrico';
        final stages = props['num-enroll-stages']?.asInt32() ?? 8;
        final scanTypeStr = props['scan-type']?.asString() ?? 'press';
        final fingerPresent = props['finger-present']?.asBoolean() ?? false;
        final fingerNeeded = props['finger-needed']?.asBoolean() ?? false;

        devices.add(
          FprintDeviceInfo(
            objectPath: path.value,
            name: rawName,
            numEnrollStages: stages > 0 ? stages : 8,
            scanType: ScanType.fromFprintd(scanTypeStr),
            fingerPresent: fingerPresent,
            fingerNeeded: fingerNeeded,
          ),
        );
      }

      return (status: HardwareStatus.ready, devices: devices, error: null);
    } on DBusServiceUnknownException {
      return (
        status: HardwareStatus.serviceUnavailable,
        devices: const <FprintDeviceInfo>[],
        error: 'El servicio del sistema fprintd no está disponible o no está instalado.',
      );
    } on DBusMethodResponseException catch (e) {
      if (e.errorName.contains('AccessDenied') ||
          e.errorName.contains('PermissionDenied')) {
        return (
          status: HardwareStatus.permissionDenied,
          devices: const <FprintDeviceInfo>[],
          error: 'Permiso D-Bus denegado al consultar net.reactivated.Fprint.',
        );
      }
      if (e.errorName.contains('NoSuchDevice')) {
        return (
          status: HardwareStatus.noDeviceFound,
          devices: const <FprintDeviceInfo>[],
          error: 'No se detectó ningún dispositivo biométrico activo.',
        );
      }
      return (
        status: HardwareStatus.error,
        devices: const <FprintDeviceInfo>[],
        error: _formatDBusError(e),
      );
    } on SocketException {
      await _resetClientOnTransportError();
      return (
        status: HardwareStatus.serviceUnavailable,
        devices: const <FprintDeviceInfo>[],
        error: 'No se pudo conectar al socket del bus del sistema (D-Bus).',
      );
    } on TimeoutException {
      return (
        status: HardwareStatus.serviceUnavailable,
        devices: const <FprintDeviceInfo>[],
        error: 'El servicio fprintd tardó demasiado en responder.',
      );
    } catch (e) {
      return (
        status: HardwareStatus.error,
        devices: const <FprintDeviceInfo>[],
        error: 'Error inesperado al consultar lectores: $e',
      );
    }
  }

  @override
  Future<List<FingerprintItem>> listEnrolledFingers(
      FprintDeviceInfo device) async {
    final client = _ensureClient();
    final devObj = DBusRemoteObject(
      client,
      name: _busName,
      path: DBusObjectPath(device.objectPath),
    );

    try {
      final result = await devObj.callMethod(
        _deviceInterface,
        'ListEnrolledFingers',
        [DBusString(username)],
        replySignature: DBusSignature('as'),
      );
      final codes = result.returnValues[0].asStringArray().toList();
      final aliases = await AliasService.loadAliases();

      return [
        for (int i = 0; i < codes.length; i++)
          FingerprintItem(
            id: 'fp-${(i + 1).toString().padLeft(2, '0')}',
            name: aliases[codes[i]] ?? FingerprintItem.getFriendlyName(codes[i]),
            fingerCode: codes[i],
            fingerName: FingerprintItem.getFriendlyName(codes[i]),
            devicePath: device.objectPath,
          ),
      ];
    } on DBusMethodResponseException catch (e) {
      // fprintd lanza Error.NoEnrolledPrints cuando el usuario no tiene huellas registradas.
      if (e.errorName.contains('NoEnrolledPrints')) {
        return const [];
      }
      rethrow;
    }
  }

  @override
  Future<bool> updateFingerName(String fingerCode, String newName) {
    return AliasService.saveAlias(fingerCode, newName);
  }

  @override
  Future<({bool success, String? error})> deleteFinger(
    FprintDeviceInfo device,
    String fingerCode,
  ) async {
    final client = _ensureClient();
    final devObj = DBusRemoteObject(
      client,
      name: _busName,
      path: DBusObjectPath(device.objectPath),
    );

    bool claimed = false;
    try {
      await devObj.callMethod(
        _deviceInterface,
        'Claim',
        [DBusString(username)],
        replySignature: DBusSignature(''),
        allowInteractiveAuthorization: true,
      );
      claimed = true;

      await devObj.callMethod(
        _deviceInterface,
        'DeleteEnrolledFinger',
        [DBusString(fingerCode)],
        replySignature: DBusSignature(''),
        allowInteractiveAuthorization: true,
      );
      await AliasService.removeAlias(fingerCode);
      return (success: true, error: null);
    } on DBusMethodResponseException catch (e) {
      if (e.errorName.contains('NoEnrolledPrints')) {
        await AliasService.removeAlias(fingerCode);
        return (success: true, error: null);
      }
      if (e.errorName.contains('UnknownMethod') &&
          !UsbMaintenanceService.isRunningInFlatpak) {
        final cli = await Process.run('fprintd-delete', [username, '-f', fingerCode]);
        if (cli.exitCode == 0) {
          await AliasService.removeAlias(fingerCode);
          return (success: true, error: null);
        }
      }
      return (success: false, error: _formatDBusError(e));
    } catch (e) {
      return (success: false, error: 'Error al eliminar la huella: $e');
    } finally {
      if (claimed) {
        try {
          await devObj.callMethod(
            _deviceInterface,
            'Release',
            const [],
            replySignature: DBusSignature(''),
          );
        } catch (_) {}
      }
    }
  }

  @override
  Future<({bool success, String? error})> deleteAllFingers(
    FprintDeviceInfo device,
  ) async {
    final client = _ensureClient();
    final devObj = DBusRemoteObject(
      client,
      name: _busName,
      path: DBusObjectPath(device.objectPath),
    );

    bool claimed = false;
    try {
      await devObj.callMethod(
        _deviceInterface,
        'Claim',
        [DBusString(username)],
        replySignature: DBusSignature(''),
        allowInteractiveAuthorization: true,
      );
      claimed = true;

      try {
        await devObj.callMethod(
          _deviceInterface,
          'DeleteEnrolledFingers2',
          const [],
          replySignature: DBusSignature(''),
          allowInteractiveAuthorization: true,
        );
      } on DBusMethodResponseException catch (e) {
        if (e.errorName.contains('UnknownMethod')) {
          await devObj.callMethod(
            _deviceInterface,
            'DeleteEnrolledFingers',
            [DBusString(username)],
            replySignature: DBusSignature(''),
            allowInteractiveAuthorization: true,
          );
        } else {
          rethrow;
        }
      }

      await AliasService.clearAllAliases();
      return (success: true, error: null);
    } on DBusMethodResponseException catch (e) {
      if (e.errorName.contains('NoEnrolledPrints')) {
        await AliasService.clearAllAliases();
        return (success: true, error: null);
      }
      return (success: false, error: _formatDBusError(e));
    } catch (e) {
      return (success: false, error: 'Error al borrar todas las huellas: $e');
    } finally {
      if (claimed) {
        try {
          await devObj.callMethod(
            _deviceInterface,
            'Release',
            const [],
            replySignature: DBusSignature(''),
          );
        } catch (_) {}
      }
    }
  }

  @override
  Future<FprintEnrollmentSession> startEnrollment(
    FprintDeviceInfo device,
    String fingerCode,
  ) async {
    final client = _ensureClient();
    final devObj = DBusRemoteObject(
      client,
      name: _busName,
      path: DBusObjectPath(device.objectPath),
    );

    bool claimed = false;
    try {
      await devObj.callMethod(
        _deviceInterface,
        'Claim',
        [DBusString(username)],
        replySignature: DBusSignature(''),
        allowInteractiveAuthorization: true,
      );
      claimed = true;

      final session = _DBusEnrollmentSession(devObj, device);
      await session.start(fingerCode);
      return session;
    } on DBusMethodResponseException catch (e) {
      if (claimed) {
        try {
          await devObj.callMethod(
            _deviceInterface,
            'Release',
            const [],
            replySignature: DBusSignature(''),
          );
        } catch (_) {}
      }
      throw FprintException(_formatDBusError(e));
    } catch (e) {
      if (claimed) {
        try {
          await devObj.callMethod(
            _deviceInterface,
            'Release',
            const [],
            replySignature: DBusSignature(''),
          );
        } catch (_) {}
      }
      throw FprintException('No se pudo iniciar el registro en el lector: $e');
    }
  }

  @override
  Future<FprintVerificationSession> startVerification(
    FprintDeviceInfo device,
    String fingerCode,
  ) async {
    final client = _ensureClient();
    final devObj = DBusRemoteObject(
      client,
      name: _busName,
      path: DBusObjectPath(device.objectPath),
    );

    bool claimed = false;
    try {
      await devObj.callMethod(
        _deviceInterface,
        'Claim',
        [DBusString(username)],
        replySignature: DBusSignature(''),
        allowInteractiveAuthorization: true,
      );
      claimed = true;

      final session = _DBusVerificationSession(devObj, device, fingerCode);
      await session.start(fingerCode);
      return session;
    } on DBusMethodResponseException catch (e) {
      if (claimed) {
        try {
          await devObj.callMethod(
            _deviceInterface,
            'Release',
            const [],
            replySignature: DBusSignature(''),
          );
        } catch (_) {}
      }
      throw FprintException(_formatDBusError(e));
    } catch (e) {
      if (claimed) {
        try {
          await devObj.callMethod(
            _deviceInterface,
            'Release',
            const [],
            replySignature: DBusSignature(''),
          );
        } catch (_) {}
      }
      throw FprintException('No se pudo iniciar la verificación en el lector: $e');
    }
  }

  @override
  Future<SystemDiagnostics> runDiagnostics() async {
    final discovery = await discoverDevices();
    final usbDevices = await UsbMaintenanceService.detectUsbFingerprintReaders();
    final hasPkexec = await UsbMaintenanceService.hasBinary('pkexec');
    final hasUsbreset = await UsbMaintenanceService.hasBinary('usbreset');
    final hasPamAuthUpdate =
        await UsbMaintenanceService.hasBinary('pam-auth-update');
    final hasAuthselect = await UsbMaintenanceService.hasBinary('authselect');
    final hasFprintdCli = await UsbMaintenanceService.hasBinary('fprintd-list');
    final isPamEnabled = await UsbMaintenanceService.isPamAuthenticationEnabled();
    final isPolkitInstalled = await UsbMaintenanceService.isPolkitConfigured();

    final dbusConnected = _client != null &&
        discovery.status != HardwareStatus.serviceUnavailable;

    return SystemDiagnostics(
      isRunningInFlatpak: UsbMaintenanceService.isRunningInFlatpak,
      dbusConnected: dbusConnected || discovery.status == HardwareStatus.ready || discovery.status == HardwareStatus.noDeviceFound,
      fprintdAvailable: discovery.status == HardwareStatus.ready ||
          discovery.status == HardwareStatus.noDeviceFound ||
          discovery.status == HardwareStatus.permissionDenied,
      hasPkexec: hasPkexec,
      hasUsbreset: hasUsbreset,
      hasPamAuthUpdate: hasPamAuthUpdate,
      hasAuthselect: hasAuthselect,
      hasFprintdCli: hasFprintdCli,
      isPamEnabled: isPamEnabled,
      isPolkitRuleInstalled: isPolkitInstalled,
      usbDevices: usbDevices,
      devices: discovery.devices,
      status: discovery.status,
      errorMessage: discovery.error,
    );
  }

  @override
  Future<void> dispose() async {
    await _resetClientOnTransportError();
  }

  static String _formatDBusError(DBusMethodResponseException e) {
    if (e.errorName.contains('AlreadyInUse')) {
      return 'El lector está siendo utilizado por otro proceso (ej. pantalla de bloqueo o terminal).';
    }
    if (e.errorName.contains('PermissionDenied')) {
      return 'Permiso denegado por Polkit para acceder al lector biométrico.';
    }
    if (e.errorName.contains('NoEnrolledPrints')) {
      return 'No hay huellas inscritas en el sistema para este usuario.';
    }
    if (e.errorName.contains('InvalidFingername')) {
      return 'El identificador de dedo seleccionado no es compatible con este lector.';
    }
    if (e.errorName.contains('PrintsNotFound')) {
      return 'No se encontraron huellas coincidentes para este dedo.';
    }
    final detail = e.response.values.isNotEmpty
        ? e.response.values.first.toNative().toString()
        : '';
    return detail.isNotEmpty ? '$detail (${e.errorName})' : e.errorName;
  }
}

class _DBusEnrollmentSession implements FprintEnrollmentSession {
  static const String _deviceInterface = 'net.reactivated.Fprint.Device';

  final DBusRemoteObject _deviceObj;
  final FprintDeviceInfo _device;
  final StreamController<EnrollmentUpdate> _controller =
      StreamController<EnrollmentUpdate>.broadcast();

  StreamSubscription<DBusSignal>? _enrollSub;
  StreamSubscription<DBusPropertiesChangedSignal>? _propsSub;

  int _currentStage = 0;
  bool _fingerPresent = false;
  bool _finished = false;

  _DBusEnrollmentSession(this._deviceObj, this._device);

  @override
  Stream<EnrollmentUpdate> get updates => _controller.stream;

  Future<void> start(String fingerCode) async {
    final enrollSignals = DBusRemoteObjectSignalStream(
      object: _deviceObj,
      interface: _deviceInterface,
      name: 'EnrollStatus',
      signature: DBusSignature('sb'),
    );

    _enrollSub = enrollSignals.listen((signal) {
      if (_finished) return;
      final result = signal.values[0].asString();
      final done = signal.values[1].asBoolean();
      _handleStatus(result, done);
    });

    _propsSub = _deviceObj.propertiesChanged.listen((signal) {
      if (_finished || signal.propertiesInterface != _deviceInterface) return;
      final fp = signal.changedProperties['finger-present'];
      if (fp != null) {
        _fingerPresent = fp.asBoolean();
        if (!_controller.isClosed) {
          _controller.add(
            EnrollmentUpdate(
              stage: _currentStage,
              totalStages: _device.numEnrollStages,
              resultCode: _fingerPresent ? 'finger-present' : 'finger-removed',
              message: _fingerPresent
                  ? 'Sensor leyendo tu huella...'
                  : (_currentStage == 0
                      ? _initialPrompt()
                      : 'Levanta el dedo y vuelve a colocarlo.'),
              fingerPresent: _fingerPresent,
            ),
          );
        }
      }
    });

    await _deviceObj.callMethod(
      _deviceInterface,
      'EnrollStart',
      [DBusString(fingerCode)],
      replySignature: DBusSignature(''),
      allowInteractiveAuthorization: true,
    );

    if (!_controller.isClosed) {
      _controller.add(
        EnrollmentUpdate(
          stage: 0,
          totalStages: _device.numEnrollStages,
          resultCode: 'enroll-started',
          message: _initialPrompt(),
          fingerPresent: _fingerPresent,
        ),
      );
    }
  }

  String _initialPrompt() {
    return _device.scanType == ScanType.swipe
        ? 'Desliza tu dedo suavemente sobre el sensor.'
        : 'Coloca tu dedo firmemente sobre el sensor.';
  }

  void _handleStatus(String result, bool done) {
    final total = _device.numEnrollStages;
    final isSwipe = _device.scanType == ScanType.swipe;

    switch (result) {
      case 'enroll-stage-passed':
        _currentStage = (_currentStage + 1).clamp(0, total);
        _emit(
          EnrollmentUpdate(
            stage: _currentStage,
            totalStages: total,
            resultCode: result,
            message: isSwipe
                ? '¡Pasada $_currentStage de $total capturada! Vuelve a deslizar el dedo.'
                : '¡Muestra $_currentStage de $total capturada! Levanta el dedo y apoya ligeramente distinto.',
            fingerPresent: _fingerPresent,
          ),
        );
        break;

      case 'enroll-completed':
        _currentStage = total;
        _emit(
          EnrollmentUpdate(
            stage: total,
            totalStages: total,
            resultCode: result,
            message: '¡Huella registrada exitosamente en el sistema!',
            isCompleted: true,
            fingerPresent: _fingerPresent,
          ),
        );
        _cleanup(stopEnroll: !done);
        break;

      case 'enroll-retry-scan':
        _emit(
          EnrollmentUpdate(
            stage: _currentStage,
            totalStages: total,
            resultCode: result,
            message: isSwipe
                ? 'No se pudo leer bien. Desliza el dedo de forma uniforme.'
                : 'Lectura incompleta. Mantén el dedo un instante más sobre el sensor.',
            isRetry: true,
            fingerPresent: _fingerPresent,
          ),
        );
        break;

      case 'enroll-swipe-too-short':
        _emit(
          EnrollmentUpdate(
            stage: _currentStage,
            totalStages: total,
            resultCode: result,
            message: 'Deslizamiento demasiado rápido o corto. Hazlo más despacio.',
            isRetry: true,
            fingerPresent: _fingerPresent,
          ),
        );
        break;

      case 'enroll-finger-not-centered':
        _emit(
          EnrollmentUpdate(
            stage: _currentStage,
            totalStages: total,
            resultCode: result,
            message: 'Centra mejor la yema del dedo sobre el sensor.',
            isRetry: true,
            fingerPresent: _fingerPresent,
          ),
        );
        break;

      case 'enroll-remove-and-retry':
        _emit(
          EnrollmentUpdate(
            stage: _currentStage,
            totalStages: total,
            resultCode: result,
            message: 'Retira completamente el dedo del lector y vuelve a colocarlo.',
            isRetry: true,
            fingerPresent: _fingerPresent,
          ),
        );
        break;

      case 'enroll-data-full':
        _emit(
          EnrollmentUpdate(
            stage: _currentStage,
            totalStages: total,
            resultCode: result,
            message: 'La memoria del lector biométrico está llena. Elimina una huella antes de añadir otra.',
            isError: true,
            fingerPresent: _fingerPresent,
          ),
        );
        _cleanup(stopEnroll: !done);
        break;

      case 'enroll-disconnected':
        _emit(
          EnrollmentUpdate(
            stage: _currentStage,
            totalStages: total,
            resultCode: result,
            message: 'El lector de huellas se desconectó durante el registro.',
            isError: true,
            fingerPresent: false,
          ),
        );
        _cleanup(stopEnroll: false);
        break;

      default:
        _emit(
          EnrollmentUpdate(
            stage: _currentStage,
            totalStages: total,
            resultCode: result,
            message: done
                ? 'El proceso de registro finalizó con error ($result).'
                : 'Intenta apoyar el dedo nuevamente ($result).',
            isError: done,
            isRetry: !done,
            fingerPresent: _fingerPresent,
          ),
        );
        if (done) {
          _cleanup(stopEnroll: false);
        }
        break;
    }
  }

  void _emit(EnrollmentUpdate update) {
    if (!_controller.isClosed) {
      _controller.add(update);
    }
  }

  Future<void> _cleanup({required bool stopEnroll}) async {
    if (_finished) return;
    _finished = true;

    await _enrollSub?.cancel();
    await _propsSub?.cancel();
    _enrollSub = null;
    _propsSub = null;

    if (stopEnroll) {
      try {
        await _deviceObj.callMethod(
          _deviceInterface,
          'EnrollStop',
          const [],
          replySignature: DBusSignature(''),
        );
      } catch (_) {}
    }
    try {
      await _deviceObj.callMethod(
        _deviceInterface,
        'Release',
        const [],
        replySignature: DBusSignature(''),
      );
    } catch (_) {}

    if (!_controller.isClosed) {
      await _controller.close();
    }
  }

  @override
  Future<void> cancel() => _cleanup(stopEnroll: true);
}

class _DBusVerificationSession implements FprintVerificationSession {
  static const String _deviceInterface = 'net.reactivated.Fprint.Device';

  final DBusRemoteObject _deviceObj;
  final FprintDeviceInfo _device;
  final String _requestedFingerCode;
  final StreamController<VerificationUpdate> _controller =
      StreamController<VerificationUpdate>.broadcast();

  StreamSubscription<DBusSignal>? _verifySub;
  StreamSubscription<DBusSignal>? _fingerSelectedSub;
  StreamSubscription<DBusPropertiesChangedSignal>? _propsSub;

  String? _selectedFinger;
  bool _fingerPresent = false;
  bool _finished = false;

  _DBusVerificationSession(
    this._deviceObj,
    this._device,
    this._requestedFingerCode,
  );

  @override
  Stream<VerificationUpdate> get updates => _controller.stream;

  Future<void> start(String fingerCode) async {
    final selectedSignals = DBusRemoteObjectSignalStream(
      object: _deviceObj,
      interface: _deviceInterface,
      name: 'VerifyFingerSelected',
      signature: DBusSignature('s'),
    );
    _fingerSelectedSub = selectedSignals.listen((signal) {
      if (_finished) return;
      _selectedFinger = signal.values[0].asString();
    });

    final verifySignals = DBusRemoteObjectSignalStream(
      object: _deviceObj,
      interface: _deviceInterface,
      name: 'VerifyStatus',
      signature: DBusSignature('sb'),
    );
    _verifySub = verifySignals.listen((signal) {
      if (_finished) return;
      final result = signal.values[0].asString();
      final done = signal.values[1].asBoolean();
      _handleStatus(result, done);
    });

    _propsSub = _deviceObj.propertiesChanged.listen((signal) {
      if (_finished || signal.propertiesInterface != _deviceInterface) return;
      final fp = signal.changedProperties['finger-present'];
      if (fp != null) {
        _fingerPresent = fp.asBoolean();
        if (!_controller.isClosed) {
          _controller.add(
            VerificationUpdate(
              state: VerificationStepState.scanning,
              resultCode: _fingerPresent ? 'finger-present' : 'finger-removed',
              message: _fingerPresent
                  ? 'Analizando huella dactilar...'
                  : _waitingMessage(),
              matchedFingerCode: _selectedFinger,
              fingerPresent: _fingerPresent,
            ),
          );
        }
      }
    });

    await _deviceObj.callMethod(
      _deviceInterface,
      'VerifyStart',
      [DBusString(fingerCode)],
      replySignature: DBusSignature(''),
      allowInteractiveAuthorization: true,
    );

    if (!_controller.isClosed) {
      _controller.add(
        VerificationUpdate(
          state: VerificationStepState.scanning,
          resultCode: 'verify-started',
          message: _waitingMessage(),
          matchedFingerCode: _selectedFinger,
          fingerPresent: _fingerPresent,
        ),
      );
    }
  }

  String _waitingMessage() {
    final action = _device.scanType == ScanType.swipe
        ? 'Desliza tu dedo sobre el lector'
        : 'Coloca tu dedo en el lector';
    if (_requestedFingerCode == kAnyFingerCode) {
      return '$action para verificar contra cualquiera de tus huellas.';
    }
    return '$action (${FingerprintItem.getFriendlyName(_requestedFingerCode)}).';
  }

  void _handleStatus(String result, bool done) {
    final resolvedFinger = _selectedFinger ??
        (_requestedFingerCode == kAnyFingerCode ? null : _requestedFingerCode);

    switch (result) {
      case 'verify-match':
        _emit(
          VerificationUpdate(
            state: VerificationStepState.match,
            resultCode: result,
            message: '¡Huella verificada con éxito!',
            matchedFingerCode: resolvedFinger,
            fingerPresent: _fingerPresent,
            done: true,
          ),
        );
        _cleanup(stopVerify: !done);
        break;

      case 'verify-no-match':
        _emit(
          VerificationUpdate(
            state: VerificationStepState.noMatch,
            resultCode: result,
            message: 'La huella no coincide. Intenta de nuevo.',
            matchedFingerCode: resolvedFinger,
            fingerPresent: _fingerPresent,
            done: done,
          ),
        );
        if (done) {
          _cleanup(stopVerify: false);
        }
        break;

      case 'verify-retry-scan':
      case 'verify-swipe-too-short':
      case 'verify-finger-not-centered':
      case 'verify-remove-and-retry':
        final retryMsg = switch (result) {
          'verify-swipe-too-short' => 'Deslizamiento demasiado rápido. Hazlo más lento.',
          'verify-finger-not-centered' => 'Centra la yema del dedo sobre el sensor.',
          'verify-remove-and-retry' => 'Retira el dedo y vuelve a colocarlo.',
          _ => 'Lectura incompleta. Apoya el dedo con firmeza.',
        };
        _emit(
          VerificationUpdate(
            state: VerificationStepState.retry,
            resultCode: result,
            message: retryMsg,
            matchedFingerCode: resolvedFinger,
            fingerPresent: _fingerPresent,
            done: done,
          ),
        );
        if (done) {
          _cleanup(stopVerify: false);
        }
        break;

      case 'verify-disconnected':
        _emit(
          VerificationUpdate(
            state: VerificationStepState.error,
            resultCode: result,
            message: 'El lector biométrico se desconectó.',
            fingerPresent: false,
            done: true,
          ),
        );
        _cleanup(stopVerify: false);
        break;

      default:
        _emit(
          VerificationUpdate(
            state: VerificationStepState.error,
            resultCode: result,
            message: 'Error en verificación ($result).',
            fingerPresent: _fingerPresent,
            done: done,
          ),
        );
        if (done) {
          _cleanup(stopVerify: false);
        }
        break;
    }
  }

  void _emit(VerificationUpdate update) {
    if (!_controller.isClosed) {
      _controller.add(update);
    }
  }

  Future<void> _cleanup({required bool stopVerify}) async {
    if (_finished) return;
    _finished = true;

    await _verifySub?.cancel();
    await _fingerSelectedSub?.cancel();
    await _propsSub?.cancel();
    _verifySub = null;
    _fingerSelectedSub = null;
    _propsSub = null;

    if (stopVerify) {
      try {
        await _deviceObj.callMethod(
          _deviceInterface,
          'VerifyStop',
          const [],
          replySignature: DBusSignature(''),
        );
      } catch (_) {}
    }
    try {
      await _deviceObj.callMethod(
        _deviceInterface,
        'Release',
        const [],
        replySignature: DBusSignature(''),
      );
    } catch (_) {}

    if (!_controller.isClosed) {
      await _controller.close();
    }
  }

  @override
  Future<void> cancel() => _cleanup(stopVerify: true);
}
