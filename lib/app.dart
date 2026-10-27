import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_scope.dart';
import 'core/palette.dart';
import 'core/theme.dart';
import 'models/settings.dart';
import 'services/discord/discord_presence_service.dart';
import 'state/performance_monitor.dart';
import 'state/player_controller.dart';
import 'state/settings_controller.dart';
import 'ui/animations/animated_background.dart';
import 'ui/screens/shell.dart';

class SonoraApp extends StatefulWidget {
  const SonoraApp({super.key});

  @override
  State<SonoraApp> createState() => _SonoraAppState();
}

class _SonoraAppState extends State<SonoraApp> {
  late final SettingsController _settings;
  late final PlayerController _player;
  late final DiscordPresenceService _discord;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _settings = SettingsController();
    _player = PlayerController(_settings);
    _discord = DiscordPresenceService(_settings);
    _boot();
  }

  Future<void> _boot() async {
    try {
      PerformanceMonitor.instance.start();
      await _settings.load();
      await _player.init();
      await _player.setVolume(_settings.value.volume);

      _player.addListener(_syncDiscord);
      _player.position.addListener(_syncDiscord);
      _syncDiscord();

      if (_settings.value.discord.enabled) {
        // Best effort: silently fails when Discord is not running.
        _discord.connect();
      }
    } catch (e) {
      debugPrint('Sonora boot error: $e');
    } finally {
      if (mounted) setState(() => _ready = true);
    }
  }

  void _syncDiscord() {
    _discord.updateNowPlaying(
      _player.current,
      _player.position.value,
      _player.playing,
    );
  }

  @override
  void dispose() {
    _player.removeListener(_syncDiscord);
    _player.position.removeListener(_syncDiscord);
    _discord.dispose();
    _player.dispose();
    _settings.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _settings,
      builder: (BuildContext context, _) {
        final AppPalette palette =
            AppPalette.byId(_settings.value.appearance.themeId);

        if (!_ready) {
          return MaterialApp(
            title: 'Sonora',
            debugShowCheckedModeBanner: false,
            theme: buildSonoraTheme(palette),
            home: _Splash(palette: palette),
          );
        }

        return SonoraScope(
          settings: _settings,
          player: _player,
          discord: _discord,
          child: MaterialApp(
            title: 'Sonora',
            debugShowCheckedModeBanner: false,
            theme: buildSonoraTheme(palette),
            builder: (BuildContext context, Widget? child) => _Frame(
              palette: palette,
              player: _player,
              child: child ?? const SizedBox.shrink(),
            ),
            home: const SonoraShell(),
          ),
        );
      },
    );
  }
}

/// Root visual frame: living background, optional glow cursor and global
/// keyboard shortcuts.
class _Frame extends StatelessWidget {
  const _Frame({
    required this.palette,
    required this.player,
    required this.child,
  });

  final AppPalette palette;
  final PlayerController player;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final AppSettings s = SonoraScope.of(context).s;
    final bool glow = s.appearance.glowCursor && !PerformanceMonitor.instance.lowQuality;

    Widget content = Stack(
      fit: StackFit.expand,
      children: <Widget>[
        Positioned.fill(
          child: _BackgroundLayer(palette: palette, player: player),
        ),
        Positioned.fill(child: KeyedSubtree(key: const ValueKey<String>('app-body'), child: child)),
      ],
    );

    if (glow) {
      content = _GlowCursorLayer(color: palette.accent, child: content);
    }

    return _ShortcutHost(child: content);
  }
}

class _BackgroundLayer extends StatefulWidget {
  const _BackgroundLayer({required this.palette, required this.player});
  final AppPalette palette;
  final PlayerController player;

  @override
  State<_BackgroundLayer> createState() => _BackgroundLayerState();
}

class _BackgroundLayerState extends State<_BackgroundLayer> {
  Color? _tint;

  @override
  void initState() {
    super.initState();
    _tint = widget.player.current?.colorA;
    widget.player.addListener(_onPlayer);
  }

  void _onPlayer() {
    final Color? next = widget.player.current?.colorA;
    if (next != _tint) setState(() => _tint = next);
  }

  @override
  void dispose() {
    widget.player.removeListener(_onPlayer);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBackground(albumTint: _tint);
  }
}

/// Soft accent halo that follows the mouse pointer (desktop touch).
class _GlowCursorLayer extends StatefulWidget {
  const _GlowCursorLayer({required this.color, required this.child});
  final Color color;
  final Widget child;

  @override
  State<_GlowCursorLayer> createState() => _GlowCursorLayerState();
}

class _GlowCursorLayerState extends State<_GlowCursorLayer> {
  final ValueNotifier<Offset?> _pos = ValueNotifier<Offset?>(null);

  @override
  void dispose() {
    _pos.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onHover: (PointerHoverEvent e) => _pos.value = e.localPosition,
      onExit: (_) => _pos.value = null,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          widget.child,
          IgnorePointer(
            child: ValueListenableBuilder<Offset?>(
              valueListenable: _pos,
              builder: (BuildContext context, Offset? p, _) {
                if (p == null) return const SizedBox.shrink();
                return CustomPaint(
                  painter: _GlowPainter(position: p, color: widget.color),
                  size: Size.infinite,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _GlowPainter extends CustomPainter {
  _GlowPainter({required this.position, required this.color});
  final Offset position;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const double r = 120;
    canvas.drawCircle(
      position,
      r,
      Paint()
        ..shader = RadialGradient(
          colors: <Color>[
            color.withOpacity(0.10),
            color.withOpacity(0.0),
          ],
        ).createShader(Rect.fromCircle(center: position, radius: r)),
    );
  }

  @override
  bool shouldRepaint(_GlowPainter old) =>
      old.position != position || old.color != color;
}

/// In-app keyboard shortcuts (desktop). Documented in Settings → Hotkeys.
class _ShortcutHost extends StatelessWidget {
  const _ShortcutHost({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: true,
      onKeyEvent: (FocusNode node, KeyEvent event) {
        if (event is! KeyDownEvent) return KeyEventResult.ignored;
        final SonoraScope scope = SonoraScope.of(context);
        final PlayerController p = scope.player;
        final LogicalKeyboardKey k = event.logicalKey;
        final bool ctrl = HardwareKeyboard.instance.isControlPressed;
        final bool shift = HardwareKeyboard.instance.isShiftPressed;

        if (k == LogicalKeyboardKey.space) {
          p.toggle();
          return KeyEventResult.handled;
        }
        if (k == LogicalKeyboardKey.arrowRight) {
          if (ctrl) {
            p.next();
          } else {
            p.seekRelative(Duration(seconds: scope.s.seekStep));
          }
          return KeyEventResult.handled;
        }
        if (k == LogicalKeyboardKey.arrowLeft) {
          if (ctrl) {
            p.previous();
          } else {
            p.seekRelative(Duration(seconds: -scope.s.seekStep));
          }
          return KeyEventResult.handled;
        }
        if (k == LogicalKeyboardKey.arrowUp) {
          final double v = (scope.s.volume + 0.05).clamp(0.0, 1.0).toDouble();
          scope.settings.update((AppSettings s) => s.copyWith(volume: v));
          p.setVolume(v);
          return KeyEventResult.handled;
        }
        if (k == LogicalKeyboardKey.arrowDown) {
          final double v = (scope.s.volume - 0.05).clamp(0.0, 1.0).toDouble();
          scope.settings.update((AppSettings s) => s.copyWith(volume: v));
          p.setVolume(v);
          return KeyEventResult.handled;
        }
        if (k == LogicalKeyboardKey.keyM) {
          final double v = scope.s.volume > 0.01 ? 0.0 : 0.8;
          scope.settings.update((AppSettings s) => s.copyWith(volume: v));
          p.setVolume(v);
          return KeyEventResult.handled;
        }
        if (k == LogicalKeyboardKey.keyL) {
          final t = p.current;
          if (t != null) p.toggleLike(t.id);
          return KeyEventResult.handled;
        }
        if (k == LogicalKeyboardKey.keyS) {
          p.toggleShuffle();
          return KeyEventResult.handled;
        }
        if (k == LogicalKeyboardKey.keyR) {
          p.cycleLoop();
          return KeyEventResult.handled;
        }
        if (k == LogicalKeyboardKey.escape) {
          Navigator.maybeOf(context)?.maybePop();
          return KeyEventResult.handled;
        }
        if (k == LogicalKeyboardKey.keyQ && shift) {
          return KeyEventResult.ignored;
        }
        return KeyEventResult.ignored;
      },
      child: child,
    );
  }
}

class _Splash extends StatelessWidget {
  const _Splash({required this.palette});
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: palette.bg0,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.6, end: 1.0),
              duration: const Duration(milliseconds: 700),
              curve: Curves.easeOutBack,
              builder: (BuildContext context, double v, Widget? child) =>
                  Transform.scale(scale: v, child: child),
              child: Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  gradient: LinearGradient(
                      colors: <Color>[palette.accent, palette.accent2]),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                        color: palette.accent.withOpacity(0.5),
                        blurRadius: 40,
                        spreadRadius: 4),
                  ],
                ),
                child: const Icon(Icons.waves_rounded,
                    color: Colors.black, size: 38),
              ),
            ),
            const SizedBox(height: 20),
            Text('Sonora',
                style: TextStyle(
                    color: palette.text,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5)),
            const SizedBox(height: 6),
            Text('запускаю аудио-движок…',
                style: TextStyle(color: palette.muted, fontSize: 12)),
            const SizedBox(height: 22),
            SizedBox(
              width: 120,
              child: LinearProgressIndicator(
                minHeight: 3,
                backgroundColor: Colors.white.withOpacity(0.08),
                valueColor: AlwaysStoppedAnimation<Color>(palette.accent),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
