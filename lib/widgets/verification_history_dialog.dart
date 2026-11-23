import 'package:flutter/material.dart';
import '../models/verification_log.dart';
import '../theme/app_theme.dart';

/// Diálogo para inspeccionar el historial de verificaciones biométricas de la sesión.
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

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.history_rounded, color: AppColors.primary(context), size: 22),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Historial de Verificaciones',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
          ),
          if (logs.isNotEmpty)
            TextButton.icon(
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                foregroundColor: AppColors.error(context),
              ),
              onPressed: onClearLogs,
              icon: const Icon(Icons.delete_sweep_outlined, size: 16),
              label: const Text('Limpiar', style: TextStyle(fontSize: 12)),
            ),
        ],
      ),
      content: SizedBox(
        width: 460,
        height: 380,
        child: logs.isEmpty
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.rule_folder_outlined, size: 44, color: theme.disabledColor),
                    const SizedBox(height: 10),
                    const Text(
                      'Sin actividad registrada',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Cada vez que pruebes el sensor biométrico, los resultados quedarán registrados aquí.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textSecondary(context),
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              )
            : ListView.separated(
                itemCount: logs.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final log = logs[logs.length - 1 - index];
                  final isSuccess = log.isSuccess;
                  final statusColor =
                      isSuccess ? AppColors.success(context) : AppColors.error(context);

                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.sidebar(context),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: statusColor.withValues(alpha: 0.30),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isSuccess ? Icons.check_circle_rounded : Icons.cancel_rounded,
                          color: statusColor,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      log.fingerName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _formatTime(log.timestamp),
                                    style: AppTheme.tabularFiguresStyle.copyWith(
                                      fontSize: 11,
                                      fontFamily: 'monospace',
                                      color: AppColors.textSecondary(context),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                log.deviceName.isNotEmpty
                                    ? '${log.details} • ${log.deviceName}'
                                    : log.details,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: AppColors.textSecondary(context),
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
