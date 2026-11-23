/// Tipo de lectura soportado por el sensor biométrico según libfprint/fprintd.
enum ScanType {
  press,
  swipe,
  unknown;

  static ScanType fromFprintd(String value) {
    switch (value.toLowerCase().trim()) {
      case 'press':
        return ScanType.press;
      case 'swipe':
        return ScanType.swipe;
      default:
        return ScanType.unknown;
    }
  }

  String get displayLabel {
    switch (this) {
      case ScanType.press:
        return 'Táctil (Presión)';
      case ScanType.swipe:
        return 'Deslizamiento';
      case ScanType.unknown:
        return 'Estándar';
    }
  }
}

/// Estado general de disponibilidad del subsistema fprintd y del hardware lector.
enum HardwareStatus {
  loading,
  ready,
  serviceUnavailable,
  noDeviceFound,
  permissionDenied,
  error,
}

/// Metadatos de un lector de huellas expuesto por net.reactivated.Fprint.Device.
class FprintDeviceInfo {
  final String objectPath;
  final String name;
  final int numEnrollStages;
  final ScanType scanType;
  final bool fingerPresent;
  final bool fingerNeeded;

  const FprintDeviceInfo({
    required this.objectPath,
    required this.name,
    required this.numEnrollStages,
    required this.scanType,
    this.fingerPresent = false,
    this.fingerNeeded = false,
  });

  FprintDeviceInfo copyWith({
    String? objectPath,
    String? name,
    int? numEnrollStages,
    ScanType? scanType,
    bool? fingerPresent,
    bool? fingerNeeded,
  }) {
    return FprintDeviceInfo(
      objectPath: objectPath ?? this.objectPath,
      name: name ?? this.name,
      numEnrollStages: numEnrollStages ?? this.numEnrollStages,
      scanType: scanType ?? this.scanType,
      fingerPresent: fingerPresent ?? this.fingerPresent,
      fingerNeeded: fingerNeeded ?? this.fingerNeeded,
    );
  }
}

/// Dispositivo USB biométrico detectado dinámicamente en sysfs (/sys/bus/usb/devices).
class UsbFingerprintDevice {
  final String vendorId;
  final String productId;
  final String vendorName;
  final String productName;
  final String sysfsPath;

  const UsbFingerprintDevice({
    required this.vendorId,
    required this.productId,
    required this.vendorName,
    required this.productName,
    required this.sysfsPath,
  });

  String get usbId => '$vendorId:$productId';
}

/// Resultado integral del diagnóstico del entorno Linux y sandbox.
class SystemDiagnostics {
  final bool isRunningInFlatpak;
  final bool dbusConnected;
  final bool fprintdAvailable;
  final bool hasPkexec;
  final bool hasUsbreset;
  final bool hasPamAuthUpdate;
  final bool hasAuthselect;
  final bool hasFprintdCli;
  final bool isPamEnabled;
  final bool isPolkitRuleInstalled;
  final List<UsbFingerprintDevice> usbDevices;
  final List<FprintDeviceInfo> devices;
  final HardwareStatus status;
  final String? errorMessage;

  const SystemDiagnostics({
    required this.isRunningInFlatpak,
    required this.dbusConnected,
    required this.fprintdAvailable,
    required this.hasPkexec,
    required this.hasUsbreset,
    required this.hasPamAuthUpdate,
    required this.hasAuthselect,
    required this.hasFprintdCli,
    required this.isPamEnabled,
    required this.isPolkitRuleInstalled,
    required this.usbDevices,
    required this.devices,
    required this.status,
    this.errorMessage,
  });
}

/// Evento emitido durante una sesión activa de registro (fprintd EnrollStatus).
class EnrollmentUpdate {
  final int stage;
  final int totalStages;
  final String resultCode;
  final String message;
  final bool isCompleted;
  final bool isError;
  final bool isRetry;
  final bool fingerPresent;

  const EnrollmentUpdate({
    required this.stage,
    required this.totalStages,
    required this.resultCode,
    required this.message,
    this.isCompleted = false,
    this.isError = false,
    this.isRetry = false,
    this.fingerPresent = false,
  });
}

/// Estado individual de una sesión de verificación (fprintd VerifyStatus).
enum VerificationStepState {
  scanning,
  match,
  noMatch,
  retry,
  error,
}

/// Evento emitido durante una sesión activa de verificación biométrica.
class VerificationUpdate {
  final VerificationStepState state;
  final String resultCode;
  final String message;
  final String? matchedFingerCode;
  final bool fingerPresent;
  final bool done;

  const VerificationUpdate({
    required this.state,
    required this.resultCode,
    required this.message,
    this.matchedFingerCode,
    this.fingerPresent = false,
    this.done = false,
  });
}

