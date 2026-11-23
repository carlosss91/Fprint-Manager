import 'dart:async';
import 'package:flutter/material.dart';
import '../models/fprint_device_info.dart';
import '../models/fingerprint_item.dart';
import '../services/fprint_service.dart';
import '../theme/app_theme.dart';
import 'fingerprint_scanner_widget.dart';

/// Diálogo interactivo agnóstico para registrar una nueva huella a través de fprintd D-Bus.
class EnrollmentDialog extends StatefulWidget {
  final FprintBackend backend;
  final FprintDeviceInfo device;
  final List<String> enrolledFingers;
  final VoidCallback onEnrollmentFinished;

  const EnrollmentDialog({
    super.key,
    required this.backend,
    required this.device,
    required this.enrolledFingers,
    required this.onEnrollmentFinished,
  });

  @override
  State<EnrollmentDialog> createState() => _EnrollmentDialogState();
}

class _EnrollmentDialogState extends State<EnrollmentDialog> {
  String _selectedFinger = 'right-index-finger';
  bool _isEnrolling = false;
  int _currentStage = 0;
  late int _totalStages;
  String _statusMessage = '';
  bool _isCompleted = false;
  bool _fingerPresent = false;
  bool _isRetry = false;
  String? _errorMessage;

  FprintEnrollmentSession? _session;
  StreamSubscription<EnrollmentUpdate>? _subscription;
  Timer? _autoCloseTimer;

  @override
  void initState() {
    super.initState();
    _totalStages = widget.device.numEnrollStages > 0
        ? widget.device.numEnrollStages
        : 8;

    for (final key in kFprintdFingers.keys) {
      if (!widget.enrolledFingers.contains(key)) {
        _selectedFinger = key;
        break;
      }
    }

    _statusMessage = widget.device.scanType == ScanType.swipe
        ? 'Desliza tu dedo suavemente sobre el sensor para comenzar.'
        : 'Coloca tu dedo firmemente sobre el sensor para comenzar.';
  }

  @override
  void dispose() {
    _autoCloseTimer?.cancel();
    _subscription?.cancel();
    unawaited(_session?.cancel());
    super.dispose();
  }

  Future<void> _startEnrollment() async {
    await _subscription?.cancel();
    await _session?.cancel();

    setState(() {
      _isEnrolling = true;
      _currentStage = 0;
      _isCompleted = false;
      _isRetry = false;
      _fingerPresent = false;
      _errorMessage = null;
      _statusMessage = 'Preparando el sensor ${widget.device.name}...';
    });

    try {
      final session = await widget.backend.startEnrollment(
        widget.device,
        _selectedFinger,
      );
      if (!mounted) {
        await session.cancel();
        return;
      }
      _session = session;
      _subscription = session.updates.listen(
        (update) {
          if (!mounted) return;
          setState(() {
            _currentStage = update.stage;
            _totalStages = update.totalStages > 0 ? update.totalStages : _totalStages;
            _fingerPresent = update.fingerPresent;
            _isRetry = update.isRetry;

            if (update.isError) {
              _errorMessage = update.message;
            } else {
              _statusMessage = update.message;
            }

            if (update.isCompleted) {
              _isCompleted = true;
              _currentStage = _totalStages;
            }
          });

          if (update.isCompleted) {
            widget.onEnrollmentFinished();
            _autoCloseTimer?.cancel();
            _autoCloseTimer = Timer(const Duration(milliseconds: 1450), () {
              if (mounted) {
                Navigator.of(context).pop();
              }
            });
          }
        },
        onError: (Object err) {
          if (!mounted) return;
          setState(() {
            _errorMessage = 'Error durante el registro: $err';
          });
        },
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _cancelEnrollment() async {
    _autoCloseTimer?.cancel();
    await _subscription?.cancel();
    _subscription = null;
    await _session?.cancel();
    _session = null;
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  SensorState _currentScannerState() {
    if (_isCompleted) return SensorState.success;
    if (_errorMessage != null) return SensorState.error;
    return SensorState.scanning;
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final progress = _totalStages > 0
        ? (_currentStage / _totalStages).clamp(0.0, 1.0)
        : 0.0;
    final alreadyEnrolled = widget.enrolledFingers.contains(_selectedFinger);

    return AlertDialog(
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: AppColors.primary(context).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.fingerprint_rounded,
              color: AppColors.primary(context),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isEnrolling
                      ? 'Registrando: ${FingerprintItem.getFriendlyName(_selectedFinger)}'
                      : 'Registrar nueva huella',
                  style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.w700),
                ),
                Text(
                  '${widget.device.name} • ${widget.device.scanType.displayLabel}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary(context),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 440,
        child: AnimatedSwitcher(
          duration: reduceMotion ? Duration.zero : const Duration(milliseconds: 260),
          child: !_isEnrolling
              ? _buildSelectionForm(context, alreadyEnrolled)
              : _buildLiveEnrollmentProgress(context, progress, reduceMotion),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _cancelEnrollment,
          child: Text(_isCompleted ? 'Cerrar' : 'Cancelar'),
        ),
        if (!_isEnrolling)
          FilledButton.icon(
            onPressed: _startEnrollment,
            icon: const Icon(Icons.play_arrow_rounded, size: 18),
            label: Text(alreadyEnrolled ? 'Sobrescribir huella' : 'Iniciar registro'),
          )
        else if (_errorMessage != null && !_isCompleted)
          FilledButton.icon(
            onPressed: _startEnrollment,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Reintentar'),
          ),
      ],
    );
  }

  Widget _buildSelectionForm(BuildContext context, bool alreadyEnrolled) {
    final scanInstruction = widget.device.scanType == ScanType.swipe
        ? 'Tu lector es de deslizamiento: requerirá $_totalStages pasadas suaves sobre el sensor.'
        : 'Tu lector es táctil: requerirá apoyar y levantar el dedo $_totalStages veces hasta completar el círculo al 100%.';

    return Column(
      key: const ValueKey('selection_form'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Selecciona el dedo que deseas registrar:',
          style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(
          initialValue: _selectedFinger,
          decoration: InputDecoration(
            isDense: true,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
          items: kFprintdFingers.entries.map((entry) {
            final isAlready = widget.enrolledFingers.contains(entry.key);
            return DropdownMenuItem(
              value: entry.key,
              child: Row(
                children: [
                  Text(entry.value),
                  if (isAlready) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: AppColors.warning(context).withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Ya inscrita',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.warning(context),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          }).toList(),
          onChanged: (val) {
            if (val != null) {
              setState(() => _selectedFinger = val);
            }
          },
        ),
        if (alreadyEnrolled) ...[
          const SizedBox(height: 10),
          Text(
            'Nota: Este dedo ya tiene una huella guardada; al registrarlo nuevamente se reemplazará en fprintd.',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.warning(context),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primary(context).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: AppColors.primary(context).withValues(alpha: 0.22),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.touch_app_rounded, size: 18, color: AppColors.primary(context)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  scanInstruction,
                  style: const TextStyle(fontSize: 12.5, height: 1.38),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLiveEnrollmentProgress(
    BuildContext context,
    double targetProgress,
    bool reduceMotion,
  ) {
    return TweenAnimationBuilder<double>(
      key: const ValueKey('enrollment_progress'),
      tween: Tween<double>(begin: 0.0, end: targetProgress),
      duration: reduceMotion ? Duration.zero : const Duration(milliseconds: 360),
      curve: Curves.easeOutCubic,
      builder: (context, animatedProgress, _) {
        final percentage = (animatedProgress * 100).round();
        final badgeColor = _isCompleted
            ? AppColors.success(context)
            : (_errorMessage != null
                ? AppColors.error(context)
                : (_isRetry ? AppColors.warning(context) : AppColors.primary(context)));

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 4),
            FingerprintScannerWidget(
              state: _currentScannerState(),
              progress: animatedProgress,
              totalStages: _totalStages,
              fingerPresent: _fingerPresent,
              size: 176,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: badgeColor.withValues(alpha: 0.13),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: badgeColor.withValues(alpha: 0.30)),
              ),
              child: Text(
                _isCompleted
                    ? '¡Registro completado • 100%!'
                    : 'Etapa $_currentStage de $_totalStages • $percentage%',
                style: AppTheme.tabularFiguresStyle.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: badgeColor,
                ),
              ),
            ),
            const SizedBox(height: 12),
            AnimatedSwitcher(
              duration: reduceMotion ? Duration.zero : const Duration(milliseconds: 200),
              child: Text(
                _errorMessage ?? _statusMessage,
                key: ValueKey<String>(_errorMessage ?? _statusMessage),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13.5,
                  height: 1.4,
                  fontWeight: FontWeight.w500,
                  color: _errorMessage != null
                      ? AppColors.error(context)
                      : (_isCompleted
                          ? AppColors.success(context)
                          : (_isRetry ? AppColors.warning(context) : null)),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
