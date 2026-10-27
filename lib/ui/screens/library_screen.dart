import 'package:flutter/material.dart';

import '../../app_scope.dart';
import '../../core/palette.dart';
import '../../models/demo_library.dart';
import '../../models/track.dart';
import '../animations/motion.dart';
import '../glass/glass.dart';
import '../widgets/artwork.dart';
import '../widgets/track_tile.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

enum _LibTab { tracks, playlists, artists }

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
                    _LibTab.playlists => _playlists(scope),
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
