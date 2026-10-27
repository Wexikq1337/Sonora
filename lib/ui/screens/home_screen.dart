import 'package:flutter/material.dart';

import '../../app_scope.dart';
import '../../core/palette.dart';
import '../../models/demo_library.dart';
import '../../models/track.dart';
import '../animations/motion.dart';
import '../glass/glass.dart';
import '../navigation.dart';
import '../widgets/artwork.dart';
import '../widgets/track_tile.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.onNavigate});

  final ValueChanged<SonoraTab> onNavigate;

  @override
  Widget build(BuildContext context) {
    final SonoraScope scope = SonoraScope.of(context);
    final AppPalette pal = scope.palette;
    final Track hero = scope.player.current ?? DemoLibrary.tracks.first;

    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 100),
        children: <Widget>[
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1080),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Appear(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: <Widget>[
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                'Добрый вечер',
                                style: TextStyle(
                                    color: pal.accent,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.2),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Что послушаем?',
                                style: TextStyle(
                                    color: pal.text,
                                    fontSize: 28,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.8),
                              ),
                            ],
                          ),
                        ),
                        GlassChip(
                          label: 'Поиск по 8 источникам',
                          icon: Icons.travel_explore_rounded,
                          onTap: () => onNavigate(SonoraTab.search),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Appear(
                    delayMs: 60,
                    child: _ContinueCard(track: hero),
                  ),
                  const SizedBox(height: 22),
                  Appear(
                    delayMs: 100,
                    child: _SourceStrip(),
                  ),
                  const SizedBox(height: 22),
                  Appear(
                    delayMs: 140,
                    child: SectionHeader(
                      title: 'Подборки для вас',
                      icon: Icons.auto_awesome_rounded,
                      actionLabel: 'Все',
                      onAction: () => onNavigate(SonoraTab.library),
                    ),
                  ),
                  const SizedBox(height: 4),
                  SizedBox(
                    height: 238,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.only(bottom: 6),
                      itemCount: DemoCollections.all.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 14),
                      itemBuilder: (BuildContext context, int i) {
                        final DemoCollections c = DemoCollections.all[i];
                        final List<Track> tracks = c.resolve();
                        return Appear(
                          delayMs: 180 + i * 70,
                          child: CollectionCard(
                            track: tracks.first,
                            title: c.title,
                            subtitle: c.subtitle,
                            onTap: () => scope.player.playQueue(tracks),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 14),
                  Appear(
                    delayMs: 260,
                    child: SectionHeader(
                      title: 'Сейчас в библиотеке',
                      icon: Icons.library_music_rounded,
                      actionLabel: 'Вся медиатека',
                      onAction: () => onNavigate(SonoraTab.library),
                    ),
                  ),
                  for (int i = 0; i < DemoLibrary.tracks.length; i++)
                    Appear(
                      delayMs: 300 + i * 45,
                      child: ListenableBuilder(
                        listenable: scope.player,
                        builder: (BuildContext context, _) {
                          final Track t = DemoLibrary.tracks[i];
                          return TrackTile(
                            track: t,
                            index: i,
                            playing: scope.player.current?.id == t.id &&
                                scope.player.playing,
                            onPlay: () => scope.player.playQueue(
                                DemoLibrary.tracks,
                                startIndex: i),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContinueCard extends StatefulWidget {
  const _ContinueCard({required this.track});
  final Track track;

  @override
  State<_ContinueCard> createState() => _ContinueCardState();
}

class _ContinueCardState extends State<_ContinueCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final SonoraScope scope = SonoraScope.of(context);
    final AppPalette pal = scope.palette;
    final Track t = widget.track;

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: LiquidGlass(
        radius: 24,
        opacityScale: _hover ? 1.25 : 1.0,
        padding: const EdgeInsets.all(14),
        tint: t.colorA,
        child: Row(
          children: <Widget>[
            Artwork(track: t, width: 92, height: 92, radius: 18, badge: true),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'ПРОДОЛЖИТЬ СЛУШАТЬ',
                    style: TextStyle(
                        color: pal.accent,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.4),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    t.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: pal.text,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${t.artist} · ${t.album} · ${t.source.label}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: pal.muted, fontSize: 12.5),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: <Widget>[
                      GlassChip(
                        label: scope.player.playing ? 'Пауза' : 'Слушать',
                        icon: scope.player.playing
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        selected: true,
                        onTap: () {
                          if (scope.player.current?.id == t.id) {
                            scope.player.toggle();
                          } else {
                            scope.player.playQueue(DemoLibrary.tracks, startIndex: 0);
                          }
                        },
                      ),
                      const SizedBox(width: 8),
                      GlassChip(
                        label: 'Открыть плеер',
                        icon: Icons.open_in_full_rounded,
                        onTap: () => openNowPlaying(context),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SourceStrip extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final AppPalette pal = SonoraScope.of(context).palette;
    const List<MusicSource> shown = <MusicSource>[
      MusicSource.navidrome,
      MusicSource.spotify,
      MusicSource.soundcloud,
      MusicSource.ytmusic,
      MusicSource.apple,
      MusicSource.yandex,
      MusicSource.vk,
      MusicSource.local,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Icon(Icons.hub_rounded, size: 15, color: pal.muted),
            const SizedBox(width: 6),
            Text('Источники',
                style: TextStyle(
                    color: pal.muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8)),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            for (int i = 0; i < shown.length; i++)
              _SourcePill(source: shown[i], connected: i < 3),
          ],
        ),
      ],
    );
  }
}

class _SourcePill extends StatelessWidget {
  const _SourcePill({required this.source, required this.connected});
  final MusicSource source;
  final bool connected;

  @override
  Widget build(BuildContext context) {
    final AppPalette pal = SonoraScope.of(context).palette;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: Colors.white.withOpacity(0.045),
        border: Border.all(
            color: Colors.white.withOpacity(0.09), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(source.icon, size: 14, color: source.color),
          const SizedBox(width: 7),
          Text(source.label,
              style: TextStyle(color: pal.text.withOpacity(0.85), fontSize: 12)),
          const SizedBox(width: 7),
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: connected
                  ? const Color(0xFF57F287)
                  : Colors.white.withOpacity(0.25),
            ),
          ),
        ],
      ),
    );
  }
}
