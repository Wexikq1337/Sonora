import 'dart:async';

import 'package:flutter/material.dart';

import '../../app_scope.dart';
import '../../core/palette.dart';
import '../../models/demo_library.dart';
import '../../models/track.dart';
import '../../services/soundcloud/soundcloud_service.dart';
import '../animations/motion.dart';
import '../glass/glass.dart';
import '../widgets/track_tile.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focus = FocusNode();
  final Set<MusicSource> _sources = MusicSource.values.toSet();

  String _query = '';
  bool _searching = false;
  Timer? _debounce;

  List<Track> _scResults = <Track>[];
  bool _scLoading = false;
  String? _scError;
  String _scFor = '';

  Future<void> _runSoundCloud(SonoraScope scope, String q) async {
    final String cid = scope.s.soundcloudClientId.trim();
    if (q.length < 2 || cid.isEmpty) {
      setState(() {
        _scResults = <Track>[];
        _scLoading = false;
        _scError = q.length >= 2 && cid.isEmpty
            ? 'SoundCloud: добавь client_id в Настройки → Источники'
            : null;
      });
      return;
    }
    if (_scFor == q) return;
    _scFor = q;
    setState(() {
      _scLoading = true;
      _scError = null;
    });
    final SoundCloudService svc = SoundCloudService(cid);
    try {
      final List<Track> r = await svc.search(q);
      if (!mounted || _scFor != q) return;
      setState(() {
        _scResults = r;
        _scLoading = false;
      });
    } catch (e) {
      if (!mounted || _scFor != q) return;
      setState(() {
        _scLoading = false;
        _scError = '$e';
        _scResults = <Track>[];
      });
    } finally {
      svc.dispose();
    }
  }

  static const List<String> _suggestions = <String>[
    'ambient',
    'night',
    'Navidrome',
    'Kaito Mori',
    'chill',
    '2026',
  ];

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    final String q = value.trim();
    setState(() {
      _query = q;
      _searching = q.isNotEmpty;
    });
    _debounce = Timer(const Duration(milliseconds: 280), () {
      if (!mounted) return;
      setState(() => _searching = false);
      _runSoundCloud(SonoraScope.of(context), q);
    });
  }

  List<Track> get _results {
    if (_query.isEmpty) return const <Track>[];
    final String q = _query.toLowerCase();
    return DemoLibrary.tracks
        .where((Track t) => _sources.contains(t.source))
        .where((Track t) =>
            t.title.toLowerCase().contains(q) ||
            t.artist.toLowerCase().contains(q) ||
            t.album.toLowerCase().contains(q) ||
            t.source.label.toLowerCase().contains(q) ||
            '${t.year}'.contains(q) ||
            '${t.bpm}'.contains(q))
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final SonoraScope scope = SonoraScope.of(context);
    final AppPalette pal = scope.palette;
    final List<Track> results = _results;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Text('Поиск',
                      style: TextStyle(
                          color: pal.text,
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.6)),
                  const SizedBox(height: 4),
                  Text('Один запрос — все подключённые источники',
                      style: TextStyle(color: pal.muted, fontSize: 12.5)),
                  const SizedBox(height: 14),
                  LiquidGlass(
                    radius: 18,
                    opacityScale: 1.15,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Row(
                      children: <Widget>[
                        Icon(Icons.search_rounded, size: 20, color: pal.accent),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            focusNode: _focus,
                            onChanged: _onChanged,
                            style: TextStyle(color: pal.text, fontSize: 15),
                            cursorColor: pal.accent,
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding:
                                  const EdgeInsets.symmetric(vertical: 15),
                              hintText: 'Трек, артист, альбом, источник…',
                              hintStyle:
                                  TextStyle(color: pal.muted.withOpacity(0.8)),
                            ),
                          ),
                        ),
                        if (_query.isNotEmpty)
                          GlassIconButton(
                            icon: Icons.close_rounded,
                            size: 30,
                            iconSize: 15,
                            onTap: () {
                              _controller.clear();
                              _onChanged('');
                            },
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 7,
                    runSpacing: 7,
                    children: <Widget>[
                      for (final MusicSource s in MusicSource.values)
                        GlassChip(
                          label: s.short,
                          dense: true,
                          icon: s.icon,
                          selected: _sources.contains(s),
                          onTap: () => setState(() {
                            if (_sources.contains(s)) {
                              if (_sources.length > 1) _sources.remove(s);
                            } else {
                              _sources.add(s);
                            }
                          }),
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
              constraints: const BoxConstraints(maxWidth: 900),
              child: _body(scope, results),
            ),
          ),
        ),
      ],
    );
  }

  Widget _body(SonoraScope scope, List<Track> results) {
    if (_query.isEmpty) return _idle(scope);
    if (_searching) return _skeleton();
    if (results.isEmpty &&
        _scResults.isEmpty &&
        !_scLoading &&
        _scError == null) {
      return _empty(scope);
    }

    final bool hasLocal = results.isNotEmpty;
    final int count = (hasLocal ? results.length : 0) + 2;

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(18, 6, 18, 100),
      itemCount: count,
      itemBuilder: (BuildContext context, int i) {
        if (i == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 6, left: 4),
            child: Text(
              hasLocal
                  ? 'Локально · ${results.length} · SoundCloud ниже'
                  : 'Результаты SoundCloud',
              style: TextStyle(
                  color: SonoraScope.of(context).palette.muted, fontSize: 11.5),
            ),
          );
        }
        if (hasLocal && i <= results.length) {
          final Track t = results[i - 1];
          return Appear(
            delayMs: i * 30,
            child: ListenableBuilder(
              listenable: scope.player,
              builder: (BuildContext context, _) => TrackTile(
                track: t,
                playing:
                    scope.player.current?.id == t.id && scope.player.playing,
                onPlay: () =>
                    scope.player.playQueue(results, startIndex: i - 1),
              ),
            ),
          );
        }
        return _soundCloudSection(scope);
      },
    );
  }

  Widget _soundCloudSection(SonoraScope scope) {
    final AppPalette pal = scope.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 14, 4, 6),
          child: Row(
            children: <Widget>[
              const Icon(Icons.cloud_rounded,
                  size: 15, color: Color(0xFFFF5500)),
              const SizedBox(width: 6),
              Text('SoundCloud',
                  style: TextStyle(
                      color: pal.muted,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6)),
              const Spacer(),
              if (_scLoading)
                const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 1.6)),
            ],
          ),
        ),
        if (_scError != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            child: Text(_scError!,
                style: TextStyle(color: pal.muted, fontSize: 11.5)),
          )
        else if (!_scLoading && _scResults.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            child: Text('Ничего не найдено в SoundCloud',
                style: TextStyle(color: pal.muted, fontSize: 11.5)),
          )
        else
          for (int i = 0; i < _scResults.length; i++)
            Appear(
              delayMs: i * 25,
              child: ListenableBuilder(
                listenable: scope.player,
                builder: (BuildContext context, _) => TrackTile(
                  track: _scResults[i],
                  playing: scope.player.current?.id == _scResults[i].id &&
                      scope.player.playing,
                  onPlay: () =>
                      scope.player.playQueue(_scResults, startIndex: i),
                ),
              ),
            ),
      ],
    );
  }

  Widget _idle(SonoraScope scope) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 100),
      children: <Widget>[
        Appear(
          child: SectionHeader(
            title: 'Попробуйте',
            icon: Icons.bolt_rounded,
          ),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            for (final String s in _suggestions)
              GlassChip(
                label: s,
                onTap: () {
                  _controller.text = s;
                  _onChanged(s);
                },
              ),
          ],
        ),
        const SizedBox(height: 24),
        Appear(
          delayMs: 80,
          child: SectionHeader(
            title: 'Источники',
            icon: Icons.device_hub_rounded,
          ),
        ),
        for (int i = 0; i < MusicSource.values.length; i++)
          Appear(
            delayMs: 120 + i * 40,
            child: _SourceRow(
              source: MusicSource.values[i],
              connected: i < 3,
              enabled: _sources.contains(MusicSource.values[i]),
            ),
          ),
      ],
    );
  }

  Widget _skeleton() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 100),
      itemCount: 6,
      itemBuilder: (BuildContext context, int i) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          children: <Widget>[
            Shimmer(width: 44, height: 44, radius: 10),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Shimmer(width: 180 + (i * 23) % 90, height: 12),
                  const SizedBox(height: 8),
                  Shimmer(width: 120, height: 10),
                ],
              ),
            ),
            Shimmer(width: 34, height: 10),
          ],
        ),
      ),
    );
  }

  Widget _empty(SonoraScope scope) {
    final AppPalette pal = scope.palette;
    return Center(
      child: LiquidGlass(
        radius: 22,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(Icons.search_off_rounded, size: 34, color: pal.muted),
            const SizedBox(height: 10),
            Text('Ничего не найдено',
                style: TextStyle(
                    color: pal.text, fontSize: 15, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text('Попробуйте другой запрос или включите больше источников',
                textAlign: TextAlign.center,
                style: TextStyle(color: pal.muted, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class _SourceRow extends StatelessWidget {
  const _SourceRow({
    required this.source,
    required this.connected,
    required this.enabled,
  });

  final MusicSource source;
  final bool connected;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final AppPalette pal = SonoraScope.of(context).palette;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
      child: LiquidGlass(
        radius: 14,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: <Widget>[
            Icon(source.icon, size: 18, color: source.color),
            const SizedBox(width: 12),
            Expanded(
              child: Text(source.label,
                  style: TextStyle(
                      color: enabled ? pal.text : pal.muted,
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
            ),
            Text(
              connected ? 'подключён' : 'не подключён',
              style: TextStyle(
                  color: connected
                      ? const Color(0xFF57F287)
                      : pal.muted.withOpacity(0.7),
                  fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}
