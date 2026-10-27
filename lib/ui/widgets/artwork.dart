import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../models/track.dart';

/// Procedurally generated cover art — no bitmap assets, unique per track.
class Artwork extends StatelessWidget {
  const Artwork({
    super.key,
    required this.track,
    this.width,
    this.height,
    this.radius = 16,
    this.badge = false,
    this.glow = true,
  });

  final Track track;
  final double? width;
  final double? height;
  final double radius;
  final bool badge;
  final bool glow;

  @override
  Widget build(BuildContext context) {
    final BorderRadius br = BorderRadius.circular(radius);
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: br,
        boxShadow: glow
            ? <BoxShadow>[
                BoxShadow(
                  color: track.colorA.withOpacity(0.35),
                  blurRadius: 26,
                  spreadRadius: -6,
                  offset: const Offset(0, 10),
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: br,
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints c) {
            final double w = c.maxWidth.isFinite ? c.maxWidth : 120;
            final double h = c.maxHeight.isFinite ? c.maxHeight : w;
            return Stack(
              fit: StackFit.expand,
              children: <Widget>[
                if (track.artUrl != null && track.artUrl!.isNotEmpty)
                  Image.network(
                    track.artUrl!,
                    fit: BoxFit.cover,
                    gaplessPlayback: true,
                    errorBuilder:
                        (BuildContext ctx, Object err, StackTrace? st) =>
                            _procedural(w, h),
                  )
                else
                  _procedural(w, h),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: <Color>[
                          Colors.white.withOpacity(0.16),
                          Colors.transparent,
                          Colors.black.withOpacity(0.22),
                        ],
                        stops: const <double>[0.0, 0.5, 1.0],
                      ),
                    ),
                  ),
                ),
                if (badge)
                  Positioned(
                    right: 6,
                    bottom: 6,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black.withOpacity(0.35),
                        border: Border.all(
                            color: Colors.white.withOpacity(0.25), width: 0.8),
                      ),
                      child: Icon(track.source.icon, size: 12, color: Colors.white),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// Gradient + blobs + generated pattern — used when there is no remote
  /// cover, and as the fallback when a network image fails to load.
  Widget _procedural(double w, double h) => Stack(
        fit: StackFit.expand,
        children: <Widget>[
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: <Color>[
                  track.colorA,
                  Color.lerp(track.colorA, track.colorB, 0.55)!,
                  track.colorB,
                ],
              ),
            ),
          ),
          Positioned(
            left: -w * 0.30,
            top: -h * 0.35,
            child: _blob(w * 0.95, Colors.white.withOpacity(0.34)),
          ),
          Positioned(
            right: -w * 0.28,
            bottom: -h * 0.32,
            child: _blob(w * 0.85, Colors.white.withOpacity(0.12)),
          ),
          Positioned.fill(
            child: CustomPaint(
              painter: _ArtPainter(seed: track.id.hashCode, w: w, h: h),
            ),
          ),
        ],
      );

  Widget _blob(double size, Color color) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: <Color>[color, color.withOpacity(0.0)],
          ),
        ),
      );
}

class _ArtPainter extends CustomPainter {
  const _ArtPainter({required this.seed, required this.w, required this.h});

  final int seed;
  final double w;
  final double h;

  @override
  void paint(Canvas canvas, Size size) {
    final math.Random rnd = math.Random(seed);
    final Paint stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(0.8, size.shortestSide * 0.008)
      ..color = Colors.white.withOpacity(0.14);

    final int lines = 3 + rnd.nextInt(3);
    for (int i = 0; i < lines; i++) {
      final double y = size.height * (0.18 + 0.2 * i) + rnd.nextDouble() * 6;
      final Path p = Path()
        ..moveTo(-size.width * 0.1, y)
        ..quadraticBezierTo(
          size.width * (0.35 + rnd.nextDouble() * 0.3),
          y - size.height * (0.12 + rnd.nextDouble() * 0.2),
          size.width * 1.1,
          y + size.height * (rnd.nextDouble() * 0.1 - 0.05),
        );
      canvas.drawPath(p, stroke);
    }

    // centre "lens"
    final Offset centre = Offset(size.width * 0.5, size.height * 0.48);
    final double r = size.shortestSide * (0.16 + rnd.nextDouble() * 0.08);
    canvas.drawCircle(
      centre,
      r,
      Paint()
        ..shader = RadialGradient(
          colors: <Color>[
            Colors.white.withOpacity(0.24),
            Colors.white.withOpacity(0.0),
          ],
        ).createShader(Rect.fromCircle(center: centre, radius: r)),
    );
    canvas.drawCircle(
      centre,
      r * 0.55,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.1
        ..color = Colors.white.withOpacity(0.22),
    );
  }

  @override
  bool shouldRepaint(_ArtPainter old) => old.seed != seed;
}
