import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

import '../../app_scope.dart';
import '../../core/palette.dart';
import '../../state/performance_monitor.dart';
import '../animations/motion.dart';
import 'glass_shaders.dart';

/// Extra blur applied by deeper navigation levels ("чем глубже — тем сильнее").
class BlurDepth extends InheritedWidget {
  const BlurDepth({super.key, required this.value, required super.child});

  final double value;

  static double of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<BlurDepth>()?.value ?? 0.0;

  @override
  bool updateShouldNotify(BlurDepth oldWidget) => oldWidget.value != value;
}

Color parseHexColor(String input, {Color fallback = Colors.white}) {
  String hex = input.trim().replaceAll('#', '');
  if (hex.length == 3) {
    hex = hex.split('').map((String c) => '$c$c').join();
  }
  if (hex.length == 6) hex = 'FF$hex';
  final int? v = int.tryParse(hex, radix: 16);
  return v == null ? fallback : Color(v);
}

/// Resolved glass parameters (settings + adaptive quality).
class GlassParams {
  const GlassParams({
    required this.enabled,
    required this.blur,
    required this.opacity,
    required this.refraction,
    required this.borderAlpha,
    required this.shadow,
    required this.noise,
    required this.highlight,
  });

  final bool enabled;
  final double blur;
  final double opacity;
  final double refraction;
  final double borderAlpha;
  final double shadow;
  final bool noise;
  final Color highlight;

  factory GlassParams.of(
    BuildContext context, {
    double blurScale = 1.0,
    double depth = 0.0,
    double opacityScale = 1.0,
  }) {
    final SonoraScope s = SonoraScope.of(context);
    final g = s.s.glass;
    final bool low =
        PerformanceMonitor.instance.lowQuality || s.s.anim.reduceMotion;
    double blur = g.blur * blurScale * (1.0 + depth * 0.4);
    if (low) blur = math.min(blur, 7.0);
    if (s.s.quality == 'low') blur = math.min(blur, 4.0);
    return GlassParams(
      enabled: g.enabled,
      blur: blur,
      opacity: (g.opacity * opacityScale).clamp(0.0, 0.85).toDouble(),
      refraction: low ? 0.0 : g.refraction,
      borderAlpha: g.borderAlpha,
      shadow: low ? g.shadow * 0.65 : g.shadow,
      noise: g.noise && !low,
      highlight: parseHexColor(g.highlightHex),
    );
  }
}

/// Convenience alias so callers don't need the extra import name.
typedef AppScope = SonoraScope;

class LiquidGlass extends StatefulWidget {
  const LiquidGlass({
    super.key,
    required this.child,
    this.radius = 24,
    this.padding = EdgeInsets.zero,
    this.tint,
    this.blurScale = 1.0,
    this.opacityScale = 1.0,
    this.showBorder = true,
    this.showShadow = true,
    this.showShader = true,
    this.specular = 1.0,
    this.pressed = 0.0,
    this.blurDepth = true,
  });

  final Widget child;
  final double radius;
  final EdgeInsetsGeometry padding;
  final Color? tint;
  final double blurScale;
  final double opacityScale;
  final bool showBorder;
  final bool showShadow;
  final bool showShader;
  final double specular;
  final double pressed;
  final bool blurDepth;

  @override
  State<LiquidGlass> createState() => _LiquidGlassState();
}

class _LiquidGlassState extends State<LiquidGlass> {
  ui.FragmentShader? _shader;

  @override
  void initState() {
    super.initState();
    _shader = GlassShaders.newShader();
  }

  @override
  void dispose() {
    _shader?.dispose();
    _shader = null;
    super.dispose();
  }

  static ui.ImageFilter _buildFilter(
      double sigma, double refraction, Size size) {
    final ui.ImageFilter blur =
        ui.ImageFilter.blur(sigmaX: sigma, sigmaY: sigma);
    if (refraction <= 0.02 || size.width <= 2 || size.height <= 2) return blur;
    // Approximate a lens: scale the backdrop around the widget centre.
    try {
      final double zoom = 1.0 + 0.055 * refraction;
      final Matrix4 m = Matrix4.identity()
        ..setEntry(0, 0, zoom)
        ..setEntry(1, 1, zoom)
        ..setEntry(0, 3, size.width / 2 * (1 - zoom))
        ..setEntry(1, 3, size.height / 2 * (1 - zoom));
      return ui.ImageFilter.compose(
        outer: blur,
        inner: ui.ImageFilter.matrix(m.storage),
      );
    } catch (_) {
      // Some backends reject matrix filters inside a backdrop filter.
      return blur;
    }
  }

  @override
  Widget build(BuildContext context) {
    final double radius = widget.radius;
    final SonoraScope scope = SonoraScope.of(context);
    final double depth = widget.blurDepth ? BlurDepth.of(context) : 0.0;
    final GlassParams p = GlassParams.of(
      context,
      blurScale: widget.blurScale,
      depth: depth,
      opacityScale: widget.opacityScale,
    );
    final AppPalette pal = scope.palette;
    final Color tintColor = widget.tint ?? pal.accent2;
    final BorderRadius br = BorderRadius.circular(radius);

    final Widget filled = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: br,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Colors.white.withOpacity(p.opacity * 0.58),
            Colors.white.withOpacity(p.opacity * 0.12),
            tintColor.withOpacity(p.opacity * 0.24),
          ],
          stops: const <double>[0.0, 0.55, 1.0],
        ),
      ),
      child: Padding(padding: widget.padding, child: widget.child),
    );

    return LayoutBuilder(
      builder: (BuildContext ctx, BoxConstraints constraints) {
        final Size size = Size(
          constraints.maxWidth.isFinite ? constraints.maxWidth : 0,
          constraints.maxHeight.isFinite ? constraints.maxHeight : 0,
        );

        Widget surface;
        if (p.enabled && p.blur > 0.05) {
          surface = ClipRRect(
            borderRadius: br,
            child: BackdropFilter(
              filter: _buildFilter(p.blur, p.refraction, size),
              child: filled,
            ),
          );
        } else {
          surface = ClipRRect(borderRadius: br, child: filled);
        }

        final ui.FragmentShader? shader = _shader;

        return Stack(
          clipBehavior: Clip.none,
          children: <Widget>[
            if (widget.showShadow && p.shadow > 0.02)
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: _GlassShadowPainter(
                      radius: radius,
                      elevation: 2 + 14 * p.shadow,
                      opacity: p.shadow,
                      glow: tintColor,
                    ),
                  ),
                ),
              ),
            surface,
            if (widget.showShader && p.enabled && shader != null)
              Positioned.fill(
                child: IgnorePointer(
                  child: ClipRRect(
                    borderRadius: br,
                    child: CustomPaint(
                      painter: GlassShaderPainter(
                        shader: shader,
                        time: radius * 0.05 + size.width * 0.001,
                        noise: p.noise ? 1.0 : 0.0,
                        highlight: widget.specular,
                        pressed: widget.pressed,
                        tint: p.highlight,
                        opacity: math.min(1.0, 0.20 + p.opacity * 0.9),
                      ),
                    ),
                  ),
                ),
              ),
            if (widget.showBorder && p.borderAlpha > 0.01)
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: GlassBorderPainter(
                      radius: radius,
                      borderAlpha: p.borderAlpha,
                      highlight: p.highlight,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _GlassShadowPainter extends CustomPainter {
  const _GlassShadowPainter({
    required this.radius,
    required this.elevation,
    required this.opacity,
    required this.glow,
  });

  final double radius;
  final double elevation;
  final double opacity;
  final Color glow;

  @override
  void paint(Canvas canvas, Size size) {
    final RRect rrect =
        RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius));
    final Path path = Path()..addRRect(rrect);
    canvas.drawShadow(path, Colors.black.withOpacity(0.6 * opacity), elevation, false);

    final Paint glowPaint = Paint()
      ..color = glow.withOpacity(0.10 * opacity)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 22);
    canvas.drawRRect(rrect, glowPaint);
  }

  @override
  bool shouldRepaint(_GlassShadowPainter old) =>
      old.elevation != elevation ||
      old.opacity != opacity ||
      old.glow != glow ||
      old.radius != radius;
}

/// Glass button with spring physics, hover glow, long-press magnification and
/// a ripple bloom. This is the base for every interactive control in the app.
class GlassButton extends StatefulWidget {
  const GlassButton({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.radius = 18,
    this.padding = const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    this.tint,
    this.selected = false,
    this.enabled = true,
    this.tooltip,
    this.minSize = 0,
    this.bloom = true,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double radius;
  final EdgeInsetsGeometry padding;
  final Color? tint;
  final bool selected;
  final bool enabled;
  final String? tooltip;
  final double minSize;
  final bool bloom;

  @override
  State<GlassButton> createState() => _GlassButtonState();
}

class _GlassButtonState extends State<GlassButton>
    with TickerProviderStateMixin {
  late final AnimationController _scale =
      AnimationController.unbounded(vsync: this, value: 1.0);
  late final AnimationController _ripple = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 520));
  bool _hover = false;
  bool _pressed = false;

  @override
  void dispose() {
    _scale.dispose();
    _ripple.dispose();
    super.dispose();
  }

  void _to(double target, {double velocity = 0}) {
    final AnimationSettingsView s = AnimationSettingsView.of(context);
    if (!s.springButtons || s.reduceMotion) {
      _scale.value = target;
      return;
    }
    final SpringDescription desc;
    switch (SonoraScope.of(context).s.glass.pressAnim) {
      case 'smooth':
        desc = const SpringDescription(mass: 1, stiffness: 260, damping: 34);
        break;
      case 'bounce':
        desc = const SpringDescription(mass: 1, stiffness: 620, damping: 15);
        break;
      case 'none':
        _scale.value = target;
        return;
      case 'spring':
      default:
        desc = const SpringDescription(mass: 1, stiffness: 520, damping: 26);
    }
    _scale.animateWith(
        SpringSimulation(desc, _scale.value, target, velocity));
  }

  void _down(TapDownDetails _) {
    if (!widget.enabled) return;
    setState(() => _pressed = true);
    _to(0.94);
    if (widget.bloom) {
      _ripple.forward(from: 0);
    }
  }

  void _up() {
    if (!widget.enabled) return;
    setState(() => _pressed = false);
    _to(_hover ? 1.03 : 1.0, velocity: 1.5);
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette pal = SonoraScope.of(context).palette;
    final bool active = widget.selected;
    final Widget content = AnimatedContainer(
      duration: motionDuration(context, 160),
      constraints: widget.minSize > 0
          ? BoxConstraints(minWidth: widget.minSize, minHeight: widget.minSize)
          : const BoxConstraints(),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(widget.radius),
        boxShadow: _hover && widget.enabled
            ? <BoxShadow>[
                BoxShadow(
                  color: (widget.tint ?? pal.accent).withOpacity(0.30),
                  blurRadius: 26,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: LiquidGlass(
        radius: widget.radius,
        padding: widget.padding,
        tint: active ? (widget.tint ?? pal.accent) : widget.tint,
        opacityScale: active ? 1.75 : (_hover ? 1.25 : 1.0),
        specular: _hover ? 1.5 : 1.0,
        pressed: _pressed ? 1.0 : 0.0,
        child: Stack(
          alignment: Alignment.center,
          children: <Widget>[
            widget.child,
            if (widget.bloom && _ripple.isAnimating)
              Positioned.fill(
                child: IgnorePointer(
                  child: AnimatedBuilder(
                    animation: _ripple,
                    builder: (BuildContext c, _) => CustomPaint(
                      painter: _RipplePainter(
                        progress: _ripple.value,
                        color: widget.tint ?? pal.accent,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );

    Widget result = MouseRegion(
      cursor: widget.enabled
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      onEnter: widget.enabled
          ? (_) {
              setState(() => _hover = true);
              _to(1.03);
            }
          : null,
      onExit: widget.enabled
          ? (_) {
              setState(() => _hover = false);
              _to(1.0);
            }
          : null,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: _down,
        onTapUp: widget.enabled ? (_) => _up() : null,
        onTapCancel: widget.enabled ? _up : null,
        onTap: widget.enabled ? widget.onTap : null,
        onLongPress: widget.enabled && widget.onLongPress != null
            ? () {
                _to(1.06);
                widget.onLongPress!();
                Future<void>.delayed(const Duration(milliseconds: 140), () {
                  if (mounted) _to(1.0);
                });
              }
            : null,
        child: AnimatedBuilder(
          animation: _scale,
          builder: (BuildContext c, Widget? child) =>
              Transform.scale(scale: _scale.value, child: child),
          child: content,
        ),
      ),
    );

    if (widget.tooltip != null && widget.tooltip!.isNotEmpty) {
      result = Tooltip(
        message: widget.tooltip!,
        waitDuration: const Duration(milliseconds: 450),
        child: result,
      );
    }
    return Opacity(opacity: widget.enabled ? 1.0 : 0.45, child: result);
  }
}

class _RipplePainter extends CustomPainter {
  _RipplePainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final double t =
        Curves.easeOutCubic.transform(progress.clamp(0.0, 1.0).toDouble());
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double maxR = math.max(size.width, size.height) * 0.85;
    final double r = maxR * t;
    if (r <= 0) return;
    final Paint paint = Paint()
      ..shader = RadialGradient(
        colors: <Color>[
          color.withOpacity(0.28 * (1 - t)),
          color.withOpacity(0.0),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: r));
    canvas.drawCircle(center, r, paint);
  }

  @override
  bool shouldRepaint(_RipplePainter old) => old.progress != progress;
}

/// Circular glass icon button.
class GlassIconButton extends StatelessWidget {
  const GlassIconButton({
    super.key,
    required this.icon,
    this.onTap,
    this.size = 48,
    this.iconSize = 22,
    this.selected = false,
    this.tint,
    this.tooltip,
    this.onLongPress,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final double size;
  final double iconSize;
  final bool selected;
  final Color? tint;
  final String? tooltip;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final AppPalette pal = SonoraScope.of(context).palette;
    return GlassButton(
      onTap: onTap,
      onLongPress: onLongPress,
      radius: size / 2,
      padding: EdgeInsets.zero,
      selected: selected,
      tint: tint,
      tooltip: tooltip,
      minSize: size,
      child: SizedBox(
        width: size,
        height: size,
        child: Icon(
          icon,
          size: iconSize,
          color: selected ? pal.text : pal.text.withOpacity(0.88),
        ),
      ),
    );
  }
}

class GlassChip extends StatelessWidget {
  const GlassChip({
    super.key,
    required this.label,
    this.selected = false,
    this.onTap,
    this.icon,
    this.dense = false,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final IconData? icon;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final AppPalette pal = SonoraScope.of(context).palette;
    final Color fg = selected ? pal.text : pal.text.withOpacity(0.72);
    return GlassButton(
      onTap: onTap,
      radius: 999,
      selected: selected,
      padding: EdgeInsets.symmetric(
          horizontal: dense ? 10 : 14, vertical: dense ? 6 : 9),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (icon != null) ...<Widget>[
            Icon(icon, size: 14, color: selected ? pal.accent : fg),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: TextStyle(
              color: fg,
              fontSize: dense ? 12 : 13,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Smooth glass toggle.
class GlassSwitch extends StatelessWidget {
  const GlassSwitch({
    super.key,
    required this.value,
    this.onChanged,
    this.activeColor,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;
  final Color? activeColor;

  @override
  Widget build(BuildContext context) {
    final AppPalette pal = SonoraScope.of(context).palette;
    final Color accent = activeColor ?? pal.accent;
    final Duration d = motionDuration(context, 260);
    return MouseRegion(
      cursor: onChanged == null
          ? SystemMouseCursors.basic
          : SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onChanged == null ? null : () => onChanged!(!value),
        child: AnimatedContainer(
          duration: d,
          curve: Curves.easeOutCubic,
          width: 48,
          height: 28,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: value
                ? accent.withOpacity(0.55)
                : Colors.white.withOpacity(0.07),
            border: Border.all(
              color: value
                  ? accent.withOpacity(0.85)
                  : Colors.white.withOpacity(0.18),
              width: 1.1,
            ),
            boxShadow: value
                ? <BoxShadow>[
                    BoxShadow(
                        color: accent.withOpacity(0.45),
                        blurRadius: 16,
                        spreadRadius: 1),
                  ]
                : null,
          ),
          child: AnimatedAlign(
            duration: d,
            curve: Curves.easeOutBack,
            alignment: value ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              width: 21,
              height: 21,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: value ? Colors.white : Colors.white.withOpacity(0.75),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                      color: Colors.black.withOpacity(0.35),
                      blurRadius: 6,
                      offset: const Offset(0, 2)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Glass progress bar with a glowing playhead.
class GlassProgressBar extends StatelessWidget {
  const GlassProgressBar({
    super.key,
    required this.value,
    this.height = 6,
    this.onSeek,
    this.buffered,
    this.color,
    this.dragging = false,
  });

  final double value;
  final double height;
  final ValueChanged<double>? onSeek;
  final double? buffered;
  final Color? color;
  final bool dragging;

  @override
  Widget build(BuildContext context) {
    final AppPalette pal = SonoraScope.of(context).palette;
    final Color accent = color ?? pal.accent;
    final Duration d = motionDuration(context, 180);
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints c) {
        final double w = c.maxWidth.isFinite ? c.maxWidth : 0;
        void seekTo(double dx) {
          if (onSeek == null || w <= 0) return;
          onSeek!((dx / w).clamp(0.0, 1.0).toDouble());
        }

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (TapDownDetails e) => seekTo(e.localPosition.dx),
          onHorizontalDragUpdate: (DragUpdateDetails e) =>
              seekTo(e.localPosition.dx),
          child: SizedBox(
            height: 22,
            child: Stack(
              alignment: Alignment.centerLeft,
              children: <Widget>[
                Container(
                  height: height,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(height),
                  ),
                ),
                if (buffered != null)
                  FractionallySizedBox(
                    widthFactor: buffered!.clamp(0.0, 1.0).toDouble(),
                    child: Container(
                      height: height,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.14),
                        borderRadius: BorderRadius.circular(height),
                      ),
                    ),
                  ),
                FractionallySizedBox(
                  widthFactor: value.clamp(0.0, 1.0).toDouble(),
                  child: AnimatedContainer(
                    duration: d,
                    height: height,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(height),
                      gradient: LinearGradient(
                        colors: <Color>[accent, pal.accent2],
                      ),
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                            color: accent.withOpacity(0.55),
                            blurRadius: 12,
                            spreadRadius: 1),
                      ],
                    ),
                  ),
                ),
                if (w > 0)
                  Positioned(
                    left: (value.clamp(0.0, 1.0).toDouble() * w -
                                (dragging ? 9 : 6))
                            .clamp(0.0, math.max(0.0, w - 18))
                            .toDouble(),
                    child: AnimatedContainer(
                      duration: d,
                      width: dragging ? 18 : 12,
                      height: dragging ? 18 : 12,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        boxShadow: <BoxShadow>[
                          BoxShadow(
                              color: accent.withOpacity(0.9),
                              blurRadius: 14,
                              spreadRadius: 2),
                        ],
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
