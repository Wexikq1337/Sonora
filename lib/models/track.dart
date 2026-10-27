import 'package:flutter/material.dart';

/// Music providers. In this build most of them are *display-only* (demo data):
/// the real adapters require OAuth + licences, see README.
enum MusicSource { navidrome, spotify, soundcloud, ytmusic, apple, yandex, vk, local }

extension MusicSourceX on MusicSource {
  String get label {
    switch (this) {
      case MusicSource.navidrome:
        return 'Navidrome';
      case MusicSource.spotify:
        return 'Spotify';
      case MusicSource.soundcloud:
        return 'SoundCloud';
      case MusicSource.ytmusic:
        return 'YouTube Music';
      case MusicSource.apple:
        return 'Apple Music';
      case MusicSource.yandex:
        return 'Яндекс Музыка';
      case MusicSource.vk:
        return 'VK Музыка';
      case MusicSource.local:
        return 'Локальные файлы';
    }
  }

  String get short {
    switch (this) {
      case MusicSource.navidrome:
        return 'ND';
      case MusicSource.spotify:
        return 'SP';
      case MusicSource.soundcloud:
        return 'SC';
      case MusicSource.ytmusic:
        return 'YT';
      case MusicSource.apple:
        return 'AM';
      case MusicSource.yandex:
        return 'YA';
      case MusicSource.vk:
        return 'VK';
      case MusicSource.local:
        return 'LOC';
    }
  }

  /// Discord rich-presence asset key for the small (source) icon.
  /// Must match an art asset uploaded to the Discord application, otherwise
  /// Discord silently ignores it.
  String get discordAssetKey => 'src_$short'.toLowerCase();

  Color get color {
    switch (this) {
      case MusicSource.navidrome:
        return const Color(0xFF22D3EE);
      case MusicSource.spotify:
        return const Color(0xFF1DB954);
      case MusicSource.soundcloud:
        return const Color(0xFFFF5500);
      case MusicSource.ytmusic:
        return const Color(0xFFFF0033);
      case MusicSource.apple:
        return const Color(0xFFFA243C);
      case MusicSource.yandex:
        return const Color(0xFFFFCC00);
      case MusicSource.vk:
        return const Color(0xFF0077FF);
      case MusicSource.local:
        return const Color(0xFF94A3B8);
    }
  }

  IconData get icon {
    switch (this) {
      case MusicSource.navidrome:
        return Icons.dns_rounded;
      case MusicSource.spotify:
        return Icons.graphic_eq_rounded;
      case MusicSource.soundcloud:
        return Icons.cloud_rounded;
      case MusicSource.ytmusic:
        return Icons.play_circle_fill_rounded;
      case MusicSource.apple:
        return Icons.audiotrack_rounded;
      case MusicSource.yandex:
        return Icons.language_rounded;
      case MusicSource.vk:
        return Icons.forum_rounded;
      case MusicSource.local:
        return Icons.folder_rounded;
    }
  }

  static MusicSource fromName(String name) =>
      MusicSource.values.firstWhere((MusicSource s) => s.name == name,
          orElse: () => MusicSource.local);
}

/// Immutable track model.
class Track {
  const Track({
    required this.id,
    required this.title,
    required this.artist,
    required this.album,
    required this.source,
    required this.duration,
    required this.asset,
    required this.colorA,
    required this.colorB,
    this.year = 2026,
    this.bpm = 90,
    this.liked = false,
    this.url,
    this.artUrl,
    this.streamResolver,
  });

  final String id;
  final String title;
  final String artist;
  final String album;
  final MusicSource source;
  final Duration duration;

  /// Path inside `assets/`, e.g. `audio/neon_drift.wav`.
  final String asset;

  /// Remote stream URL (Subsonic/Navidrome). When set, [asset] is ignored.
  final String? url;

  /// Remote cover art URL (already includes auth params).
  final String? artUrl;

  /// Some providers (SoundCloud) need a second request to turn a transcoding
  /// endpoint into a direct media URL. Resolved lazily right before playback.
  final Future<String> Function()? streamResolver;

  Future<String> resolveStream() async {
    final Future<String> Function()? r = streamResolver;
    if (r != null) return r();
    return url ?? '';
  }

  /// Palette used to render procedural cover art (no bitmaps shipped).
  final Color colorA;
  final Color colorB;
  final int year;
  final int bpm;
  final bool liked;

  bool get isRemote => url != null && url!.isNotEmpty;

  Track copyWith({bool? liked}) => Track(
        id: id,
        title: title,
        artist: artist,
        album: album,
        source: source,
        duration: duration,
        asset: asset,
        colorA: colorA,
        colorB: colorB,
        year: year,
        bpm: bpm,
        liked: liked ?? this.liked,
        url: url,
        artUrl: artUrl,
        streamResolver: streamResolver,
      );
}
