import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';

import '../../../app_scope.dart';
import '../../../core/format.dart';
import '../../../core/palette.dart';
import '../../../models/settings.dart';
import '../../../models/track.dart';
import '../../../services/discord/discord_presence_service.dart';
import '../../../services/discord/discord_template.dart';
import '../../glass/glass.dart';
import 'settings_widgets.dart';

class DiscordTab extends StatefulWidget {
  const DiscordTab({super.key});

  @override
  State<DiscordTab> createState() => _DiscordTabState();
}

class _DiscordTabState extends State<DiscordTab> {
  bool _init = false;
  DiscordSettings _draft = const DiscordSettings();
  Timer? _debounce;

  final TextEditingController _appId = TextEditingController();
  final TextEditingController _state = TextEditingController();
  final TextEditingController _signature = TextEditingController();
  final TextEditingController _b1l = TextEditingController();
  final TextEditingController _b1u = TextEditingController();
  final TextEditingController _b2l = TextEditingController();
  final TextEditingController _b2u = TextEditingController();
  final TextEditingController _large = TextEditingController();
  final TextEditingController _small = TextEditingController();
  final TextEditingController _profileName = TextEditingController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_init) return;
    _init = true;
    _draft = SonoraScope.of(context).s.discord;
    _syncControllers();
  }

  void _syncControllers() {
    _appId.text = _draft.appId;
    _state.text = _draft.stateTemplate;
    _signature.text = _draft.signature;
    _b1l.text = _draft.button1Label;
    _b1u.text = _draft.button1Url;
    _b2l.text = _draft.button2Label;
    _b2u.text = _draft.button2Url;
    _large.text = _draft.largeImageKey;
    _small.text = _draft.smallImageKey;
    _profileName.text = _draft.profileName;
  }

  @override
  void dispose() {
    _debounce?.cancel();
    for (final TextEditingController c in <TextEditingController>[
      _appId,
      _state,
      _signature,
      _b1l,
      _b1u,
      _b2l,
      _b2u,
      _large,
      _small,
      _profileName,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _set(DiscordSettings next) {
    setState(() => _draft = next);
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      final SonoraScope scope = SonoraScope.of(context);
      scope.settings.update((AppSettings s) => s.copyWith(discord: _draft));
    });
  }

  @override
  Widget build(BuildContext context) {
    final SonoraScope scope = SonoraScope.of(context);
    final AppPalette pal = scope.palette;
    final DiscordPresenceService discord = scope.discord;
    final Track? track = scope.player.current;

    return SettingsPage(
      title: 'Discord Rich Presence',
      subtitle: 'Статус «слушает» с кастомным оформлением',
      children: <Widget>[
        ListenableBuilder(
          listenable: discord,
          builder: (BuildContext context, _) => _StatusCard(discord: discord),
        ),
        if (Platform.isAndroid)
          const InfoNote(
            text: 'На Android Discord RPC официально не работает: IPC-сокет '
                'существует только в десктопном клиенте. Вкладка остаётся для '
                'настройки профиля — он применится на desktop.',
            icon: Icons.smartphone_rounded,
          ),
        SettingsCard(
          title: 'Приложение Discord',
          icon: Icons.apps_rounded,
          subtitle: 'Без Application ID статус отправить нельзя',
          children: <Widget>[
            _Field(
              label: 'Application ID',
              hint: 'например 1234567890123456789',
              controller: _appId,
              onChanged: (String v) => _set(_draft.copyWith(appId: v)),
            ),
            SettingSwitchRow(
              title: 'Показывать прогресс',
              description: 'Таймстемпы start/end — Discord сам рисует полосу',
              value: _draft.showProgress,
              onChanged: (bool v) => _set(_draft.copyWith(showProgress: v)),
            ),
            SettingSwitchRow(
              title: 'Показывать источник',
              description: 'Маленькая иконка сервиса (Navidrome, Spotify, …)',
              value: _draft.showSource,
              onChanged: (bool v) => _set(_draft.copyWith(showSource: v)),
            ),
            SettingSwitchRow(
              title: 'Статус «Listening to»',
              description: 'Иначе Discord покажет «Playing»',
              value: _draft.listeningType,
              onChanged: (bool v) => _set(_draft.copyWith(listeningType: v)),
            ),
            const InfoNote(
              text: '1) discord.com/developers → New Application → скопируйте '
                  'Application ID. 2) Rich Presence → Art Assets → загрузите '
                  'картинки (PNG/JPG, до 512 КБ) и запомните их имена.',
            ),
          ],
        ),
        SettingsCard(
          title: 'Текст статуса',
          icon: Icons.text_fields_rounded,
          children: <Widget>[
            LockedField(
              label: 'DETAILS — НАЗВАНИЕ ТРЕКА',
              value: track?.title ?? 'Нет активного трека',
              hint: 'Название трека — только из плеера. В модели нет поля для '
                  'ручного ввода, поэтому изменить его невозможно.',
            ),
            const InfoNote(
              text: '🔒 Первая строка всегда формируется из плеера. Ниже можно '
                  'настроить вторую строку и подпись — но не название трека.',
              icon: Icons.lock_rounded,
            ),
            const SizedBox(height: 10),
            _Field(
              label: 'STATE — вторая строка',
              hint: '{artist} · {album}',
              controller: _state,
              onChanged: (String v) => _set(_draft.copyWith(stateTemplate: v)),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 2, bottom: 6),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: <Widget>[
                  for (final String token in DiscordTemplate.tokens)
                    _TokenChip(
                      token: token,
                      onTap: () {
                        final String cur = _state.text;
                        final String next =
                            cur.isEmpty ? token : '$cur $token';
                        _state.text = next;
                        _set(_draft.copyWith(stateTemplate: next));
                      },
                    ),
                ],
              ),
            ),
            _Field(
              label: 'Подпись (доп. текст)',
              hint: 'например: на виниле · ночной эфир',
              controller: _signature,
              onChanged: (String v) => _set(_draft.copyWith(signature: v)),
            ),
            if (_state.text.toLowerCase().contains('{track}'))
              const InfoNote(
                text: 'Токен {track} игнорируется: название трека подставляется '
                    'автоматически и не может быть переопределено.',
                icon: Icons.block_rounded,
              ),
            const SizedBox(height: 6),
            _RenderedLines(draft: _draft, track: track),
          ],
        ),
        SettingsCard(
          title: 'Кнопки в статусе',
          icon: Icons.touch_app_rounded,
          subtitle: 'До двух кнопок, label ≤ 32 символа, URL http(s)',
          children: <Widget>[
            SettingSwitchRow(
              title: 'Показывать кнопки',
              description: 'Discord отображает максимум две',
              value: _draft.showButtons,
              onChanged: (bool v) => _set(_draft.copyWith(showButtons: v)),
            ),
            _Field(
              label: 'Кнопка 1 — текст',
              hint: 'Открыть Sonora',
              controller: _b1l,
              onChanged: (String v) => _set(_draft.copyWith(button1Label: v)),
            ),
            _Field(
              label: 'Кнопка 1 — URL',
              hint: 'https://…',
              controller: _b1u,
              onChanged: (String v) => _set(_draft.copyWith(button1Url: v)),
            ),
            _Field(
              label: 'Кнопка 2 — текст',
              hint: 'Плейлист недели',
              controller: _b2l,
              onChanged: (String v) => _set(_draft.copyWith(button2Label: v)),
            ),
            _Field(
              label: 'Кнопка 2 — URL',
              hint: 'https://…',
              controller: _b2u,
              onChanged: (String v) => _set(_draft.copyWith(button2Url: v)),
            ),
          ],
        ),
        SettingsCard(
          title: 'Картинки',
          icon: Icons.image_outlined,
          subtitle: 'Имена артефактов из Rich Presence → Art Assets',
          children: <Widget>[
            _Field(
              label: 'large_image (фон / обложка)',
              hint: 'sonora_cover',
              controller: _large,
              onChanged: (String v) => _set(_draft.copyWith(largeImageKey: v)),
            ),
            _Field(
              label: 'small_image (иконка источника)',
              hint: 'оставьте пустым — подставится src_nd / src_sp / …',
              controller: _small,
              onChanged: (String v) => _set(_draft.copyWith(smallImageKey: v)),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                children: <Widget>[
                  Text('Фон превью',
                      style: TextStyle(color: pal.muted, fontSize: 11.5)),
                  const SizedBox(width: 10),
                  for (final String preset in <String>[
                    'aurora',
                    'midnight',
                    'sunset',
                    'mono',
                  ])
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: GlassChip(
                        label: preset,
                        dense: true,
                        selected: _draft.bgPreset == preset,
                        onTap: () => _set(_draft.copyWith(bgPreset: preset)),
                      ),
                    ),
                ],
              ),
            ),
            const InfoNote(
              text: 'Discord показывает статичные PNG/JPG, GIF не '
                  'анимируется в Rich Presence. Загрузите картинку 512×512 '
                  '(до 512 КБ) как артефакт и укажите её имя выше.',
            ),
          ],
        ),
        SettingsCard(
          title: 'Профили RPC',
          icon: Icons.dashboard_rounded,
          subtitle: 'Быстрое переключение «Стрим / Чилл / Ночь»',
          children: <Widget>[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                for (final String preset in <String>['Стрим', 'Чилл', 'Ночь'])
                  GlassChip(
                    label: preset,
                    dense: true,
                    icon: Icons.bolt_rounded,
                    onTap: () {
                      final DiscordSettings next = _applyPreset(preset);
                      _syncControllers();
                      _set(next);
                    },
                  ),
                for (final DiscordProfile p in _draft.profiles)
                  GlassChip(
                    label: p.name,
                    dense: true,
                    selected: p.name == _draft.profileName,
                    icon: Icons.person_rounded,
                    onTap: () {
                      final DiscordSettings next = _draft.copyWith(
                        profileName: p.name,
                        stateTemplate: p.stateTemplate,
                        signature: p.signature,
                        largeImageKey: p.largeImageKey,
                        smallImageKey: p.smallImageKey,
                      );
                      _syncControllers();
                      _set(next);
                    },
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: <Widget>[
                Expanded(
                  child: _Field(
                    label: 'Сохранить текущий как профиль',
                    hint: 'Имя профиля',
                    controller: _profileName,
                    onChanged: (String v) =>
                        _set(_draft.copyWith(profileName: v)),
                  ),
                ),
                const SizedBox(width: 8),
                GlassChip(
                  label: 'Сохранить',
                  icon: Icons.save_rounded,
                  onTap: () {
                    final String name = _profileName.text.trim().isEmpty
                        ? 'Профиль'
                        : _profileName.text.trim();
                    final List<DiscordProfile> list = <DiscordProfile>[
                      ..._draft.profiles.where((DiscordProfile p) =>
                          p.name != name),
                      DiscordProfile(
                        name: name,
                        stateTemplate: _draft.stateTemplate,
                        signature: _draft.signature,
                        largeImageKey: _draft.largeImageKey,
                        smallImageKey: _draft.smallImageKey,
                      ),
                    ];
                    _set(_draft.copyWith(profiles: list, profileName: name));
                  },
                ),
              ],
            ),
          ],
        ),
        SettingsCard(
          title: 'Превью',
          icon: Icons.visibility_outlined,
          subtitle: 'Именно это увидят другие в вашем профиле',
          children: <Widget>[
            Center(
              child: DiscordPreviewCard(
                draft: _draft,
                track: track,
                playing: scope.player.playing,
                position: scope.player.position.value,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                GlassChip(
                  label: 'Применить и переподключиться',
                  icon: Icons.refresh_rounded,
                  selected: true,
                  onTap: () async {
                    scope.settings.update(
                        (AppSettings s) => s.copyWith(discord: _draft));
                    await scope.discord.reconnect();
                  },
                ),
                const SizedBox(width: 8),
                GlassChip(
                  label: 'Показать превью',
                  icon: Icons.send_rounded,
                  onTap: () {
                    final PresenceModel? p = discord.preview;
                    final AppPalette p2 = pal;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: p2.bg1,
                        behavior: SnackBarBehavior.floating,
                        content: Text(
                          p == null
                              ? 'Нет активного трека'
                              : 'Отправлено: ${p.details} — ${p.state ?? ''}',
                          style: TextStyle(color: p2.text, fontSize: 12),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  DiscordSettings _applyPreset(String name) {
    switch (name) {
      case 'Стрим':
        return _draft.copyWith(
          profileName: 'Стрим',
          stateTemplate: '🎧 {source} · стрим',
          signature: 'смотрю чат',
          showButtons: true,
          button1Label: 'Смотреть',
          button1Url: 'https://twitch.tv/',
        );
      case 'Чилл':
        return _draft.copyWith(
          profileName: 'Чилл',
          stateTemplate: '{artist} · {album}',
          signature: 'чилю',
          showButtons: false,
        );
      case 'Ночь':
      default:
        return _draft.copyWith(
          profileName: 'Ночь',
          stateTemplate: '🌙 {artist}',
          signature: '{time} · ночной эфир',
          showButtons: false,
          bgPreset: 'midnight',
        );
    }
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.discord});
  final DiscordPresenceService discord;

  @override
  Widget build(BuildContext context) {
    final AppPalette pal = SonoraScope.of(context).palette;
    final Color dot = switch (discord.status) {
      DiscordStatus.connected => const Color(0xFF57F287),
      DiscordStatus.connecting => const Color(0xFFFEE75C),
      DiscordStatus.off => pal.muted,
      DiscordStatus.noAppId => const Color(0xFFFEE75C),
      _ => const Color(0xFFED4245),
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: LiquidGlass(
        radius: 20,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(11),
                    color: const Color(0xFF5865F2).withOpacity(0.18),
                    border: Border.all(
                        color: const Color(0xFF5865F2).withOpacity(0.5)),
                  ),
                  child: const Icon(Icons.chat_bubble_rounded,
                      size: 19, color: Color(0xFF8B93FF)),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: dot,
                              boxShadow: <BoxShadow>[
                                BoxShadow(
                                    color: dot.withOpacity(0.8),
                                    blurRadius: 8)
                              ],
                            ),
                          ),
                          const SizedBox(width: 7),
                          Text(discord.statusLabel,
                              style: TextStyle(
                                  color: pal.text,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700)),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(discord.statusDetail,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: pal.muted, fontSize: 10.5)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: <Widget>[
                GlassChip(
                  label: 'Подключить',
                  icon: Icons.link_rounded,
                  selected: true,
                  onTap: discord.connect,
                ),
                const SizedBox(width: 8),
                GlassChip(
                  label: 'Отключить',
                  icon: Icons.link_off_rounded,
                  onTap: discord.disconnect,
                ),
                const Spacer(),
                if (discord.discordUser != null)
                  Text(discord.discordUser!,
                      style: TextStyle(color: pal.muted, fontSize: 10.5)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.hint,
    required this.controller,
    required this.onChanged,
  });

  final String label;
  final String hint;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final AppPalette pal = SonoraScope.of(context).palette;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(label,
              style: TextStyle(
                  color: pal.muted,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3)),
          const SizedBox(height: 5),
          TextField(
            controller: controller,
            onChanged: onChanged,
            style: TextStyle(color: pal.text, fontSize: 13),
            cursorColor: pal.accent,
            decoration: InputDecoration(
              isDense: true,
              filled: true,
              fillColor: Colors.black.withOpacity(0.24),
              hintText: hint,
              hintStyle: TextStyle(color: pal.muted.withOpacity(0.65), fontSize: 12),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(11),
                borderSide:
                    BorderSide(color: Colors.white.withOpacity(0.09)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(11),
                borderSide: BorderSide(color: pal.accent, width: 1.2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TokenChip extends StatelessWidget {
  const _TokenChip({required this.token, required this.onTap});
  final String token;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final AppPalette pal = SonoraScope.of(context).palette;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(7),
          color: pal.accent.withOpacity(0.12),
          border: Border.all(color: pal.accent.withOpacity(0.3), width: 0.8),
        ),
        child: Text(token,
            style: TextStyle(
                color: pal.accent,
                fontSize: 10.5,
                fontWeight: FontWeight.w600)),
      ),
    );
  }
}

class _RenderedLines extends StatelessWidget {
  const _RenderedLines({required this.draft, required this.track});
  final DiscordSettings draft;
  final Track? track;

  @override
  Widget build(BuildContext context) {
    final AppPalette pal = SonoraScope.of(context).palette;
    final Track? t = track;
    final String state = t == null
        ? '—'
        : <String>[
            DiscordTemplate.render(draft.stateTemplate, t),
            if (draft.signature.trim().isNotEmpty)
              DiscordTemplate.render(draft.signature, t),
          ].where((String s) => s.isNotEmpty).join('  ·  ');

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(11),
        color: Colors.black.withOpacity(0.22),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('Превью строк',
              style: TextStyle(color: pal.muted, fontSize: 9.5,
                  fontWeight: FontWeight.w700, letterSpacing: 0.5)),
          const SizedBox(height: 6),
          Row(
            children: <Widget>[
              Icon(Icons.lock_rounded, size: 11, color: pal.muted),
              const SizedBox(width: 5),
              Expanded(
                child: Text(t?.title ?? '—',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: pal.text,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(state,
              maxLines: 2,
              style: TextStyle(color: pal.muted, fontSize: 11.5)),
        ],
      ),
    );
  }
}

/// Discord-style activity card. Rendered purely from [PresenceModel] rules, so
/// it always matches what would be sent to the gateway.
class DiscordPreviewCard extends StatelessWidget {
  const DiscordPreviewCard({
    super.key,
    required this.draft,
    required this.track,
    required this.playing,
    required this.position,
  });

  final DiscordSettings draft;
  final Track? track;
  final bool playing;
  final Duration position;

  @override
  Widget build(BuildContext context) {
    final Track? t = track;
    final List<Color> bg = switch (draft.bgPreset) {
      'midnight' => <Color>[const Color(0xFF0B1020), const Color(0xFF1E1B4B)],
      'sunset' => <Color>[const Color(0xFF2A0F1E), const Color(0xFF7C2D12)],
      'mono' => <Color>[const Color(0xFF111214), const Color(0xFF2B2D31)],
      _ => <Color>[const Color(0xFF062033), const Color(0xFF1E1B4B)],
    };

    final String details = t?.title ?? 'Нет активного трека';
    final String state = t == null
        ? 'Запустите любой трек'
        : <String>[
            DiscordTemplate.render(draft.stateTemplate, t),
            if (draft.signature.trim().isNotEmpty)
              DiscordTemplate.render(draft.signature, t),
          ].where((String s) => s.isNotEmpty).join('  ·  ');

    final List<Map<String, String>> buttons = <Map<String, String>>[];
    if (draft.showButtons) {
      if (draft.button1Label.trim().isNotEmpty &&
          draft.button1Url.trim().isNotEmpty) {
        buttons.add(<String, String>{
          'label': draft.button1Label.trim(),
          'url': draft.button1Url.trim()
        });
      }
      if (draft.button2Label.trim().isNotEmpty &&
          draft.button2Url.trim().isNotEmpty) {
        buttons.add(<String, String>{
          'label': draft.button2Label.trim(),
          'url': draft.button2Url.trim()
        });
      }
    }

    return Container(
      width: 348,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: const Color(0xFF232428),
        border: Border.all(color: const Color(0xFF3BA55D).withOpacity(0.35)),
        boxShadow: <BoxShadow>[
          BoxShadow(
              color: Colors.black.withOpacity(0.45),
              blurRadius: 24,
              offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Stack(
                clipBehavior: Clip.none,
                children: <Widget>[
                  Container(
                    width: 62,
                    height: 62,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: bg,
                      ),
                    ),
                    child: Icon(
                      t == null ? Icons.music_note_rounded : Icons.graphic_eq_rounded,
                      color: Colors.white.withOpacity(0.75),
                      size: 26,
                    ),
                  ),
                  if (draft.showSource && t != null)
                    Positioned(
                      right: -4,
                      bottom: -4,
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF1E1F22),
                          border: Border.all(
                              color: const Color(0xFF232428), width: 2.5),
                        ),
                        child: Icon(t.source.icon,
                            size: 12, color: t.source.color),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        const Text('Sonora',
                            style: TextStyle(
                                color: Color(0xFFB9BBBE),
                                fontSize: 11,
                                fontWeight: FontWeight.w600)),
                        const Text('  ·  ',
                            style: TextStyle(
                                color: Color(0xFF6D6F78), fontSize: 11)),
                        Text(draft.listeningType ? 'Listening to' : 'Playing',
                            style: const TextStyle(
                                color: Color(0xFF6D6F78), fontSize: 11)),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: <Widget>[
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(3),
                            color: const Color(0xFFED4245),
                          ),
                          child: const Text('🔒',
                              style:
                                  TextStyle(fontSize: 8, color: Colors.white)),
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            details,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      state.isEmpty ? ' ' : state,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: Color(0xFFB9BBBE), fontSize: 11.5),
                    ),
                    if (draft.showProgress && t != null) ...<Widget>[
                      const SizedBox(height: 6),
                      Row(
                        children: <Widget>[
                          Icon(
                            playing
                                ? Icons.play_arrow_rounded
                                : Icons.pause_rounded,
                            size: 11,
                            color: const Color(0xFF57F287),
                          ),
                          const SizedBox(width: 3),
                          Text(
                            '${fmtPosition(position)} / ${fmtPosition(t.duration)}',
                            style: const TextStyle(
                                color: Color(0xFF6D6F78), fontSize: 10),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(2),
                              child: LinearProgressIndicator(
                                value: t.duration.inMilliseconds == 0
                                    ? 0
                                    : (position.inMilliseconds /
                                            t.duration.inMilliseconds)
                                        .clamp(0.0, 1.0)
                                        .toDouble(),
                                minHeight: 3,
                                backgroundColor:
                                    const Color(0xFF3F4147),
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                    Color(0xFF57F287)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (buttons.isNotEmpty) ...<Widget>[
            const SizedBox(height: 9),
            Row(
              children: <Widget>[
                for (final Map<String, String> b in buttons) ...<Widget>[
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 7),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(5),
                        color: const Color(0xFF4E5058),
                      ),
                      child: Text(
                        b['label']!.length > 20
                            ? '${b['label']!.substring(0, 20)}…'
                            : b['label']!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}
