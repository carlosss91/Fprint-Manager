import 'package:flutter/material.dart';
import '../models/verification_log.dart';

/// Diálogo minimalista para inspeccionar el historial de intentos de verificación biométrica de la sesión.
class VerificationHistoryDialog extends StatelessWidget {
  final List<VerificationLog> logs;
  final VoidCallback onClearLogs;

  const VerificationHistoryDialog({
    super.key,
    required this.logs,
    required this.onClearLogs,
  });

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    final s = dt.second.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          const Icon(Icons.history_rounded, color: Color(0xFF3584E4), size: 22),
          const SizedBox(width: 10),
          const Text('Historial de Verificaciones', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          const Spacer(),
          if (logs.isNotEmpty)
            TextButton.icon(
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                foregroundColor: const Color(0xFFE01B24),
              ),
              onPressed: onClearLogs,
              icon: const Icon(Icons.delete_sweep_outlined, size: 16),
              label: const Text('Limpiar', style: TextStyle(fontSize: 12)),
            ),
        ],
      ),
      content: SizedBox(
        width: 440,
        height: 380,
        child: logs.isEmpty
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.rule_folder_outlined, size: 44, color: theme.disabledColor),
                    const SizedBox(height: 10),
                    const Text('Sin actividad registrada', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 4),
                    Text(
                      'Cada vez que pruebes el sensor físico con "fprintd-verify", los resultados quedarán registrados aquí.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: theme.hintColor, fontSize: 12.5),
                    ),
                  ],
                ),
              )
            : ListView.separated(
                itemCount: logs.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  // Mostrar más recientes primero
                  final log = logs[logs.length - 1 - index];
                  final isSuccess = log.isSuccess;

                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF262629) : const Color(0xFFF8F9FA),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSuccess
                            ? const Color(0xFF2EC27E).withValues(alpha: 0.3)
                            : const Color(0xFFE01B24).withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isSuccess ? Icons.check_circle_rounded : Icons.cancel_rounded,
                          color: isSuccess ? const Color(0xFF2EC27E) : const Color(0xFFE01B24),
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    log.fingerName,
                                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                  ),
                                  const Spacer(),
                                  Text(
                                    _formatTime(log.timestamp),
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontFamily: 'monospace',
                                      color: isDark ? Colors.white54 : Colors.black45,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                log.details,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: isDark ? Colors.white70 : Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cerrar'),
        ),
      ],
    );
  }
}
