import 'dart:async';
import 'dart:io';

/// Tiny persistence layer (no plugins). On desktop we use the OS config dirs,
/// on Android we fall back to the app sandbox cache directory.
class LocalStore {
  LocalStore._();

  static Directory? _dirCache;

  static Directory get dir {
    final Directory? cached = _dirCache;
    if (cached != null) return cached;
    Directory d;
    try {
      if (Platform.isWindows) {
        final String base =
            Platform.environment['APPDATA'] ?? Directory.systemTemp.path;
        d = Directory('$base\\Sonora');
      } else if (Platform.isLinux) {
        final String home = Platform.environment['HOME'] ?? '';
        final String base = Platform.environment['XDG_DATA_HOME'] ??
            (home.isEmpty ? Directory.systemTemp.path : '$home/.local/share');
        d = Directory('$base/sonora');
      } else {
        d = Directory('${Directory.systemTemp.path}/sonora');
      }
      d.createSync(recursive: true);
    } catch (_) {
      d = Directory.systemTemp;
    }
    _dirCache = d;
    return d;
  }

  static File file(String name) => File('${dir.path}${Platform.pathSeparator}$name');

  static Future<String?> read(String name) async {
    try {
      final File f = file(name);
      if (!await f.exists()) return null;
      return await f.readAsString();
    } catch (_) {
      return null;
    }
  }

  static Future<void> write(String name, String data) async {
    try {
      await file(name).writeAsString(data, flush: true);
    } catch (_) {
      // Persisting is best-effort: never crash the UI because of it.
    }
  }
}

/// Very small debouncer used for settings writes.
class Debouncer {
  Debouncer(this._delay);
  final Duration _delay;
  Timer? _t;

  void run(void Function() action) {
    _t?.cancel();
    _t = Timer(_delay, action);
  }

  void dispose() => _t?.cancel();
}
