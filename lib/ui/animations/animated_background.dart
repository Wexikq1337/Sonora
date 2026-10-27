import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app_scope.dart';
import '../../core/palette.dart';

/// Living gradient background: three slowly orbiting light blobs plus a
/// vignette. Everything under the glass layers is blurred from this painting.
class AnimatedBackground extends StatefulWidget {
  const AnimatedBackground({super.key, this.albumTint});

  /// When a track is playing the background is tinted by its artwork colours.
  final Color? albumTint;

  @override
  State<AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(seconds: 32));

  bool _running = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final bool motion = SonoraScope.of(context).s.anim.backgroundMotion &&
        !SonoraScope.of(context).s.anim.reduceMotion;
    if (motion && !_c.isAnimating) {
      _c.repeat();
      _running = true;
    } else if (!motion && _c.isAnimating) {
      _c.stop();
      _running = false;
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final SonoraScope scope = SonoraScope.of(context);
    final AppPalette pal = scope.palette;
    final double intensity = scope.s.appearance.backgroundIntensity;
    final double noise = scope.s.appearance.noiseOverlay;

    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _c,
        builder: (BuildContext context, _) {
          return CustomPaint(
            painter: _BackgroundPainter(
              palette: pal,
              t: _running ? _c.value * math.pi * 2 : 0.0,
              intensity: intensity,
              albumTint: widget.albumTint,
              noise: noise,
            ),
            size: Size.infinite,
          );
        },
      ),
    );
  }
}

class _BackgroundPainter extends CustomPainter {
  _BackgroundPainter({
    required this.palette,
    required this.t,
    required this.intensity,
    required this.noise,
    this.albumTint,
  });

  final AppPalette palette;
  final double t;
  final double intensity;
  final double noise;
  final Color? albumTint;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Offset.zero & size;

    // base
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[palette.bg0, palette.bg1, palette.bg0],
          stops: const <double>[0.0, 0.55, 1.0],
        ).createShader(rect),
    );

    // orb A
    _orb(
      canvas,
      rect,
      center: Offset(
        size.width * (0.24 + 0.10 * math.sin(t)),
        size.height * (0.18 + 0.08 * math.cos(t * 0.8)),
      ),
      radius: size.shortestSide * (0.62 + 0.05 * math.sin(t * 1.3)),
      color: albumTint ?? palette.glowA,
      alpha: 0.34 * intensity,
    );

    // orb B
    _orb(
      canvas,
      rect,
      center: Offset(
        size.width * (0.82 + 0.07 * math.cos(t * 0.7 + 1.2)),
        size.height * (0.72 + 0.09 * math.sin(t * 0.9 + 0.6)),
      ),
      radius: size.shortestSide * (0.55 + 0.06 * math.cos(t * 1.1)),
      color: palette.glowB,
      alpha: 0.30 * intensity,
    );

    // orb C (small accent)
    _orb(
      canvas,
      rect,
      center: Offset(
        size.width * (0.55 + 0.16 * math.sin(t * 0.5 + 2.0)),
        size.height * (0.42 + 0.14 * math.cos(t * 0.6 + 1.0)),
      ),
      radius: size.shortestSide * (0.34 + 0.04 * math.sin(t * 1.7)),
      color: palette.accent,
      alpha: 0.16 * intensity,
    );

    // album tint wash
    final Color? tint = albumTint;
    if (tint != null) {
      canvas.drawRect(
        rect,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: <Color>[
              tint.withOpacity(0.16 * intensity),
              Colors.transparent,
            ],
          ).createShader(rect),
      );
    }

    // vignette
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          center: Alignment.center,
          radius: 0.95,
          colors: <Color>[
            Colors.transparent,
            palette.bg0.withOpacity(0.55 * noise + 0.25),
          ],
          stops: const <double>[0.45, 1.0],
        ).createShader(rect),
    );
  }

  void _orb(
    Canvas canvas,
    Rect rect, {
    required Offset center,
    required double radius,
    required Color color,
    required double alpha,
  }) {
    if (radius <= 0) return;
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = RadialGradient(
          colors: <Color>[
            color.withOpacity(alpha),
            color.withOpacity(alpha * 0.35),
            color.withOpacity(0.0),
          ],
          stops: const <double>[0.0, 0.55, 1.0],
        ).createShader(Rect.fromCircle(center: center, radius: radius)),
    );
  }

  @override
  bool shouldRepaint(_BackgroundPainter old) =>
      old.t != t ||
      old.palette != palette ||
      old.albumTint != albumTint ||
      old.intensity != intensity;
}
