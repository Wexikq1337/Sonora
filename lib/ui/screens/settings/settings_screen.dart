import 'dart:io';
import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';

import '../../../app_scope.dart';
import '../../../core/palette.dart';
import '../../../core/format.dart';
import '../../../models/settings.dart';
import '../../../models/track.dart';
import '../../../services/discord/discord_presence_service.dart';
import '../../../services/local_store.dart';
import '../../../state/performance_monitor.dart';
import '../../../state/player_controller.dart';
import '../../animations/motion.dart';
import '../../glass/glass.dart';
import '../equalizer_sheet.dart';
import '../now_playing.dart';
import 'discord_tab.dart';
import 'settings_widgets.dart';

class _TabDef {
  const _TabDef(this.title, this.icon, this.desc);
  final String title;
  final IconData icon;
  final String desc;
}

const List<_TabDef> _tabs = <_TabDef>[
  _TabDef('Внешний вид', Icons.palette_outlined, 'Темы, фон, курсор, профили'),
  _TabDef('Анимации', Icons.animation_rounded, 'Микро- и макро-анимации'),
  _TabDef('Блюр и Glass', Icons.blur_on_rounded, 'Стекло, размытие, качество'),
  _TabDef('Плеер', Icons.play_circle_outline_rounded, 'Поведение и мини-плеер'),
  _TabDef('Звук', Icons.graphic_eq_rounded, 'Эквалайзер, эффекты, качество'),
  _TabDef('Источники', Icons.hub_outlined, 'Аккаунты и авторизация'),
  _TabDef('Библиотека', Icons.storage_rounded, 'Кэш, сканирование, синк'),
  _TabDef('Уведомления и виджет', Icons.notifications_none_rounded,
      'Виджет, трей, уведомления'),
  _TabDef('Горячие клавиши', Icons.keyboard_outlined, 'Только desktop'),
  _TabDef('Приватность и данные', Icons.shield_outlined,
      'История, телеметрия, экспорт'),
  _TabDef('О приложении', Icons.info_outline_rounded, 'Версия и лицензии'),
  _TabDef('Discord', Icons.discord_rounded, 'Rich Presence и профили'),
];

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, this.initialTab = 0});

  final int initialTab;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late int _index = widget.initialTab.clamp(0, _tabs.length - 1).toInt();
  bool _mobileDetail = false;

  void _select(int i) {
    setState(() {
      _index = i;
      _mobileDetail = true;
    });
  }

  void _upd(BuildContext context, AppSettings Function(AppSettings) f) {
    SonoraScope.of(context).settings.update(f);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints c) {
        final bool desktop = c.maxWidth >= 860;
        if (desktop) {
          return Row(
            children: <Widget>[
              SizedBox(
                width: 268,
                child: _tabList(compact: true),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: AnimatedSwitcher(
                  duration: motionDuration(context, 240),
                  child: KeyedSubtree(
                    key: ValueKey<int>(_index),
                    child: _content(context),
                  ),
                ),
              ),
            ],
          );
        }
        if (!_mobileDetail) {
          return _tabList(compact: false);
        }
        return Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
              child: Row(
                children: <Widget>[
                  GlassIconButton(
                    icon: Icons.arrow_back_rounded,
                    size: 38,
                    iconSize: 19,
                    onTap: () => setState(() => _mobileDetail = false),
                  ),
                  const SizedBox(width: 10),
                  Text(_tabs[_index].title,
                      style: TextStyle(
                          color: SonoraScope.of(context).palette.text,
                          fontSize: 17,
                          fontWeight: FontWeight.w700)),
                ],
              ),
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: motionDuration(context, 240),
                child: KeyedSubtree(
                  key: ValueKey<int>(_index),
                  child: _content(context),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _tabList({required bool compact}) {
    final AppPalette pal = SonoraScope.of(context).palette;
    return ListView(
      padding: EdgeInsets.fromLTRB(14, compact ? 14 : 18, 14, 100),
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('Настройки',
                  style: TextStyle(
                      color: pal.text,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5)),
              const SizedBox(height: 2),
              Text('12 разделов · всё сохраняется автоматически',
                  style: TextStyle(color: pal.muted, fontSize: 11.5)),
            ],
          ),
        ),
        if (compact)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: LiquidGlass(
              radius: 16,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: <Widget>[
                  Icon(Icons.person_rounded, size: 16, color: pal.accent),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('Локальный профиль',
                        style: TextStyle(color: pal.text, fontSize: 12)),
                  ),
                  Icon(Icons.chevron_right_rounded,
                      size: 16, color: pal.muted),
                ],
              ),
            ),
          ),
        for (int i = 0; i < _tabs.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 3),
            child: _TabTile(
              def: _tabs[i],
              active: i == _index,
              onTap: () => _select(i),
            ),
          ),
      ],
    );
  }

  Widget _content(BuildContext context) {
    switch (_index) {
      case 0:
        return _appearance(context);
      case 1:
        return _animations(context);
      case 2:
        return _blurGlass(context);
      case 3:
        return _player(context);
      case 4:
        return _sound(context);
      case 5:
        return _sources(context);
      case 6:
        return _library(context);
      case 7:
        return _notifications(context);
      case 8:
        return _hotkeys(context);
      case 9:
        return _privacy(context);
      case 10:
        return _about(context);
      default:
        return const DiscordTab();
    }
  }

  // ---------------------------------------------------------------------------
  // 0. Appearance
  // ---------------------------------------------------------------------------
  Widget _appearance(BuildContext context) {
    final SonoraScope scope = SonoraScope.of(context);
    final AppSettings s = scope.s;
    return SettingsPage(
      title: 'Внешний вид',
      subtitle: 'Тема, фон, курсор и профили оформления',
      children: <Widget>[
        SettingsCard(
          title: 'Палитра',
          icon: Icons.color_lens_outlined,
          subtitle: 'Влияет на стекло, акценты и фоновые блики',
          children: <Widget>[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                for (final AppPalette p in AppPalette.all)
                  _ThemeChip(
                    palette: p,
                    selected: s.appearance.themeId == p.id,
                    onTap: () => _upd(context,
                        (AppSettings v) => v.copyWith(appearance: v.appearance.copyWith(themeId: p.id))),
                  ),
              ],
            ),
          ],
        ),
        SettingsCard(
          title: 'Фон',
          icon: Icons.gradient_rounded,
          children: <Widget>[
            SettingSlider(
              title: 'Интенсивность фона',
              description: 'Яркость движущихся световых пятен под стеклом',
              value: s.appearance.backgroundIntensity,
              min: 0,
              max: 1,
              format: (double v) => '${(v * 100).round()}%',
              onChanged: (double v) => _upd(context,
                  (AppSettings x) => x.copyWith(appearance: x.appearance.copyWith(backgroundIntensity: v))),
            ),
            SettingSlider(
              title: 'Виньетка и шум',
              description: 'Затемнение по краям — повышает контраст текста',
              value: s.appearance.noiseOverlay,
              min: 0,
              max: 1,
              format: (double v) => '${(v * 100).round()}%',
              onChanged: (double v) => _upd(context,
                  (AppSettings x) => x.copyWith(appearance: x.appearance.copyWith(noiseOverlay: v))),
            ),
            const InfoNote(
              text: 'Видео-фон, пользовательские изображения и GIF — в следующей '
                  'итерации: нужен file_picker и отдельный слой с текстурой.',
            ),
          ],
        ),
        SettingsCard(
          title: 'Курсор и указатель',
          icon: Icons.mouse_outlined,
          children: <Widget>[
            SettingSwitchRow(
              title: 'Свечение за курсором',
              description: 'Мягкий ореол, следующий за указателем (desktop)',
              tooltip: 'На Android не используется — там тактильный отклик',
              value: s.appearance.glowCursor,
              onChanged: (bool v) => _upd(context,
                  (AppSettings x) => x.copyWith(appearance: x.appearance.copyWith(glowCursor: v))),
            ),
            SettingSwitchRow(
              title: 'Компактный интерфейс',
              description: 'Меньше отступы в списках',
              value: s.appearance.compactUi,
              onChanged: (bool v) => _upd(context,
                  (AppSettings x) => x.copyWith(appearance: x.appearance.copyWith(compactUi: v))),
            ),
            const InfoNote(
              text: 'Полноценная замена курсора (SVG/PNG) требует скрытия системного '
                  'указателя и overlay-слоя — каркас готов, UI-редактор в разработке.',
            ),
          ],
        ),
        SettingsCard(
          title: 'Профиль оформления',
          icon: Icons.save_outlined,
          subtitle: 'Экспорт/импорт всей конфигурации в JSON',
          children: <Widget>[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                GlassChip(
                  label: 'Экспорт JSON',
                  icon: Icons.download_rounded,
                  onTap: () => _showExport(context, scope.settings.exportJson()),
                ),
                GlassChip(
                  label: 'Импорт JSON',
                  icon: Icons.upload_rounded,
                  onTap: () => _showImport(context),
                ),
                GlassChip(
                  label: 'Сбросить всё',
                  icon: Icons.restart_alt_rounded,
                  onTap: () => _confirmReset(context),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 1. Animations
  // ---------------------------------------------------------------------------
  Widget _animations(BuildContext context) {
    final SonoraScope scope = SonoraScope.of(context);
    final AppSettings s = scope.s;
    return SettingsPage(
      title: 'Анимации',
      subtitle: 'Скорость, физика и отдельные типы движения',
      children: <Widget>[
        SettingsCard(
          title: 'Доступность',
          icon: Icons.accessibility_new_rounded,
          children: <Widget>[
            SettingSwitchRow(
              title: 'Уменьшить движение',
              description: 'Отключает blur-анимации, параллакс и фоновое движение',
              tooltip: 'Рекомендуется при укачивании и на слабых устройствах',
              value: s.anim.reduceMotion,
              onChanged: (bool v) => _upd(context,
                  (AppSettings x) => x.copyWith(anim: x.anim.copyWith(reduceMotion: v))),
            ),
            SettingRow(
              title: 'Множитель скорости',
              description: 'Все длительности делятся на это значение',
              trailing: Text(
                '${s.anim.speed.toStringAsFixed(1)}x',
                style: TextStyle(
                    color: scope.palette.accent,
                    fontSize: 12,
                    fontWeight: FontWeight.w700),
              ),
            ),
            ChoiceRow(
              options: const <String>['0.5x', '0.75x', '1.0x', '1.5x', '2.0x'],
              selected: '${s.anim.speed}x',
              onSelect: (String v) => _upd(
                  context,
                  (AppSettings x) => x.copyWith(
                      anim: x.anim.copyWith(
                          speed: double.parse(v.replaceAll('x', ''))))),
            ),
          ],
        ),
        SettingsCard(
          title: 'Стиль нажатия',
          icon: Icons.touch_app_outlined,
          children: <Widget>[
            ChoiceRow(
              options: const <String>['Spring', 'Bounce', 'Smooth', 'None'],
              selected: _pressLabel(s.glass.pressAnim),
              onSelect: (String v) => _upd(
                  context,
                  (AppSettings x) => x.copyWith(
                      glass: x.glass.copyWith(pressAnim: _pressValue(v)))),
            ),
            _AnimPreview(),
          ],
        ),
        SettingsCard(
          title: 'Типы анимаций',
          icon: Icons.tune_rounded,
          children: <Widget>[
            SettingSwitchRow(
              title: 'Пружинные кнопки',
              description: 'Physics-based spring вместо кривых Безье',
              value: s.anim.springButtons,
              onChanged: (bool v) => _upd(context,
                  (AppSettings x) => x.copyWith(anim: x.anim.copyWith(springButtons: v))),
            ),
            SettingSwitchRow(
              title: 'Shimmer-скелетоны',
              description: 'Переливающиеся заглушки при загрузке списков',
              value: s.anim.shimmer,
              onChanged: (bool v) => _upd(context,
                  (AppSettings x) => x.copyWith(anim: x.anim.copyWith(shimmer: v))),
            ),
            SettingSwitchRow(
              title: 'Hero-переходы',
              description: 'Обложка «перелетает» из мини-плеера в полный экран',
              value: s.anim.hero,
              onChanged: (bool v) => _upd(context,
                  (AppSettings x) => x.copyWith(anim: x.anim.copyWith(hero: v))),
            ),
            SettingSwitchRow(
              title: 'Staggered-появление списков',
              description: 'Элементы появляются каскадом с задержкой',
              value: s.anim.staggered,
              onChanged: (bool v) => _upd(context,
                  (AppSettings x) => x.copyWith(anim: x.anim.copyWith(staggered: v))),
            ),
            SettingSwitchRow(
              title: 'Движение фона',
              description: 'Орбиты световых пятен (≈2–3 % GPU)',
              value: s.anim.backgroundMotion,
              onChanged: (bool v) => _upd(context,
                  (AppSettings x) => x.copyWith(anim: x.anim.copyWith(backgroundMotion: v))),
            ),
            SettingSwitchRow(
              title: 'Визуализатор',
              description: 'Спектр в плеере, синхронизирован с BPM трека',
              value: s.anim.visualizer,
              onChanged: (bool v) => _upd(context,
                  (AppSettings x) => x.copyWith(anim: x.anim.copyWith(visualizer: v))),
            ),
            SettingSwitchRow(
              title: 'Морфинг иконок',
              description: 'play ⇄ pause, сердце fill ⇄ outline',
              value: s.anim.morphIcons,
              onChanged: (bool v) => _upd(context,
                  (AppSettings x) => x.copyWith(anim: x.anim.copyWith(morphIcons: v))),
            ),
            SettingSwitchRow(
              title: 'Параллакс при скролле',
              description: 'Обложки слегка смещаются относительно контента',
              value: s.anim.parallax,
              onChanged: (bool v) => _upd(context,
                  (AppSettings x) => x.copyWith(anim: x.anim.copyWith(parallax: v))),
            ),
          ],
        ),
      ],
    );
  }

  static String _pressLabel(String v) {
    switch (v) {
      case 'bounce':
        return 'Bounce';
      case 'smooth':
        return 'Smooth';
      case 'none':
        return 'None';
      default:
        return 'Spring';
    }
  }

  static String _pressValue(String label) => label.toLowerCase();

  // ---------------------------------------------------------------------------
  // 2. Blur & glass
  // ---------------------------------------------------------------------------
  Widget _blurGlass(BuildContext context) {
    final SonoraScope scope = SonoraScope.of(context);
    final AppSettings s = scope.s;
    final GlassSettings g = s.glass;

    return SettingsPage(
      title: 'Блюр и Glass',
      subtitle: 'Стеклянные поверхности, размытие и адаптивное качество',
      children: <Widget>[
        SettingsCard(
          title: 'Стекло',
          icon: Icons.blur_on_rounded,
          children: <Widget>[
            SettingSwitchRow(
              title: 'Включить glass-эффект',
              description: 'Backdrop blur + преломление + блики на всех панелях',
              tooltip: 'При выключении остаются полупрозрачные градиенты',
              value: g.enabled,
              onChanged: (bool v) => _upd(
                  context, (AppSettings x) => x.copyWith(glass: x.glass.copyWith(enabled: v))),
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: GlassButton(
                  radius: 18,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Icon(Icons.play_arrow_rounded,
                          size: 18, color: scope.palette.accent),
                      const SizedBox(width: 6),
                      Text('Так выглядит стеклянная кнопка',
                          style: TextStyle(
                              color: scope.palette.text, fontSize: 12)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        SettingsCard(
          title: 'Размытие',
          icon: Icons.filter_center_focus_rounded,
          children: <Widget>[
            ChoiceRow(
              options: const <String>['Light', 'Medium', 'Heavy', 'Custom'],
              selected: _blurPreset(g.blur),
              onSelect: (String v) {
                final double b = switch (v) {
                  'Light' => 8,
                  'Medium' => 18,
                  'Heavy' => 30,
                  _ => g.blur,
                };
                _upd(context, (AppSettings x) => x.copyWith(glass: x.glass.copyWith(blur: b)));
              },
            ),
            SettingSlider(
              title: 'Сила размытия',
              description: 'Sigma для BackdropFilter. Глубже навигация — сильнее blur',
              value: g.blur,
              min: 0,
              max: 50,
              format: (double v) => '${v.round()} px',
              onChanged: (double v) => _upd(
                  context, (AppSettings x) => x.copyWith(glass: x.glass.copyWith(blur: v))),
            ),
            SettingSlider(
              title: 'Прозрачность стекла',
              description: 'Альфа подложки: меньше — прозрачнее',
              value: g.opacity,
              min: 0.10,
              max: 0.50,
              format: (double v) => v.toStringAsFixed(2),
              onChanged: (double v) => _upd(
                  context, (AppSettings x) => x.copyWith(glass: x.glass.copyWith(opacity: v))),
            ),
            SettingSlider(
              title: 'Преломление (линза)',
              description: 'Масштабирование фона под стеклом — эффект «толщины»',
              tooltip: 'ImageFilter.matrix внутри BackdropFilter; отключается в low-quality',
              value: g.refraction,
              min: 0,
              max: 1,
              format: (double v) => '${(v * 100).round()}%',
              onChanged: (double v) => _upd(
                  context, (AppSettings x) => x.copyWith(glass: x.glass.copyWith(refraction: v))),
            ),
            SettingSlider(
              title: 'Обводка',
              description: 'Яркость 1px-бордера по контуру',
              value: g.borderAlpha,
              min: 0.05,
              max: 0.60,
              format: (double v) => v.toStringAsFixed(2),
              onChanged: (double v) => _upd(
                  context, (AppSettings x) => x.copyWith(glass: x.glass.copyWith(borderAlpha: v))),
            ),
            SettingSlider(
              title: 'Тень',
              description: 'Глубина и свечение под панелью',
              value: g.shadow,
              min: 0,
              max: 1,
              format: (double v) => '${(v * 100).round()}%',
              onChanged: (double v) => _upd(
                  context, (AppSettings x) => x.copyWith(glass: x.glass.copyWith(shadow: v))),
            ),
          ],
        ),
        SettingsCard(
          title: 'Детали стекла',
          icon: Icons.texture_rounded,
          children: <Widget>[
            SettingSwitchRow(
              title: 'Шум-текстура',
              description: 'Анимированное зерно в фрагментном шейдере',
              tooltip: 'Shader: shaders/glass.frag (specular + grain)',
              value: g.noise,
              onChanged: (bool v) => _upd(
                  context, (AppSettings x) => x.copyWith(glass: x.glass.copyWith(noise: v))),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(
                children: <Widget>[
                  Text('Цвет блика',
                      style: TextStyle(
                          color: scope.palette.text, fontSize: 13)),
                  const SizedBox(width: 12),
                  for (final String hex in <String>[
                    '#FFFFFF',
                    '#FFE9C7',
                    '#A5F3FC',
                    '#C4B5FD',
                    '#BBF7D0',
                    '#FDA4AF',
                  ])
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: GestureDetector(
                        onTap: () => _upd(
                            context,
                            (AppSettings x) => x.copyWith(
                                glass: x.glass.copyWith(highlightHex: hex))),
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: parseHexColor(hex),
                            border: Border.all(
                              color: g.highlightHex.toLowerCase() ==
                                      hex.toLowerCase()
                                  ? scope.palette.accent
                                  : Colors.white.withOpacity(0.25),
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            SettingSwitchRow(
              title: 'Частицы в кнопках',
              description: 'Дополнительные блёстки — заметно бьёт по FPS',
              value: g.particles,
              onChanged: (bool v) => _upd(
                  context, (AppSettings x) => x.copyWith(glass: x.glass.copyWith(particles: v))),
            ),
          ],
        ),
        SettingsCard(
          title: 'Производительность',
          icon: Icons.speed_rounded,
          children: <Widget>[
            ChoiceRow(
              options: const <String>['auto', 'high', 'balanced', 'low'],
              selected: s.quality,
              onSelect: (String v) => _upd(
                  context, (AppSettings x) => x.copyWith(quality: v)),
            ),
            SettingSwitchRow(
              title: 'Счётчик FPS',
              description: 'Показывает FPS и время кадра в правом верхнем углу',
              value: s.showFps,
              onChanged: (bool v) => _upd(
                  context, (AppSettings x) => x.copyWith(showFps: v)),
            ),
            ListenableBuilder(
              listenable: PerformanceMonitor.instance,
              builder: (BuildContext context, _) {
                final PerformanceMonitor m = PerformanceMonitor.instance;
                return SettingRow(
                  title: 'Текущее состояние',
                  description: m.lowQuality
                      ? 'Low-quality: blur ≤ 7 px, преломление и шум отключены'
                      : 'Quality: полный эффект',
                  trailing: Text(
                    '${m.fps} FPS',
                    style: TextStyle(
                        color: m.lowQuality
                            ? const Color(0xFFFFB020)
                            : const Color(0xFF57F287),
                        fontSize: 12,
                        fontWeight: FontWeight.w700),
                  ),
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  static String _blurPreset(double blur) {
    if ((blur - 8).abs() < 1.5) return 'Light';
    if ((blur - 18).abs() < 1.5) return 'Medium';
    if ((blur - 30).abs() < 1.5) return 'Heavy';
    return 'Custom';
  }

  // ---------------------------------------------------------------------------
  // 3. Player
  // ---------------------------------------------------------------------------
  Widget _player(BuildContext context) {
    final SonoraScope scope = SonoraScope.of(context);
    final AppSettings s = scope.s;
    return SettingsPage(
      title: 'Плеер',
      subtitle: 'Транспорт, очередь и мини-плеер',
      children: <Widget>[
        SettingsCard(
          title: 'Транспорт',
          icon: Icons.play_circle_outline_rounded,
          children: <Widget>[
            SettingSwitchRow(
              title: 'Прогресс в мини-плеере',
              description: 'Тонкая полоса прогресса под названием трека',
              value: s.showMiniProgress,
              onChanged: (bool v) => _upd(
                  context, (AppSettings x) => x.copyWith(showMiniProgress: v)),
            ),
            SettingSwitchRow(
              title: 'Gapless',
              description: 'Без паузы между треками (libmpv)',
              value: s.gapless,
              onChanged: (bool v) =>
                  _upd(context, (AppSettings x) => x.copyWith(gapless: v)),
            ),
            SettingSwitchRow(
              title: 'Нормализация громкости',
              description: 'ReplayGain/LUFS — выравнивает уровень треков',
              badge: 'DEMO',
              value: s.normalize,
              onChanged: (bool v) =>
                  _upd(context, (AppSettings x) => x.copyWith(normalize: v)),
            ),
            SettingSlider(
              title: 'Кроссфейд',
              description: 'Плавный переход между треками',
              tooltip: 'Требует второго экземпляра плеера — DSP-часть пока заглушка',
              value: s.crossfadeSec,
              min: 0,
              max: 12,
              divisions: 12,
              format: (double v) => v < 0.5 ? 'выкл' : '${v.round()} с',
              onChanged: (double v) => _upd(
                  context, (AppSettings x) => x.copyWith(crossfadeSec: v)),
            ),
            SettingRow(
              title: 'Шаг перемотки',
              description: 'Стрелки ← → в приложении',
              trailing: Text('${s.seekStep} с',
                  style: TextStyle(
                      color: scope.palette.accent,
                      fontSize: 12,
                      fontWeight: FontWeight.w700)),
            ),
            ChoiceRow(
              options: const <String>['5', '10', '30'],
              selected: '${s.seekStep}',
              onSelect: (String v) => _upd(
                  context, (AppSettings x) => x.copyWith(seekStep: int.parse(v))),
            ),
          ],
        ),
        SettingsCard(
          title: 'Быстрые действия',
          icon: Icons.bolt_rounded,
          children: <Widget>[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                GlassChip(
                  label: 'Эквалайзер',
                  icon: Icons.equalizer_rounded,
                  onTap: () => showEqualizerSheet(context),
                ),
                GlassChip(
                  label: 'Очередь',
                  icon: Icons.queue_music_rounded,
                  onTap: () => showQueueSheet(context),
                ),
                GlassChip(
                  label: 'Открыть плеер',
                  icon: Icons.open_in_full_rounded,
                  onTap: () => Navigator.of(context).push<void>(
                      MaterialPageRoute<void>(
                          builder: (BuildContext c) => const NowPlayingScreen())),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 4. Sound
  // ---------------------------------------------------------------------------
  Widget _sound(BuildContext context) {
    final SonoraScope scope = SonoraScope.of(context);
    final AppSettings s = scope.s;
    return SettingsPage(
      title: 'Звук',
      subtitle: 'Эквалайзер, эффекты и качество стриминга',
      children: <Widget>[
        SettingsCard(
          title: 'Эквалайзер',
          icon: Icons.graphic_eq_rounded,
          subtitle: '10 полос ISO: 31 Гц … 16 кГц',
          children: <Widget>[
            SettingRow(
              title: 'Открыть эквалайзер',
              description: 'Пресеты, preamp, bass boost, virtualizer, reverb',
              trailing: Icon(Icons.chevron_right_rounded,
                  color: scope.palette.muted),
              onTap: () => showEqualizerSheet(context),
            ),
            const InfoNote(
              text: 'UI и профили работают полностью. Применение к аудио '
                  '(mpv af-граф) — заглушка в этой сборке: аудио-движок '
                  'audioplayers не отдаёт доступ к DSP.',
            ),
          ],
        ),
        SettingsCard(
          title: 'Громкость',
          icon: Icons.volume_up_rounded,
          children: <Widget>[
            SettingSlider(
              title: 'Уровень',
              description: 'Применяется к текущему движку',
              value: s.volume,
              min: 0,
              max: 1,
              format: (double v) => '${(v * 100).round()}%',
              onChanged: (double v) {
                _upd(context, (AppSettings x) => x.copyWith(volume: v));
                scope.player.setVolume(v);
              },
            ),
          ],
        ),
        SettingsCard(
          title: 'Качество',
          icon: Icons.high_quality_rounded,
          children: <Widget>[
            ChoiceRow(
              options: const <String>['auto', 'high', 'balanced', 'low'],
              selected: s.quality,
              onSelect: (String v) => _upd(
                  context, (AppSettings x) => x.copyWith(quality: v)),
            ),
            const InfoNote(
              text: 'Пресет quality управляет и графикой: в low отключается '
                  'преломление и снижается blur.',
            ),
          ],
        ),
        SettingsCard(
          title: 'Движок',
          icon: Icons.memory_rounded,
          children: <Widget>[
            SettingRow(
              title: 'Аудио-бэкенд',
              description: scope.player.engineKind,
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  color: scope.player.audioAvailable
                      ? const Color(0xFF57F287).withOpacity(0.15)
                      : const Color(0xFFFFB020).withOpacity(0.15),
                ),
                child: Text(
                  scope.player.audioAvailable ? 'звук есть' : 'без звука',
                  style: TextStyle(
                      color: scope.player.audioAvailable
                          ? const Color(0xFF57F287)
                          : const Color(0xFFFFB020),
                      fontSize: 10,
                      fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 5. Sources
  // ---------------------------------------------------------------------------
  Widget _sources(BuildContext context) {
    return SettingsPage(
      title: 'Источники',
      subtitle: 'Аккаунты, приоритет и участие в поиске',
      children: <Widget>[
        for (int i = 0; i < MusicSource.values.length; i++)
          _SourceCard(source: MusicSource.values[i], connected: i < 3),
        const InfoNote(
          text: 'Подключение Яндекс/VK/Apple/SoundCloud требует официальных '
              'договоров и DRM — в демо это заглушки. Реально работают '
              'локальные файлы и self-hosted (Navidrome/Jellyfin).',
          icon: Icons.gavel_rounded,
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 6. Library
  // ---------------------------------------------------------------------------
  Widget _library(BuildContext context) {
    final SonoraScope scope = SonoraScope.of(context);
    return SettingsPage(
      title: 'Библиотека',
      subtitle: 'Хранилище, сканирование и синхронизация',
      children: <Widget>[
        SettingsCard(
          title: 'Хранилище',
          icon: Icons.folder_open_rounded,
          children: <Widget>[
            SettingRow(
              title: 'Папка данных',
              description: LocalStore.dir.path,
              trailing: Icon(Icons.copy_rounded,
                  size: 15, color: scope.palette.muted),
              tooltip: 'Здесь лежит settings.json',
            ),
            SettingRow(
              title: 'Проиндексировано треков',
              description: 'Демо-библиотека из assets/audio',
              trailing: Text('6',
                  style: TextStyle(
                      color: scope.palette.accent,
                      fontSize: 12,
                      fontWeight: FontWeight.w700)),
            ),
          ],
        ),
        SettingsCard(
          title: 'Действия',
          icon: Icons.sync_rounded,
          children: <Widget>[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                GlassChip(
                  label: 'Пересканировать',
                  icon: Icons.refresh_rounded,
                  onTap: () => _snack(context, 'Сканирование завершено: 6 треков'),
                ),
                GlassChip(
                  label: 'Очистить кэш обложек',
                  icon: Icons.cleaning_services_rounded,
                  onTap: () => _snack(context, 'Обложки генерируются на лету — кэш пуст'),
                ),
              ],
            ),
          ],
        ),
        SettingsCard(
          title: 'Синхронизация',
          icon: Icons.cloud_sync_outlined,
          children: <Widget>[
            SettingRow(
              title: 'Self-hosted сервер',
              description: 'https://navidrome.local — не подключён',
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  color: Colors.white.withOpacity(0.07),
                ),
                child: Text('DEMO',
                    style: TextStyle(
                        color: scope.palette.muted,
                        fontSize: 9,
                        fontWeight: FontWeight.w800)),
              ),
            ),
            const InfoNote(
              text: 'Протокол синхронизации (outbox + LWW) описан, но сервер '
                  'не входит в демо-сборку.',
            ),
          ],
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 7. Notifications & widget
  // ---------------------------------------------------------------------------
  Widget _notifications(BuildContext context) {
    final AppPalette pal = SonoraScope.of(context).palette;
    return SettingsPage(
      title: 'Уведомления и виджет',
      subtitle: 'Мини-плеер, трей, системные медиа-контролы',
      children: <Widget>[
        SettingsCard(
          title: 'Платформенные интеграции',
          icon: Icons.widgets_outlined,
          children: <Widget>[
            SettingRow(
              title: 'Android App Widget',
              description: 'Glance-виджет 2×1 / 4×1 / 4×2 + MediaSession',
              badge: 'ROADMAP',
              trailing: _statusDot(pal, false),
            ),
            SettingRow(
              title: 'Windows SMTC',
              description: 'System Media Transport Controls + мини-окно',
              badge: 'ROADMAP',
              trailing: _statusDot(pal, false),
            ),
            SettingRow(
              title: 'Linux MPRIS',
              description: 'Управление из GNOME/KDE, playerctl',
              badge: 'ROADMAP',
              trailing: _statusDot(pal, false),
            ),
            SettingRow(
              title: 'Иконка в трее',
              description: 'AppIndicator / Shell_NotifyIcon',
              badge: 'ROADMAP',
              trailing: _statusDot(pal, false),
            ),
          ],
        ),
        SettingsCard(
          title: 'Стиль мини-плеера',
          icon: Icons.picture_in_picture_alt_rounded,
          children: <Widget>[
            ChoiceRow(
              options: const <String>['Компакт', 'Стандарт', 'Широкий'],
              selected: 'Стандарт',
              onSelect: (String v) => _snack(
                  context, 'Стиль «$v» применится после релиза мини-окна'),
            ),
            const InfoNote(
              text: 'Нативные виджеты требуют платформенного кода (Kotlin/C++). '
                  'В этой сборке их нет — есть встроенный мини-плеер, который '
                  'работает на всех трёх платформах.',
            ),
          ],
        ),
      ],
    );
  }

  Widget _statusDot(AppPalette pal, bool on) => Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: on ? const Color(0xFF57F287) : pal.muted.withOpacity(0.5),
        ),
      );

  // ---------------------------------------------------------------------------
  // 8. Hotkeys
  // ---------------------------------------------------------------------------
  Widget _hotkeys(BuildContext context) {
    final AppPalette pal = SonoraScope.of(context).palette;
    const List<List<String>> rows = <List<String>>[
      <String>['Space', 'Играть / пауза'],
      <String>['→ / ←', 'Перемотка ±шаг'],
      <String>['Ctrl + → / ←', 'Следующий / предыдущий трек'],
      <String>['↑ / ↓', 'Громкость ±5 %'],
      <String>['M', 'Без звука'],
      <String>['L', 'Нравится'],
      <String>['S', 'Перемешать'],
      <String>['R', 'Повтор'],
      <String>['Q', 'Очередь'],
      <String>['E', 'Эквалайзер'],
      <String>['Esc', 'Закрыть плеер / диалог'],
    ];
    return SettingsPage(
      title: 'Горячие клавиши',
      subtitle: 'Работают, когда окно приложения в фокусе',
      children: <Widget>[
        SettingsCard(
          title: 'Клавиши',
          icon: Icons.keyboard_outlined,
          children: <Widget>[
            for (final List<String> r in rows)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  children: <Widget>[
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        color: Colors.white.withOpacity(0.07),
                        border: Border.all(
                            color: Colors.white.withOpacity(0.12), width: 1),
                      ),
                      child: Text(r[0],
                          style: TextStyle(
                              color: pal.text,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              fontFeatures: const <FontFeature>[
                                FontFeature.tabularFigures()
                              ])),
                    ),
                    const SizedBox(width: 12),
                    Text(r[1],
                        style: TextStyle(color: pal.muted, fontSize: 12)),
                  ],
                ),
              ),
          ],
        ),
        const InfoNote(
          text: 'Глобальные хоткеи (вне окна) требуют нативного плагина: '
              'RegisterHotKey на Windows, XGrabKey на X11, портал '
              'GlobalShortcuts на Wayland.',
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 9. Privacy
  // ---------------------------------------------------------------------------
  Widget _privacy(BuildContext context) {
    final SonoraScope scope = SonoraScope.of(context);
    return SettingsPage(
      title: 'Приватность и данные',
      subtitle: 'Всё хранится локально — по умолчанию',
      children: <Widget>[
        SettingsCard(
          title: 'Данные',
          icon: Icons.shield_outlined,
          children: <Widget>[
            SettingSwitchRow(
              title: 'История прослушивания',
              description: 'Локально, в JSON/SQLite рядом с настройками',
              value: true,
              onChanged: (bool v) => _snack(context, 'История: ${v ? 'вкл' : 'выкл'}'),
            ),
            SettingSwitchRow(
              title: 'Телеметрия и крашлитинг',
              description: 'По умолчанию выключено, отправка только с согласия',
              value: false,
              onChanged: (bool v) =>
                  _snack(context, 'Телеметрия: ${v ? 'вкл' : 'выкл'} (демо)'),
            ),
            SettingRow(
              title: 'Файл настроек',
              description: '${LocalStore.dir.path}${Platform.pathSeparator}settings.json',
              trailing: Icon(Icons.description_outlined,
                  size: 15, color: scope.palette.muted),
            ),
          ],
        ),
        SettingsCard(
          title: 'Управление',
          icon: Icons.delete_outline_rounded,
          children: <Widget>[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                GlassChip(
                  label: 'Экспортировать всё',
                  icon: Icons.download_rounded,
                  onTap: () =>
                      _showExport(context, scope.settings.exportJson()),
                ),
                GlassChip(
                  label: 'Сбросить настройки',
                  icon: Icons.restart_alt_rounded,
                  onTap: () => _confirmReset(context),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 10. About
  // ---------------------------------------------------------------------------
  Widget _about(BuildContext context) {
    final SonoraScope scope = SonoraScope.of(context);
    final AppPalette pal = scope.palette;
    return SettingsPage(
      title: 'О приложении',
      subtitle: 'Sonora 1.0.0 (демо-сборка)',
      children: <Widget>[
        SettingsCard(
          title: 'Диагностика',
          icon: Icons.monitor_heart_outlined,
          children: <Widget>[
            _kv('Версия', '1.0.0+1', pal),
            _kv('Платформа', Platform.operatingSystem, pal),
            _kv('Аудио-движок', scope.player.engineKind, pal),
            _kv('Звук доступен', scope.player.audioAvailable ? 'да' : 'нет', pal),
            _kv('Rich Presence', scope.discord.statusLabel, pal),
            _kv('Папка данных', LocalStore.dir.path, pal),
          ],
        ),
        SettingsCard(
          title: 'Лицензии и право',
          icon: Icons.gavel_rounded,
          children: <Widget>[
            const InfoNote(
              text: 'Flutter (BSD-3), audioplayers (MIT), ffi (BSD-3). '
                  'Демо-треки сгенерированы скриптом tool/gen_audio.py — '
                  'никаких сторонних фонограмм.',
            ),
            const InfoNote(
              text: 'Sonora не аффилирована со Spotify, Apple, Яндекс, VK, '
                  'SoundCloud и YouTube. Приложение не обходит DRM и не '
                  'извлекает защищённые потоки.',
              icon: Icons.shield_rounded,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: <Widget>[
                GlassChip(
                  label: 'Сбросить настройки',
                  icon: Icons.restart_alt_rounded,
                  onTap: () => _confirmReset(context),
                ),
                GlassChip(
                  label: 'Скопировать отчёт',
                  icon: Icons.copy_rounded,
                  onTap: () => _snack(context,
                      'Отчёт: flutter demo · ${Platform.operatingSystem} · ${scope.player.engineKind}'),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _kv(String k, String v, AppPalette pal) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SizedBox(
              width: 130,
              child: Text(k,
                  style: TextStyle(color: pal.muted, fontSize: 11.5)),
            ),
            Expanded(
              child: Text(v,
                  style: TextStyle(color: pal.text, fontSize: 11.5)),
            ),
          ],
        ),
      );

  // ---------------------------------------------------------------------------
  // Dialogs
  // ---------------------------------------------------------------------------
  void _snack(BuildContext context, String text) {
    final AppPalette pal = SonoraScope.of(context).palette;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: pal.bg1,
        behavior: SnackBarBehavior.floating,
        content: Text(text, style: TextStyle(color: pal.text, fontSize: 12.5)),
      ),
    );
  }

  Future<void> _showExport(BuildContext context, String json) async {
    final AppPalette pal = SonoraScope.of(context).palette;
    await showDialog<void>(
      context: context,
      builder: (BuildContext c) => AlertDialog(
        backgroundColor: pal.bg1,
        title: Text('Экспорт профиля',
            style: TextStyle(color: pal.text, fontSize: 16)),
        content: SizedBox(
          width: 560,
          height: 360,
          child: SingleChildScrollView(
            child: SelectableText(json,
                style: TextStyle(
                    color: pal.text.withOpacity(0.85),
                    fontSize: 11,
                    height: 1.4)),
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(c).pop(),
            child: Text('Закрыть', style: TextStyle(color: pal.accent)),
          ),
        ],
      ),
    );
  }

  Future<void> _showImport(BuildContext context) async {
    final AppPalette pal = SonoraScope.of(context).palette;
    final TextEditingController ctrl = TextEditingController();
    bool ok = true;
    await showDialog<void>(
      context: context,
      builder: (BuildContext c) => StatefulBuilder(
        builder: (BuildContext c, void Function(void Function()) setState) =>
            AlertDialog(
          backgroundColor: pal.bg1,
          title: Text('Импорт профиля (JSON)',
              style: TextStyle(color: pal.text, fontSize: 16)),
          content: SizedBox(
            width: 560,
            height: 320,
            child: TextField(
              controller: ctrl,
              maxLines: null,
              expands: true,
              style: TextStyle(color: pal.text, fontSize: 11),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: '{ "glass": { "blur": 24 }, ... }',
                hintStyle: TextStyle(color: pal.muted),
              ),
            ),
          ),
          actions: <Widget>[
            if (!ok)
              Text('Ошибка JSON',
                  style: TextStyle(
                      color: const Color(0xFFED4245), fontSize: 11)),
            TextButton(
              onPressed: () => Navigator.of(c).pop(),
              child: Text('Отмена', style: TextStyle(color: pal.muted)),
            ),
            TextButton(
              onPressed: () {
                final bool success =
                    SonoraScope.of(context).settings.importJson(ctrl.text);
                if (success) {
                  Navigator.of(c).pop();
                } else {
                  setState(() => ok = false);
                }
              },
              child: Text('Применить', style: TextStyle(color: pal.accent)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmReset(BuildContext context) async {
    final AppPalette pal = SonoraScope.of(context).palette;
    final bool? yes = await showDialog<bool>(
      context: context,
      builder: (BuildContext c) => AlertDialog(
        backgroundColor: pal.bg1,
        title: Text('Сбросить настройки?',
            style: TextStyle(color: pal.text, fontSize: 16)),
        content: Text('Все темы, стекло, анимации и Discord-профили вернутся к '
            'значениям по умолчанию.',
            style: TextStyle(color: pal.muted, fontSize: 12.5)),
        actions: <Widget>[
          TextButton(
              onPressed: () => Navigator.of(c).pop(false),
              child: Text('Отмена', style: TextStyle(color: pal.muted))),
          TextButton(
              onPressed: () => Navigator.of(c).pop(true),
              child: Text('Сбросить',
                  style: TextStyle(color: const Color(0xFFED4245)))),
        ],
      ),
    );
    if (yes == true && context.mounted) {
      SonoraScope.of(context).settings.resetAll();
    }
  }
}

class _AnimPreview extends StatefulWidget {
  const _AnimPreview();

  @override
  State<_AnimPreview> createState() => _AnimPreviewState();
}

class _AnimPreviewState extends State<_AnimPreview> {
  bool _right = false;

  @override
  Widget build(BuildContext context) {
    final AppPalette pal = SonoraScope.of(context).palette;
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Container(
            height: 34,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.black.withOpacity(0.22),
              border: Border.all(color: Colors.white.withOpacity(0.06)),
            ),
            child: AnimatedAlign(
              alignment:
                  _right ? Alignment.centerRight : Alignment.centerLeft,
              duration: motionDuration(context, 520),
              curve: Curves.elasticOut,
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                      colors: <Color>[pal.accent, pal.accent2]),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                        color: pal.accent.withOpacity(0.6),
                        blurRadius: 16,
                        spreadRadius: 2),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: GlassChip(
              label: 'Проиграть анимацию',
              icon: Icons.play_arrow_rounded,
              onTap: () => setState(() => _right = !_right),
            ),
          ),
        ],
      ),
    );
  }
}

class _TabTile extends StatelessWidget {
  const _TabTile({
    required this.def,
    required this.active,
    required this.onTap,
  });

  final _TabDef def;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final AppPalette pal = SonoraScope.of(context).palette;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(13),
          color: active ? pal.accent.withOpacity(0.15) : Colors.transparent,
          border: Border.all(
              color: active
                  ? pal.accent.withOpacity(0.4)
                  : Colors.transparent),
        ),
        child: Row(
          children: <Widget>[
            Icon(def.icon, size: 17, color: active ? pal.accent : pal.muted),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(def.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: active ? pal.text : pal.text.withOpacity(0.8),
                          fontSize: 12.5,
                          fontWeight:
                              active ? FontWeight.w700 : FontWeight.w500)),
                  Text(def.desc,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: pal.muted, fontSize: 9.5)),
                ],
              ),
            ),
            if (active)
              Icon(Icons.chevron_right_rounded,
                  size: 16, color: pal.accent),
          ],
        ),
      ),
    );
  }
}

class _ThemeChip extends StatelessWidget {
  const _ThemeChip({
    required this.palette,
    required this.selected,
    required this.onTap,
  });

  final AppPalette palette;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: selected
              ? Colors.white.withOpacity(0.10)
              : Colors.white.withOpacity(0.03),
          border: Border.all(
              color: selected
                  ? palette.accent
                  : Colors.white.withOpacity(0.10),
              width: selected ? 1.6 : 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(7),
                gradient: LinearGradient(
                    colors: <Color>[palette.accent, palette.accent2]),
              ),
            ),
            const SizedBox(width: 8),
            Text(palette.name,
                style: TextStyle(
                    color: palette.text.withOpacity(selected ? 1 : 0.8),
                    fontSize: 12,
                    fontWeight:
                        selected ? FontWeight.w700 : FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

class _SourceCard extends StatelessWidget {
  const _SourceCard({required this.source, required this.connected});

  final MusicSource source;
  final bool connected;

  @override
  Widget build(BuildContext context) {
    final SonoraScope scope = SonoraScope.of(context);
    final AppPalette pal = scope.palette;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: LiquidGlass(
        radius: 16,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: <Widget>[
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: source.color.withOpacity(0.15),
                border: Border.all(
                    color: source.color.withOpacity(0.35), width: 1),
              ),
              child: Icon(source.icon, size: 17, color: source.color),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(source.label,
                      style: TextStyle(
                          color: pal.text,
                          fontSize: 13,
                          fontWeight: FontWeight.w600)),
                  Text(
                    connected
                        ? 'Подключён · участвует в поиске'
                        : 'Не подключён · только каталог',
                    style: TextStyle(color: pal.muted, fontSize: 10.5),
                  ),
                ],
              ),
            ),
            GlassChip(
              label: connected ? 'Настроить' : 'Подключить',
              dense: true,
              selected: connected,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: pal.bg1,
                    behavior: SnackBarBehavior.floating,
                    content: Text(
                      connected
                          ? 'Настройки ${source.label}: приоритет, поиск, синк (демо)'
                          : 'OAuth-флоу ${source.label} — заглушка в демо-сборке',
                      style: TextStyle(color: pal.text, fontSize: 12),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
