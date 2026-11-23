import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'config/monetization_config.dart';
import 'models/fprint_device_info.dart';
import 'models/fingerprint_item.dart';
import 'models/monetization_models.dart';
import 'models/verification_log.dart';
import 'services/alias_service.dart';
import 'services/fprint_service.dart';
import 'services/monetization_service.dart';
import 'services/usb_maintenance_service.dart';
import 'theme/app_theme.dart';
import 'widgets/edit_name_dialog.dart';
import 'widgets/enrollment_dialog.dart';
import 'widgets/fingerprint_scanner_widget.dart';
import 'widgets/maintenance_dialog.dart';
import 'widgets/sponsor_banner.dart';
import 'widgets/support_dialog.dart';
import 'widgets/verification_history_dialog.dart';

void main() {
  runApp(const FprintManagerApp());
}

class FprintManagerApp extends StatefulWidget {
  final FprintBackend? backend;
  final MonetizationBackend? monetizationBackend;

  const FprintManagerApp({
    super.key,
    this.backend,
    this.monetizationBackend,
  });

  @override
  State<FprintManagerApp> createState() => _FprintManagerAppState();
}

class _FprintManagerAppState extends State<FprintManagerApp> {
  ThemeMode _themeMode = ThemeMode.system;
  late final FprintBackend _backend;
  late final MonetizationBackend _monetizationBackend;
  late final bool _ownsBackend;

  @override
  void initState() {
    super.initState();
    _ownsBackend = widget.backend == null;
    _backend = widget.backend ?? DBusFprintBackend();
    _monetizationBackend = widget.monetizationBackend ?? HttpMonetizationBackend();
  }

  @override
  void dispose() {
    if (_ownsBackend) {
      unawaited(_backend.dispose());
    }
    super.dispose();
  }

  void _toggleTheme() {
    final isCurrentlyDark =
        _themeMode == ThemeMode.dark ||
        (_themeMode == ThemeMode.system &&
            WidgetsBinding.instance.platformDispatcher.platformBrightness ==
                Brightness.dark);
    setState(() {
      _themeMode = isCurrentlyDark ? ThemeMode.light : ThemeMode.dark;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fprint-Manager',
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      home: FprintHomePage(
        backend: _backend,
        monetizationBackend: _monetizationBackend,
        onToggleTheme: _toggleTheme,
        currentThemeMode: _themeMode,
      ),
    );
  }
}

class FprintHomePage extends StatefulWidget {
  final FprintBackend backend;
  final MonetizationBackend monetizationBackend;
  final VoidCallback onToggleTheme;
  final ThemeMode currentThemeMode;

  const FprintHomePage({
    super.key,
    required this.backend,
    required this.monetizationBackend,
    required this.onToggleTheme,
    required this.currentThemeMode,
  });

  @override
  State<FprintHomePage> createState() => _FprintHomePageState();
}

class _FprintHomePageState extends State<FprintHomePage> {
  HardwareStatus _hardwareStatus = HardwareStatus.loading;
  String? _hardwareError;
  List<FprintDeviceInfo> _devices = [];
  FprintDeviceInfo? _activeDevice;
  List<UsbFingerprintDevice> _usbDevices = [];

  List<FingerprintItem> _fingerprints = [];
  final List<VerificationLog> _verificationLogs = [];

  SupporterLicenseState _licenseState = const SupporterLicenseState.inactive(
    provider: MonetizationConfig.licenseProvider,
  );
  EthicalAdItem? _currentAd;

  bool _isPolkitConfigured = false;
  bool _isPamEnabled = false;
  bool _isRunningInFlatpak = false;
  bool _isRestartingUsb = false;

  // Target de verificación: por defecto 'any' para soportar cualquier dedo inscrito.
  String _selectedVerifyFingerCode = kAnyFingerCode;

  SensorState _sensorState = SensorState.idle;
  bool _fingerPresent = false;
  String? _lastMatchedFingerName;
  String _sensorStatusText =
      'Selecciona una huella o usa detección automática para probar el lector.';

  // Índice de pestaña en modo ventana estrecha: 0 = Verificar, 1 = Huellas
  int _narrowSectionIndex = 0;

  Timer? _resetTimer;
  FprintVerificationSession? _activeVerifySession;
  StreamSubscription<VerificationUpdate>? _verifySub;
  final FocusNode _keyboardFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _refreshAll();
    unawaited(_initMonetization());
  }

  Future<void> _initMonetization() async {
    final license = await widget.monetizationBackend.loadLicenseState();
    if (!mounted) return;
    setState(() => _licenseState = license);

    if (!license.isSupporter) {
      final ad = await widget.monetizationBackend.fetchAd();
      if (!mounted || _licenseState.isSupporter) return;
      setState(() => _currentAd = ad);
    }
  }

  @override
  void dispose() {
    _resetTimer?.cancel();
    _verifySub?.cancel();
    unawaited(_activeVerifySession?.cancel());
    _keyboardFocusNode.dispose();
    super.dispose();
  }

  Future<void> _refreshAll() async {
    await _cancelActiveVerification(silent: true);
    if (!mounted) return;
    setState(() {
      _hardwareStatus = HardwareStatus.loading;
      _hardwareError = null;
    });

    final diagFuture = widget.backend.runDiagnostics();
    final diag = await diagFuture;
    if (!mounted) return;

    FprintDeviceInfo? chosen = _activeDevice;
    if (diag.devices.isNotEmpty) {
      final keepExisting = chosen != null &&
          diag.devices.any((d) => d.objectPath == chosen!.objectPath);
      chosen = keepExisting
          ? diag.devices.firstWhere((d) => d.objectPath == chosen!.objectPath)
          : diag.devices.first;
    } else {
      chosen = null;
    }

    List<FingerprintItem> prints = [];
    HardwareStatus finalStatus = diag.status;
    String? finalError = diag.errorMessage;

    if (finalStatus == HardwareStatus.ready && chosen != null) {
      try {
        prints = await widget.backend.listEnrolledFingers(chosen);
      } catch (e) {
        finalStatus = HardwareStatus.error;
        finalError = 'No se pudieron leer las huellas del dispositivo: $e';
      }
    }

    if (!mounted) return;
    setState(() {
      _hardwareStatus = finalStatus;
      _hardwareError = finalError;
      _devices = diag.devices;
      _activeDevice = chosen;
      _usbDevices = diag.usbDevices;
      _fingerprints = prints;
      _isPolkitConfigured = diag.isPolkitRuleInstalled;
      _isPamEnabled = diag.isPamEnabled;
      _isRunningInFlatpak = diag.isRunningInFlatpak;

      if (_fingerprints.isEmpty) {
        _selectedVerifyFingerCode = kAnyFingerCode;
      } else if (_selectedVerifyFingerCode != kAnyFingerCode &&
          !_fingerprints.any((f) => f.fingerCode == _selectedVerifyFingerCode)) {
        _selectedVerifyFingerCode = kAnyFingerCode;
      }

      if (finalStatus == HardwareStatus.ready && chosen != null) {
        _sensorState = SensorState.idle;
        _sensorStatusText = _defaultIdlePrompt(chosen);
      } else {
        _sensorState = SensorState.unavailable;
      }
    });
  }

  String _defaultIdlePrompt(FprintDeviceInfo device) {
    if (_fingerprints.isEmpty) {
      return 'Aún no tienes huellas registradas en ${device.name}. Añade una desde el panel lateral.';
    }
    return device.scanType == ScanType.swipe
        ? 'Pulsa el lector o Espacio y desliza tu dedo para verificar.'
        : 'Pulsa el lector o Espacio y coloca tu dedo para verificar.';
  }

  Future<void> _selectDevice(FprintDeviceInfo device) async {
    await _cancelActiveVerification(silent: true);
    if (!mounted) return;
    setState(() {
      _activeDevice = device;
      _hardwareStatus = HardwareStatus.loading;
    });

    try {
      final prints = await widget.backend.listEnrolledFingers(device);
      if (!mounted) return;
      setState(() {
        _hardwareStatus = HardwareStatus.ready;
        _fingerprints = prints;
        _selectedVerifyFingerCode = kAnyFingerCode;
        _sensorState = SensorState.idle;
        _sensorStatusText = _defaultIdlePrompt(device);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _hardwareStatus = HardwareStatus.error;
        _hardwareError = e.toString();
        _sensorState = SensorState.unavailable;
      });
    }
  }

  Future<void> _startRealVerification() async {
    final device = _activeDevice;
    if (_hardwareStatus != HardwareStatus.ready || device == null) return;

    if (_sensorState == SensorState.scanning) {
      await _cancelActiveVerification();
      return;
    }

    if (_fingerprints.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Registra al menos una huella antes de verificar.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    _resetTimer?.cancel();
    final targetCode = _selectedVerifyFingerCode;
    final targetLabel = _resolveFingerDisplayName(targetCode);

    setState(() {
      _sensorState = SensorState.scanning;
      _fingerPresent = false;
      _lastMatchedFingerName = null;
      _sensorStatusText = targetCode == kAnyFingerCode
          ? 'Sensor activo (detección automática). Apoya cualquiera de tus huellas...'
          : 'Sensor activo (-f $targetCode). Apoya "$targetLabel" en el lector...';
    });

    try {
      final session = await widget.backend.startVerification(device, targetCode);
      if (!mounted) {
        await session.cancel();
        return;
      }
      _activeVerifySession = session;
      _verifySub = session.updates.listen(
        (update) {
          if (!mounted) return;
          final matchedCode = update.matchedFingerCode ?? targetCode;
          final matchedName = _resolveFingerDisplayName(matchedCode);

          switch (update.state) {
            case VerificationStepState.scanning:
              setState(() {
                _fingerPresent = update.fingerPresent;
                _sensorStatusText = update.message;
              });
              break;
            case VerificationStepState.retry:
              setState(() {
                _fingerPresent = update.fingerPresent;
                _sensorStatusText = update.message;
              });
              if (update.done) _scheduleReset();
              break;
            case VerificationStepState.match:
              final rawMatchedCode = update.matchedFingerCode;
              final effectiveMatchedCode =
                  (rawMatchedCode != null && rawMatchedCode != kAnyFingerCode)
                      ? rawMatchedCode
                      : (targetCode != kAnyFingerCode
                          ? targetCode
                          : (_fingerprints.length == 1
                              ? _fingerprints.first.fingerCode
                              : kAnyFingerCode));
              final effectiveMatchedName =
                  _resolveFingerDisplayName(effectiveMatchedCode);
              final hasSpecificFinger = effectiveMatchedCode != kAnyFingerCode;

              setState(() {
                _sensorState = SensorState.success;
                _fingerPresent = false;
                _lastMatchedFingerName =
                    hasSpecificFinger ? effectiveMatchedName : null;
                _sensorStatusText = hasSpecificFinger
                    ? '¡Huella verificada con éxito!\nHuella detectada: $effectiveMatchedName'
                    : '¡Huella verificada con éxito!\nCoincidencia con una de tus ${_fingerprints.length} huellas registradas (fprintd no informa el dedo en modo automático).';
                _verificationLogs.add(
                  VerificationLog(
                    timestamp: DateTime.now(),
                    fingerCode: effectiveMatchedCode,
                    fingerName: effectiveMatchedName,
                    isSuccess: true,
                    details: 'verify-match • Lectura verificada',
                    deviceName: device.name,
                  ),
                );
              });
              _activeVerifySession = null;
              _scheduleReset();
              break;
            case VerificationStepState.noMatch:
              setState(() {
                _sensorState = SensorState.error;
                _fingerPresent = false;
                _sensorStatusText = targetCode == kAnyFingerCode
                    ? 'La huella no coincide con ninguna registrada. Intenta de nuevo.'
                    : 'La huella no coincide con "$targetLabel". Intenta de nuevo.';
                _verificationLogs.add(
                  VerificationLog(
                    timestamp: DateTime.now(),
                    fingerCode: matchedCode,
                    fingerName: matchedName,
                    isSuccess: false,
                    details: 'verify-no-match • Sin coincidencia',
                    deviceName: device.name,
                  ),
                );
              });
              _activeVerifySession = null;
              _scheduleReset();
              break;
            case VerificationStepState.error:
              setState(() {
                _sensorState = SensorState.error;
                _fingerPresent = false;
                _sensorStatusText = update.message;
              });
              _activeVerifySession = null;
              _scheduleReset();
              break;
          }
        },
        onError: (Object err) {
          if (!mounted) return;
          setState(() {
            _sensorState = SensorState.error;
            _fingerPresent = false;
            _sensorStatusText = 'Error en verificación: $err';
          });
          _activeVerifySession = null;
          _scheduleReset();
        },
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _sensorState = SensorState.error;
        _fingerPresent = false;
        _sensorStatusText = e.toString();
      });
      _scheduleReset();
    }
  }

  String _resolveFingerDisplayName(String code) {
    if (code == kAnyFingerCode) {
      return FingerprintItem.getFriendlyName(kAnyFingerCode);
    }
    for (final f in _fingerprints) {
      if (f.fingerCode == code) return f.name;
    }
    return FingerprintItem.getFriendlyName(code);
  }

  Future<void> _cancelActiveVerification({bool silent = false}) async {
    await _verifySub?.cancel();
    _verifySub = null;
    await _activeVerifySession?.cancel();
    _activeVerifySession = null;

    if (!mounted || silent) return;
    setState(() {
      _fingerPresent = false;
      _sensorState =
          _hardwareStatus == HardwareStatus.ready ? SensorState.idle : SensorState.unavailable;
      if (_activeDevice != null) {
        _sensorStatusText = 'Verificación cancelada. Pulsa para iniciar.';
      }
    });
  }

  void _scheduleReset() {
    _resetTimer?.cancel();
    _resetTimer = Timer(const Duration(milliseconds: 3400), () {
      if (!mounted || _sensorState == SensorState.scanning) return;
      setState(() {
        _fingerPresent = false;
        _lastMatchedFingerName = null;
        if (_hardwareStatus == HardwareStatus.ready && _activeDevice != null) {
          _sensorState = SensorState.idle;
          _sensorStatusText = _defaultIdlePrompt(_activeDevice!);
        } else {
          _sensorState = SensorState.unavailable;
        }
      });
    });
  }

  void _editFingerName(FingerprintItem item) {
    showDialog(
      context: context,
      builder: (ctx) => EditNameDialog(
        item: item,
        onSaved: (newName) async {
          await widget.backend.updateFingerName(item.fingerCode, newName);
          await _refreshAll();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Nombre de "${item.fingerName}" actualizado a "$newName".'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
      ),
    );
  }

  Future<void> _restartUsbReader() async {
    if (_isRestartingUsb) return;
    await _cancelActiveVerification(silent: true);
    if (!mounted) return;

    setState(() {
      _isRestartingUsb = true;
      _sensorState = SensorState.restarting;
      _sensorStatusText = 'Reiniciando servicio fprintd y lectores detectados...';
    });

    final result = await UsbMaintenanceService.resetUsbAndDaemon(_usbDevices);
    await _refreshAll();

    if (!mounted) return;
    setState(() {
      _isRestartingUsb = false;
    });

    if (result.manualCommand != null) {
      _showCommandDialog(
        title: 'Reinicio manual requerido',
        message: result.message,
        command: result.manualCommand!,
      );
      return;
    }

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              result.success ? Icons.check_circle_rounded : Icons.info_outline_rounded,
              color: result.success ? AppColors.success(context) : AppColors.primary(context),
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(result.message)),
          ],
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _togglePamFromStatusStrip() async {
    final messenger = ScaffoldMessenger.of(context);
    final willEnable = !_isPamEnabled;
    final result = await UsbMaintenanceService.setPamAuthenticationEnabled(willEnable);
    await _refreshAll();
    if (!mounted) return;

    if (result.manualCommand != null) {
      _showCommandDialog(
        title: 'Configurar PAM (Login y sudo)',
        message: result.message,
        command: result.manualCommand!,
      );
      return;
    }

    messenger.showSnackBar(
      SnackBar(
        content: Text(result.message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showCommandDialog({
    required String title,
    required String message,
    required String command,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
        content: SizedBox(
          width: 460,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(message, style: const TextStyle(fontSize: 13.5)),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.canvas(context),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border(context)),
                ),
                child: SelectableText(
                  command,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cerrar'),
          ),
          FilledButton.icon(
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              await Clipboard.setData(ClipboardData(text: command));
              if (!ctx.mounted) return;
              Navigator.of(ctx).pop();
              if (!mounted) return;
              messenger.showSnackBar(
                const SnackBar(
                  content: Text('Comando copiado al portapapeles.'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            icon: const Icon(Icons.copy_rounded, size: 16),
            label: const Text('Copiar comando'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteFingerprint(FingerprintItem item) {
    final device = _activeDevice;
    if (device == null) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.error(context)),
            const SizedBox(width: 10),
            const Text('Eliminar huella', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          ],
        ),
        content: Text(
          '¿Deseas eliminar permanentemente "${item.name}" (${item.fingerCode}) de ${device.name}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error(context)),
            onPressed: () async {
              Navigator.of(ctx).pop();
              final result = await widget.backend.deleteFinger(device, item.fingerCode);
              await _refreshAll();
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    result.success
                        ? 'Huella "${item.name}" eliminada correctamente.'
                        : (result.error ?? 'No se pudo eliminar la huella.'),
                  ),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteAllFingerprints() {
    final device = _activeDevice;
    if (device == null) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.delete_forever_rounded, color: AppColors.error(context)),
            const SizedBox(width: 10),
            const Text('Borrar todas las huellas', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          ],
        ),
        content: Text(
          '¿Estás seguro de que deseas borrar TODAS las huellas registradas en ${device.name}? Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error(context)),
            onPressed: () async {
              Navigator.of(ctx).pop();
              final result = await widget.backend.deleteAllFingers(device);
              await _refreshAll();
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    result.success
                        ? 'Todas las huellas han sido eliminadas.'
                        : (result.error ?? 'No se pudieron eliminar las huellas.'),
                  ),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text('Borrar Todo'),
          ),
        ],
      ),
    );
  }

  void _showAddFingerprintDialog() {
    final device = _activeDevice;
    if (device == null) return;
    unawaited(_cancelActiveVerification(silent: true));

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => EnrollmentDialog(
        backend: widget.backend,
        device: device,
        enrolledFingers: _fingerprints.map((f) => f.fingerCode).toList(),
        onEnrollmentFinished: () {
          unawaited(_refreshAll());
        },
      ),
    );
  }

  void _showMaintenanceDialog() {
    showDialog(
      context: context,
      builder: (ctx) => MaintenanceDialog(
        backend: widget.backend,
        onHardwareReset: () {
          unawaited(_refreshAll());
        },
      ),
    );
  }

  void _showHistoryDialog() {
    showDialog(
      context: context,
      builder: (ctx) => VerificationHistoryDialog(
        logs: _verificationLogs,
        onClearLogs: () {
          setState(() => _verificationLogs.clear());
          Navigator.of(context).pop();
        },
      ),
    );
  }

  void _showSupportDialog() {
    showDialog(
      context: context,
      builder: (ctx) => SupportDialog(
        backend: widget.monetizationBackend,
        initialLicenseState: _licenseState,
        onLicenseChanged: (newState) {
          setState(() {
            _licenseState = newState;
            if (newState.isSupporter) {
              _currentAd = null;
            }
          });
          if (!newState.isSupporter) {
            unawaited(_initMonetization());
          }
        },
      ),
    );
  }

  void _showInfoDialog() {
    final deviceDesc = _activeDevice != null
        ? '${_activeDevice!.name} (${_activeDevice!.scanType.displayLabel}, ${_activeDevice!.numEnrollStages} etapas)'
        : 'Ningún lector activo';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Image.asset(
              'assets/images/app_icon.png',
              width: 30,
              height: 30,
              filterQuality: FilterQuality.medium,
              errorBuilder: (context, error, stackTrace) =>
                  Icon(Icons.info_outline_rounded, color: AppColors.primary(context)),
            ),
            const SizedBox(width: 10),
            const Text('Acerca de Fprint-Manager', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          ],
        ),
        content: SizedBox(
          width: 440,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Gestor biométrico de huellas dactilares para escritorio Linux y elementary OS, conectado mediante D-Bus a fprintd y libfprint.',
                  style: TextStyle(fontSize: 13.5, height: 1.4),
                ),
                const SizedBox(height: 14),
                _InfoBullet(label: 'Lector activo', value: deviceDesc),
                _InfoBullet(
                  label: 'Entorno de ejecución',
                  value: _isRunningInFlatpak ? 'Flatpak Sandbox' : 'Nativo Linux',
                ),
                _InfoBullet(
                  label: 'Usuario del sistema',
                  value: widget.backend.username,
                ),
                _InfoBullet(
                  label: 'Configuración de apodos',
                  value: AliasService.configDirectoryPath,
                ),
                _InfoBullet(
                  label: 'Autenticación PAM',
                  value: _isPamEnabled ? 'Activa (Login, bloqueo y sudo)' : 'Desactivada',
                ),
                _InfoBullet(
                  label: 'Permisos Polkit',
                  value: _isPolkitConfigured ? 'Permanentes' : 'Predeterminados',
                ),
              ],
            ),
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.space ||
          event.logicalKey == LogicalKeyboardKey.enter) {
        if (_hardwareStatus == HardwareStatus.ready) {
          unawaited(_startRealVerification());
          return KeyEventResult.handled;
        }
      } else if (event.logicalKey == LogicalKeyboardKey.escape) {
        if (_sensorState == SensorState.scanning) {
          unawaited(_cancelActiveVerification());
          return KeyEventResult.handled;
        }
      } else if ((HardwareKeyboard.instance.isControlPressed &&
              event.logicalKey == LogicalKeyboardKey.keyR) ||
          event.logicalKey == LogicalKeyboardKey.f5) {
        unawaited(_refreshAll());
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return Focus(
      focusNode: _keyboardFocusNode,
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: _buildHeaderBar(context, isDark),
        ),
        body: Column(
          children: [
            _buildStatusStrip(context),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  if (_hardwareStatus == HardwareStatus.loading) {
                    return _buildLoadingView(context);
                  }
                  if (_hardwareStatus != HardwareStatus.ready ||
                      _activeDevice == null) {
                    return _buildDegradedHardwareView(context);
                  }

                  final isWideLayout = constraints.maxWidth >= 780;
                  if (isWideLayout) {
                    final sidebarWidth =
                        (constraints.maxWidth * 0.38).clamp(310.0, 380.0);

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(
                          width: sidebarWidth,
                          child: _buildFingerprintsListPanel(context),
                        ),
                        VerticalDivider(
                          width: 1,
                          thickness: 1,
                          color: AppColors.border(context),
                        ),
                        Expanded(
                          child: _buildSensorInteractivePanel(context, reduceMotion),
                        ),
                      ],
                    );
                  }

                  // Vista adaptable para ventanas estrechas (< 780px)
                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                        child: SegmentedButton<int>(
                          segments: [
                            const ButtonSegment(
                              value: 0,
                              icon: Icon(Icons.fingerprint_rounded, size: 17),
                              label: Text('Verificar'),
                            ),
                            ButtonSegment(
                              value: 1,
                              icon: const Icon(Icons.list_alt_rounded, size: 17),
                              label: Text('Huellas (${_fingerprints.length})'),
                            ),
                          ],
                          selected: {_narrowSectionIndex},
                          onSelectionChanged: (selection) {
                            setState(() => _narrowSectionIndex = selection.first);
                          },
                        ),
                      ),
                      Expanded(
                        child: AnimatedSwitcher(
                          duration: reduceMotion
                              ? Duration.zero
                              : const Duration(milliseconds: 200),
                          child: _narrowSectionIndex == 0
                              ? _buildSensorInteractivePanel(context, reduceMotion)
                              : _buildFingerprintsListPanel(context),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            _buildSponsorBannerSlot(reduceMotion),
            _buildBottomActionBar(context),
          ],
        ),
      ),
    );
  }

  Widget _buildSponsorBannerSlot(bool reduceMotion) {
    final showBanner = !_licenseState.isSupporter && _currentAd != null;
    final Widget banner = showBanner
        ? SponsorBanner(
            ad: _currentAd!,
            onOpenAd: () {
              unawaited(
                widget.monetizationBackend.openExternalUrl(_currentAd!.linkUrl),
              );
            },
            onRemoveAds: _showSupportDialog,
            onReportImpression: (viewUrl) {
              unawaited(
                widget.monetizationBackend.reportAdImpression(viewUrl),
              );
            },
          )
        : const SizedBox.shrink();

    if (reduceMotion) {
      return banner;
    }

    return AnimatedSize(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      child: banner,
    );
  }

  Widget _buildHeaderBar(BuildContext context, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).appBarTheme.backgroundColor,
        border: Border(
          bottom: BorderSide(color: AppColors.border(context), width: 1),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Image.asset(
                'assets/images/app_icon.png',
                width: 28,
                height: 28,
                filterQuality: FilterQuality.medium,
                errorBuilder: (context, error, stackTrace) => Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.primary(context).withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.fingerprint_rounded,
                    color: AppColors.primary(context),
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Fprint-Manager',
                style: TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: _buildDeviceHeaderChip(context),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: _licenseState.isSupporter
                    ? 'Supporter activo • Apoyar proyecto'
                    : 'Apoyar proyecto / Quitar anuncios',
                icon: Icon(
                  _licenseState.isSupporter
                      ? Icons.favorite_rounded
                      : Icons.favorite_outline_rounded,
                  size: 19,
                  color: _licenseState.isSupporter
                      ? AppColors.success(context)
                      : null,
                ),
                onPressed: _showSupportDialog,
              ),
              IconButton(
                tooltip: 'Recargar lectores y huellas (Ctrl+R)',
                icon: const Icon(Icons.refresh_rounded, size: 19),
                onPressed: _isRestartingUsb ? null : _refreshAll,
              ),
              IconButton(
                tooltip: 'Historial de verificaciones (${_verificationLogs.length})',
                icon: Badge(
                  isLabelVisible: _verificationLogs.isNotEmpty,
                  label: Text('${_verificationLogs.length}'),
                  backgroundColor: AppColors.primary(context),
                  child: const Icon(Icons.history_rounded, size: 19),
                ),
                onPressed: _showHistoryDialog,
              ),
              IconButton(
                tooltip: 'Diagnóstico y mantenimiento del sistema',
                icon: const Icon(Icons.build_circle_outlined, size: 19),
                onPressed: _showMaintenanceDialog,
              ),
              IconButton(
                tooltip: isDark ? 'Cambiar a tema claro' : 'Cambiar a tema oscuro',
                icon: Icon(
                  isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                  size: 19,
                ),
                onPressed: widget.onToggleTheme,
              ),
              IconButton(
                tooltip: 'Información del sistema',
                icon: const Icon(Icons.info_outline_rounded, size: 19),
                onPressed: _showInfoDialog,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDeviceHeaderChip(BuildContext context) {
    if (_hardwareStatus == HardwareStatus.loading) {
      return _HeaderPill(
        color: AppColors.primary(context),
        label: 'Detectando hardware...',
      );
    }
    if (_hardwareStatus != HardwareStatus.ready || _activeDevice == null) {
      final label = switch (_hardwareStatus) {
        HardwareStatus.serviceUnavailable => 'fprintd no disponible',
        HardwareStatus.noDeviceFound => 'Sin lector conectado',
        HardwareStatus.permissionDenied => 'Permiso denegado',
        _ => 'Error de lector',
      };
      return _HeaderPill(
        color: AppColors.warning(context),
        label: label,
      );
    }

    if (_devices.length <= 1) {
      return _HeaderPill(
        color: AppColors.primary(context),
        label: _activeDevice!.name,
      );
    }

    return PopupMenuButton<FprintDeviceInfo>(
      tooltip: 'Cambiar lector biométrico activo',
      onSelected: _selectDevice,
      itemBuilder: (ctx) => _devices
          .map(
            (dev) => PopupMenuItem<FprintDeviceInfo>(
              value: dev,
              child: Row(
                children: [
                  Icon(
                    dev.objectPath == _activeDevice?.objectPath
                        ? Icons.radio_button_checked_rounded
                        : Icons.radio_button_unchecked_rounded,
                    size: 16,
                    color: AppColors.primary(context),
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Text(dev.name, overflow: TextOverflow.ellipsis)),
                ],
              ),
            ),
          )
          .toList(),
      child: _HeaderPill(
        color: AppColors.primary(context),
        label: '${_activeDevice!.name} (${_devices.length})',
        showChevron: true,
      ),
    );
  }

  Widget _buildStatusStrip(BuildContext context) {
    final deviceReady =
        _hardwareStatus == HardwareStatus.ready && _activeDevice != null;
    final statusDotColor = deviceReady
        ? AppColors.success(context)
        : (_hardwareStatus == HardwareStatus.loading
            ? AppColors.primary(context)
            : AppColors.warning(context));

    final summaryText = deviceReady
        ? '${_activeDevice!.name} • ${_activeDevice!.scanType.displayLabel} • ${_activeDevice!.numEnrollStages} etapas'
        : (_hardwareStatus == HardwareStatus.loading
            ? 'Consultando D-Bus net.reactivated.Fprint...'
            : (_hardwareError ?? 'Lector no disponible'));

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.sidebar(context),
        border: Border(
          bottom: BorderSide(color: AppColors.border(context), width: 1),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: statusDotColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              summaryText,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary(context),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            borderRadius: BorderRadius.circular(6),
            onTap: _togglePamFromStatusStrip,
            child: Tooltip(
              message: 'Habilitar o deshabilitar huella en login y sudo (PAM)',
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: (_isPamEnabled
                          ? AppColors.success(context)
                          : AppColors.warning(context))
                      .withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: (_isPamEnabled
                            ? AppColors.success(context)
                            : AppColors.warning(context))
                        .withValues(alpha: 0.35),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _isPamEnabled ? Icons.shield_rounded : Icons.shield_outlined,
                      size: 13,
                      color: _isPamEnabled
                          ? AppColors.success(context)
                          : AppColors.warning(context),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      _isPamEnabled ? 'Login & Sudo: Activo' : 'Login & Sudo: Off',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: _isPamEnabled
                            ? AppColors.success(context)
                            : AppColors.warning(context),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingView(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const FingerprintScannerWidget(
            state: SensorState.restarting,
            size: 136,
          ),
          const SizedBox(height: 18),
          const Text(
            'Buscando lectores biométricos en el sistema...',
            style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(
            'Conectando por D-Bus a net.reactivated.Fprint',
            style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary(context)),
          ),
        ],
      ),
    );
  }

  Widget _buildDegradedHardwareView(BuildContext context) {
    final isServiceDown = _hardwareStatus == HardwareStatus.serviceUnavailable;
    final isPermDenied = _hardwareStatus == HardwareStatus.permissionDenied;

    final title = switch (_hardwareStatus) {
      HardwareStatus.serviceUnavailable => 'Servicio fprintd no disponible',
      HardwareStatus.noDeviceFound => 'No se detectó ningún lector de huellas',
      HardwareStatus.permissionDenied => 'Permisos insuficientes en D-Bus',
      _ => 'No se pudo inicializar el lector biométrico',
    };

    final description = switch (_hardwareStatus) {
      HardwareStatus.serviceUnavailable =>
        'No fue posible comunicarse con net.reactivated.Fprint. Verifica que el paquete fprintd esté instalado y activo en tu distribución Linux.',
      HardwareStatus.noDeviceFound =>
        'El servicio fprintd está activo, pero libfprint no detectó sensores compatibles conectados. Si tienes un lector USB y quedó bloqueado tras suspender, prueba reiniciar el sensor.',
      HardwareStatus.permissionDenied =>
        'Polkit rechazó el acceso al dispositivo. Configura los permisos permanentes en el panel de Diagnóstico y Mantenimiento.',
      _ => _hardwareError ?? 'Ocurrió un problema al consultar el hardware.',
    };

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 540),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const FingerprintScannerWidget(
                    state: SensorState.unavailable,
                    size: 130,
                  ),
                  const SizedBox(height: 14),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.45,
                      color: AppColors.textSecondary(context),
                    ),
                  ),
                  if (_usbDevices.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.sidebar(context),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.border(context)),
                      ),
                      child: Text(
                        'Dispositivos USB detectados: ${_usbDevices.map((d) => "${d.productName} [${d.usbId}]").join(", ")}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                  if (isServiceDown) ...[
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.canvas(context),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.border(context)),
                      ),
                      child: const SelectableText(
                        'Instalación recomendada:\n'
                        '• elementary OS / Ubuntu / Debian: sudo apt install fprintd libpam-fprintd\n'
                        '• Fedora: sudo dnf install fprintd fprintd-pam\n'
                        '• Arch Linux: sudo pacman -S fprintd',
                        style: TextStyle(fontFamily: 'monospace', fontSize: 11.5),
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 10,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: [
                      FilledButton.icon(
                        onPressed: _refreshAll,
                        icon: const Icon(Icons.refresh_rounded, size: 17),
                        label: const Text('Reintentar detección'),
                      ),
                      if (!isServiceDown)
                        OutlinedButton.icon(
                          onPressed: _isRestartingUsb ? null : _restartUsbReader,
                          icon: const Icon(Icons.restart_alt_rounded, size: 17),
                          label: const Text('Reiniciar lector y fprintd'),
                        ),
                      if (isPermDenied || isServiceDown)
                        OutlinedButton.icon(
                          onPressed: _showMaintenanceDialog,
                          icon: const Icon(Icons.build_circle_outlined, size: 17),
                          label: const Text('Abrir diagnóstico'),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFingerprintsListPanel(BuildContext context) {
    return Container(
      color: AppColors.sidebar(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 14, 12),
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Flexible(
                        child: Text(
                          'Huellas Registradas',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary(context).withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${_fingerprints.length}',
                          style: AppTheme.tabularFiguresStyle.copyWith(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary(context),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_fingerprints.isNotEmpty)
                  IconButton(
                    tooltip: 'Borrar todas las huellas de este lector',
                    style: IconButton.styleFrom(
                      foregroundColor: AppColors.error(context),
                      visualDensity: VisualDensity.compact,
                    ),
                    icon: const Icon(Icons.delete_sweep_rounded, size: 20),
                    onPressed: _confirmDeleteAllFingerprints,
                  ),
                const SizedBox(width: 4),
                FilledButton.tonalIcon(
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                    visualDensity: VisualDensity.compact,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: _showAddFingerprintDialog,
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: const Text('Agregar', style: TextStyle(fontSize: 12.5)),
                ),
              ],
            ),
          ),
          Expanded(
            child: _fingerprints.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.fingerprint_rounded,
                            size: 46,
                            color: Theme.of(context).disabledColor,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Sin huellas inscritas',
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Pulsa «Agregar» para registrar un dedo en ${_activeDevice?.name ?? "tu lector"}.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.textSecondary(context),
                              fontSize: 12.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(14, 2, 14, 14),
                    itemCount: _fingerprints.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final item = _fingerprints[index];
                      final isSelected = item.fingerCode == _selectedVerifyFingerCode;
                      return _FingerprintCard(
                        item: item,
                        isSelected: isSelected,
                        onSelect: () {
                          setState(() {
                            _selectedVerifyFingerCode = item.fingerCode;
                            _sensorStatusText =
                                'Objetivo seleccionado: ${item.name} (-f ${item.fingerCode}).';
                            _narrowSectionIndex = 0;
                          });
                        },
                        onEdit: () => _editFingerName(item),
                        onDelete: () => _confirmDeleteFingerprint(item),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSensorInteractivePanel(BuildContext context, bool reduceMotion) {
    final isScanning = _sensorState == SensorState.scanning;

    final Color badgeColor;
    final IconData stateIcon;
    final String badgeTitle;

    switch (_sensorState) {
      case SensorState.scanning:
        badgeColor = AppColors.primary(context);
        stateIcon = _fingerPresent ? Icons.fingerprint_rounded : Icons.sensors_rounded;
        badgeTitle = _fingerPresent
            ? 'LEYENDO HUELLA...'
            : 'ESPERANDO LECTURA EN EL SENSOR';
        break;
      case SensorState.success:
        badgeColor = AppColors.success(context);
        stateIcon = Icons.check_circle_rounded;
        badgeTitle = _lastMatchedFingerName != null
            ? 'VERIFICACIÓN EXITOSA • ${_lastMatchedFingerName!.toUpperCase()}'
            : 'VERIFICACIÓN EXITOSA';
        break;
      case SensorState.error:
        badgeColor = AppColors.error(context);
        stateIcon = Icons.error_rounded;
        badgeTitle = 'SIN COINCIDENCIA / ERROR';
        break;
      case SensorState.restarting:
        badgeColor = AppColors.primary(context);
        stateIcon = Icons.sync_rounded;
        badgeTitle = 'REINICIANDO LECTOR';
        break;
      case SensorState.unavailable:
        badgeColor = AppColors.textSecondary(context);
        stateIcon = Icons.portable_wifi_off_outlined;
        badgeTitle = 'SENSOR NO DISPONIBLE';
        break;
      case SensorState.idle:
        badgeColor = AppColors.textSecondary(context);
        stateIcon = Icons.touch_app_rounded;
        badgeTitle = 'LISTO PARA VERIFICAR (ESPACIO / CLIC)';
        break;
    }

    final targetLabel = _resolveFingerDisplayName(_selectedVerifyFingerCode);

    return Container(
      color: AppColors.canvas(context),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: reduceMotion ? Duration.zero : const Duration(milliseconds: 240),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: badgeColor.withValues(alpha: 0.32)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(stateIcon, size: 14, color: badgeColor),
                      const SizedBox(width: 7),
                      Flexible(
                        child: Text(
                          badgeTitle,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                            color: badgeColor,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                FingerprintScannerWidget(
                  state: _sensorState,
                  progress: _sensorState == SensorState.success ? 1.0 : 0.0,
                  fingerPresent: _fingerPresent,
                  onTap: _startRealVerification,
                  size: 168,
                ),

                const SizedBox(height: 16),

                if (_fingerprints.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.surface(context),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border(context)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedVerifyFingerCode,
                        isExpanded: true,
                        items: [
                          DropdownMenuItem(
                            value: kAnyFingerCode,
                            child: Row(
                              children: [
                                Icon(Icons.auto_awesome_rounded,
                                    size: 16, color: AppColors.primary(context)),
                                const SizedBox(width: 8),
                                const Expanded(
                                  child: Text(
                                    'Cualquier huella (automático)',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Text(
                                  '(-f any)',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondary(context),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ..._fingerprints.map((item) {
                            return DropdownMenuItem(
                              value: item.fingerCode,
                              child: Row(
                                children: [
                                  Icon(Icons.fingerprint_rounded,
                                      size: 16, color: AppColors.primary(context)),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(item.name, overflow: TextOverflow.ellipsis),
                                  ),
                                  Text(
                                    '(-f ${item.fingerCode})',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textSecondary(context),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                        onChanged: isScanning
                            ? null
                            : (val) {
                                if (val != null) {
                                  setState(() {
                                    _selectedVerifyFingerCode = val;
                                    _sensorStatusText = val == kAnyFingerCode
                                        ? 'Modo automático activo: verificará contra todas tus huellas.'
                                        : 'Objetivo: ${_resolveFingerDisplayName(val)}. Pulsa para verificar.';
                                  });
                                }
                              },
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                ],

                AnimatedSwitcher(
                  duration: reduceMotion ? Duration.zero : const Duration(milliseconds: 220),
                  child: Text(
                    _sensorStatusText,
                    key: ValueKey<String>(_sensorStatusText),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13.5,
                      height: 1.45,
                      fontWeight: FontWeight.w500,
                      color: _sensorState == SensorState.success
                          ? AppColors.success(context)
                          : (_sensorState == SensorState.error
                              ? AppColors.error(context)
                              : null),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: isScanning
                            ? AppColors.error(context)
                            : AppColors.primary(context),
                      ),
                      onPressed: isScanning
                          ? _cancelActiveVerification
                          : _startRealVerification,
                      icon: Icon(
                        isScanning ? Icons.stop_rounded : Icons.fingerprint_rounded,
                        size: 18,
                      ),
                      label: Text(
                        isScanning
                            ? 'Cancelar verificación (Esc)'
                            : (_selectedVerifyFingerCode == kAnyFingerCode
                                ? 'Verificar huella'
                                : 'Verificar $targetLabel'),
                      ),
                    ),
                    if (_fingerprints.isEmpty)
                      OutlinedButton.icon(
                        onPressed: _showAddFingerprintDialog,
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text('Registrar primera huella'),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomActionBar(BuildContext context) {
    final serviceOk = _hardwareStatus == HardwareStatus.ready ||
        _hardwareStatus == HardwareStatus.noDeviceFound;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).appBarTheme.backgroundColor,
        border: Border(
          top: BorderSide(color: AppColors.border(context), width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Icon(
              _isRestartingUsb
                  ? Icons.sync_rounded
                  : (serviceOk ? Icons.verified_user_outlined : Icons.warning_amber_rounded),
              size: 17,
              color: _isRestartingUsb
                  ? AppColors.primary(context)
                  : (serviceOk ? AppColors.success(context) : AppColors.warning(context)),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _isRestartingUsb
                    ? 'Reiniciando servicio y hardware...'
                    : 'fprintd: ${serviceOk ? "Activo" : "Inactivo"} • Polkit: ${_isPolkitConfigured ? "Sin contraseñas" : "Predeterminado"}',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary(context),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 12),
            FilledButton.tonalIcon(
              onPressed: _isRestartingUsb ? null : _restartUsbReader,
              icon: _isRestartingUsb
                  ? const SizedBox(
                      width: 15,
                      height: 15,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.restart_alt_rounded, size: 17),
              label: Text(
                _isRestartingUsb
                    ? 'Reiniciando...'
                    : (_isRunningInFlatpak
                        ? 'Reinicio de hardware...'
                        : 'Reiniciar lector y servicio'),
                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderPill extends StatelessWidget {
  final Color color;
  final String label;
  final bool showChevron;

  const _HeaderPill({
    required this.color,
    required this.label,
    this.showChevron = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: color,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (showChevron) ...[
            const SizedBox(width: 4),
            Icon(Icons.arrow_drop_down_rounded, size: 16, color: color),
          ],
        ],
      ),
    );
  }
}

class _FingerprintCard extends StatefulWidget {
  final FingerprintItem item;
  final bool isSelected;
  final VoidCallback onSelect;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _FingerprintCard({
    required this.item,
    required this.isSelected,
    required this.onSelect,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<_FingerprintCard> createState() => _FingerprintCardState();
}

class _FingerprintCardState extends State<_FingerprintCard> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final isCustomized = widget.item.name != widget.item.fingerName;
    final primary = AppColors.primary(context);

    final borderColor = widget.isSelected || _focused
        ? primary
        : (_hovered
            ? primary.withValues(alpha: 0.45)
            : AppColors.border(context));

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: reduceMotion ? Duration.zero : const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: widget.isSelected
              ? primary.withValues(alpha: 0.06)
              : AppColors.surface(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: borderColor,
            width: widget.isSelected || _focused ? 1.8 : 1.0,
          ),
          boxShadow: widget.isSelected || _hovered
              ? [
                  BoxShadow(
                    color: primary.withValues(alpha: widget.isSelected ? 0.12 : 0.06),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(11),
          onFocusChange: (hasFocus) => setState(() => _focused = hasFocus),
          onTap: widget.onSelect,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: widget.isSelected
                        ? primary.withValues(alpha: 0.16)
                        : AppColors.sidebar(context),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.fingerprint_rounded,
                    color: widget.isSelected
                        ? primary
                        : AppColors.textSecondary(context),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              widget.item.name,
                              style: TextStyle(
                                fontWeight:
                                    widget.isSelected ? FontWeight.w700 : FontWeight.w600,
                                fontSize: 13.5,
                                color: widget.isSelected ? primary : null,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (widget.isSelected)
                            Container(
                              margin: const EdgeInsets.only(left: 6),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 1.5,
                              ),
                              decoration: BoxDecoration(
                                color: primary.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'Objetivo',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: primary,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Wrap(
                        spacing: 6,
                        runSpacing: 2,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          if (isCustomized)
                            Text(
                              widget.item.fingerName,
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary(context),
                              ),
                            ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.sidebar(context),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              widget.item.fingerCode,
                              style: TextStyle(
                                fontSize: 10.5,
                                fontFamily: 'monospace',
                                color: AppColors.textSecondary(context),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Editar nombre personalizado',
                  style: IconButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    foregroundColor: primary,
                  ),
                  icon: const Icon(Icons.edit_outlined, size: 17),
                  onPressed: widget.onEdit,
                ),
                IconButton(
                  tooltip: 'Eliminar huella',
                  style: IconButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    foregroundColor: AppColors.error(context),
                  ),
                  icon: const Icon(Icons.delete_outline_rounded, size: 18),
                  onPressed: widget.onDelete,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoBullet extends StatelessWidget {
  final String label;
  final String value;

  const _InfoBullet({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: RichText(
        text: TextSpan(
          style: DefaultTextStyle.of(context).style.copyWith(fontSize: 12.5),
          children: [
            TextSpan(
              text: '• $label: ',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            TextSpan(
              text: value,
              style: TextStyle(color: AppColors.textSecondary(context)),
            ),
          ],
        ),
      ),
    );
  }
}
