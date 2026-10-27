import 'package:flutter/foundation.dart';

import '../models/settings.dart';
import '../services/local_store.dart';

/// Single source of truth for every user-tweakable setting.
class SettingsController extends ChangeNotifier {
  SettingsController();

  static const String _fileName = 'settings.json';

  AppSettings _value = const AppSettings();
  final Debouncer _saveDebounce = Debouncer(const Duration(milliseconds: 350));
  bool _loaded = false;

  AppSettings get value => _value;
  bool get loaded => _loaded;

  Future<void> load() async {
    final String? raw = await LocalStore.read(_fileName);
    if (raw != null && raw.trim().isNotEmpty) {
      try {
        _value = AppSettings.decode(raw);
      } catch (e) {
        debugPrint('Sonora: settings decode failed ($e), using defaults');
      }
    }
    _loaded = true;
    notifyListeners();
  }

  void update(AppSettings Function(AppSettings current) transform) {
    _value = transform(_value);
    notifyListeners();
    _saveDebounce.run(() => LocalStore.write(_fileName, _value.encode()));
  }

  void resetAll() {
    _value = const AppSettings();
    notifyListeners();
    _saveDebounce.run(() => LocalStore.write(_fileName, _value.encode()));
  }

  /// Import/export used by the "Внешний вид" tab (JSON round-trip).
  String exportJson() => _value.encode();

  bool importJson(String raw) {
    try {
      _value = AppSettings.decode(raw);
      notifyListeners();
      _saveDebounce.run(() => LocalStore.write(_fileName, _value.encode()));
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  void dispose() {
    _saveDebounce.dispose();
    super.dispose();
  }
}
