import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../models/settings.dart';
import '../../models/track.dart';
import '../../state/settings_controller.dart';
import 'discord_ipc.dart';
import 'discord_template.dart';

enum DiscordStatus { off, noClient, noAppId, connecting, connected, error }

/// Owns the Discord IPC connection and translates player state into a
/// Rich Presence activity. Rate limited to 1 update / 15 s as required by
/// Discord's IPC gateway (5 SET_ACTIVITY per 20 s).
class DiscordPresenceService extends ChangeNotifier {
  DiscordPresenceService(this._settings);

  final SettingsController _settings;
  final DiscordRpcClient _client = DiscordRpcClient();

  DiscordStatus _status = DiscordStatus.off;
  String _statusDetail = 'Отключено';
  PresenceModel? _preview;
  Track? _track;
  Duration _position = Duration.zero;
  bool _playing = false;
  bool _busy = false;

  DateTime? _lastPushAt;
  PresenceModel? _pending;
  Timer? _flushTimer;
  Timer? _heartbeat;

  /// Track/pause state at the moment of the last push — used to detect
  /// "something really changed" vs. a 200 ms position tick.
  String? _lastPushedKey;
  Duration _lastPushedPos = Duration.zero;
  String _lastUiKey = '';

  DiscordStatus get status => _status;
  String get statusDetail => _statusDetail;
  PresenceModel? get preview => _preview;
  bool get connected => _status == DiscordStatus.connected;
  String? get discordUser =>
      _client.user == null ? null : '${_client.user!['username'] ?? 'discord user'}';

  String get statusLabel {
    switch (_status) {
      case DiscordStatus.off:
        return 'Выключено';
      case DiscordStatus.noClient:
        return 'Discord не запущен';
      case DiscordStatus.noAppId:
        return 'Нужен Application ID';
      case DiscordStatus.connecting:
        return 'Подключение…';
      case DiscordStatus.connected:
        return 'Подключено';
      case DiscordStatus.error:
        return 'Ошибка';
    }
  }

  // -------------------------------------------------------------------------
  // Public API
  // -------------------------------------------------------------------------

  Future<void> connect() async {
    final DiscordSettings d = _settings.value.discord;
    if (!d.enabled) {
      _setStatus(DiscordStatus.off, 'Rich Presence выключен в настройках');
      return;
    }
    final String id = d.appId.trim();
    if (id.isEmpty || int.tryParse(id) == null) {
      _setStatus(DiscordStatus.noAppId,
          'Укажите Application ID из Discord Developer Portal → Rich Presence');
      return;
    }
    if (_busy) return;
    _busy = true;
    _setStatus(DiscordStatus.connecting, 'Открываю IPC-канал…');
    try {
      final bool ok = await _client.connect(id);
      if (!ok) {
        _setStatus(DiscordStatus.noClient,
            _client.lastError ?? 'Не удалось подключиться к Discord');
        return;
      }
      _setStatus(DiscordStatus.connected, 'Канал открыт, отправляю активность');
      _heartbeat?.cancel();
      _heartbeat = Timer.periodic(const Duration(seconds: 30), (_) {
        final PresenceModel? p = _preview;
        if (p != null && _client.connected) {
          _push(p, force: true);
        }
      });
      final Track? t = _track;
      if (t != null) _rebuildPreview(t, _position, _playing);
      final PresenceModel? p = _preview;
      if (p != null) await _push(p, force: true);
    } catch (e) {
      _setStatus(DiscordStatus.error, '$e');
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<void> disconnect() async {
    _heartbeat?.cancel();
    _flushTimer?.cancel();
    try {
      await _client.clearActivity();
    } catch (_) {}
    await _client.close();
    _setStatus(DiscordStatus.off, 'Отключено');
  }

  /// Called whenever the player state changes (track, play/pause, seek).
  void updateNowPlaying(Track? track, Duration position, bool playing) {
    final String uiKey =
        '${track?.id}|${playing ? 'p' : 's'}|${position.inSeconds}';
    if (uiKey == _lastUiKey) return;
    _lastUiKey = uiKey;

    _track = track;
    _position = position;
    _playing = playing;
    if (track == null) return;

    _rebuildPreview(track, position, playing);

    final DiscordSettings d = _settings.value.discord;
    if (!d.enabled) {
      _setStatus(DiscordStatus.off, 'Rich Presence выключен в настройках');
      return;
    }
    if (_status == DiscordStatus.connected) {
      final String key = '${track.id}|${playing ? 'p' : 's'}';
      final bool changed = key != _lastPushedKey;
      final bool jumped =
          (position - _lastPushedPos).abs() > const Duration(seconds: 4);
      final PresenceModel? p = _preview;
      if (p != null && (changed || jumped)) _push(p);
    }
    notifyListeners();
  }

  /// Re-applies settings and reconnects if the app id / toggles changed.
  Future<void> applySettings() async {
    if (!_settings.value.discord.enabled) {
      await disconnect();
      return;
    }
    if (_status == DiscordStatus.connected) {
      final Track? t = _track;
      if (t != null) {
        _rebuildPreview(t, _position, _playing);
        final PresenceModel? p = _preview;
        if (p != null) await _push(p, force: true);
      }
      return;
    }
    await connect();
  }

  /// Forces a fresh reconnect (used by "Применить и переподключиться").
  Future<void> reconnect() async {
    await disconnect();
    await connect();
  }

  // -------------------------------------------------------------------------
  // Internals
  // -------------------------------------------------------------------------

  void _rebuildPreview(Track track, Duration position, bool playing) {
    final DiscordSettings d = _settings.value.discord;
    final String rendered = DiscordTemplate.render(d.stateTemplate, track);
    final String joined = <String>[
      if (rendered.isNotEmpty) rendered,
      if (d.signature.trim().isNotEmpty) d.signature.trim(),
    ].join('  ·  ');

    final List<Map<String, String>> buttons = <Map<String, String>>[];
    if (d.showButtons) {
      final Map<String, String>? b1 = _button(d.button1Label, d.button1Url);
      if (b1 != null) buttons.add(b1);
      final Map<String, String>? b2 = _button(d.button2Label, d.button2Url);
      if (b2 != null) buttons.add(b2);
    }

    DateTime? start;
    DateTime? end;
    if (d.showProgress) {
      final Duration pos = position > track.duration ? track.duration : position;
      start = DateTime.now().subtract(pos);
      end = start.add(track.duration);
      if (!playing) start = null;
    }

    _preview = PresenceModel(
      // 🔒 read-only by construction: only the player can set this value.
      details: track.title,
      state: joined.isEmpty ? null : DiscordTemplate.clampLine(joined),
      largeImage: d.largeImageKey.trim().isEmpty ? null : d.largeImageKey.trim(),
      largeText: '${track.album} · ${track.year}',
      smallImage: d.showSource
          ? (d.smallImageKey.trim().isEmpty
              ? track.source.discordAssetKey
              : d.smallImageKey.trim())
          : null,
      smallText: track.source.label,
      buttons: buttons,
      start: start,
      end: end,
    );
  }

  Map<String, String>? _button(String label, String url) {
    final String l = label.trim();
    final String u = url.trim();
    if (l.isEmpty || u.isEmpty) return null;
    if (!u.startsWith('http://') && !u.startsWith('https://')) return null;
    return <String, String>{
      'label': l.length > 32 ? l.substring(0, 32) : l,
      'url': u.length > 256 ? u.substring(0, 256) : u,
    };
  }

  Future<void> _push(PresenceModel model, {bool force = false}) async {
    if (!_client.connected) return;
    final DateTime now = DateTime.now();
    final DateTime? last = _lastPushAt;
    final bool tooSoon =
        last != null && now.difference(last) < const Duration(seconds: 15);
    if (tooSoon && !force) {
      _pending = model;
      _flushTimer?.cancel();
      final int waitMs = 15000 - now.difference(last).inMilliseconds;
      _flushTimer = Timer(Duration(milliseconds: waitMs < 0 ? 0 : waitMs), () {
        final PresenceModel? p = _pending;
        if (p != null) _push(p, force: true);
      });
      return;
    }
    _lastPushAt = now;
    _pending = null;
    _lastPushedKey = '${_track?.id}|${_playing ? 'p' : 's'}';
    _lastPushedPos = _position;
    try {
      await _client.setActivity(
        model.toActivity(listening: _settings.value.discord.listeningType),
      );
      if (_statusDetail != 'Активность обновлена') {
        _setStatus(DiscordStatus.connected, 'Активность обновлена');
      }
    } catch (e) {
      _setStatus(DiscordStatus.error, '$e');
    }
  }

  void _setStatus(DiscordStatus s, String detail) {
    _status = s;
    _statusDetail = detail;
    notifyListeners();
  }

  @override
  void dispose() {
    _flushTimer?.cancel();
    _heartbeat?.cancel();
    _client.dispose();
    super.dispose();
  }
}
