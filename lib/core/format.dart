/// Small formatting helpers used across the UI.
String fmtDuration(Duration? d) {
  if (d == null) return '--:--';
  final int total = d.inSeconds;
  final int m = total ~/ 60;
  final int s = total % 60;
  if (total >= 3600) {
    final int h = total ~/ 3600;
    return '$h:${(m % 60).toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
  return '$m:${s.toString().padLeft(2, '0')}';
}

String fmtPosition(Duration? d) => fmtDuration(d);

double clamp01(double v) => v < 0 ? 0 : (v > 1 ? 1 : v);

String shortId(String s, [int max = 10]) =>
    s.length <= max ? s : '${s.substring(0, max)}…';
