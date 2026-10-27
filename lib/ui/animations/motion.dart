import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

import '../../app_scope.dart';

/// Resolves an animation duration respecting the user's speed multiplier and
/// the "reduce motion" accessibility switch.
Duration motionDuration(BuildContext context, int baseMs) {
  final AnimationSettingsView s = AnimationSettingsView.of(context);
  if (s.reduceMotion) return Duration.zero;
  return Duration(
      milliseconds: (baseMs / s.speed).round().clamp(0, 4000).toInt());
}

/// Lightweight view over the animation settings, so widgets don't need to know
/// about [AppSettings].
class AnimationSettingsView {
  const AnimationSettingsView({
    required this.speed,
    required this.reduceMotion,
    required this.springButtons,
    required this.shimmer,
    required this.staggered,
    required this.backgroundMotion,
    required this.visualizer,
    required this.morphIcons,
    required this.parallax,
    required this.hero,
  });

  final double speed;
  final bool reduceMotion;
  final bool springButtons;
  final bool shimmer;
  final bool staggered;
  final bool backgroundMotion;
  final bool visualizer;
  final bool morphIcons;
  final bool parallax;
  final bool hero;

  static AnimationSettingsView of(BuildContext context) {
    final a = SonoraScope.of(context).s.anim;
    return AnimationSettingsView(
      speed: a.speed,
      reduceMotion: a.reduceMotion,
      springButtons: a.springButtons,
      shimmer: a.shimmer,
      staggered: a.staggered,
      backgroundMotion: a.backgroundMotion,
      visualizer: a.visualizer,
      morphIcons: a.morphIcons,
      parallax: a.parallax,
      hero: a.hero,
    );
  }
}

/// Physics-based press wrapper: scales down on tap, springs back on release.
class SpringScale extends StatefulWidget {
  const SpringScale({
    super.key,
    required this.child,
    this.pressedScale = 0.94,
    this.hoverScale = 1.02,
    this.onTap,
    this.onLongPress,
    this.enabled = true,
  });

  final Widget child;
  final double pressedScale;
  final double hoverScale;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool enabled;

  @override
  State<SpringScale> createState() => _SpringScaleState();
}

class _SpringScaleState extends State<SpringScale>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController.unbounded(vsync: this, value: 1.0);
  bool _hover = false;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _to(double target, {double velocity = 0}) {
    final AnimationSettingsView s = AnimationSettingsView.of(context);
    if (!s.springButtons || s.reduceMotion) {
      _c.value = target;
      return;
    }
    _c.animateWith(SpringSimulation(
      const SpringDescription(mass: 1, stiffness: 520, damping: 30),
      _c.value,
      target,
      velocity,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: widget.enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) {
        setState(() => _hover = true);
        _to(widget.hoverScale);
      },
      onExit: (_) {
        setState(() => _hover = false);
        _to(1.0);
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: widget.enabled ? (_) => _to(widget.pressedScale) : null,
        onTapUp: widget.enabled ? (_) => _to(_hover ? widget.hoverScale : 1.0) : null,
        onTapCancel: widget.enabled ? () => _to(1.0) : null,
        onTap: widget.enabled ? widget.onTap : null,
        onLongPress: widget.enabled ? widget.onLongPress : null,
        child: AnimatedBuilder(
          animation: _c,
          builder: (BuildContext c, Widget? child) =>
              Transform.scale(scale: _c.value, child: child),
          child: widget.child,
        ),
      ),
    );
  }
}

/// Fade + slide + scale entrance used for staggered lists and screens.
class Appear extends StatefulWidget {
  const Appear({
    super.key,
    required this.child,
    this.delayMs = 0,
    this.durationMs = 460,
    this.offsetY = 0.06,
    this.scaleFrom = 0.97,
  });

  final Widget child;
  final int delayMs;
  final int durationMs;
  final double offsetY;
  final double scaleFrom;

  @override
  State<Appear> createState() => _AppearState();
}

class _AppearState extends State<Appear> {
  bool _on = false;
  bool _scheduled = false;
  Timer? _timer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_scheduled) return;
    _scheduled = true;
    _schedule();
  }

  void _schedule() {
    final AnimationSettingsView s = AnimationSettingsView.of(context);
    if (s.reduceMotion) {
      _on = true;
      return;
    }
    _timer = Timer(
      Duration(milliseconds: (widget.delayMs / s.speed).round()),
      () {
        if (mounted) setState(() => _on = true);
      },
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Duration d = motionDuration(context, widget.durationMs);
    return AnimatedOpacity(
      opacity: _on ? 1 : 0,
      duration: d,
      curve: Curves.easeOutCubic,
      child: AnimatedSlide(
        offset: _on ? Offset.zero : Offset(0, widget.offsetY),
        duration: d,
        curve: Curves.easeOutCubic,
        child: AnimatedScale(
          scale: _on ? 1 : widget.scaleFrom,
          duration: d,
          curve: Curves.easeOutCubic,
          child: widget.child,
        ),
      ),
    );
  }
}

/// Shimmer skeleton block for loading states.
class Shimmer extends StatefulWidget {
  const Shimmer({
    super.key,
    this.width,
    this.height = 16,
    this.radius = 8,
    this.baseColor,
  });

  final double? width;
  final double height;
  final double radius;
  final Color? baseColor;

  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AnimationSettingsView s = AnimationSettingsView.of(context);
    final Color base = widget.baseColor ?? Colors.white.withOpacity(0.06);
    if (!s.shimmer || s.reduceMotion) {
      return Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: base,
          borderRadius: BorderRadius.circular(widget.radius),
        ),
      );
    }
    return AnimatedBuilder(
      animation: _c,
      builder: (BuildContext context, _) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(widget.radius),
          child: ShaderMask(
            blendMode: BlendMode.srcATop,
            shaderCallback: (Rect bounds) {
              final double t = _c.value * 2.4 - 0.7;
              return LinearGradient(
                begin: Alignment(-1 + t * 2, -0.3),
                end: Alignment(t * 2, 0.3),
                colors: <Color>[
                  base,
                  Colors.white.withOpacity(0.16),
                  base,
                ],
                stops: const <double>[0.0, 0.5, 1.0],
              ).createShader(bounds);
            },
            child: Container(
              width: widget.width,
              height: widget.height,
              color: base,
            ),
          ),
        );
      },
    );
  }
}

/// Cross-fades between two icons with a small rotation + scale.
class MorphIcon extends StatelessWidget {
  const MorphIcon({
    super.key,
    required this.icon,
    this.size = 24,
    this.color,
    this.durationMs = 220,
  });

  final IconData icon;
  final double size;
  final Color? color;
  final int durationMs;

  @override
  Widget build(BuildContext context) {
    final AnimationSettingsView s = AnimationSettingsView.of(context);
    final Duration d = s.reduceMotion || !s.morphIcons
        ? Duration.zero
        : motionDuration(context, durationMs);
    return AnimatedSwitcher(
      duration: d,
      switchInCurve: Curves.easeOutBack,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (Widget child, Animation<double> anim) {
        return ScaleTransition(
          scale: anim,
          child: RotationTransition(
            turns: Tween<double>(begin: -0.12, end: 0).animate(anim),
            child: child,
          ),
        );
      },
      child: Icon(icon, key: ValueKey<IconData>(icon), size: size, color: color),
    );
  }
}

/// Animated heart that pops when toggled.
class HeartButton extends StatelessWidget {
  const HeartButton({
    super.key,
    required this.liked,
    required this.onTap,
    this.size = 22,
  });

  final bool liked;
  final VoidCallback onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    final AnimationSettingsView s = AnimationSettingsView.of(context);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: AnimatedScale(
          scale: liked ? 1.0 : 0.92,
          duration: motionDuration(context, 260),
          curve: Curves.elasticOut,
          child: AnimatedSwitcher(
            duration: s.reduceMotion ? Duration.zero : motionDuration(context, 200),
            transitionBuilder: (Widget child, Animation<double> a) =>
                ScaleTransition(scale: a, child: child),
            child: Icon(
              liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              key: ValueKey<bool>(liked),
              size: size,
              color: liked ? const Color(0xFFFF4D6D) : Colors.white.withOpacity(0.65),
            ),
          ),
        ),
      ),
    );
  }
}

/// Rotating "album art disc" used in the mini player.
class SpinningDisc extends StatefulWidget {
  const SpinningDisc({super.key, required this.child, required this.spinning});
  final Widget child;
  final bool spinning;

  @override
  State<SpinningDisc> createState() => _SpinningDiscState();
}

class _SpinningDiscState extends State<SpinningDisc>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 18),
  );

  @override
  void initState() {
    super.initState();
    if (widget.spinning) _c.repeat();
  }

  @override
  void didUpdateWidget(covariant SpinningDisc old) {
    super.didUpdateWidget(old);
    if (widget.spinning && !_c.isAnimating) _c.repeat();
    if (!widget.spinning && _c.isAnimating) _c.stop();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _c,
      child: widget.child,
    );
  }
}
