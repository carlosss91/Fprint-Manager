import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import '../models/fingerprint_item.dart';
import '../services/fprint_service.dart';
import 'fingerprint_scanner_widget.dart';

/// Diálogo interactivo para registrar una nueva huella con fprintd usando la bandera obligatoria -f.
class EnrollmentDialog extends StatefulWidget {
  final int totalStages;
  final List<String> enrolledFingers;
  final VoidCallback onEnrollmentFinished;

  const EnrollmentDialog({
    super.key,
    required this.totalStages,
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
  String _statusMessage = 'Coloca tu dedo firmemente sobre el sensor para comenzar.';
  bool _isCompleted = false;
  String? _errorMessage;
  Process? _enrollProcess;

  @override
  void initState() {
    super.initState();
    // Seleccionar el primer dedo no registrado de forma predeterminada
    for (final key in kFprintdFingers.keys) {
      if (!widget.enrolledFingers.contains(key)) {
        _selectedFinger = key;
        break;
      }
    }
  }

  @override
  void dispose() {
    _enrollProcess?.kill();
    super.dispose();
  }

  /// Inicia el enrolamiento invocando `fprintd-enroll -f <dedo>`
  Future<void> _startEnrollment() async {
    setState(() {
      _isEnrolling = true;
      _currentStage = 0;
      _isCompleted = false;
      _errorMessage = null;
      _statusMessage = 'Sensor listo. Coloca tu dedo sobre el lector físico.';
    });

    try {
      final process = await FprintService.startEnrollProcess(_selectedFinger);
      _enrollProcess = process;

      process.stdout
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen((line) {
        if (!mounted) return;

        if (line.contains('enroll-stage-passed')) {
          setState(() {
            _currentStage = (_currentStage + 1).clamp(0, widget.totalStages);
            _statusMessage = '¡Muestra $_currentStage capturada! Levanta el dedo y vuelve a colocarlo.';
          });
        } else if (line.contains('enroll-retry-scan') || line.contains('enroll-swipe-too-short')) {
          setState(() {
            _statusMessage = 'Lectura incompleta. Vuelve a apoyar el dedo con firmeza.';
          });
        } else if (line.contains('enroll-finger-not-centered')) {
          setState(() {
            _statusMessage = 'Centra más el dedo sobre la superficie del sensor.';
          });
        } else if (line.contains('enroll-remove-and-retry')) {
          setState(() {
            _statusMessage = 'Retira el dedo y vuelve a colocarlo.';
          });
        } else if (line.contains('enroll-completed')) {
          setState(() {
            _currentStage = widget.totalStages;
            _isCompleted = true;
            _statusMessage = '¡Huella dactilar registrada exitosamente!';
          });
          widget.onEnrollmentFinished();
          Future.delayed(const Duration(milliseconds: 1600), () {
            if (mounted) Navigator.of(context).pop();
          });
        } else if (line.contains('enroll-failed')) {
          setState(() {
            _errorMessage = 'El registro ha fallado. Intenta de nuevo.';
          });
        }
      });

      process.stderr
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen((errorLine) {
        if (!mounted) return;
        if (errorLine.contains('failed to claim') || errorLine.contains('Device was already claimed')) {
          setState(() {
            _errorMessage = 'El sensor está ocupado. Cancela y reinicia el servicio.';
          });
        }
      });

      process.exitCode.then((code) {
        if (mounted && !_isCompleted && _errorMessage == null && code != 0) {
          setState(() {
            _errorMessage = 'Registro cancelado o interrumpido (código: $code).';
          });
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'No se pudo iniciar fprintd-enroll: $e';
        });
      }
    }
  }

  void _cancelEnrollment() {
    _enrollProcess?.kill();
    _enrollProcess = null;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final progress = widget.totalStages > 0
        ? (_currentStage / widget.totalStages).clamp(0.0, 1.0)
        : 0.0;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFF3584E4).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.fingerprint_rounded, color: Color(0xFF3584E4), size: 20),
          ),
          const SizedBox(width: 10),
          Text(
            _isEnrolling
                ? 'Registrando: ${FingerprintItem.getFriendlyName(_selectedFinger)}'
                : 'Registrar nueva huella',
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      content: SizedBox(
        width: 420,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: !_isEnrolling
              ? _buildSelectionForm(context)
              : _buildLiveEnrollmentProgress(context, progress, isDark),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _cancelEnrollment,
          child: Text(_isCompleted ? 'Cerrar' : 'Cancelar'),
        ),
        if (!_isEnrolling)
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF3584E4),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: _startEnrollment,
            icon: const Icon(Icons.play_arrow_rounded, size: 18),
            label: const Text('Iniciar en Sensor'),
          ),
      ],
    );
  }

  Widget _buildSelectionForm(BuildContext context) {
    return Column(
      key: const ValueKey('selection_form'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Selecciona el dedo que vas a registrar con la bandera -f:',
          style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 12),
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
                    const Text('(Ya registrada)', style: TextStyle(fontSize: 11, color: Colors.grey)),
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
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF3584E4).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF3584E4).withValues(alpha: 0.2)),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.touch_app_rounded, size: 18, color: Color(0xFF3584E4)),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Coloca y levanta el dedo varias veces según el patrón del sensor Goodix hasta completar el anillo al 100%.',
                  style: TextStyle(fontSize: 12.5, height: 1.3),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLiveEnrollmentProgress(BuildContext context, double targetProgress, bool isDark) {
    return TweenAnimationBuilder<double>(
      key: const ValueKey('enrollment_progress'),
      tween: Tween<double>(begin: 0.0, end: targetProgress),
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeOutCubic,
      builder: (context, animatedProgress, child) {
        final percentage = (animatedProgress * 100).toInt();

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            SizedBox(
              width: 190,
              height: 190,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 180,
                    height: 180,
                    child: CircularProgressIndicator(
                      value: animatedProgress,
                      strokeWidth: 8,
                      strokeCap: StrokeCap.round,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _isCompleted ? const Color(0xFF2EC27E) : const Color(0xFF3584E4),
                      ),
                      backgroundColor: isDark ? const Color(0xFF333338) : const Color(0xFFE5E7EB),
                    ),
                  ),
                  Icon(
                    Icons.fingerprint_rounded,
                    size: 110,
                    color: isDark ? Colors.white12 : const Color(0xFFD6DAE0),
                  ),
                  ClipRect(
                    clipper: VerticalFillClipper(animatedProgress),
                    child: Icon(
                      Icons.fingerprint_rounded,
                      size: 110,
                      color: _isCompleted ? const Color(0xFF2EC27E) : const Color(0xFF3584E4),
                    ),
                  ),
                  if (_isCompleted)
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Color(0xFF2EC27E),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check, color: Colors.white, size: 28),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              decoration: BoxDecoration(
                color: _isCompleted
                    ? const Color(0xFF2EC27E).withValues(alpha: 0.15)
                    : const Color(0xFF3584E4).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                _isCompleted
                    ? '¡Completado 100%!'
                    : 'Paso $_currentStage de ${widget.totalStages} • $percentage%',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: _isCompleted ? const Color(0xFF2EC27E) : const Color(0xFF3584E4),
                ),
              ),
            ),
            const SizedBox(height: 14),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Text(
                _errorMessage ?? _statusMessage,
                key: ValueKey<String>(_errorMessage ?? _statusMessage),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13.5,
                  height: 1.4,
                  fontWeight: FontWeight.w500,
                  color: _errorMessage != null
                      ? const Color(0xFFE01B24)
                      : (_isCompleted ? const Color(0xFF2EC27E) : null),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

