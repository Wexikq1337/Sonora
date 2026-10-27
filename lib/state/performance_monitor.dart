import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

/// Watches real frame timings and flips the app into "low quality" mode when
/// the device cannot keep up (blur + particles off). This is what keeps the
/// glass effect from destroying frame-rate on weak Android GPUs.
class PerformanceMonitor extends ChangeNotifier {
  PerformanceMonitor._();
  static final PerformanceMonitor instance = PerformanceMonitor._();

  bool _started = false;
  double _emaFrameMs = 16.7;
  bool _lowQuality = false;
  int _fps = 60;
  int _samples = 0;

  bool get lowQuality => _lowQuality;
  int get fps => _fps;
  double get frameMs => _emaFrameMs;

  void start() {
    if (_started) return;
    _started = true;
    SchedulerBinding.instance.addTimingsCallback(_onTimings);
  }

  void _onTimings(List<FrameTiming> timings) {
    if (timings.isEmpty) return;
    double sum = 0;
    for (final FrameTiming t in timings) {
      sum += t.totalSpan.inMicroseconds / 1000.0;
    }
    final double avg = sum / timings.length;
    _emaFrameMs = _emaFrameMs * 0.88 + avg * 0.12;
    _samples++;
    _fps = (1000 / (_emaFrameMs <= 0.1 ? 0.1 : _emaFrameMs))
        .round()
        .clamp(1, 240)
        .toInt();

    // Need a few frames before trusting the average.
    if (_samples < 45) {
      if (_samples % 15 == 0) notifyListeners();
      return;
    }

    final bool shouldBeLow = _emaFrameMs > 23.0;
    final bool shouldBeHigh = _emaFrameMs < 15.5;
    if (shouldBeLow && !_lowQuality) {
      _lowQuality = true;
      notifyListeners();
    } else if (shouldBeHigh && _lowQuality) {
      _lowQuality = false;
      notifyListeners();
    } else if (_samples % 30 == 0) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    if (_started) {
      SchedulerBinding.instance.removeTimingsCallback(_onTimings);
      _started = false;
    }
    super.dispose();
  }
}
