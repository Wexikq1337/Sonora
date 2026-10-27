import 'package:flutter/material.dart';

import '../../app_scope.dart';
import '../../core/palette.dart';
import '../../services/discord/discord_presence_service.dart';
import '../../state/performance_monitor.dart';
import '../animations/motion.dart';
import '../glass/glass.dart';
import '../navigation.dart';
import '../widgets/mini_player.dart';
import 'downloads_screen.dart';
import 'equalizer_sheet.dart';
import 'home_screen.dart';
import 'library_screen.dart';
import 'now_playing.dart';
import 'search_screen.dart';
import 'settings/settings_screen.dart';

class SonoraShell extends StatefulWidget {
  const SonoraShell({super.key});

  @override
  State<SonoraShell> createState() => _SonoraShellState();
}

class _SonoraShellState extends State<SonoraShell> {
  SonoraTab _tab = SonoraTab.home;
  int _settingsTab = 0;

  void _select(SonoraTab tab) {
    if (_tab == tab) return;
    setState(() => _tab = tab);
  }

  void _openDiscord() {
    setState(() {
      _settingsTab = 11;
      _tab = SonoraTab.settings;
    });
  }

  Widget _page(BuildContext context) {
    switch (_tab) {
      case SonoraTab.home:
        return HomeScreen(onNavigate: _select);
      case SonoraTab.search:
        return const SearchScreen();
      case SonoraTab.library:
        return const LibraryScreen();
      case SonoraTab.downloads:
        return const DownloadsScreen();
      case SonoraTab.settings:
        return SettingsScreen(
          key: ValueKey<String>('settings-$_settingsTab'),
          initialTab: _settingsTab,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final SonoraScope scope = SonoraScope.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints c) {
          final bool desktop = c.maxWidth >= 1000;
          final bool wide = c.maxWidth >= 1360;

          final Widget page = AnimatedSwitcher(
            duration: motionDuration(context, 280),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (Widget child, Animation<double> anim) {
              return FadeTransition(
                opacity: anim,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.015, 0),
                    end: Offset.zero,
                  ).animate(anim),
                  child: child,
                ),
              );
            },
            child: KeyedSubtree(
              key: ValueKey<String>('${_tab.name}-$_settingsTab'),
              child: _page(context),
            ),
          );

          return Stack(
            children: <Widget>[
              SafeArea(
                bottom: false,
                child: desktop
                    ? Column(
                        children: <Widget>[
                          Expanded(
                            child: Row(
                              children: <Widget>[
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(14, 14, 8, 8),
                                  child: SizedBox(
                                    width: 226,
                                    child: _Rail(
                                      current: _tab,
                                      onSelect: _select,
                                      onOpenDiscord: _openDiscord,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.fromLTRB(4, 14, 8, 0),
                                    child: page,
                                  ),
                                ),
                                if (wide)
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(4, 14, 14, 8),
                                    child: SizedBox(
                                      width: 320,
                                      child: const NowPlayingSidePanel(),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          MiniPlayerBar(
                            desktop: true,
                            onExpand: () => openNowPlaying(context),
                          ),
                        ],
                      )
                    : Column(
                        children: <Widget>[
                          Expanded(child: page),
                          MiniPlayerBar(
                            onExpand: () => openNowPlaying(context),
                          ),
                          _NavBar(current: _tab, onSelect: _select),
                        ],
                      ),
              ),
              if (scope.s.showFps)
                const Positioned(top: 8, right: 12, child: _FpsBadge()),
            ],
          );
        },
      ),
    );
  }
}

class _Rail extends StatelessWidget {
  const _Rail({
    required this.current,
    required this.onSelect,
    required this.onOpenDiscord,
  });

  final SonoraTab current;
  final ValueChanged<SonoraTab> onSelect;
  final VoidCallback onOpenDiscord;

  @override
  Widget build(BuildContext context) {
    final SonoraScope scope = SonoraScope.of(context);
    final AppPalette pal = scope.palette;

    return LiquidGlass(
      radius: 26,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(6, 6, 6, 16),
            child: Row(
              children: <Widget>[
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    gradient: LinearGradient(
                        colors: <Color>[pal.accent, pal.accent2]),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                          color: pal.accent.withOpacity(0.5),
                          blurRadius: 18,
                          spreadRadius: 1),
                    ],
                  ),
                  child: const Icon(Icons.waves_rounded,
                      size: 18, color: Colors.black),
                ),
                const SizedBox(width: 10),
                Text(
                  'Sonora',
                  style: TextStyle(
                      color: pal.text,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4),
                ),
              ],
            ),
          ),
          for (final TabSpec t in kTabs)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: _RailItem(
                spec: t,
                active: current == t.tab,
                onTap: () => onSelect(t.tab),
              ),
            ),
          const Spacer(),
          const SizedBox(height: 8),
          GlassButton(
            radius: 16,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            tint: pal.accent,
            onTap: () => showEqualizerSheet(context),
            child: Row(
              children: <Widget>[
                Icon(Icons.equalizer_rounded, size: 18, color: pal.accent),
                const SizedBox(width: 10),
                Text('Эквалайзер',
                    style: TextStyle(
                        color: pal.text, fontSize: 13, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          const SizedBox(height: 10),
          _DiscordChip(onTap: onOpenDiscord),
        ],
      ),
    );
  }
}

class _RailItem extends StatefulWidget {
  const _RailItem({
    required this.spec,
    required this.active,
    required this.onTap,
  });

  final TabSpec spec;
  final bool active;
  final VoidCallback onTap;

  @override
  State<_RailItem> createState() => _RailItemState();
}

class _RailItemState extends State<_RailItem> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final AppPalette pal = SonoraScope.of(context).palette;
    final Color fg = widget.active
        ? pal.text
        : (_hover ? pal.text.withOpacity(0.9) : pal.muted);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: motionDuration(context, 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            color: widget.active
                ? pal.accent.withOpacity(0.16)
                : (_hover ? Colors.white.withOpacity(0.05) : Colors.transparent),
            border: Border.all(
              color: widget.active
                  ? pal.accent.withOpacity(0.45)
                  : Colors.transparent,
              width: 1,
            ),
          ),
          child: Row(
            children: <Widget>[
              Icon(widget.active ? widget.spec.activeIcon : widget.spec.icon,
                  size: 19, color: widget.active ? pal.accent : fg),
              const SizedBox(width: 11),
              Text(
                widget.spec.label,
                style: TextStyle(
                    color: fg,
                    fontSize: 13.5,
                    fontWeight:
                        widget.active ? FontWeight.w700 : FontWeight.w500),
              ),
              const Spacer(),
              if (widget.active)
                Container(
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: pal.accent,
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                            color: pal.accent.withOpacity(0.8), blurRadius: 8)
                      ]),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DiscordChip extends StatelessWidget {
  const _DiscordChip({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final SonoraScope scope = SonoraScope.of(context);
    final AppPalette pal = scope.palette;
    return ListenableBuilder(
      listenable: scope.discord,
      builder: (BuildContext context, _) {
        final DiscordStatus st = scope.discord.status;
        final Color dot = switch (st) {
          DiscordStatus.connected => const Color(0xFF57F287),
          DiscordStatus.connecting => const Color(0xFFFEE75C),
          DiscordStatus.off => pal.muted,
          _ => const Color(0xFFED4245),
        };
        return GlassButton(
          radius: 14,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          onTap: onTap,
          child: Row(
            children: <Widget>[
              Icon(Icons.discord_rounded, size: 16, color: dot),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  scope.discord.statusLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: pal.muted, fontSize: 11.5),
                ),
              ),
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: dot,
                  boxShadow: <BoxShadow>[
                    BoxShadow(color: dot.withOpacity(0.8), blurRadius: 8)
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _NavBar extends StatelessWidget {
  const _NavBar({required this.current, required this.onSelect});

  final SonoraTab current;
  final ValueChanged<SonoraTab> onSelect;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 2, 10, 8),
      child: LiquidGlass(
        radius: 24,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            for (final TabSpec t in kTabs)
              Expanded(
                child: _NavItem(
                  spec: t,
                  active: current == t.tab,
                  onTap: () => onSelect(t.tab),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.spec,
    required this.active,
    required this.onTap,
  });

  final TabSpec spec;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final AppPalette pal = SonoraScope.of(context).palette;
    final Color fg = active ? pal.accent : pal.muted;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: motionDuration(context, 220),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: active ? pal.accent.withOpacity(0.14) : Colors.transparent,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(active ? spec.activeIcon : spec.icon, size: 21, color: fg),
            const SizedBox(height: 3),
            Text(
              spec.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  color: fg,
                  fontSize: 9.5,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}

class _FpsBadge extends StatelessWidget {
  const _FpsBadge();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: ListenableBuilder(
        listenable: PerformanceMonitor.instance,
        builder: (BuildContext context, _) {
          final PerformanceMonitor m = PerformanceMonitor.instance;
          final Color c = m.lowQuality
              ? const Color(0xFFFFB020)
              : const Color(0xFF57F287);
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.45),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: c.withOpacity(0.4)),
            ),
            child: Text(
              '${m.fps} FPS · ${m.frameMs.toStringAsFixed(1)} ms'
              '${m.lowQuality ? ' · LOW' : ''}',
              style: TextStyle(
                  color: c, fontSize: 10, fontWeight: FontWeight.w600),
            ),
          );
        },
      ),
    );
  }
}
