/// Identificador especial de fprintd para verificar contra cualquier huella inscrita.
const String kAnyFingerCode = 'any';

/// Diccionario estándar de dedos reconocidos por fprintd.
const Map<String, String> kFprintdFingers = {
  'right-index-finger': 'Índice Derecho',
  'right-thumb': 'Pulgar Derecho',
  'right-middle-finger': 'Medio Derecho',
  'right-ring-finger': 'Anular Derecho',
  'right-little-finger': 'Meñique Derecho',
  'left-index-finger': 'Índice Izquierdo',
  'left-thumb': 'Pulgar Izquierdo',
  'left-middle-finger': 'Medio Izquierdo',
  'left-ring-finger': 'Anular Izquierdo',
  'left-little-finger': 'Meñique Izquierdo',
};

/// Modelo que representa una huella dactilar registrada.
class FingerprintItem {
  final String id;
  final String name;
  final String fingerCode;
  final String fingerName;
  final String devicePath;

  const FingerprintItem({
    required this.id,
    required this.name,
    required this.fingerCode,
    required this.fingerName,
    this.devicePath = '',
  });

  /// Retorna el nombre traducido amigable según el estándar fprintd.
  static String getFriendlyName(String code) {
    if (code == kAnyFingerCode) {
      return 'Cualquier huella (automático)';
    }
    return kFprintdFingers[code] ?? code;
  }
}

/// Estados de visualización del sensor biométrico en la interfaz.
enum SensorState {
  idle,
  scanning,
  success,
  error,
  unavailable,
  restarting,
}
