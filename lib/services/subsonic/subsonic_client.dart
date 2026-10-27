import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:ui' show Color;

import 'package:crypto/crypto.dart';

import '../../models/settings.dart';
import '../../models/track.dart';

class SubsonicException implements Exception {
  SubsonicException(this.message, {this.code});

  final String message;
  final int? code;

  @override
  String toString() => message;
}

class SubsonicAlbum {
  const SubsonicAlbum({
    required this.id,
    required this.name,
    required this.artist,
    this.year = 0,
    this.songCount = 0,
    this.coverArt,
  });

  final String id;
  final String name;
  final String artist;
  final int year;
  final int songCount;
  final String? coverArt;

  factory SubsonicAlbum.fromJson(Map<String, dynamic> j) => SubsonicAlbum(
        id: '${j['id']}',
        name: '${j['name'] ?? j['title'] ?? 'Альбом'}',
        artist: '${j['artist'] ?? ''}',
        year: (j['year'] as num?)?.toInt() ?? 0,
        songCount: (j['songCount'] as num?)?.toInt() ?? 0,
        coverArt: j['coverArt']?.toString(),
      );
}

/// Minimal Subsonic API client (works with Navidrome, Airsonic, Gonic, …).
/// Auth follows the spec: `t = md5(password + salt)`, sent with `s` and `u`.
class SubsonicClient {
  SubsonicClient(this.config) : _salt = _makeSalt();

  final ServerSettings config;

  static const String _apiVersion = '1.16.1';
  static const String _clientName = 'Sonora';
  static final Random _rnd = Random.secure();

  final String _salt;

  static const List<List<Color>> _palettes = <List<Color>>[
    <Color>[Color(0xFF22D3EE), Color(0xFF6366F1)],
    <Color>[Color(0xFFA78BFA), Color(0xFF38BDF8)],
    <Color>[Color(0xFFF97316), Color(0xFFEF4444)],
    <Color>[Color(0xFF34D399), Color(0xFFFBBF24)],
    <Color>[Color(0xFFFB7185), Color(0xFF8B5CF6)],
    <Color>[Color(0xFF818CF8), Color(0xFF1E1B4B)],
  ];

  static String _makeSalt() {
    const String chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    return List<String>.generate(
            10, (_) => chars[_rnd.nextInt(chars.length)]).join();
  }

  String get _base {
    String u = config.url.trim();
    if (u.isEmpty) return '';
    if (!u.startsWith('http://') && !u.startsWith('https://')) {
      u = 'http://$u';
    }
    while (u.endsWith('/')) {
      u = u.substring(0, u.length - 1);
    }
    return u;
  }

  Map<String, String> get _auth => <String, String>{
        'u': config.user,
        't': md5.convert(utf8.encode('${config.password}$_salt')).toString(),
        's': _salt,
        'v': _apiVersion,
        'c': _clientName,
        'f': 'json',
      };

  Uri _uri(String method, [Map<String, String> extra = const <String, String>{}]) =>
      Uri.parse('$_base/rest/$method')
          .replace(queryParameters: <String, String>{..._auth, ...extra});

  String streamUrl(String songId) => _uri('stream.view', <String, String>{
        'id': songId,
        'maxBitRate': '320',
      }).toString();

  String? coverUrl(String? coverArtId, {int size = 320}) {
    if (coverArtId == null || coverArtId.isEmpty) return null;
    return _uri('getCoverArt.view', <String, String>{
      'id': coverArtId,
      'size': '$size',
    }).toString();
  }

  Future<Map<String, dynamic>> _get(String method,
      [Map<String, String> extra = const <String, String>{}]) async {
    if (_base.isEmpty) throw SubsonicException('Не указан адрес сервера');
    final HttpClient client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 6);
    try {
      final HttpClientRequest req = await client
          .getUrl(_uri(method, extra))
          .timeout(const Duration(seconds: 8));
      final HttpClientResponse res =
          await req.close().timeout(const Duration(seconds: 8));
      final String body = await res
          .transform(utf8.decoder)
          .join()
          .timeout(const Duration(seconds: 12));

      final dynamic decoded = jsonDecode(body);
      if (decoded is! Map<String, dynamic>) {
        throw SubsonicException(
            'Сервер вернул не JSON. Это точно Subsonic/Navidrome?');
      }
      final dynamic rootRaw = decoded['subsonic-response'];
      if (rootRaw is! Map<String, dynamic>) {
        throw SubsonicException(
            'В ответе нет subsonic-response — проверь адрес (обычно :4533)');
      }
      if (rootRaw['status'] != 'ok') {
        final dynamic err = rootRaw['error'];
        final String msg = err is Map
            ? '${err['message'] ?? 'ошибка сервера'}'
            : 'Сервер вернул ошибку';
        throw SubsonicException(msg,
            code: err is Map ? (err['code'] as num?)?.toInt() : null);
      }
      return rootRaw;
    } on SocketException catch (e) {
      throw SubsonicException('Нет связи с ${_base}: ${e.message}');
    } on HttpException catch (e) {
      throw SubsonicException('HTTP-ошибка: ${e.message}');
    } finally {
      client.close(force: true);
    }
  }

  /// Returns a human readable server description, throws on failure.
  Future<String> ping() async {
    final Map<String, dynamic> root = await _get('ping.view');
    return 'Subsonic API ${root['version'] ?? _apiVersion}';
  }

  Future<List<SubsonicAlbum>> getAlbums({
    String type = 'newest',
    int size = 40,
  }) async {
    final Map<String, dynamic> root =
        await _get('getAlbumList2.view', <String, String>{
      'type': type,
      'size': '$size',
    });
    final dynamic list = (root['albumList2'] as Map<String, dynamic>?)?['album'];
    if (list is! List) return <SubsonicAlbum>[];
    return list
        .whereType<Map<String, dynamic>>()
        .map(SubsonicAlbum.fromJson)
        .toList(growable: false);
  }

  Future<List<Track>> getAlbumTracks(SubsonicAlbum album) async {
    final Map<String, dynamic> root =
        await _get('getAlbum.view', <String, String>{'id': album.id});
    final dynamic songs = (root['album'] as Map<String, dynamic>?)?['song'];
    if (songs is! List) return <Track>[];
    return songs
        .whereType<Map<String, dynamic>>()
        .map((Map<String, dynamic> s) => _toTrack(s, album))
        .toList(growable: false);
  }

  Future<List<Track>> search(String query, {int limit = 40}) async {
    if (query.trim().isEmpty) return <Track>[];
    final Map<String, dynamic> root =
        await _get('search3.view', <String, String>{
      'query': query,
      'songCount': '$limit',
      'albumCount': '0',
      'artistCount': '0',
    });
    final dynamic songs =
        (root['searchResult3'] as Map<String, dynamic>?)?['song'];
    if (songs is! List) return <Track>[];
    return songs
        .whereType<Map<String, dynamic>>()
        .map((Map<String, dynamic> s) => _toTrack(s, null))
        .toList(growable: false);
  }

  Future<void> scrobble(String songId, {bool submission = true}) async {
    // Fire and forget: never block playback on a scrobble.
    try {
      await _get('scrobble.view', <String, String>{
        'id': songId,
        'submission': submission ? 'true' : 'false',
      });
    } catch (_) {
      // Ignore: scrobbling is best effort.
    }
  }

  Track _toTrack(Map<String, dynamic> s, SubsonicAlbum? album) {
    final String id = '${s['id']}';
    final List<Color> pair = _palettes[id.hashCode.abs() % _palettes.length];
    final String? cover =
        (s['coverArt'] ?? album?.coverArt)?.toString();
    final int seconds = (s['duration'] as num?)?.toInt() ?? 0;
    return Track(
      id: 'sub:$id',
      title: '${s['title'] ?? 'Без названия'}',
      artist: '${s['artist'] ?? album?.artist ?? 'Неизвестный артист'}',
      album: '${s['album'] ?? album?.name ?? ''}',
      source: MusicSource.navidrome,
      duration: Duration(seconds: seconds),
      asset: '',
      colorA: pair[0],
      colorB: pair[1],
      year: album?.year ?? 0,
      url: streamUrl(id),
      artUrl: coverUrl(cover),
    );
  }
}
