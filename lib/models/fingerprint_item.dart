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

  const FingerprintItem({
    required this.id,
    required this.name,
    required this.fingerCode,
    required this.fingerName,
  });

  /// Retorna el nombre traducido amigable según el estándar fprintd.
  static String getFriendlyName(String code) {
    return kFprintdFingers[code] ?? code;
  }
}

/// Estados de visualización del sensor biométrico.
enum SensorState {
  idle,
  scanning,
  success,
  error,
}

