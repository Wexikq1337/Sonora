import 'dart:convert';

/// User-owned library data: favourites, play history and (later) playlists.
/// Persisted as JSON next to settings.json — no plugins, no database.
class HistoryEntry {
  const HistoryEntry({required this.trackId, required this.at});

  final String trackId;
  final DateTime at;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': trackId,
        'at': at.millisecondsSinceEpoch,
      };

  factory HistoryEntry.fromJson(Map<String, dynamic> j) => HistoryEntry(
        trackId: '${j['id']}',
        at: DateTime.fromMillisecondsSinceEpoch(
            (j['at'] as num?)?.toInt() ?? 0),
      );
}

class UserPlaylist {
  UserPlaylist({
    required this.id,
    required this.name,
    List<String>? trackIds,
    DateTime? createdAt,
  })  : trackIds = trackIds ?? <String>[],
        createdAt = createdAt ?? DateTime.now();

  final String id;
  String name;
  final List<String> trackIds;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'name': name,
        'tracks': trackIds,
        'createdAt': createdAt.millisecondsSinceEpoch,
      };

  factory UserPlaylist.fromJson(Map<String, dynamic> j) => UserPlaylist(
        id: '${j['id']}',
        name: '${j['name'] ?? 'Плейлист'}',
        trackIds: (j['tracks'] as List<dynamic>? ?? <dynamic>[])
            .map((dynamic e) => '$e')
            .toList(),
        createdAt: DateTime.fromMillisecondsSinceEpoch(
            (j['createdAt'] as num?)?.toInt() ?? 0),
      );
}

class LibraryData {
  LibraryData({
    Set<String>? liked,
    List<HistoryEntry>? history,
    List<UserPlaylist>? playlists,
  })  : liked = liked ?? <String>{},
        history = history ?? <HistoryEntry>[],
        playlists = playlists ?? <UserPlaylist>[];

  final Set<String> liked;
  final List<HistoryEntry> history;
  final List<UserPlaylist> playlists;

  static LibraryData empty() => LibraryData();

  Map<String, dynamic> toJson() => <String, dynamic>{
        'liked': liked.toList(),
        'history': history.map((HistoryEntry e) => e.toJson()).toList(),
        'playlists':
            playlists.map((UserPlaylist p) => p.toJson()).toList(),
      };

  static LibraryData decode(String raw) {
    final dynamic decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) return LibraryData.empty();
    return LibraryData(
      liked: (decoded['liked'] as List<dynamic>? ?? <dynamic>[])
          .map((dynamic e) => '$e')
          .toSet(),
      history: (decoded['history'] as List<dynamic>? ?? <dynamic>[])
          .whereType<Map<String, dynamic>>()
          .map(HistoryEntry.fromJson)
          .toList(),
      playlists: (decoded['playlists'] as List<dynamic>? ?? <dynamic>[])
          .whereType<Map<String, dynamic>>()
          .map(UserPlaylist.fromJson)
          .toList(),
    );
  }

  String encode() => const JsonEncoder.withIndent('  ').convert(toJson());
}
