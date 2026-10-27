import 'package:flutter/material.dart';

import 'track.dart';

/// Offline demo library. Every track maps to a real bundled WAV file, so the
/// player genuinely plays audio. Streaming providers are represented by the
/// `source` field only (see README: real adapters need OAuth + licences).
class DemoLibrary {
  const DemoLibrary._();

  static const List<Track> tracks = <Track>[
    Track(
      id: 'nd-001',
      title: 'Neon Drift',
      artist: 'Kaito Mori',
      album: 'Nightlines',
      source: MusicSource.navidrome,
      duration: Duration(seconds: 16),
      asset: 'audio/neon_drift.wav',
      colorA: Color(0xFF22D3EE),
      colorB: Color(0xFF6366F1),
      year: 2025,
      bpm: 84,
    ),
    Track(
      id: 'sp-002',
      title: 'Glass Horizon',
      artist: 'Anya Vela',
      album: 'Prisms',
      source: MusicSource.spotify,
      duration: Duration(seconds: 16),
      asset: 'audio/glass_horizon.wav',
      colorA: Color(0xFFA78BFA),
      colorB: Color(0xFF38BDF8),
      year: 2026,
      bpm: 72,
    ),
    Track(
      id: 'sc-003',
      title: 'Midnight Transit',
      artist: 'Low Theory',
      album: 'Line 4',
      source: MusicSource.soundcloud,
      duration: Duration(seconds: 16),
      asset: 'audio/midnight_transit.wav',
      colorA: Color(0xFFF97316),
      colorB: Color(0xFFEF4444),
      year: 2024,
      bpm: 104,
    ),
    Track(
      id: 'yt-004',
      title: 'Paper Sky',
      artist: 'Mira Sonn',
      album: 'Daylight Files',
      source: MusicSource.ytmusic,
      duration: Duration(seconds: 16),
      asset: 'audio/paper_sky.wav',
      colorA: Color(0xFF34D399),
      colorB: Color(0xFFFBBF24),
      year: 2026,
      bpm: 92,
    ),
    Track(
      id: 'ya-005',
      title: 'Low Orbit',
      artist: 'Severny',
      album: 'Тихий сигнал',
      source: MusicSource.yandex,
      duration: Duration(seconds: 16),
      asset: 'audio/low_orbit.wav',
      colorA: Color(0xFF818CF8),
      colorB: Color(0xFF1E1B4B),
      year: 2023,
      bpm: 64,
    ),
    Track(
      id: 'am-006',
      title: 'Velvet Static',
      artist: 'Hollow Coast',
      album: 'Soft Errors',
      source: MusicSource.apple,
      duration: Duration(seconds: 16),
      asset: 'audio/velvet_static.wav',
      colorA: Color(0xFFFB7185),
      colorB: Color(0xFF8B5CF6),
      year: 2025,
      bpm: 78,
    ),
  ];

  static List<Track> get queueAll => tracks;
}

/// Curated collections shown on Home.
class DemoCollections {
  const DemoCollections(this.title, this.subtitle, this.trackIds);

  final String title;
  final String subtitle;
  final List<String> trackIds;

  static const List<DemoCollections> all = <DemoCollections>[
    DemoCollections('Вечерний фокус', 'ambient · 6 треков',
        <String>['nd-001', 'ya-005', 'am-006']),
    DemoCollections('Стеклянные горизонты', 'downtempo · 5 треков',
        <String>['sp-002', 'yt-004', 'nd-001']),
    DemoCollections('Ночная линия', 'deep · 4 трека',
        <String>['sc-003', 'ya-005', 'sp-002']),
    DemoCollections('Утро без спешки', 'chill · 5 треков',
        <String>['yt-004', 'am-006', 'nd-001']),
  ];

  List<Track> resolve() => DemoLibrary.tracks
      .where((Track t) => trackIds.contains(t.id))
      .toList(growable: false);
}
