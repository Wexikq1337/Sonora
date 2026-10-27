import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// Platform audio output abstraction.
///
/// The primary implementation is backed by `audioplayers`, which maps to
/// MediaPlayer on Android, Media Foundation on Windows and GStreamer on Linux.
/// If the plugin cannot initialise (missing codec back-end, headless CI, ...)
/// the app transparently falls back to [SimulatedEngine] so that the whole UI,
/// queue and Discord presence keep working — only sound is missing.
abstract class AudioEngine {
  String get kind;

  Future<bool> init();

  Future<void> load(String asset, Duration duration, {bool remote = false});

  Future<void> play();

  Future<void> pause();

  Future<void> seek(Duration position);

  Future<void> setVolume(double value);

  Stream<Duration> get positions;

  Stream<void> get completions;

  Future<void> dispose();
}

class AudioplayersEngine implements AudioEngine {
  final AudioPlayer _player = AudioPlayer();
  final StreamController<Duration> _positions =
      StreamController<Duration>.broadcast();
  final StreamController<void> _completions = StreamController<void>.broadcast();
  final List<StreamSubscription<dynamic>> _subs = <StreamSubscription<dynamic>>[];
  bool _ready = false;

  @override
  String get kind => 'audioplayers (MF / GStreamer / MediaPlayer)';

  @override
  Stream<Duration> get positions => _positions.stream;

  @override
  Stream<void> get completions => _completions.stream;

  @override
  Future<bool> init() async {
    try {
      await _player.setReleaseMode(ReleaseMode.stop);
      _subs.add(_player.onPositionChanged.listen((Duration d) {
        if (!_positions.isClosed) _positions.add(d);
      }));
      _subs.add(_player.onPlayerComplete.listen((_) {
        if (!_completions.isClosed) _completions.add(null);
      }));
      _ready = true;
    } catch (e) {
      debugPrint('Sonora: audioplayers init failed: $e');
      _ready = false;
    }
    return _ready;
  }

  @override
  Future<void> load(String asset, Duration duration, {bool remote = false}) async {
    if (!_ready) return;
    await _player.stop();
    if (remote) {
      await _player.setSource(UrlSource(asset));
    } else {
      await _player.setSource(AssetSource(asset));
    }
  }

  @override
  Future<void> play() async {
    if (!_ready) return;
    await _player.resume();
  }

  @override
  Future<void> pause() async {
    if (!_ready) return;
    await _player.pause();
  }

  @override
  Future<void> seek(Duration position) async {
    if (!_ready) return;
    await _player.seek(position);
  }

  @override
  Future<void> setVolume(double value) async {
    if (!_ready) return;
    await _player.setVolume(value.clamp(0.0, 1.0).toDouble());
  }

  @override
  Future<void> dispose() async {
    for (final StreamSubscription<dynamic> s in _subs) {
      await s.cancel();
    }
    _subs.clear();
    await _player.dispose();
    await _positions.close();
    await _completions.close();
  }
}

/// Clock-only engine: keeps transport, queue and UI alive without sound.
class SimulatedEngine implements AudioEngine {
  final StreamController<Duration> _positions =
      StreamController<Duration>.broadcast();
  final StreamController<void> _completions = StreamController<void>.broadcast();
  Timer? _timer;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  @override
  String get kind => 'simulated clock (без звука)';

  @override
  Stream<Duration> get positions => _positions.stream;

  @override
  Stream<void> get completions => _completions.stream;

  @override
  Future<bool> init() async => true;

  @override
  Future<void> load(String asset, Duration duration,
      {bool remote = false}) async {
    _timer?.cancel();
    _position = Duration.zero;
    _duration = duration;
    if (!_positions.isClosed) _positions.add(_position);
  }

  @override
  Future<void> play() async {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 250), (Timer t) {
      _position += const Duration(milliseconds: 250);
      if (_position >= _duration) {
        _position = _duration;
        t.cancel();
        if (!_positions.isClosed) _positions.add(_position);
        if (!_completions.isClosed) _completions.add(null);
        return;
      }
      if (!_positions.isClosed) _positions.add(_position);
    });
  }

  @override
  Future<void> pause() async {
    _timer?.cancel();
  }

  @override
  Future<void> seek(Duration position) async {
    _position = position < Duration.zero ? Duration.zero : position;
    if (!_positions.isClosed) _positions.add(_position);
  }

  @override
  Future<void> setVolume(double value) async {}

  @override
  Future<void> dispose() async {
    _timer?.cancel();
    await _positions.close();
    await _completions.close();
  }
}
