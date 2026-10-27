import 'dart:convert';
import 'dart:io';
import 'dart:ui' show Color;

import '../../models/track.dart';

/// SoundCloud (unofficial web API, "bring your own client_id").
///
/// Public API registration is closed for new apps, so the app asks the user
/// for a client_id (or finds the public one automatically). Playback resolves
/// a `progressive` transcoding to a direct MP3 URL that audioplayers can play.
///
/// ⚠️ This is not an official Spotify-style SDK; SoundCloud ToS restrict
/// third-party clients. Use it for your own library / personal use.
class SoundCloudService {
  SoundCloudService(this.clientId);

  final String clientId;

  static const String _ua =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) Sonora/1.0';
  static const String _api = 'https://api-v2.soundcloud.com';

  final HttpClient _http = HttpClient()
    ..connectionTimeout = const Duration(seconds: 8);

  void dispose() => _http.close(force: true);

  Future<String> _get(String url) async {
    final HttpClientRequest req = await _http.getUrl(Uri.parse(url));
    req.headers.set(HttpHeaders.userAgentHeader, _ua);
    req.headers.set(HttpHeaders.acceptHeader, 'application/json');
    final HttpClientResponse res =
        await req.close().timeout(const Duration(seconds: 10));
    final String body = await res
        .transform(utf8.decoder)
        .join()
        .timeout(const Duration(seconds: 15));
    if (res.statusCode >= 400) {
      throw Exception('SoundCloud HTTP ${res.statusCode}');
    }
    return body;
  }

  /// Scrapes the public web player bundle for a `client_id`.
  static Future<String?> detectClientId() async {
    final HttpClient http = HttpClient()
      ..connectionTimeout = const Duration(seconds: 8);
    try {
      final HttpClientRequest req =
          await http.getUrl(Uri.parse('https://soundcloud.com/'));
      req.headers.set(HttpHeaders.userAgentHeader, _ua);
      final HttpClientResponse res = await req.close();
      final String html = await res.transform(utf8.decoder).join();

      final RegExp scripts =
          RegExp(r'<script[^>]+src="(https://a-v2\.sndcdn\.com/assets/[^"]+\.js)"');
      final List<RegExpMatch> matches = scripts.allMatches(html).toList();
      // The client id lives in one of the later bundles; three tries is enough.
      for (final RegExpMatch m in matches.reversed.take(3)) {
        final String js = await _plain(http, m.group(1)!);
        final RegExpMatch? id =
            RegExp(r'client_id\s*[:=]\s*"([a-zA-Z0-9]{20,40})"').firstMatch(js);
        if (id != null) return id.group(1);
      }
      return null;
    } catch (_) {
      return null;
    } finally {
      http.close(force: true);
    }
  }

  static Future<String> _plain(HttpClient http, String url) async {
    final HttpClientRequest req = await http.getUrl(Uri.parse(url));
    req.headers.set(HttpHeaders.userAgentHeader, _ua);
    final HttpClientResponse res = await req.close();
    return res.transform(utf8.decoder).join();
  }

  Future<List<Track>> search(String query, {int limit = 20}) async {
    if (clientId.isEmpty) throw Exception('Не задан SoundCloud client_id');
    final String url = '$_api/search/tracks'
        '?q=${Uri.encodeQueryComponent(query)}'
        '&client_id=$clientId&limit=$limit&linked_partitioning=1';
    final Map<String, dynamic> json =
        jsonDecode(await _get(url)) as Map<String, dynamic>;
    final List<dynamic> items = json['collection'] as List<dynamic>? ?? <dynamic>[];
    return items
        .whereType<Map<String, dynamic>>()
        .map(_toTrack)
        .whereType<Track>()
        .toList(growable: false);
  }

  Track? _toTrack(Map<String, dynamic> j) {
    final String? streamEndpoint = _progressiveUrl(j);
    if (streamEndpoint == null) return null; // HLS-only track: skip
    final String id = '${j['id']}';
    String? art = j['artwork_url']?.toString();
    if (art == null) {
      final Map<String, dynamic>? user =
          j['user'] as Map<String, dynamic>?;
      art = user?['avatar_url']?.toString();
    }
    art = art?.replaceAll('-large', '-t500x500');

    return Track(
      id: 'sc:$id',
      title: '${j['title'] ?? 'Без названия'}',
      artist: (j['user'] as Map<String, dynamic>?)?['username']?.toString() ??
          'SoundCloud',
      album: 'SoundCloud',
      source: MusicSource.soundcloud,
      duration: Duration(milliseconds: (j['duration'] as num?)?.toInt() ?? 0),
      asset: '',
      colorA: const Color(0xFFFF5500),
      colorB: const Color(0xFFFF8A00),
      url: streamEndpoint,
      artUrl: art,
      streamResolver: () => resolveStream(streamEndpoint),
    );
  }

  static String? _progressiveUrl(Map<String, dynamic> j) {
    final List<dynamic> t =
        j['media']?['transcodings'] as List<dynamic>? ?? <dynamic>[];
    for (final dynamic raw in t) {
      if (raw is! Map<String, dynamic>) continue;
      final Map<String, dynamic>? format =
          raw['format'] as Map<String, dynamic>?;
      final String? protocol = format?['protocol']?.toString();
      if (protocol == 'progressive') {
        final String? u = raw['url']?.toString();
        if (u != null) return u;
      }
    }
    return null;
  }

  /// Two-step resolve: transcoding endpoint → direct MP3 URL.
  Future<String> resolveStream(String endpoint) async {
    final String body =
        await _get('$endpoint${endpoint.contains('?') ? '&' : '?'}client_id=$clientId');
    final dynamic decoded = jsonDecode(body);
    if (decoded is Map<String, dynamic>) {
      final dynamic url = decoded['url'];
      if (url is String && url.isNotEmpty) return url;
    }
    throw Exception('SoundCloud не отдал поток (трек с защитой лейбла)');
  }
}
