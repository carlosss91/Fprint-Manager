import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/fingerprint_item.dart';
import '../theme/app_theme.dart';

/// Clipper personalizado para rellenar verticalmente el gráfico de la huella dactilar.
class VerticalFillClipper extends CustomClipper<Rect> {
  final double factor;

  const VerticalFillClipper(this.factor);

  @override
  Rect getClip(Size size) {
    final clamped = factor.clamp(0.0, 1.0);
    final top = size.height * (1.0 - clamped);
    return Rect.fromLTRB(0, top, size.width, size.height);
  }

  @override
  bool shouldReclip(VerticalFillClipper oldClipper) => oldClipper.factor != factor;
}

/// Widget de escáner biométrico animado a 60/120 fps mediante CustomPainter y RepaintBoundary.
/// - Solo mantiene controladores repetitivos activos durante el escaneo (0% CPU/GPU en reposo).
/// - Respeta automáticamente prefers-reduced-motion (MediaQuery.disableAnimationsOf).
class FingerprintScannerWidget extends StatefulWidget {
  final SensorState state;
  final double progress; // 0.0 .. 1.0
  final int totalStages; // >0 para arco segmentado durante el registro
  final bool fingerPresent;
  final VoidCallback? onTap;
  final double size;

  const FingerprintScannerWidget({
    super.key,
    required this.state,
    this.progress = 0.0,
    this.totalStages = 0,
    this.fingerPresent = false,
    this.onTap,
    this.size = 176,
  });

  @override
  State<FingerprintScannerWidget> createState() => _FingerprintScannerWidgetState();
}

class _FingerprintScannerWidgetState extends State<FingerprintScannerWidget>
    with TickerProviderStateMixin {
  late final AnimationController _radarController;
  late final AnimationController _beamController;
  late final AnimationController _burstController;
  late final AnimationController _shakeController;
  bool _isHovered = false;
  bool _reduceMotion = false;

  @override
  void initState() {
    super.initState();
    _radarController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );
    _beamController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1450),
    );
    _burstController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 620),
    );
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.disableAnimationsOf(context);
    _syncControllers(previousState: null);
  }

  @override
  void didUpdateWidget(FingerprintScannerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    _reduceMotion = MediaQuery.disableAnimationsOf(context);
    _syncControllers(previousState: oldWidget.state);
  }

  void _syncControllers({SensorState? previousState}) {
    final shouldAnimateLoop =
        (widget.state == SensorState.scanning ||
            widget.state == SensorState.restarting) &&
        !_reduceMotion;

    if (shouldAnimateLoop) {
      if (!_radarController.isAnimating) {
        _radarController.repeat();
      }
      if (widget.state == SensorState.scanning && !_beamController.isAnimating) {
        _beamController.repeat(reverse: true);
      } else if (widget.state != SensorState.scanning && _beamController.isAnimating) {
        _beamController.stop();
        _beamController.reset();
      }
    } else {
      if (_radarController.isAnimating) {
        _radarController.stop();
        _radarController.reset();
      }
      if (_beamController.isAnimating) {
        _beamController.stop();
        _beamController.reset();
      }
    }

    if (previousState != null && previousState != widget.state) {
      if (widget.state == SensorState.success && !_reduceMotion) {
        _burstController.forward(from: 0.0);
      } else if (widget.state == SensorState.error && !_reduceMotion) {
        _shakeController.forward(from: 0.0);
      }
    }
  }

  @override
  void dispose() {
    _radarController.dispose();
    _beamController.dispose();
    _burstController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  Color _accentForState(BuildContext context) {
    switch (widget.state) {
      case SensorState.scanning:
      case SensorState.restarting:
        return AppColors.primary(context);
      case SensorState.success:
        return AppColors.success(context);
      case SensorState.error:
        return AppColors.error(context);
      case SensorState.unavailable:
        return AppColors.textSecondary(context).withValues(alpha: 0.55);
      case SensorState.idle:
        return widget.fingerPresent
            ? AppColors.primary(context)
            : AppColors.textSecondary(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = _accentForState(context);
    final isScanning = widget.state == SensorState.scanning;
    final isRestarting = widget.state == SensorState.restarting;
    final isUnavailable = widget.state == SensorState.unavailable;
    final outerSize = widget.size + 64;
    final hoverScale = (!_reduceMotion && _isHovered && widget.onTap != null && !isUnavailable)
        ? 1.03
        : 1.0;
    final touchBoost = widget.fingerPresent && !_reduceMotion ? 0.985 : 1.0;

    final double fillFactor;
    if (widget.state == SensorState.success) {
      fillFactor = 1.0;
    } else if (widget.progress > 0.0) {
      fillFactor = widget.progress.clamp(0.0, 1.0);
    } else if (isScanning && widget.fingerPresent) {
      fillFactor = 0.72;
    } else if (isScanning) {
      fillFactor = 0.36;
    } else {
      fillFactor = 0.0;
    }

    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _shakeController,
        builder: (context, child) {
          final shakeDx = _reduceMotion
              ? 0.0
              : math.sin(_shakeController.value * math.pi * 5) *
                  9.0 *
                  (1.0 - _shakeController.value);

          return Transform.translate(
            offset: Offset(shakeDx, 0),
            child: SizedBox(
              width: outerSize,
              height: outerSize,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Capa pintada en GPU (ondas de radar, arco giratorio, segmentos, rayo y destello)
                  Positioned.fill(
                    child: AnimatedBuilder(
                      animation: Listenable.merge([
                        _radarController,
                        _beamController,
                        _burstController,
                      ]),
                      builder: (context, _) {
                        return CustomPaint(
                          painter: _ScannerCanvasPainter(
                            state: widget.state,
                            accentColor: accentColor,
                            trackColor: AppColors.border(context),
                            radarValue: _radarController.value,
                            beamValue: _beamController.value,
                            burstValue: _burstController.value,
                            progress: widget.progress,
                            totalStages: widget.totalStages,
                            fingerPresent: widget.fingerPresent,
                            reduceMotion: _reduceMotion,
                            circleSize: widget.size,
                          ),
                        );
                      },
                    ),
                  ),

                  // Núcleo interactivo del lector
                  MouseRegion(
                    cursor: (widget.onTap != null && !isUnavailable)
                        ? SystemMouseCursors.click
                        : SystemMouseCursors.basic,
                    onEnter: (_) => setState(() => _isHovered = true),
                    onExit: (_) => setState(() => _isHovered = false),
                    child: GestureDetector(
                      onTap: isUnavailable ? null : widget.onTap,
                      child: AnimatedScale(
                        scale: hoverScale * touchBoost,
                        duration: _reduceMotion
                            ? Duration.zero
                            : const Duration(milliseconds: 180),
                        curve: Curves.easeOutCubic,
                        child: AnimatedContainer(
                          duration: _reduceMotion
                              ? Duration.zero
                              : const Duration(milliseconds: 280),
                          curve: Curves.easeOutCubic,
                          width: widget.size,
                          height: widget.size,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.surface(context),
                            border: Border.all(
                              color: widget.fingerPresent
                                  ? accentColor
                                  : (isUnavailable
                                      ? AppColors.border(context)
                                      : accentColor.withValues(
                                          alpha: widget.state == SensorState.idle
                                              ? (_isHovered ? 0.85 : 0.45)
                                              : 0.92,
                                        )),
                              width: widget.fingerPresent ||
                                      widget.state == SensorState.success ||
                                      widget.state == SensorState.error
                                  ? 3.5
                                  : 2.0,
                            ),
                            boxShadow: [
                              if (!isUnavailable)
                                BoxShadow(
                                  color: accentColor.withValues(
                                    alpha: widget.fingerPresent
                                        ? 0.34
                                        : (isScanning
                                            ? 0.24
                                            : (widget.state == SensorState.success
                                                ? 0.30
                                                : (_isHovered ? 0.14 : 0.06))),
                                  ),
                                  blurRadius: widget.fingerPresent || isScanning
                                      ? 30
                                      : (widget.state == SensorState.success
                                          ? 32
                                          : 16),
                                  spreadRadius: widget.fingerPresent ? 4 : 1,
                                ),
                            ],
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              if (isRestarting)
                                SizedBox(
                                  width: widget.size * 0.42,
                                  height: widget.size * 0.42,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 3,
                                    color: accentColor,
                                  ),
                                )
                              else ...[
                                // Silueta base de huella
                                Icon(
                                  isUnavailable
                                      ? Icons.fingerprint_outlined
                                      : Icons.fingerprint_rounded,
                                  size: widget.size * 0.58,
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.12)
                                      : const Color(0xFFD3D8E0),
                                ),

                                // Relleno vertical progresivo de la huella
                                ClipRect(
                                  clipper: VerticalFillClipper(fillFactor),
                                  child: Icon(
                                    Icons.fingerprint_rounded,
                                    size: widget.size * 0.58,
                                    color: accentColor,
                                  ),
                                ),

                                // Haz de escaneo horizontal fluido
                                if (isScanning && !_reduceMotion)
                                  AnimatedBuilder(
                                    animation: _beamController,
                                    builder: (context, _) {
                                      final dy = (_beamController.value * 2 - 1) *
                                          (widget.size * 0.28);
                                      return Transform.translate(
                                        offset: Offset(0, dy),
                                        child: Container(
                                          width: widget.size * 0.56,
                                          height: 3,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(2),
                                            gradient: LinearGradient(
                                              colors: [
                                                accentColor.withValues(alpha: 0.0),
                                                accentColor.withValues(alpha: 0.85),
                                                accentColor.withValues(alpha: 0.0),
                                              ],
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: accentColor.withValues(alpha: 0.55),
                                                blurRadius: 10,
                                                spreadRadius: 1,
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                              ],

                              // Badge inferior de confirmación o error
                              if (widget.state == SensorState.success)
                                Positioned(
                                  bottom: 10,
                                  right: 10,
                                  child: TweenAnimationBuilder<double>(
                                    tween: Tween(begin: _reduceMotion ? 1.0 : 0.0, end: 1.0),
                                    duration: _reduceMotion
                                        ? Duration.zero
                                        : const Duration(milliseconds: 420),
                                    curve: Curves.elasticOut,
                                    builder: (context, val, _) {
                                      return Transform.scale(
                                        scale: val,
                                        child: Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color: AppColors.success(context),
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: AppColors.surface(context),
                                              width: 2.5,
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.check_rounded,
                                            color: Colors.white,
                                            size: 16,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                )
                              else if (widget.state == SensorState.error)
                                Positioned(
                                  bottom: 10,
                                  right: 10,
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: AppColors.error(context),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: AppColors.surface(context),
                                        width: 2.5,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.close_rounded,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ScannerCanvasPainter extends CustomPainter {
  final SensorState state;
  final Color accentColor;
  final Color trackColor;
  final double radarValue;
  final double beamValue;
  final double burstValue;
  final double progress;
  final int totalStages;
  final bool fingerPresent;
  final bool reduceMotion;
  final double circleSize;

  const _ScannerCanvasPainter({
    required this.state,
    required this.accentColor,
    required this.trackColor,
    required this.radarValue,
    required this.beamValue,
    required this.burstValue,
    required this.progress,
    required this.totalStages,
    required this.fingerPresent,
    required this.reduceMotion,
    required this.circleSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final baseRadius = circleSize / 2;

    // 1. Ondas concéntricas durante el escaneo
    if (state == SensorState.scanning && !reduceMotion) {
      for (int i = 0; i < 3; i++) {
        final wave = (radarValue + (i / 3.0)) % 1.0;
        final radius = baseRadius + (wave * 28.0);
        final alpha = (1.0 - wave) * (fingerPresent ? 0.42 : 0.28);
        final paint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0 * (1.0 - wave * 0.4)
          ..color = accentColor.withValues(alpha: alpha);
        canvas.drawCircle(center, radius, paint);
      }

      // Arco luminoso giratorio alrededor del sensor
      final sweepRect = Rect.fromCircle(center: center, radius: baseRadius + 7);
      final sweepPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0
        ..strokeCap = StrokeCap.round
        ..shader = SweepGradient(
          startAngle: 0,
          endAngle: math.pi * 2,
          transform: GradientRotation(radarValue * math.pi * 2),
          colors: [
            accentColor.withValues(alpha: 0.0),
            accentColor.withValues(alpha: 0.15),
            accentColor.withValues(alpha: 0.90),
          ],
          stops: const [0.0, 0.55, 1.0],
        ).createShader(sweepRect);
      canvas.drawCircle(center, baseRadius + 7, sweepPaint);
    }

    // 2. Anillo segmentado o continuo de progreso (registro multi-etapa)
    if (totalStages > 0) {
      final ringRadius = baseRadius + 9;
      final rect = Rect.fromCircle(center: center, radius: ringRadius);
      final gapAngle = totalStages > 1 ? 0.08 : 0.0;
      final fullStep = (math.pi * 2) / totalStages;
      final sweepAngle = math.max(0.05, fullStep - gapAngle);
      final completedFloat = (progress.clamp(0.0, 1.0)) * totalStages;

      for (int i = 0; i < totalStages; i++) {
        final startAngle = -math.pi / 2 + (i * fullStep) + (gapAngle / 2);
        final isFilled = i < completedFloat.floor();
        final partial = (completedFloat - i).clamp(0.0, 1.0);

        // Pista del segmento
        final bgPaint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6.0
          ..strokeCap = StrokeCap.round
          ..color = trackColor.withValues(alpha: 0.75);
        canvas.drawArc(rect, startAngle, sweepAngle, false, bgPaint);

        // Progreso del segmento
        if (isFilled || partial > 0.001) {
          final activePaint = Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 6.5
            ..strokeCap = StrokeCap.round
            ..color = accentColor;
          canvas.drawArc(
            rect,
            startAngle,
            sweepAngle * (isFilled ? 1.0 : partial),
            false,
            activePaint,
          );
        }
      }
    } else if (progress > 0.0) {
      final ringRadius = baseRadius + 9;
      final rect = Rect.fromCircle(center: center, radius: ringRadius);
      final bgPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5.5
        ..color = trackColor.withValues(alpha: 0.7);
      canvas.drawCircle(center, ringRadius, bgPaint);

      final activePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6.0
        ..strokeCap = StrokeCap.round
        ..color = accentColor;
      canvas.drawArc(
        rect,
        -math.pi / 2,
        math.pi * 2 * progress.clamp(0.0, 1.0),
        false,
        activePaint,
      );
    }

    // 3. Destello expansivo puntual al completar con éxito
    if (state == SensorState.success && burstValue > 0.0 && burstValue < 1.0) {
      final burstRadius = baseRadius + (burstValue * 30.0);
      final burstPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.0 * (1.0 - burstValue)
        ..color = accentColor.withValues(alpha: (1.0 - burstValue) * 0.65);
      canvas.drawCircle(center, burstRadius, burstPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _ScannerCanvasPainter oldDelegate) {
    return oldDelegate.state != state ||
        oldDelegate.accentColor != accentColor ||
        oldDelegate.radarValue != radarValue ||
        oldDelegate.beamValue != beamValue ||
        oldDelegate.burstValue != burstValue ||
        oldDelegate.progress != progress ||
        oldDelegate.totalStages != totalStages ||
        oldDelegate.fingerPresent != fingerPresent ||
        oldDelegate.reduceMotion != reduceMotion;
  }
}
