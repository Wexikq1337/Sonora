import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app_scope.dart';

/// Pseudo-spectrum visualiser. It is driven by the transport clock and the
/// track BPM (a real PCM tap needs a native plugin, see README "что заглушка"),
/// but it reacts to play/pause and looks alive.
class Visualizer extends StatefulWidget {
  const Visualizer({
    super.key,
    required this.playing,
    required this.seed,
    this.bars = 32,
    this.height = 72,
    this.bpm = 90,
  });

  final bool playing;
  final int seed;
  final int bars;
  final double height;
  final int bpm;

  @override
  State<Visualizer> createState() => _VisualizerState();
}

class _VisualizerState extends State<Visualizer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 8),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final SonoraScope scope = SonoraScope.of(context);
    final bool enabled =
        scope.s.anim.visualizer && !scope.s.anim.reduceMotion;
    if (!enabled) {
      return SizedBox(height: widget.height);
    }
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _c,
        builder: (BuildContext context, _) {
          return CustomPaint(
            size: Size(double.infinity, widget.height),
            painter: _SpectrumPainter(
              t: _c.value * 8.0,
              playing: widget.playing,
              bars: widget.bars,
              seed: widget.seed,
              bpm: widget.bpm,
              colorA: scope.palette.accent,
              colorB: scope.palette.accent2,
            ),
          );
        },
      ),
    );
  }
}

class _SpectrumPainter extends CustomPainter {
  _SpectrumPainter({
    required this.t,
    required this.playing,
    required this.bars,
    required this.seed,
    required this.bpm,
    required this.colorA,
    required this.colorB,
  });

  final double t;
  final bool playing;
  final int bars;
  final int seed;
  final int bpm;
  final Color colorA;
  final Color colorB;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0) return;
    final double gap = 3.0;
    final double barW = math.max(2.0, (size.width - gap * (bars - 1)) / bars);
    final double phase = t * (bpm / 90.0);
    final double amp = playing ? 1.0 : 0.0;

    for (int i = 0; i < bars; i++) {
      final double n = i / bars;
      // pretend low frequencies on the left are louder
      final double band = math.pow(1.0 - n, 0.6).toDouble();
      final double w1 = math.sin(phase * 2.1 + i * 0.55 + seed) * 0.5 + 0.5;
      final double w2 = math.sin(phase * 0.7 + i * 1.7) * 0.5 + 0.5;
      final double idle = 0.08 + 0.03 * math.sin(t * 0.6 + i * 0.3);
      final double h = (idle + amp * band * (0.25 + 0.75 * w1 * w2))
          .clamp(0.03, 1.0)
          .toDouble();
      final double barH = size.height * h;
      final double x = i * (barW + gap);
      final Rect rect =
          Rect.fromLTWH(x, size.height - barH, barW, barH);
      final RRect rr =
          RRect.fromRectAndRadius(rect, Radius.circular(barW / 2));
      final Paint p = Paint()
        ..shader = LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: <Color>[
            colorA.withOpacity(0.95),
            colorB.withOpacity(0.75),
            colorB.withOpacity(0.15),
          ],
          stops: const <double>[0.0, 0.65, 1.0],
        ).createShader(Rect.fromLTWH(x, 0, barW, size.height));
      canvas.drawRRect(rr, p);
    }
  }

  @override
  bool shouldRepaint(_SpectrumPainter old) =>
      old.t != t || old.playing != playing || old.bpm != bpm;
}
