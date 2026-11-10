/// Modelo para registrar el historial de eventos de verificación biométrica.
class VerificationLog {
  final DateTime timestamp;
  final String fingerCode;
  final String fingerName;
  final bool isSuccess;
  final String details;

  const VerificationLog({
    required this.timestamp,
    required this.fingerCode,
    required this.fingerName,
    required this.isSuccess,
    required this.details,
  });

  Map<String, dynamic> toJson() => {
        'timestamp': timestamp.toIso8601String(),
        'fingerCode': fingerCode,
        'fingerName': fingerName,
        'isSuccess': isSuccess,
        'details': details,
      };

  factory VerificationLog.fromJson(Map<String, dynamic> json) => VerificationLog(
        timestamp: DateTime.parse(json['timestamp'] as String),
        fingerCode: json['fingerCode'] as String,
        fingerName: json['fingerName'] as String,
        isSuccess: json['isSuccess'] as bool,
        details: json['details'] as String,
      );
}

