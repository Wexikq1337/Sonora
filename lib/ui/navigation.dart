import 'package:flutter/material.dart';

import 'screens/now_playing.dart';

enum SonoraTab { home, search, library, downloads, settings }

class TabSpec {
  const TabSpec(this.tab, this.label, this.icon, this.activeIcon);
  final SonoraTab tab;
  final String label;
  final IconData icon;
  final IconData activeIcon;
}

const List<TabSpec> kTabs = <TabSpec>[
  TabSpec(SonoraTab.home, 'Главная', Icons.explore_outlined, Icons.explore_rounded),
  TabSpec(SonoraTab.search, 'Поиск', Icons.search_rounded, Icons.search_rounded),
  TabSpec(SonoraTab.library, 'Медиатека', Icons.library_music_outlined,
      Icons.library_music_rounded),
  TabSpec(SonoraTab.downloads, 'Загрузки', Icons.download_outlined,
      Icons.download_rounded),
  TabSpec(SonoraTab.settings, 'Настройки', Icons.tune_outlined, Icons.tune_rounded),
];

/// Shared fade + slide + scale route used for every push in the app.
Route<T> glassRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    transitionDuration: const Duration(milliseconds: 380),
    reverseTransitionDuration: const Duration(milliseconds: 280),
    pageBuilder: (BuildContext context, Animation<double> a, Animation<double> s) =>
        page,
    transitionsBuilder: (BuildContext context, Animation<double> a,
        Animation<double> secondary, Widget child) {
      final Animation<double> curved = CurvedAnimation(
        parent: a,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.035),
            end: Offset.zero,
          ).animate(curved),
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.985, end: 1.0).animate(curved),
            child: child,
          ),
        ),
      );
    },
  );
}

Future<void> openNowPlaying(BuildContext context) {
  return Navigator.of(context).push<void>(glassRoute<void>(const NowPlayingScreen()));
}
