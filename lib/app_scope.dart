import 'package:flutter/widgets.dart';

import 'core/palette.dart';
import 'models/settings.dart';
import 'services/discord/discord_presence_service.dart';
import 'state/player_controller.dart';
import 'state/settings_controller.dart';

/// Dependency injection for the whole app: settings, player and Discord
/// presence. Widgets read it with `SonoraScope.of(context)`; rebuilds are
/// driven by the individual controllers, not by this inherited widget.
class SonoraScope extends InheritedWidget {
  const SonoraScope({
    super.key,
    required this.settings,
    required this.player,
    required this.discord,
    required super.child,
  });

  final SettingsController settings;
  final PlayerController player;
  final DiscordPresenceService discord;

  AppSettings get s => settings.value;

  AppPalette get palette => AppPalette.byId(settings.value.appearance.themeId);

  static SonoraScope of(BuildContext context) {
    final SonoraScope? scope =
        context.dependOnInheritedWidgetOfExactType<SonoraScope>();
    assert(scope != null, 'SonoraScope is missing above this widget');
    return scope!;
  }

  static SonoraScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<SonoraScope>();

  @override
  bool updateShouldNotify(SonoraScope oldWidget) =>
      settings != oldWidget.settings ||
      player != oldWidget.player ||
      discord != oldWidget.discord;
}
