import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../audio/audio_engine.dart';
import '../models/demo_library.dart';
import '../models/track.dart';
import 'library_controller.dart';
import 'settings_controller.dart';

enum LoopMode { off, all, one }

/// Playback state machine. Owns the queue and the transport; favourites and
/// history live in [LibraryController].
class PlayerController extends ChangeNotifier {
  PlayerController(this._settings, this._library);

  final SettingsController _settings;
  final LibraryController _library;
  final Random _random = Random();

  AudioEngine? _engine;
  StreamSubscription<Duration>? _posSub;
  StreamSubscription<void>? _doneSub;

  List<Track> _queue = <Track>[];
  int _index = 0;
  bool _playing = false;
  bool _shuffle = false;
  LoopMode _loop = LoopMode.all;
  String? _error;
  String? _loadedId;
  bool _audioAvailable = false;
  String _engineKind = 'инициализация…';

  final ValueNotifier<Duration> position =
      ValueNotifier<Duration>(Duration.zero);

  List<Track> get queue => List<Track>.unmodifiable(_queue);
  int get index => _index;
  bool get playing => _playing;
  bool get shuffle => _shuffle;
  LoopMode get loop => _loop;
  bool get audioAvailable => _audioAvailable;
  String get engineKind => _engineKind;
  String? get error => _error;
  Set<String> get liked => _library.likedIds;

  Track? get current =>
      (_queue.isEmpty || _index < 0 || _index >= _queue.length) ? null : _queue[_index];

  Duration get duration => current?.duration ?? Duration.zero;

  double get progress {
    final int total = duration.inMilliseconds;
    if (total <= 0) return 0;
    return (position.value.inMilliseconds / total).clamp(0.0, 1.0).toDouble();
  }

  bool isLiked(String id) => _library.isLiked(id);

  Future<void> init() async {
    final AudioplayersEngine real = AudioplayersEngine();
    bool ok = false;
    try {
      ok = await real.init();
    } catch (e) {
      debugPrint('Sonora: real audio engine failed: $e');
    }
    if (ok) {
      _engine = real;
      _audioAvailable = true;
      _engineKind = real.kind;
    } else {
      await real.dispose().catchError((Object _) {});
      final SimulatedEngine sim = SimulatedEngine();
      await sim.init();
      _engine = sim;
      _audioAvailable = false;
      _engineKind = sim.kind;
    }
    _bindEngine(_engine!);
    await _engine!.setVolume(_settings.value.volume);
    _queue = List<Track>.of(DemoLibrary.tracks);
    _index = 0;
    notifyListeners();
  }

  void _bindEngine(AudioEngine engine) {
    _posSub?.cancel();
    _doneSub?.cancel();
    _posSub = engine.positions.listen((Duration d) {
      if (d > duration && duration > Duration.zero) return;
      position.value = d;
    });
    _doneSub = engine.completions.listen((_) => next(auto: true));
  }

  Future<void> playQueue(List<Track> tracks, {int startIndex = 0}) async {
    if (tracks.isEmpty) return;
    _queue = List<Track>.of(tracks);
    _index = startIndex.clamp(0, _queue.length - 1).toInt();
    await _loadCurrent();
  }

  Future<void> _loadCurrent() async {
    final Track? t = current;
    if (t == null) return;
    _error = null;
    position.value = Duration.zero;
    try {
      await _engine?.load(t.isRemote ? t.url! : t.asset, t.duration,
          remote: t.isRemote);
      await _engine?.setVolume(_settings.value.volume);
      await _engine?.play();
      _playing = true;
      _loadedId = t.id;
      _library.logPlay(t.id);
    } catch (e) {
      _error = '$e';
      _playing = false;
    }
    notifyListeners();
  }

  Future<void> toggle() async {
    final Track? t = current;
    if (t == null) {
      await playQueue(DemoLibrary.tracks);
      return;
    }
    // Nothing loaded yet (first interaction / after a failed load):
    // perform a full load instead of trying to resume an empty source.
    if (_loadedId != t.id) {
      await _loadCurrent();
      return;
    }
    if (_playing) {
      await _engine?.pause();
      _playing = false;
    } else {
      await _engine?.play();
      _playing = true;
    }
    notifyListeners();
  }

  Future<void> playTrack(Track t) async {
    final int i = _queue.indexWhere((Track x) => x.id == t.id);
    if (i >= 0) {
      _index = i;
      await _loadCurrent();
    } else {
      await playQueue(<Track>[t]);
    }
  }

  Future<void> next({bool auto = false}) async {
    if (_queue.isEmpty) return;
    if (auto && _loop == LoopMode.one) {
      await _engine?.seek(Duration.zero);
      await _engine?.play();
      _playing = true;
      notifyListeners();
      return;
    }
    int nextIndex = _index + 1;
    if (_shuffle && _queue.length > 1) {
      do {
        nextIndex = _random.nextInt(_queue.length);
      } while (nextIndex == _index);
    }
    if (nextIndex >= _queue.length) {
      if (_loop == LoopMode.off && auto) {
        _playing = false;
        position.value = Duration.zero;
        await _engine?.pause();
        notifyListeners();
        return;
      }
      nextIndex = 0;
    }
    _index = nextIndex;
    await _loadCurrent();
  }

  Future<void> previous() async {
    if (_queue.isEmpty) return;
    final int nextIndex = _index - 1 < 0 ? _queue.length - 1 : _index - 1;
    _index = nextIndex;
    await _loadCurrent();
  }

  Future<void> seek(Duration d) async {
    final Duration max = duration;
    Duration target = d;
    if (target < Duration.zero) target = Duration.zero;
    if (max > Duration.zero && target > max) target = max;
    position.value = target;
    await _engine?.seek(target);
  }

  Future<void> seekRelative(Duration delta) => seek(position.value + delta);

  void toggleShuffle() {
    _shuffle = !_shuffle;
    notifyListeners();
  }

  void cycleLoop() {
    switch (_loop) {
      case LoopMode.off:
        _loop = LoopMode.all;
        break;
      case LoopMode.all:
        _loop = LoopMode.one;
        break;
      case LoopMode.one:
        _loop = LoopMode.off;
        break;
    }
    notifyListeners();
  }

  void toggleLike(String id) => _library.toggleLike(id);

  /// Lets the library controller re-broadcast state so heart buttons
  /// (which listen to the player) refresh after a like/history change.
  void poke() => notifyListeners();

  Future<void> setVolume(double v) async {
    await _engine?.setVolume(v);
  }

  @override
  void dispose() {
    _posSub?.cancel();
    _doneSub?.cancel();
    _engine?.dispose();
    position.dispose();
    super.dispose();
  }
}
