import '../models/track.dart';

/// Renders the user-editable part of a Discord Rich Presence activity.
///
/// 🔒 SECURITY / PRODUCT RULE
/// The first line (`details`) always contains the *current track title* and is
/// produced exclusively by [PresenceModel.fromPlayer]. There is deliberately
/// no template field for it, and the `{track}` token is neutralised so a user
/// cannot accidentally (or intentionally) replace the track name.
class DiscordTemplate {
  const DiscordTemplate._();

  static const List<String> tokens = <String>[
    '{artist}',
    '{album}',
    '{source}',
    '{year}',
    '{bpm}',
    '{time}',
  ];

  static const String lockedTrackHint =
      'Название трека берётся из плеера и не редактируется';

  static String _clean(String input) => input
      .replaceAll('\n', ' ')
      .replaceAll('\r', ' ')
      .replaceAll(RegExp(r'\s{2,}'), ' ')
      .trim();

  /// Clamps to Discord's limits. Returns null for strings that would be
  /// rejected by the IPC gateway (length < 2 or > 128).
  static String? clampLine(String input, {int min = 2, int max = 128}) {
    final String s = _clean(input);
    if (s.length < min) return null;
    return s.length <= max ? s : s.substring(0, max);
  }

  static String render(String template, Track track) {
    String out = template;
    // Neutralise forbidden tokens first (they must never inject the title).
    out = out.replaceAll(RegExp(r'\{track\}', caseSensitive: false), '');
    out = out.replaceAll(RegExp(r'\{title\}', caseSensitive: false), '');
    out = out.replaceAll('{artist}', track.artist);
    out = out.replaceAll('{album}', track.album);
    out = out.replaceAll('{source}', track.source.label);
    out = out.replaceAll('{year}', '${track.year}');
    out = out.replaceAll('{bpm}', '${track.bpm} BPM');
    final DateTime now = DateTime.now();
    out = out.replaceAll(
        '{time}', '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}');
    return _clean(out);
  }
}

/// Fully resolved activity, ready for both the IPC payload and the in-app
/// "what Discord will show" preview card.
class PresenceModel {
  const PresenceModel({
    required this.details,
    this.state,
    this.largeImage,
    this.largeText,
    this.smallImage,
    this.smallText,
    this.buttons = const <Map<String, String>>[],
    this.start,
    this.end,
  });

  /// 🔒 Always the track title, never user input.
  final String details;
  final String? state;
  final String? largeImage;
  final String? largeText;
  final String? smallImage;
  final String? smallText;
  final List<Map<String, String>> buttons;
  final DateTime? start;
  final DateTime? end;

  Map<String, dynamic> toActivity({required bool listening}) {
    final Map<String, dynamic> assets = <String, dynamic>{};
    if (largeImage != null && largeImage!.isNotEmpty) {
      assets['large_image'] = largeImage;
      if (largeText != null && largeText!.isNotEmpty) assets['large_text'] = largeText;
    }
    if (smallImage != null && smallImage!.isNotEmpty) {
      assets['small_image'] = smallImage;
      if (smallText != null && smallText!.isNotEmpty) assets['small_text'] = smallText;
    }

    final Map<String, dynamic> activity = <String, dynamic>{
      'details': DiscordTemplate.clampLine(details) ?? details,
      if (state != null && state!.isNotEmpty) 'state': state,
      if (start != null)
        'timestamps': <String, int>{
          'start': start!.millisecondsSinceEpoch,
          if (end != null) 'end': end!.millisecondsSinceEpoch,
        },
      if (assets.isNotEmpty) 'assets': assets,
      if (buttons.isNotEmpty) 'buttons': buttons,
      'instance': false,
    };
    if (listening) activity['type'] = 2; // 2 = "Listening to"
    return activity;
  }
}
