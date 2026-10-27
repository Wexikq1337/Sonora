import 'package:flutter/foundation.dart';

import '../models/library.dart';
import '../services/local_store.dart';

/// Owns the user's library: favourites, history, playlists.
/// Everything is persisted to `library.json` (debounced), so likes and history
/// survive a restart.
class LibraryController extends ChangeNotifier {
  static const String _fileName = 'library.json';
  static const int historyLimit = 200;

  LibraryData _data = LibraryData.empty();
  final Debouncer _saveDebounce =
      Debouncer(const Duration(milliseconds: 300));

  /// Called after every mutation so the player can re-broadcast its state
  /// (heart buttons listen to [PlayerController]).
  void Function()? onChanged;

  LibraryData get data => _data;
  Set<String> get likedIds => Set<String>.unmodifiable(_data.liked);
  List<UserPlaylist> get playlists => List<UserPlaylist>.unmodifiable(_data.playlists);
  List<HistoryEntry> get history => List<HistoryEntry>.unmodifiable(_data.history);

  bool isLiked(String trackId) => _data.liked.contains(trackId);

  Future<void> load() async {
    final String? raw = await LocalStore.read(_fileName);
    if (raw != null && raw.trim().isNotEmpty) {
      try {
        _data = LibraryData.decode(raw);
      } catch (e) {
        debugPrint('Sonora: library decode failed ($e)');
      }
    }
    notifyListeners();
  }

  void _commit() {
    _saveDebounce.run(() => LocalStore.write(_fileName, _data.encode()));
    notifyListeners();
    onChanged?.call();
  }

  // ---------------------------------------------------------------- favourites
  void toggleLike(String trackId) {
    if (!_data.liked.remove(trackId)) {
      _data.liked.add(trackId);
    }
    _commit();
  }

  // ------------------------------------------------------------------ history
  void logPlay(String trackId) {
    // Collapse repeats: re-playing the same track just bumps the timestamp.
    if (_data.history.isNotEmpty && _data.history.first.trackId == trackId) {
      _data.history[0] = HistoryEntry(trackId: trackId, at: DateTime.now());
    } else {
      _data.history.insert(
          0, HistoryEntry(trackId: trackId, at: DateTime.now()));
      if (_data.history.length > historyLimit) {
        _data.history.removeRange(historyLimit, _data.history.length);
      }
    }
    _commit();
  }

  void clearHistory() {
    _data.history.clear();
    _commit();
  }

  // ---------------------------------------------------------------- playlists
  UserPlaylist createPlaylist(String name) {
    final UserPlaylist p = UserPlaylist(
      id: 'pl-${DateTime.now().microsecondsSinceEpoch}',
      name: name.trim().isEmpty ? 'Новый плейлист' : name.trim(),
    );
    _data.playlists.add(p);
    _commit();
    return p;
  }

  void renamePlaylist(String id, String name) {
    for (final UserPlaylist p in _data.playlists) {
      if (p.id == id) p.name = name.trim().isEmpty ? p.name : name.trim();
    }
    _commit();
  }

  void deletePlaylist(String id) {
    _data.playlists.removeWhere((UserPlaylist p) => p.id == id);
    _commit();
  }

  void addToPlaylist(String playlistId, String trackId) {
    for (final UserPlaylist p in _data.playlists) {
      if (p.id != playlistId) continue;
      if (p.trackIds.contains(trackId)) return;
      p.trackIds.add(trackId);
      _commit();
      return;
    }
  }

  void removeFromPlaylist(String playlistId, String trackId) {
    for (final UserPlaylist p in _data.playlists) {
      if (p.id != playlistId) continue;
      p.trackIds.remove(trackId);
      _commit();
      return;
    }
  }

  @override
  void dispose() {
    _saveDebounce.dispose();
    super.dispose();
  }
}
