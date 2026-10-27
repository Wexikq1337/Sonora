import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Loads the runtime fragment shader once at startup. Failure is non-fatal:
/// the glass falls back to gradients + borders only (still looks like glass,
/// just without animated grain/specular).
class GlassShaders {
  GlassShaders._();

  static ui.FragmentProgram? _program;
  static bool _broken = false;

  static bool get available => _program != null && !_broken;

  static Future<void> load() async {
    try {
      _program = await ui.FragmentProgram.fromAsset('shaders/glass.frag');
    } catch (e) {
      debugPrint('Sonora: glass shader unavailable ($e)');
      _program = null;
    }
  }

  static ui.FragmentShader? newShader() {
    final ui.FragmentProgram? p = _program;
    if (p == null || _broken) return null;
    try {
      return p.fragmentShader();
    } catch (e) {
      _broken = true;
      debugPrint('Sonora: shader instantiation failed ($e)');
      return null;
    }
  }
}

/// Paints the glass shader over a rounded rect area.
class GlassShaderPainter extends CustomPainter {
  GlassShaderPainter({
    required this.shader,
    required this.time,
    required this.noise,
    required this.highlight,
    required this.pressed,
    required this.tint,
    required this.opacity,
  });

  final ui.FragmentShader shader;
  final double time;
  final double noise;
  final double highlight;
  final double pressed;
  final Color tint;
  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    try {
      shader
        ..setFloat(0, size.width)
        ..setFloat(1, size.height)
        ..setFloat(2, time)
        ..setFloat(3, noise)
        ..setFloat(4, highlight)
        ..setFloat(5, pressed)
        ..setFloat(6, 0.6)
        ..setFloat(7, tint.red / 255.0)
        ..setFloat(8, tint.green / 255.0)
        ..setFloat(9, tint.blue / 255.0)
        ..setFloat(10, opacity);
      canvas.drawRect(Offset.zero & size, Paint()..shader = shader);
    } catch (_) {
      // Swallow: a broken shader must never break the UI.
    }
  }

  @override
  bool shouldRepaint(GlassShaderPainter old) =>
      old.time != time ||
      old.noise != noise ||
      old.highlight != highlight ||
      old.pressed != pressed ||
      old.opacity != opacity;
}

/// Gradient border + inner top highlight. Cheap and works everywhere.
class GlassBorderPainter extends CustomPainter {
  GlassBorderPainter({
    required this.radius,
    required this.borderAlpha,
    required this.highlight,
  });

  final double radius;
  final double borderAlpha;
  final Color highlight;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Offset.zero & size;
    final RRect rrect = RRect.fromRectAndRadius(
        rect.deflate(0.7), Radius.circular(radius));
    final Paint stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: <Color>[
          highlight.withOpacity(borderAlpha),
          highlight.withOpacity(borderAlpha * 0.25),
          highlight.withOpacity(borderAlpha * 0.75),
        ],
        stops: const <double>[0.0, 0.45, 1.0],
      ).createShader(rect);
    canvas.drawRRect(rrect, stroke);

    // inner top highlight (fake inset light)
    final Paint inner = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5)
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.center,
        colors: <Color>[
          highlight.withOpacity(borderAlpha * 0.55),
          highlight.withOpacity(0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height * 0.55));
    canvas.drawRRect(
        RRect.fromRectAndRadius(rect.deflate(1.6), Radius.circular(radius)),
        inner);
  }

  @override
  bool shouldRepaint(GlassBorderPainter old) =>
      old.borderAlpha != borderAlpha || old.highlight != highlight;
}
