import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fprint_manager/config/monetization_config.dart';
import 'package:fprint_manager/main.dart';
import 'package:fprint_manager/models/fprint_device_info.dart';
import 'package:fprint_manager/models/fingerprint_item.dart';
import 'package:fprint_manager/models/monetization_models.dart';
import 'package:fprint_manager/services/fprint_service.dart';
import 'package:fprint_manager/services/monetization_service.dart';

class FakeEnrollmentSession implements FprintEnrollmentSession {
  final StreamController<EnrollmentUpdate> controller =
      StreamController<EnrollmentUpdate>.broadcast();
  bool cancelled = false;

  @override
  Stream<EnrollmentUpdate> get updates => controller.stream;

  @override
  Future<void> cancel() async {
    cancelled = true;
    if (!controller.isClosed) {
      await controller.close();
    }
  }
}

class FakeVerificationSession implements FprintVerificationSession {
  final StreamController<VerificationUpdate> controller =
      StreamController<VerificationUpdate>.broadcast();
  bool cancelled = false;

  @override
  Stream<VerificationUpdate> get updates => controller.stream;

  @override
  Future<void> cancel() async {
    cancelled = true;
    if (!controller.isClosed) {
      await controller.close();
    }
  }
}

class FakeFprintBackend implements FprintBackend {
  HardwareStatus statusToReturn;
  String? errorToReturn;
  List<FprintDeviceInfo> devicesToReturn;
  List<String> enrolledCodes;
  final Map<String, String> aliases = {};
  bool isPamEnabled = true;
  bool isPolkitInstalled = true;

  FakeEnrollmentSession? lastEnrollmentSession;
  FakeVerificationSession? lastVerificationSession;
  String? lastVerifiedFingerCode;
  String? lastEnrolledFingerCode;

  FakeFprintBackend({
    this.statusToReturn = HardwareStatus.ready,
    this.errorToReturn,
    List<FprintDeviceInfo>? devices,
    List<String>? enrolled,
  })  : devicesToReturn = devices ??
            const [
              FprintDeviceInfo(
                objectPath: '/org/freedesktop/test/Device0',
                name: 'Universal Biometric Sensor',
                numEnrollStages: 8,
                scanType: ScanType.press,
              ),
            ],
        enrolledCodes = enrolled ?? ['right-index-finger', 'left-thumb'];

  @override
  String get username => 'testuser';

  @override
  Future<({HardwareStatus status, List<FprintDeviceInfo> devices, String? error})>
      discoverDevices() async {
    return (
      status: statusToReturn,
      devices: statusToReturn == HardwareStatus.ready
          ? devicesToReturn
          : const <FprintDeviceInfo>[],
      error: errorToReturn,
    );
  }

  @override
  Future<List<FingerprintItem>> listEnrolledFingers(
      FprintDeviceInfo device) async {
    return [
      for (int i = 0; i < enrolledCodes.length; i++)
        FingerprintItem(
          id: 'fp-0${i + 1}',
          name: aliases[enrolledCodes[i]] ??
              FingerprintItem.getFriendlyName(enrolledCodes[i]),
          fingerCode: enrolledCodes[i],
          fingerName: FingerprintItem.getFriendlyName(enrolledCodes[i]),
          devicePath: device.objectPath,
        ),
    ];
  }

  @override
  Future<bool> updateFingerName(String fingerCode, String newName) async {
    aliases[fingerCode] = newName;
    return true;
  }

  @override
  Future<({bool success, String? error})> deleteFinger(
    FprintDeviceInfo device,
    String fingerCode,
  ) async {
    enrolledCodes.remove(fingerCode);
    aliases.remove(fingerCode);
    return (success: true, error: null);
  }

  @override
  Future<({bool success, String? error})> deleteAllFingers(
      FprintDeviceInfo device) async {
    enrolledCodes.clear();
    aliases.clear();
    return (success: true, error: null);
  }

  @override
  Future<FprintEnrollmentSession> startEnrollment(
    FprintDeviceInfo device,
    String fingerCode,
  ) async {
    lastEnrolledFingerCode = fingerCode;
    final session = FakeEnrollmentSession();
    lastEnrollmentSession = session;
    return session;
  }

  @override
  Future<FprintVerificationSession> startVerification(
    FprintDeviceInfo device,
    String fingerCode,
  ) async {
    lastVerifiedFingerCode = fingerCode;
    final session = FakeVerificationSession();
    lastVerificationSession = session;
    return session;
  }

  @override
  Future<SystemDiagnostics> runDiagnostics() async {
    return SystemDiagnostics(
      isRunningInFlatpak: false,
      dbusConnected: statusToReturn != HardwareStatus.serviceUnavailable,
      fprintdAvailable: statusToReturn != HardwareStatus.serviceUnavailable,
      hasPkexec: true,
      hasUsbreset: true,
      hasPamAuthUpdate: true,
      hasAuthselect: false,
      hasFprintdCli: true,
      isPamEnabled: isPamEnabled,
      isPolkitRuleInstalled: isPolkitInstalled,
      usbDevices: const [],
      devices: statusToReturn == HardwareStatus.ready ? devicesToReturn : const [],
      status: statusToReturn,
      errorMessage: errorToReturn,
    );
  }

  @override
  Future<void> dispose() async {}
}

class FakeMonetizationBackend implements MonetizationBackend {
  SupporterLicenseState licenseState;
  EthicalAdItem? adToReturn;
  final List<String> reportedImpressions = [];
  final List<String> openedUrls = [];
  String validKey = 'VALID-KEY-1234';

  FakeMonetizationBackend({
    SupporterLicenseState? initialLicense,
    EthicalAdItem? ad,
  })  : licenseState = initialLicense ??
            const SupporterLicenseState.inactive(
              provider: LicenseProvider.gumroad,
            ),
        adToReturn = ad ??
            const EthicalAdItem(
              text: 'Build better Linux tools with EthicalAds',
              linkUrl: 'https://example.com/ad',
              viewUrl: 'https://server.ethicalads.io/view/test',
            );

  @override
  Future<SupporterLicenseState> loadLicenseState() async => licenseState;

  @override
  Future<LicenseActivationResult> activateLicenseKey(String licenseKey) async {
    if (licenseKey.trim() == validKey) {
      licenseState = SupporterLicenseState(
        isSupporter: true,
        licenseKey: licenseKey.trim(),
        provider: LicenseProvider.gumroad,
        customerEmail: 'supporter@example.com',
        activatedAt: DateTime(2026, 11, 20),
      );
      return LicenseActivationResult(
        success: true,
        message: '¡Licencia Supporter activada!',
        state: licenseState,
      );
    }
    return LicenseActivationResult(
      success: false,
      message: 'La clave de licencia no es válida.',
      state: licenseState,
    );
  }

  @override
  Future<void> deactivateLicense() async {
    licenseState = const SupporterLicenseState.inactive(
      provider: LicenseProvider.gumroad,
    );
  }

  @override
  Future<EthicalAdItem?> fetchAd() async => adToReturn;

  @override
  Future<void> reportAdImpression(String viewUrl) async {
    reportedImpressions.add(viewUrl);
  }

  @override
  Future<bool> openExternalUrl(String url) async {
    openedUrls.add(url);
    return true;
  }
}

void main() {
  void setDesktopWindow(WidgetTester tester, {Size size = const Size(1100, 740)}) {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  testWidgets('Initial desktop layout renders cleanly and settles with 0 idle loops',
      (WidgetTester tester) async {
    setDesktopWindow(tester);
    final backend = FakeFprintBackend();

    await tester.pumpWidget(FprintManagerApp(backend: backend, monetizationBackend: FakeMonetizationBackend()));
    await tester.pumpAndSettle();

    expect(find.text('Fprint-Manager'), findsOneWidget);
    expect(find.text('Universal Biometric Sensor'), findsOneWidget);
    expect(find.text('Huellas Registradas'), findsOneWidget);
    expect(find.text('Índice Derecho'), findsOneWidget);
    expect(find.text('Pulgar Izquierdo'), findsOneWidget);
    expect(find.text('Verificar huella'), findsOneWidget);
  });

  testWidgets('Enrollment flow steps cleanly through stages 1..8 and completes',
      (WidgetTester tester) async {
    setDesktopWindow(tester);
    final backend = FakeFprintBackend();

    await tester.pumpWidget(FprintManagerApp(backend: backend, monetizationBackend: FakeMonetizationBackend()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Agregar'));
    await tester.pumpAndSettle();

    expect(find.text('Registrar nueva huella'), findsOneWidget);
    await tester.tap(find.text('Iniciar registro'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    final session = backend.lastEnrollmentSession!;
    expect(backend.lastEnrolledFingerCode, 'right-thumb');

    session.controller.add(const EnrollmentUpdate(
      stage: 1,
      totalStages: 8,
      resultCode: 'enroll-stage-passed',
      message: 'Muestra 1 de 8 capturada',
      fingerPresent: true,
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 450));
    expect(find.text('Etapa 1 de 8 • 13%'), findsOneWidget);

    backend.enrolledCodes.add('right-thumb');
    session.controller.add(const EnrollmentUpdate(
      stage: 8,
      totalStages: 8,
      resultCode: 'enroll-completed',
      message: '¡Huella registrada exitosamente en el sistema!',
      isCompleted: true,
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('¡Registro completado • 100%!'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 1600));
    await tester.pumpAndSettle();
    expect(find.text('Pulgar Derecho'), findsOneWidget);
  });

  testWidgets('Verification match and mismatch update state and audit history',
      (WidgetTester tester) async {
    setDesktopWindow(tester);
    final backend = FakeFprintBackend();

    await tester.pumpWidget(FprintManagerApp(backend: backend, monetizationBackend: FakeMonetizationBackend()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Verificar huella'));
    await tester.pump();

    expect(backend.lastVerifiedFingerCode, kAnyFingerCode);
    backend.lastVerificationSession!.controller.add(const VerificationUpdate(
      state: VerificationStepState.match,
      resultCode: 'verify-match',
      message: '¡Huella verificada con éxito!',
      matchedFingerCode: 'left-thumb',
      done: true,
    ));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('VERIFICACIÓN EXITOSA • PULGAR IZQUIERDO'), findsOneWidget);
    expect(find.textContaining('Huella detectada: Pulgar Izquierdo'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 3500));
    await tester.pumpAndSettle();

    // Prueba de fallo tras seleccionar dedo concreto
    await tester.tap(find.text('Índice Derecho'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Verificar Índice Derecho'));
    await tester.pump();

    expect(backend.lastVerifiedFingerCode, 'right-index-finger');
    backend.lastVerificationSession!.controller.add(const VerificationUpdate(
      state: VerificationStepState.noMatch,
      resultCode: 'verify-no-match',
      message: 'La huella no coincide.',
      matchedFingerCode: 'right-index-finger',
      done: true,
    ));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('SIN COINCIDENCIA / ERROR'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 3500));
    await tester.pumpAndSettle();

    // Abre historial y comprueba las 2 entradas
    await tester.tap(
      find.ancestor(
        of: find.byIcon(Icons.history_rounded),
        matching: find.byType(IconButton),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Historial de Verificaciones'), findsOneWidget);
    expect(find.text('Pulgar Izquierdo'), findsWidgets);
    await tester.tap(find.text('Cerrar'));
    await tester.pumpAndSettle();
  });

  testWidgets('Degraded hardware states display helpful Spanish guidance',
      (WidgetTester tester) async {
    setDesktopWindow(tester);
    final backend = FakeFprintBackend(
      statusToReturn: HardwareStatus.noDeviceFound,
      errorToReturn: 'No compatible device',
    );

    await tester.pumpWidget(FprintManagerApp(backend: backend, monetizationBackend: FakeMonetizationBackend()));
    await tester.pumpAndSettle();
    expect(find.text('No se detectó ningún lector de huellas'), findsOneWidget);
    expect(find.text('Reintentar detección'), findsOneWidget);

    backend.statusToReturn = HardwareStatus.serviceUnavailable;
    await tester.tap(find.text('Reintentar detección'));
    await tester.pumpAndSettle();
    expect(find.text('Servicio fprintd no disponible'), findsOneWidget);
    expect(find.textContaining('sudo apt install fprintd'), findsOneWidget);
  });

  testWidgets('Narrow window layout and reduced motion work without overflow',
      (WidgetTester tester) async {
    setDesktopWindow(tester, size: const Size(600, 580));
    final backend = FakeFprintBackend();

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(
          size: Size(600, 580),
          disableAnimations: true,
        ),
        child: FprintManagerApp(backend: backend, monetizationBackend: FakeMonetizationBackend()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Verificar'), findsOneWidget);
    expect(find.text('Huellas (2)'), findsOneWidget);

    await tester.tap(find.text('Huellas (2)'));
    await tester.pumpAndSettle();
    expect(find.text('Pulgar Izquierdo'), findsOneWidget);
  });

  testWidgets('Editing a fingerprint custom name updates the UI',
      (WidgetTester tester) async {
    setDesktopWindow(tester);
    final backend = FakeFprintBackend();

    await tester.pumpWidget(FprintManagerApp(backend: backend, monetizationBackend: FakeMonetizationBackend()));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.edit_outlined).first);
    await tester.pumpAndSettle();
    expect(find.text('Personalizar Nombre de Huella'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Dedo Principal Sudo');
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();

    expect(find.text('Dedo Principal Sudo'), findsOneWidget);
  });

  testWidgets('SponsorBanner displays ad, reports impression once, and opens SupportDialog',
      (WidgetTester tester) async {
    setDesktopWindow(tester);
    final backend = FakeFprintBackend();
    final monetization = FakeMonetizationBackend();

    await tester.pumpWidget(
      FprintManagerApp(
        backend: backend,
        monetizationBackend: monetization,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Build better Linux tools with EthicalAds'), findsOneWidget);
    expect(find.text('EthicalAds'), findsOneWidget);
    expect(
      monetization.reportedImpressions,
      ['https://server.ethicalads.io/view/test'],
    );

    await tester.tap(find.text('Quitar (${MonetizationConfig.removeAdsPriceLabel})'));
    await tester.pumpAndSettle();
    expect(find.text('Apoyar Fprint-Manager'), findsOneWidget);

    await tester.tap(find.text('Cerrar'));
    await tester.pumpAndSettle();
  });

  testWidgets('Activating valid Supporter license removes banner; invalid key shows error',
      (WidgetTester tester) async {
    setDesktopWindow(tester);
    final backend = FakeFprintBackend();
    final monetization = FakeMonetizationBackend();

    await tester.pumpWidget(
      FprintManagerApp(
        backend: backend,
        monetizationBackend: monetization,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.favorite_outline_rounded));
    await tester.pumpAndSettle();

    // Clave inválida
    await tester.enterText(find.byType(TextField), 'BAD-KEY');
    await tester.tap(find.text('Activar licencia'));
    await tester.pumpAndSettle();
    expect(find.text('La clave de licencia no es válida.'), findsOneWidget);

    // Clave válida
    await tester.enterText(find.byType(TextField), 'VALID-KEY-1234');
    await tester.tap(find.text('Activar licencia'));
    await tester.pumpAndSettle();
    expect(find.text('Licencia Supporter Activa'), findsOneWidget);

    await tester.tap(find.text('Cerrar'));
    await tester.pumpAndSettle();
    expect(find.text('Build better Linux tools with EthicalAds'), findsNothing);
    expect(find.byIcon(Icons.favorite_rounded), findsOneWidget);
  });

  testWidgets('Voluntary donation button opens configured donation URL',
      (WidgetTester tester) async {
    setDesktopWindow(tester);
    final backend = FakeFprintBackend();
    final monetization = FakeMonetizationBackend();

    await tester.pumpWidget(
      FprintManagerApp(
        backend: backend,
        monetizationBackend: monetization,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.favorite_outline_rounded));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Donar con PayPal / Ko-fi'));
    await tester.pumpAndSettle();
    expect(monetization.openedUrls, [MonetizationConfig.donationUrl]);
  });

  testWidgets('Theme toggle switches immediately on first tap from system theme',
      (WidgetTester tester) async {
    setDesktopWindow(tester);
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

    await tester.pumpWidget(
      FprintManagerApp(
        backend: FakeFprintBackend(),
        monetizationBackend: FakeMonetizationBackend(),
      ),
    );
    await tester.pumpAndSettle();

    // Inicia en claro (según sistema); el primer clic debe cambiar a oscuro.
    expect(find.byIcon(Icons.dark_mode_outlined), findsOneWidget);
    await tester.tap(find.byIcon(Icons.dark_mode_outlined));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.light_mode_outlined), findsOneWidget);

    // El segundo clic debe volver a claro.
    await tester.tap(find.byIcon(Icons.light_mode_outlined));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.dark_mode_outlined), findsOneWidget);
  });
}
