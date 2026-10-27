import 'dart:math' as math;
import 'dart:ui' show FontFeature, ImageFilter;

import 'package:flutter/material.dart';

import '../../app_scope.dart';
import '../../core/format.dart';
import '../../core/palette.dart';
import '../../models/track.dart';
import '../../state/performance_monitor.dart';
import '../../state/player_controller.dart';
import '../animations/animated_background.dart';
import '../animations/visualizer.dart';
import '../glass/glass.dart';
import '../widgets/artwork.dart';
import 'equalizer_sheet.dart';

class NowPlayingScreen extends StatelessWidget {
  const NowPlayingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final SonoraScope scope = SonoraScope.of(context);
    final PlayerController player = scope.player;

    return ListenableBuilder(
      listenable: player,
      builder: (BuildContext context, _) {
        final Track? t = player.current;
        if (t == null) {
          return Scaffold(
            backgroundColor: Colors.transparent,
            body: Center(
              child: GlassChip(
                label: 'Ничего не играет',
                icon: Icons.music_off_rounded,
                onTap: () => Navigator.of(context).maybePop(),
              ),
            ),
          );
        }

        final bool heavy = !PerformanceMonitor.instance.lowQuality;
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: Stack(
            children: <Widget>[
              Positioned.fill(child: AnimatedBackground(albumTint: t.colorA)),
              Positioned.fill(
                child: heavy
                    ? BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 46, sigmaY: 46),
                        child: ColoredBox(color: Colors.black.withOpacity(0.32)),
                      )
                    : ColoredBox(color: Colors.black.withOpacity(0.55)),
              ),
              SafeArea(
                child: LayoutBuilder(
                  builder: (BuildContext context, BoxConstraints c) {
                    final bool wide = c.maxWidth >= 900;
                    return wide
                        ? _wide(context, scope, t, c)
                        : _narrow(context, scope, t, c);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _topBar(BuildContext context, SonoraScope scope, Track t) {
    final AppPalette pal = scope.palette;
    return Row(
      children: <Widget>[
        GlassIconButton(
          icon: Icons.keyboard_arrow_down_rounded,
          size: 42,
          iconSize: 24,
          onTap: () => Navigator.of(context).maybePop(),
          tooltip: 'Свернуть',
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('ИГРАЕТ ИЗ',
                  style: TextStyle(
                      color: pal.muted,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.4)),
              const SizedBox(height: 2),
              Row(
                children: <Widget>[
                  Icon(t.source.icon, size: 13, color: t.source.color),
                  const SizedBox(width: 5),
                  Flexible(
                    child: Text(
                      t.source.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: pal.text,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        GlassIconButton(
          icon: Icons.queue_music_rounded,
          size: 42,
          iconSize: 20,
          tooltip: 'Очередь',
          onTap: () => showQueueSheet(context),
        ),
        const SizedBox(width: 8),
        GlassIconButton(
          icon: Icons.equalizer_rounded,
          size: 42,
          iconSize: 20,
          tooltip: 'Эквалайзер',
          onTap: () => showEqualizerSheet(context),
        ),
      ],
    );
  }

  Widget _artworkBlock(Track t, double size) {
    return Hero(
      tag: 'now-art',
      child: Artwork(track: t, width: size, height: size, radius: 26),
    );
  }

  Widget _titleBlock(SonoraScope scope, Track t, {double titleSize = 26}) {
    final AppPalette pal = scope.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          t.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
              color: pal.text,
              fontSize: titleSize,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.7,
              height: 1.1),
        ),
        const SizedBox(height: 6),
        Row(
          children: <Widget>[
            Flexible(
              child: Text(
                t.artist,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    color: pal.text.withOpacity(0.82),
                    fontSize: 15,
                    fontWeight: FontWeight.w500),
              ),
            ),
            Text('  ·  ${t.album}',
                maxLines: 1,
                style: TextStyle(color: pal.muted, fontSize: 13)),
          ],
        ),
      ],
    );
  }

  Widget _progress(BuildContext context, SonoraScope scope, Track t) {
    final AppPalette pal = scope.palette;
    return ValueListenableBuilder<Duration>(
      valueListenable: scope.player.position,
      builder: (BuildContext context, Duration pos, _) => Column(
        children: <Widget>[
          GlassProgressBar(
            value: scope.player.progress,
            height: 5,
            onSeek: (double v) => scope.player.seek(t.duration * v),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text(fmtPosition(pos),
                    style: TextStyle(
                        color: pal.muted,
                        fontSize: 11,
                        fontFeatures: const <FontFeature>[
                          FontFeature.tabularFigures()
                        ])),
                Text(fmtPosition(t.duration),
                    style: TextStyle(
                        color: pal.muted,
                        fontSize: 11,
                        fontFeatures: const <FontFeature>[
                          FontFeature.tabularFigures()
                        ])),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _controls(SonoraScope scope, {double playSize = 76}) {
    final PlayerController p = scope.player;
    final AppPalette pal = scope.palette;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        GlassIconButton(
          icon: Icons.shuffle_rounded,
          size: 44,
          iconSize: 18,
          selected: p.shuffle,
          tint: pal.accent,
          tooltip: 'Перемешать',
          onTap: p.toggleShuffle,
        ),
        const SizedBox(width: 14),
        GlassIconButton(
          icon: Icons.skip_previous_rounded,
          size: 54,
          iconSize: 26,
          tooltip: 'Предыдущий',
          onTap: () => p.previous(),
        ),
        const SizedBox(width: 14),
        GlassIconButton(
          icon: p.playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
          size: playSize,
          iconSize: playSize * 0.46,
          selected: true,
          tooltip: p.playing ? 'Пауза' : 'Играть',
          onTap: () => p.toggle(),
        ),
        const SizedBox(width: 14),
        GlassIconButton(
          icon: Icons.skip_next_rounded,
          size: 54,
          iconSize: 26,
          tooltip: 'Следующий',
          onTap: () => p.next(),
        ),
        const SizedBox(width: 14),
        GlassIconButton(
          icon: p.loop == LoopMode.one
              ? Icons.repeat_one_rounded
              : Icons.repeat_rounded,
          size: 44,
          iconSize: 18,
          selected: p.loop != LoopMode.off,
          tint: pal.accent,
          tooltip: 'Повтор',
          onTap: p.cycleLoop,
        ),
      ],
    );
  }

  Widget _bottomRow(BuildContext context, SonoraScope scope, Track t) {
    final PlayerController p = scope.player;
    final AppPalette pal = scope.palette;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: <Widget>[
        GlassIconButton(
          icon: p.isLiked(t.id)
              ? Icons.favorite_rounded
              : Icons.favorite_border_rounded,
          size: 42,
          iconSize: 19,
          selected: p.isLiked(t.id),
          tint: const Color(0xFFFF4D6D),
          tooltip: 'Нравится',
          onTap: () => p.toggleLike(t.id),
        ),
        GlassIconButton(
          icon: Icons.download_rounded,
          size: 42,
          iconSize: 19,
          tooltip: 'Скачать',
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: pal.bg1,
                content: Text('Трек уже сохранён в памяти (демо)',
                    style: TextStyle(color: pal.text)),
              ),
            );
          },
        ),
        GlassIconButton(
          icon: Icons.queue_music_rounded,
          size: 42,
          iconSize: 19,
          tooltip: 'Очередь',
          onTap: () => showQueueSheet(context),
        ),
        GlassIconButton(
          icon: Icons.share_rounded,
          size: 42,
          iconSize: 19,
          tooltip: 'Поделиться',
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: pal.bg1,
                content: Text('Ссылка скопирована (демо)',
                    style: TextStyle(color: pal.text)),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _narrow(
      BuildContext context, SonoraScope scope, Track t, BoxConstraints c) {
    final double art = math.min(
      math.min(c.maxWidth - 76, c.maxHeight * 0.36),
      340.0,
    );
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
      child: Column(
        children: <Widget>[
          _topBar(context, scope, t),
          const SizedBox(height: 18),
          _artworkBlock(t, math.max(150.0, art)),
          const SizedBox(height: 22),
          Align(
            alignment: Alignment.centerLeft,
            child: _titleBlock(scope, t, titleSize: 24),
          ),
          const SizedBox(height: 12),
          Visualizer(
            playing: scope.player.playing,
            seed: t.id.hashCode,
            bpm: t.bpm,
            height: 46,
            bars: 34,
          ),
          const SizedBox(height: 6),
          _progress(context, scope, t),
          const SizedBox(height: 14),
          _controls(scope),
          const SizedBox(height: 18),
          _bottomRow(context, scope, t),
        ],
      ),
    );
  }

  Widget _wide(
      BuildContext context, SonoraScope scope, Track t, BoxConstraints c) {
    final double art = math.min(400.0, c.maxHeight - 190);
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 12, 28, 20),
      child: Column(
        children: <Widget>[
          _topBar(context, scope, t),
          const Spacer(),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              _artworkBlock(t, math.max(220.0, art)),
              const SizedBox(width: 36),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    _titleBlock(scope, t, titleSize: 34),
                    const SizedBox(height: 22),
                    Visualizer(
                      playing: scope.player.playing,
                      seed: t.id.hashCode,
                      bpm: t.bpm,
                      height: 64,
                      bars: 44,
                    ),
                    const SizedBox(height: 14),
                    _progress(context, scope, t),
                    const SizedBox(height: 18),
                    _controls(scope, playSize: 86),
                    const SizedBox(height: 18),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: _bottomRow(context, scope, t),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Spacer(),
        ],
      ),
    );
  }
}

/// Compact now-playing card for the desktop right rail.
class NowPlayingSidePanel extends StatelessWidget {
  const NowPlayingSidePanel({super.key});

  @override
  Widget build(BuildContext context) {
    final SonoraScope scope = SonoraScope.of(context);
    final PlayerController p = scope.player;
    return ListenableBuilder(
      listenable: p,
      builder: (BuildContext context, _) {
        final Track? t = p.current;
        final AppPalette pal = scope.palette;
        if (t == null) {
          return LiquidGlass(
            radius: 24,
            padding: const EdgeInsets.all(18),
            child: Text('Ничего не играет',
                style: TextStyle(color: pal.muted, fontSize: 12)),
          );
        }
        return LiquidGlass(
          radius: 24,
          padding: const EdgeInsets.all(14),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('СЕЙЧАС ИГРАЕТ',
                    style: TextStyle(
                        color: pal.muted,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.3)),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () => _open(context),
                  child: Artwork(
                      track: t, width: double.infinity, height: 280, radius: 18),
                ),
                const SizedBox(height: 12),
                Text(t.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: pal.text,
                        fontSize: 15,
                        fontWeight: FontWeight.w700)),
                Text('${t.artist} · ${t.album}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: pal.muted, fontSize: 11.5)),
                const SizedBox(height: 10),
                Visualizer(
                  playing: p.playing,
                  seed: t.id.hashCode,
                  bpm: t.bpm,
                  height: 40,
                  bars: 26,
                ),
                const SizedBox(height: 8),
                ValueListenableBuilder<Duration>(
                  valueListenable: p.position,
                  builder: (BuildContext context, Duration pos, _) => Column(
                    children: <Widget>[
                      GlassProgressBar(
                        value: p.progress,
                        height: 4,
                        onSeek: (double v) => p.seek(t.duration * v),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Text(fmtPosition(pos),
                              style: TextStyle(
                                  color: pal.muted, fontSize: 10)),
                          Text(fmtPosition(t.duration),
                              style: TextStyle(
                                  color: pal.muted, fontSize: 10)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: <Widget>[
                    GlassIconButton(
                      icon: Icons.skip_previous_rounded,
                      size: 40,
                      iconSize: 18,
                      onTap: () => p.previous(),
                    ),
                    GlassIconButton(
                      icon: p.playing
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      size: 52,
                      iconSize: 24,
                      selected: true,
                      onTap: () => p.toggle(),
                    ),
                    GlassIconButton(
                      icon: Icons.skip_next_rounded,
                      size: 40,
                      iconSize: 18,
                      onTap: () => p.next(),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: GlassChip(
                        label: 'Эквалайзер',
                        icon: Icons.equalizer_rounded,
                        dense: true,
                        onTap: () => showEqualizerSheet(context),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: GlassChip(
                        label: 'Очередь',
                        icon: Icons.queue_music_rounded,
                        dense: true,
                        onTap: () => showQueueSheet(context),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _open(BuildContext context) {
    Navigator.of(context).push<void>(glassRouteForNowPlaying());
  }
}

Route<void> glassRouteForNowPlaying() => MaterialPageRoute<void>(
      builder: (BuildContext context) => const NowPlayingScreen(),
      fullscreenDialog: true,
    );

Future<void> showQueueSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    barrierColor: Colors.black.withOpacity(0.55),
    builder: (BuildContext ctx) => const BlurDepth(
      value: 2,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[_QueueSheet()],
        ),
      ),
    ),
  );
}

class _QueueSheet extends StatelessWidget {
  const _QueueSheet();

  @override
  Widget build(BuildContext context) {
    final SonoraScope scope = SonoraScope.of(context);
    final PlayerController p = scope.player;
    final AppPalette pal = scope.palette;

    return ConstrainedBox(
      constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.8, maxWidth: 640),
      child: LiquidGlass(
        radius: 28,
        blurScale: 1.15,
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
        child: ListenableBuilder(
          listenable: p,
          builder: (BuildContext context, _) => Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Icon(Icons.queue_music_rounded,
                      size: 18, color: pal.accent),
                  const SizedBox(width: 8),
                  Text('Очередь',
                      style: TextStyle(
                          color: pal.text,
                          fontSize: 16,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(width: 8),
                  Text('${p.queue.length} треков',
                      style: TextStyle(color: pal.muted, fontSize: 11.5)),
                  const Spacer(),
                  GlassIconButton(
                    icon: Icons.close_rounded,
                    size: 34,
                    iconSize: 17,
                    onTap: () => Navigator.of(context).maybePop(),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  itemCount: p.queue.length,
                  itemBuilder: (BuildContext context, int i) {
                    final Track t = p.queue[i];
                    final bool active = i == p.index;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: LiquidGlass(
                        radius: 12,
                        opacityScale: active ? 1.7 : 0.8,
                        tint: active ? pal.accent : null,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 7),
                        child: Row(
                          children: <Widget>[
                            SizedBox(
                              width: 22,
                              child: active
                                  ? Icon(Icons.graphic_eq_rounded,
                                      size: 15, color: pal.accent)
                                  : Text('${i + 1}',
                                      style: TextStyle(
                                          color: pal.muted, fontSize: 11)),
                            ),
                            Artwork(
                                track: t,
                                width: 34,
                                height: 34,
                                radius: 8,
                                glow: false),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(t.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                          color: active ? pal.accent : pal.text,
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w600)),
                                  Text(t.artist,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                          color: pal.muted, fontSize: 10.5)),
                                ],
                              ),
                            ),
                            Text(fmtDuration(t.duration),
                                style: TextStyle(
                                    color: pal.muted.withOpacity(0.8),
                                    fontSize: 10.5)),
                            const SizedBox(width: 6),
                            GlassIconButton(
                              icon: Icons.play_arrow_rounded,
                              size: 30,
                              iconSize: 15,
                              onTap: () => p.playQueue(p.queue, startIndex: i),
                            ),
                          ],
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
    );
  }
}
