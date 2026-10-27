import 'package:flutter/material.dart';

import '../../../app_scope.dart';
import '../../../core/palette.dart';
import '../../glass/glass.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({
    super.key,
    required this.title,
    required this.subtitle,
    required this.children,
  });

  final String title;
  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final AppPalette pal = SonoraScope.of(context).palette;
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 100),
      children: <Widget>[
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(title,
                    style: TextStyle(
                        color: pal.text,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5)),
                const SizedBox(height: 3),
                Text(subtitle,
                    style: TextStyle(color: pal.muted, fontSize: 12.5)),
                const SizedBox(height: 16),
                ...children,
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class SettingsCard extends StatelessWidget {
  const SettingsCard({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    required this.children,
    this.tint,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final List<Widget> children;
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    final AppPalette pal = SonoraScope.of(context).palette;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: LiquidGlass(
        radius: 20,
        tint: tint,
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: <Widget>[
                if (icon != null) ...<Widget>[
                  Icon(icon, size: 16, color: pal.accent),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(title,
                      style: TextStyle(
                          color: pal.text,
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700)),
                ),
              ],
            ),
            if (subtitle != null) ...<Widget>[
              const SizedBox(height: 3),
              Text(subtitle!,
                  style: TextStyle(color: pal.muted, fontSize: 11.5)),
            ],
            const SizedBox(height: 8),
            ...children,
          ],
        ),
      ),
    );
  }
}

class SettingRow extends StatelessWidget {
  const SettingRow({
    super.key,
    required this.title,
    this.description,
    this.tooltip,
    this.trailing,
    this.locked = false,
    this.badge,
    this.onTap,
  });

  final String title;
  final String? description;
  final String? tooltip;
  final Widget? trailing;
  final bool locked;
  final String? badge;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final AppPalette pal = SonoraScope.of(context).palette;
    final Widget row = Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Flexible(
                      child: Text(title,
                          style: TextStyle(
                              color: pal.text,
                              fontSize: 13,
                              fontWeight: FontWeight.w600)),
                    ),
                    if (locked) ...<Widget>[
                      const SizedBox(width: 6),
                      Icon(Icons.lock_rounded,
                          size: 12, color: pal.muted.withOpacity(0.9)),
                    ],
                    if (badge != null) ...<Widget>[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 1.5),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(5),
                          color: pal.accent.withOpacity(0.14),
                          border: Border.all(
                              color: pal.accent.withOpacity(0.35), width: 0.7),
                        ),
                        child: Text(badge!,
                            style: TextStyle(
                                color: pal.accent,
                                fontSize: 8.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5)),
                      ),
                    ],
                    if (tooltip != null) ...<Widget>[
                      const SizedBox(width: 6),
                      Tooltip(
                        message: tooltip!,
                        waitDuration: const Duration(milliseconds: 350),
                        child: Icon(Icons.help_rounded,
                            size: 13, color: pal.muted.withOpacity(0.8)),
                      ),
                    ],
                  ],
                ),
                if (description != null) ...<Widget>[
                  const SizedBox(height: 3),
                  Text(description!,
                      style: TextStyle(color: pal.muted, fontSize: 11)),
                ],
              ],
            ),
          ),
          if (trailing != null) ...<Widget>[
            const SizedBox(width: 12),
            trailing!,
          ],
        ],
      ),
    );

    if (onTap == null) return row;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: row,
    );
  }
}

class SettingSwitchRow extends StatelessWidget {
  const SettingSwitchRow({
    super.key,
    required this.title,
    this.description,
    this.tooltip,
    required this.value,
    required this.onChanged,
    this.badge,
  });

  final String title;
  final String? description;
  final String? tooltip;
  final bool value;
  final ValueChanged<bool> onChanged;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return SettingRow(
      title: title,
      description: description,
      tooltip: tooltip,
      badge: badge,
      trailing: GlassSwitch(value: value, onChanged: onChanged),
    );
  }
}

class SettingSlider extends StatelessWidget {
  const SettingSlider({
    super.key,
    required this.title,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.description,
    this.tooltip,
    this.divisions,
    this.format,
  });

  final String title;
  final String? description;
  final String? tooltip;
  final double value;
  final double min;
  final double max;
  final int? divisions;
  final ValueChanged<double> onChanged;
  final String Function(double)? format;

  @override
  Widget build(BuildContext context) {
    final AppPalette pal = SonoraScope.of(context).palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        SettingRow(
          title: title,
          description: description,
          tooltip: tooltip,
          trailing: Text(
            format?.call(value) ?? value.toStringAsFixed(1),
            style: TextStyle(
                color: pal.accent, fontSize: 12, fontWeight: FontWeight.w700),
          ),
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 3,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
            activeTrackColor: pal.accent,
            inactiveTrackColor: Colors.white.withOpacity(0.12),
            thumbColor: Colors.white,
            overlayColor: pal.accent.withOpacity(0.16),
          ),
          child: Slider(
            min: min,
            max: max,
            divisions: divisions,
            value: value.clamp(min, max).toDouble(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}

class ChoiceRow extends StatelessWidget {
  const ChoiceRow({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelect,
    this.dense = false,
  });

  final List<String> options;
  final String selected;
  final ValueChanged<String> onSelect;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 6),
      child: Wrap(
        spacing: 7,
        runSpacing: 7,
        children: <Widget>[
          for (final String o in options)
            GlassChip(
              label: o,
              dense: dense,
              selected: o == selected,
              onTap: () => onSelect(o),
            ),
        ],
      ),
    );
  }
}

/// Grayed-out read-only field with a lock marker — used for the track title in
/// Discord RPC settings, which is generated by the player only.
class LockedField extends StatelessWidget {
  const LockedField({
    super.key,
    required this.label,
    required this.value,
    this.hint = 'Значение формируется автоматически и не может быть изменено',
  });

  final String label;
  final String value;
  final String hint;

  @override
  Widget build(BuildContext context) {
    final AppPalette pal = SonoraScope.of(context).palette;
    return Tooltip(
      message: '🔒 $hint',
      waitDuration: const Duration(milliseconds: 300),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.black.withOpacity(0.28),
          border: Border.all(
              color: Colors.white.withOpacity(0.07), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(Icons.lock_rounded,
                    size: 12, color: pal.muted.withOpacity(0.9)),
                const SizedBox(width: 6),
                Text(label,
                    style: TextStyle(
                        color: pal.muted,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.4)),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(5),
                    color: Colors.white.withOpacity(0.06),
                  ),
                  child: Text('auto',
                      style: TextStyle(
                          color: pal.muted, fontSize: 8.5,
                          fontWeight: FontWeight.w700)),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  color: pal.text.withOpacity(0.75),
                  fontSize: 13,
                  fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

class InfoNote extends StatelessWidget {
  const InfoNote({super.key, required this.text, this.icon = Icons.info_rounded});
  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final AppPalette pal = SonoraScope.of(context).palette;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, size: 13, color: pal.muted.withOpacity(0.8)),
          const SizedBox(width: 7),
          Expanded(
            child: Text(text,
                style: TextStyle(
                    color: pal.muted.withOpacity(0.9), fontSize: 10.5, height: 1.35)),
          ),
        ],
      ),
    );
  }
}
