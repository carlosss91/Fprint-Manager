import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/fingerprint_item.dart';

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

/// Widget con animaciones avanzadas:
/// 1. Ondas concéntricas expansivas (Radar Ripple Effect) durante el escaneo.
/// 2. Efecto de sacudida (Shake Animation) ante lecturas fallidas.
/// 3. Resplandor expansivo y rebote (Elastic Pop) al verificar con éxito.
/// 4. Relleno progresivo fluido de la huella dactilar.
class FingerprintScannerWidget extends StatefulWidget {
  final SensorState state;
  final double progress; // Valor entre 0.0 y 1.0
  final Animation<double>? pulseAnimation;
  final VoidCallback? onTap;
  final double size;

  const FingerprintScannerWidget({
    super.key,
    required this.state,
    this.progress = 0.0,
    this.pulseAnimation,
    this.onTap,
    this.size = 170,
  });

  @override
  State<FingerprintScannerWidget> createState() => _FingerprintScannerWidgetState();
}

class _FingerprintScannerWidgetState extends State<FingerprintScannerWidget>
    with TickerProviderStateMixin {
  late final AnimationController _rippleController;
  late final AnimationController _shakeController;

  @override
  void initState() {
    super.initState();
    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
  }

  @override
  void didUpdateWidget(FingerprintScannerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.state == SensorState.error && oldWidget.state != SensorState.error) {
      _shakeController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _rippleController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Color sensorColor;
    Color glowColor;

    switch (widget.state) {
      case SensorState.scanning:
        sensorColor = const Color(0xFF3584E4); // elementary Blue
        glowColor = const Color(0xFF3584E4).withValues(alpha: 0.32);
        break;
      case SensorState.success:
        sensorColor = const Color(0xFF2EC27E); // elementary Green
        glowColor = const Color(0xFF2EC27E).withValues(alpha: 0.45);
        break;
      case SensorState.error:
        sensorColor = const Color(0xFFE01B24); // elementary Red
        glowColor = const Color(0xFFE01B24).withValues(alpha: 0.42);
        break;
      case SensorState.idle:
        sensorColor = isDark ? const Color(0xFF7C828A) : const Color(0xFF4A5568);
        glowColor = Colors.transparent;
        break;
    }

    final isScanning = widget.state == SensorState.scanning;
    final scale = (isScanning && widget.pulseAnimation != null)
        ? widget.pulseAnimation!.value
        : 1.0;

    return AnimatedBuilder(
      animation: _shakeController,
      builder: (context, child) {
        // Cálculo del desplazamiento horizontal de sacudida ante error
        final shakeOffset = math.sin(_shakeController.value * math.pi * 5) * 8 * (1.0 - _shakeController.value);

        return Transform.translate(
          offset: Offset(shakeOffset, 0),
          child: SizedBox(
            width: widget.size + 60,
            height: widget.size + 60,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // 1. ONDAS CONCÉNTRICAS EXPANSIVAS (RIPPLE EFFECT) CUANDO ESCANEA
                if (isScanning)
                  ...List.generate(2, (index) {
                    return AnimatedBuilder(
                      animation: _rippleController,
                      builder: (context, child) {
                        final waveProgress = (_rippleController.value + (index * 0.5)) % 1.0;
                        final currentSize = widget.size + (waveProgress * 55);
                        final opacity = (1.0 - waveProgress) * 0.35;

                        return Container(
                          width: currentSize,
                          height: currentSize,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: sensorColor.withValues(alpha: opacity),
                              width: 2.2,
                            ),
                          ),
                        );
                      },
                    );
                  }),

                // 2. CONTENEDOR PRINCIPAL DEL SENSOR CON SOMBRA RESPLANDECIENTE
                MouseRegion(
                  cursor: widget.onTap != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
                  child: GestureDetector(
                    onTap: widget.onTap,
                    child: Transform.scale(
                      scale: scale,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 350),
                        curve: Curves.easeOutBack,
                        width: widget.size,
                        height: widget.size,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isDark ? const Color(0xFF262629) : Colors.white,
                          border: Border.all(
                            color: sensorColor,
                            width: widget.state == SensorState.idle ? 2.5 : 4,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: glowColor,
                              blurRadius: isScanning ? 36 : (widget.state == SensorState.success ? 40 : 18),
                              spreadRadius: isScanning ? 8 : (widget.state == SensorState.success ? 10 : 2),
                            ),
                          ],
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Anillo exterior de progreso circular si hay progreso activo
                            if (widget.progress > 0.0 || isScanning)
                              SizedBox(
                                width: widget.size - 14,
                                height: widget.size - 14,
                                child: CircularProgressIndicator(
                                  value: widget.progress > 0.0 ? widget.progress : null,
                                  strokeWidth: 4,
                                  strokeCap: StrokeCap.round,
                                  valueColor: AlwaysStoppedAnimation<Color>(sensorColor),
                                  backgroundColor: isDark ? const Color(0xFF333338) : const Color(0xFFE5E7EB),
                                ),
                              ),

                            // Huella base inactiva (fondo suave)
                            Icon(
                              Icons.fingerprint_rounded,
                              size: widget.size * 0.62,
                              color: isDark ? Colors.white12 : const Color(0xFFD6DAE0),
                            ),

                            // Huella que se rellena verticalmente de color con micro-animación
                            ClipRect(
                              clipper: VerticalFillClipper(
                                widget.state == SensorState.success
                                    ? 1.0
                                    : (widget.progress > 0.0 ? widget.progress : (isScanning ? 0.38 : 0.0)),
                              ),
                              child: Icon(
                                Icons.fingerprint_rounded,
                                size: widget.size * 0.62,
                                color: sensorColor,
                              ),
                            ),

                            // Badge de éxito animado con rebote elástico
                            if (widget.state == SensorState.success)
                              Positioned(
                                bottom: 12,
                                right: 12,
                                child: TweenAnimationBuilder<double>(
                                  tween: Tween(begin: 0.0, end: 1.0),
                                  duration: const Duration(milliseconds: 400),
                                  curve: Curves.elasticOut,
                                  builder: (context, val, child) {
                                    return Transform.scale(
                                      scale: val,
                                      child: Container(
                                        padding: const EdgeInsets.all(5),
                                        decoration: const BoxDecoration(
                                          color: Color(0xFF2EC27E),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.check,
                                          color: Colors.white,
                                          size: 18,
                                        ),
                                      ),
                                    );
                                  },
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
    );
  }
}
