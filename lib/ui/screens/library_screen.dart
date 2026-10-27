import 'package:flutter/material.dart';

import '../../app_scope.dart';
import '../../core/format.dart';
import '../../core/palette.dart';
import '../../models/demo_library.dart';
import '../../models/library.dart';
import '../../models/track.dart';
import '../../services/subsonic/subsonic_client.dart';
import '../../state/player_controller.dart';
import '../animations/motion.dart';
import '../glass/glass.dart';
import '../widgets/artwork.dart';
import '../widgets/track_tile.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

enum _LibTab { tracks, server, playlists, liked, history, artists }

class _LibraryScreenState extends State<LibraryScreen> {
  _LibTab _tab = _LibTab.tracks;
  String _sort = 'По умолчанию';

  List<Track> get _sorted {
    final List<Track> list = List<Track>.of(DemoLibrary.tracks);
    switch (_sort) {
      case 'По названию':
        list.sort((Track a, Track b) => a.title.compareTo(b.title));
        break;
      case 'По артисту':
        list.sort((Track a, Track b) => a.artist.compareTo(b.artist));
        break;
      case 'По источнику':
        list.sort((Track a, Track b) => a.source.index.compareTo(b.source.index));
        break;
      default:
        break;
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final SonoraScope scope = SonoraScope.of(context);
    final AppPalette pal = scope.palette;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 980),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text('Медиатека',
                          style: TextStyle(
                              color: pal.text,
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.6)),
                      const SizedBox(height: 3),
                      Text(
                        '${DemoLibrary.tracks.length} треков · '
                        '${DemoCollections.all.length} подборки · 8 источников',
                        style: TextStyle(color: pal.muted, fontSize: 12.5),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: <Widget>[
                          GlassChip(
                            label: 'Слушать всё',
                            icon: Icons.play_arrow_rounded,
                            selected: true,
                            onTap: () => scope.player.playQueue(_sorted),
                          ),
                          GlassChip(
                            label: 'Перемешать',
                            icon: Icons.shuffle_rounded,
                            onTap: () {
                              if (!scope.player.shuffle) {
                                scope.player.toggleShuffle();
                              }
                              scope.player.playQueue(_sorted);
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: <Widget>[
                      GlassChip(
                        label: 'Треки',
                        dense: true,
                        selected: _tab == _LibTab.tracks,
                        onTap: () => setState(() => _tab = _LibTab.tracks),
                      ),
                      GlassChip(
                        label: 'Сервер',
                        dense: true,
                        icon: Icons.dns_rounded,
                        selected: _tab == _LibTab.server,
                        onTap: () => setState(() => _tab = _LibTab.server),
                      ),
                      GlassChip(
                        label: 'Плейлисты',
                        dense: true,
                        selected: _tab == _LibTab.playlists,
                        onTap: () => setState(() => _tab = _LibTab.playlists),
                      ),
                      GlassChip(
                        label: 'Артисты',
                        dense: true,
                        selected: _tab == _LibTab.artists,
                        onTap: () => setState(() => _tab = _LibTab.artists),
                      ),
                      GlassChip(
                        label: 'Избранное',
                        dense: true,
                        icon: Icons.favorite_rounded,
                        selected: _tab == _LibTab.liked,
                        onTap: () => setState(() => _tab = _LibTab.liked),
                      ),
                      GlassChip(
                        label: 'История',
                        dense: true,
                        icon: Icons.history_rounded,
                        selected: _tab == _LibTab.history,
                        onTap: () => setState(() => _tab = _LibTab.history),
                      ),
                      if (_tab == _LibTab.tracks)
                        PopupMenuButton<String>(
                          tooltip: 'Сортировка',
                          color: pal.bg1,
                          onSelected: (String v) => setState(() => _sort = v),
                          itemBuilder: (BuildContext context) =>
                              <PopupMenuEntry<String>>[
                            for (final String s in <String>[
                              'По умолчанию',
                              'По названию',
                              'По артисту',
                              'По источнику',
                            ])
                              PopupMenuItem<String>(
                                value: s,
                                child: Text(s,
                                    style: TextStyle(
                                        color: pal.text, fontSize: 13)),
                              ),
                          ],
                          child: GlassChip(
                            label: _sort,
                            icon: Icons.sort_rounded,
                            dense: true,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 980),
              child: AnimatedSwitcher(
                duration: motionDuration(context, 240),
                child: KeyedSubtree(
                  key: ValueKey<_LibTab>(_tab),
                  child: switch (_tab) {
                    _LibTab.tracks => _tracks(scope),
                    _LibTab.server => _ServerTab(scope: scope),
                    _LibTab.playlists => _playlists(scope),
                    _LibTab.liked => _liked(scope),
                    _LibTab.history => _history(scope),
                    _LibTab.artists => _artists(scope),
                  },
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _tracks(SonoraScope scope) {
    final List<Track> list = _sorted;
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(18, 4, 18, 100),
      itemCount: list.length,
      itemBuilder: (BuildContext context, int i) {
        final Track t = list[i];
        return Appear(
          delayMs: i * 35,
          child: ListenableBuilder(
            listenable: scope.player,
            builder: (BuildContext context, _) => TrackTile(
              track: t,
              index: i,
              playing: scope.player.current?.id == t.id && scope.player.playing,
              onPlay: () => scope.player.playQueue(list, startIndex: i),
            ),
          ),
        );
      },
    );
  }

  Widget _liked(SonoraScope scope) {
    return ListenableBuilder(
      listenable: scope.library,
      builder: (BuildContext context, _) {
        final List<Track> list = DemoLibrary.tracks
            .where((Track t) => scope.library.isLiked(t.id))
            .toList(growable: false);
        if (list.isEmpty) {
          return _emptyState(
            icon: Icons.favorite_border_rounded,
            title: 'В избранном пока пусто',
            subtitle: 'Нажми ♥ на любом треке — он появится здесь и останется '
                'после перезапуска приложения',
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(18, 6, 18, 100),
          itemCount: list.length + 1,
          itemBuilder: (BuildContext context, int i) {
            if (i == 0) {
              return _listHeader(
                '${list.length} треков в избранном',
                actionLabel: 'Слушать',
                onAction: () => scope.player.playQueue(list),
              );
            }
            final Track t = list[i - 1];
            return Appear(
              delayMs: i * 30,
              child: ListenableBuilder(
                listenable: scope.player,
                builder: (BuildContext context, _) => TrackTile(
                  track: t,
                  index: i - 1,
                  playing:
                      scope.player.current?.id == t.id && scope.player.playing,
                  onPlay: () =>
                      scope.player.playQueue(list, startIndex: i - 1),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _history(SonoraScope scope) {
    return ListenableBuilder(
      listenable: scope.library,
      builder: (BuildContext context, _) {
        final List<HistoryEntry> entries = scope.library.history;
        final List<Track> list = <Track>[];
        final List<String> times = <String>[];
        for (final HistoryEntry e in entries) {
          for (final Track t in DemoLibrary.tracks) {
            if (t.id == e.trackId) {
              list.add(t);
              times.add(_timeLabel(e.at));
              break;
            }
          }
        }
        if (list.isEmpty) {
          return _emptyState(
            icon: Icons.history_rounded,
            title: 'История пуста',
            subtitle: 'Включи любой трек — здесь появится список всего, что ты '
                'слушал, с временем запуска',
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(18, 6, 18, 100),
          itemCount: list.length + 1,
          itemBuilder: (BuildContext context, int i) {
            if (i == 0) {
              return _listHeader(
                '${list.length} записей',
                actionLabel: 'Очистить',
                onAction: scope.library.clearHistory,
              );
            }
            final Track t = list[i - 1];
            return Appear(
              delayMs: i * 30,
              child: ListenableBuilder(
                listenable: scope.player,
                builder: (BuildContext context, _) => TrackTile(
                  track: t,
                  playing:
                      scope.player.current?.id == t.id && scope.player.playing,
                  onPlay: () =>
                      scope.player.playQueue(list, startIndex: i - 1),
                  trailing: Text(
                    times[i - 1],
                    style: TextStyle(
                      color: scope.palette.muted.withOpacity(0.8),
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _timeLabel(DateTime t) {
    final DateTime now = DateTime.now();
    final bool sameDay =
        now.year == t.year && now.month == t.month && now.day == t.day;
    final String hh = t.hour.toString().padLeft(2, '0');
    final String mm = t.minute.toString().padLeft(2, '0');
    return sameDay
        ? '$hh:$mm'
        : '${t.day.toString().padLeft(2, '0')}.${t.month.toString().padLeft(2, '0')}';
  }

  Widget _listHeader(String label,
      {required String actionLabel, required VoidCallback onAction}) {
    final AppPalette pal = SonoraScope.of(context).palette;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(label,
                style: TextStyle(color: pal.muted, fontSize: 11.5)),
          ),
          GlassChip(label: actionLabel, dense: true, onTap: onAction),
        ],
      ),
    );
  }

  Widget _emptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final AppPalette pal = SonoraScope.of(context).palette;
    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
        child: LiquidGlass(
          radius: 22,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(icon, size: 34, color: pal.muted),
              const SizedBox(height: 12),
              Text(title,
                  style: TextStyle(
                      color: pal.text,
                      fontSize: 15,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              Text(subtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: pal.muted, fontSize: 12, height: 1.35)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _playlists(SonoraScope scope) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(18, 6, 18, 100),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 220,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.74,
      ),
      itemCount: DemoCollections.all.length,
      itemBuilder: (BuildContext context, int i) {
        final DemoCollections c = DemoCollections.all[i];
        final List<Track> tracks = c.resolve();
        return Appear(
          delayMs: i * 60,
          child: CollectionCard(
            track: tracks.first,
            title: c.title,
            subtitle: '${tracks.length} треков · ${c.subtitle}',
            width: 190,
            onTap: () => scope.player.playQueue(tracks),
          ),
        );
      },
    );
  }

  Widget _artists(SonoraScope scope) {
    final Map<String, List<Track>> byArtist = <String, List<Track>>{};
    for (final Track t in DemoLibrary.tracks) {
      byArtist.putIfAbsent(t.artist, () => <Track>[]).add(t);
    }
    final List<String> names = byArtist.keys.toList();
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(18, 6, 18, 100),
      itemCount: names.length,
      itemBuilder: (BuildContext context, int i) {
        final String name = names[i];
        final List<Track> tracks = byArtist[name]!;
        return Appear(
          delayMs: i * 50,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 4),
            child: GlassButton(
              radius: 16,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              onTap: () => scope.player.playQueue(tracks),
              child: Row(
                children: <Widget>[
                  ClipOval(
                    child: Artwork(
                      track: tracks.first,
                      width: 44,
                      height: 44,
                      radius: 22,
                      glow: false,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(name,
                            style: TextStyle(
                                color: scope.palette.text,
                                fontSize: 14,
                                fontWeight: FontWeight.w600)),
                        Text('${tracks.length} треков · ${tracks.first.album}',
                            style: TextStyle(
                                color: scope.palette.muted, fontSize: 11.5)),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded,
                      color: scope.palette.muted, size: 20),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ServerTab extends StatefulWidget {
  const _ServerTab({required this.scope});
  final SonoraScope scope;

  @override
  State<_ServerTab> createState() => _ServerTabState();
}

class _ServerTabState extends State<_ServerTab> {
  late SubsonicClient _client = SubsonicClient(widget.scope.s.server);
  late Future<List<SubsonicAlbum>> _future = _load();

  Future<List<SubsonicAlbum>> _load() {
    _client = SubsonicClient(widget.scope.s.server);
    if (!widget.scope.s.server.isConfigured) {
      return Future<List<SubsonicAlbum>>.value(const <SubsonicAlbum>[]);
    }
    return _client.getAlbums(size: 36);
  }

  void _reload() => setState(() => _future = _load());

  @override
  Widget build(BuildContext context) {
    final AppPalette pal = widget.scope.palette;
    if (!widget.scope.s.server.isConfigured) {
      return _panel(
        icon: Icons.dns_rounded,
        title: 'Сервер не подключён',
        text: 'Настройки → Источники → Navidrome / Subsonic.\n'
            'Адрес обычно http://IP-компьютера:4533',
      );
    }
    return FutureBuilder<List<SubsonicAlbum>>(
      future: _future,
      builder:
          (BuildContext context, AsyncSnapshot<List<SubsonicAlbum>> snap) {
        if (snap.connectionState != ConnectionState.done) {
          return Center(
            child: CircularProgressIndicator(color: pal.accent, strokeWidth: 2),
          );
        }
        if (snap.hasError) {
          return _panel(
            icon: Icons.cloud_off_rounded,
            title: 'Сервер не ответил',
            text: '${snap.error}',
            action: _reload,
          );
        }
        final List<SubsonicAlbum> albums = snap.data ?? const <SubsonicAlbum>[];
        if (albums.isEmpty) {
          return _panel(
            icon: Icons.library_music_outlined,
            title: 'Библиотека пуста',
            text: 'На сервере нет альбомов — добавь музыку в папку и запусти '
                'сканирование в Navidrome.',
            action: _reload,
          );
        }
        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(18, 6, 18, 100),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 190,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 0.70,
          ),
          itemCount: albums.length,
          itemBuilder: (BuildContext context, int i) => _AlbumCard(
            album: albums[i],
            coverUrl: _client.coverUrl(albums[i].coverArt),
            onTap: () => _openAlbum(context, albums[i]),
          ),
        );
      },
    );
  }

  Widget _panel({
    required IconData icon,
    required String title,
    required String text,
    VoidCallback? action,
  }) {
    final AppPalette pal = widget.scope.palette;
    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
        child: LiquidGlass(
          radius: 22,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(icon, size: 34, color: pal.muted),
              const SizedBox(height: 12),
              Text(title,
                  style: TextStyle(
                      color: pal.text,
                      fontSize: 15,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              Text(text,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: pal.muted, fontSize: 12, height: 1.35)),
              if (action != null) ...<Widget>[
                const SizedBox(height: 14),
                GlassChip(
                  label: 'Повторить',
                  icon: Icons.refresh_rounded,
                  onTap: action,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openAlbum(BuildContext context, SubsonicAlbum album) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      barrierColor: Colors.black54,
      builder: (BuildContext ctx) => BlurDepth(
        value: 2,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: 560,
                  maxHeight: MediaQuery.sizeOf(ctx).height * 0.82,
                ),
                child: _AlbumSheet(
                  client: _client,
                  album: album,
                  player: widget.scope.player,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AlbumCard extends StatelessWidget {
  const _AlbumCard({
    required this.album,
    required this.coverUrl,
    required this.onTap,
  });

  final SubsonicAlbum album;
  final String? coverUrl;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final AppPalette pal = SonoraScope.of(context).palette;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            AspectRatio(
              aspectRatio: 1,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: _cover(pal),
              ),
            ),
            const SizedBox(height: 8),
            Text(album.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    color: pal.text,
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
            Text(
              '${album.artist}${album.songCount > 0 ? ' · ${album.songCount} треков' : ''}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: pal.muted, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cover(AppPalette pal) {
    final String? url = coverUrl;
    if (url == null || url.isEmpty) return ColoredBox(color: pal.bg1);
    return Image.network(
      url,
      fit: BoxFit.cover,
      gaplessPlayback: true,
      errorBuilder: (BuildContext c, Object e, StackTrace? s) =>
          ColoredBox(color: pal.bg1),
      loadingBuilder:
          (BuildContext c, Widget child, ImageChunkEvent? progress) =>
              progress == null ? child : ColoredBox(color: pal.bg1),
    );
  }
}

class _AlbumSheet extends StatefulWidget {
  const _AlbumSheet({
    required this.client,
    required this.album,
    required this.player,
  });

  final SubsonicClient client;
  final SubsonicAlbum album;
  final PlayerController player;

  @override
  State<_AlbumSheet> createState() => _AlbumSheetState();
}

class _AlbumSheetState extends State<_AlbumSheet> {
  late final Future<List<Track>> _future =
      widget.client.getAlbumTracks(widget.album);

  @override
  Widget build(BuildContext context) {
    final AppPalette pal = SonoraScope.of(context).palette;
    return LiquidGlass(
      radius: 26,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
      child: FutureBuilder<List<Track>>(
        future: _future,
        builder: (BuildContext context, AsyncSnapshot<List<Track>> snap) {
          final List<Track> tracks = snap.data ?? const <Track>[];
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(widget.album.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                color: pal.text,
                                fontSize: 15,
                                fontWeight: FontWeight.w700)),
                        Text(
                          '${widget.album.artist}'
                          '${widget.album.year > 0 ? ' · ${widget.album.year}' : ''}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              TextStyle(color: pal.muted, fontSize: 11.5),
                        ),
                      ],
                    ),
                  ),
                  if (tracks.isNotEmpty)
                    GlassChip(
                      label: 'Слушать',
                      icon: Icons.play_arrow_rounded,
                      selected: true,
                      onTap: () {
                        widget.player.playQueue(tracks);
                        Navigator.of(context).maybePop();
                      },
                    ),
                  const SizedBox(width: 6),
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
                child: snap.connectionState != ConnectionState.done
                    ? const Padding(
                        padding: EdgeInsets.all(28),
                        child: SizedBox(
                          width: 26,
                          height: 26,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : snap.hasError
                        ? Padding(
                            padding: const EdgeInsets.all(20),
                            child: Text('${snap.error}',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    color: pal.muted, fontSize: 12)),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            itemCount: tracks.length,
                            itemBuilder: (BuildContext context, int i) =>
                                _row(tracks[i], i, tracks, pal),
                          ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _row(Track t, int i, List<Track> all, AppPalette pal) {
    return InkWell(
      onTap: () {
        widget.player.playQueue(all, startIndex: i);
        Navigator.of(context).maybePop();
      },
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 4),
        child: Row(
          children: <Widget>[
            SizedBox(
              width: 24,
              child: Text('${i + 1}',
                  style: TextStyle(color: pal.muted, fontSize: 11)),
            ),
            Expanded(
              child: Text(t.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: pal.text, fontSize: 13)),
            ),
            const SizedBox(width: 8),
            Text(fmtDuration(t.duration),
                style: TextStyle(color: pal.muted, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}
