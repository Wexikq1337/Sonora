import 'package:flutter/material.dart';

import '../../app_scope.dart';
import '../../core/format.dart';
import '../../models/track.dart';
import '../../state/player_controller.dart';
import '../animations/motion.dart';
import '../glass/glass.dart';
import 'artwork.dart';

/// Persistent transport bar. Sits above the bottom navigation on mobile and
/// spans the full window width on desktop.
class MiniPlayerBar extends StatelessWidget {
  const MiniPlayerBar({
    super.key,
    required this.onExpand,
    this.desktop = false,
  });

  final VoidCallback onExpand;
  final bool desktop;

  @override
  Widget build(BuildContext context) {
    final SonoraScope scope = SonoraScope.of(context);
    final PlayerController player = scope.player;

    return ListenableBuilder(
      listenable: player,
      builder: (BuildContext context, _) {
        final Track? t = player.current;
        if (t == null) return const SizedBox.shrink();
        return Padding(
          padding: EdgeInsets.fromLTRB(desktop ? 16 : 10, 4, desktop ? 16 : 10, 6),
          child: LiquidGlass(
              radius: 20,
              opacityScale: 1.15,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      GestureDetector(
                        onTap: onExpand,
                        child: Hero(
                          tag: 'now-art',
                          child: Artwork(
                            track: t,
                            width: 40,
                            height: 40,
                            radius: 10,
                            glow: false,
                            badge: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: GestureDetector(
                          onTap: onExpand,
                          behavior: HitTestBehavior.opaque,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Text(
                                t.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: scope.palette.text,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                t.artist,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    color: scope.palette.muted, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (desktop) ...<Widget>[
                        _VolButton(scope: scope),
                        const SizedBox(width: 4),
                      ],
                      GlassIconButton(
                        icon: Icons.skip_previous_rounded,
                        size: 36,
                        iconSize: 18,
                        onTap: () => player.previous(),
                        tooltip: 'Предыдущий',
                      ),
                      const SizedBox(width: 6),
                      GlassIconButton(
                        icon: player.playing
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        size: desktop ? 42 : 38,
                        iconSize: 22,
                        selected: true,
                        onTap: () => player.toggle(),
                        tooltip: player.playing ? 'Пауза' : 'Играть',
                      ),
                      const SizedBox(width: 6),
                      GlassIconButton(
                        icon: Icons.skip_next_rounded,
                        size: 36,
                        iconSize: 18,
                        onTap: () => player.next(),
                        tooltip: 'Следующий',
                      ),
                      if (desktop) ...<Widget>[
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 108,
                          child: ValueListenableBuilder<Duration>(
                            valueListenable: player.position,
                            builder: (BuildContext context, Duration pos, _) =>
                                Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: <Widget>[
                                Text(
                                  '${fmtPosition(pos)} / ${fmtPosition(t.duration)}',
                                  style: TextStyle(
                                    color: scope.palette.muted,
                                    fontSize: 10,
                                    fontFeatures: const <FontFeature>[
                                      FontFeature.tabularFigures()
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 2),
                                GlassProgressBar(
                                  value: player.progress,
                                  height: 4,
                                  onSeek: (double v) => player
                                      .seek(t.duration * v),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                      ],
                      GlassIconButton(
                        icon: Icons.open_in_full_rounded,
                        size: 36,
                        iconSize: 17,
                        onTap: onExpand,
                        tooltip: 'Открыть плеер',
                      ),
                    ],
                  ),
                  if (!desktop) ...<Widget>[
                    const SizedBox(height: 6),
                    ValueListenableBuilder<Duration>(
                      valueListenable: player.position,
                      builder: (BuildContext context, Duration pos, _) =>
                          GlassProgressBar(
                        value: player.progress,
                        height: 3,
                        onSeek: (double v) => player.seek(t.duration * v),
                      ),
                    ),
                  ],
                ],
              ),
            ),
        );
      },
    );
  }
}

class _VolButton extends StatefulWidget {
  const _VolButton({required this.scope});
  final SonoraScope scope;

  @override
  State<_VolButton> createState() => _VolButtonState();
}

class _VolButtonState extends State<_VolButton> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final double v = widget.scope.s.volume;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        GlassIconButton(
          icon: v <= 0.01
              ? Icons.volume_off_rounded
              : (v < 0.5 ? Icons.volume_down_rounded : Icons.volume_up_rounded),
          size: 36,
          iconSize: 18,
          tooltip: 'Звук',
          onTap: () => setState(() => _open = !_open),
        ),
        AnimatedContainer(
          duration: motionDuration(context, 220),
          width: _open ? 92 : 0,
          curve: Curves.easeOutCubic,
          child: _open
              ? SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 3,
                    thumbShape:
                        const RoundSliderThumbShape(enabledThumbRadius: 5),
                    overlayShape: SliderComponentShape.noOverlay,
                    activeTrackColor: widget.scope.palette.accent,
                    inactiveTrackColor: Colors.white.withOpacity(0.14),
                    thumbColor: Colors.white,
                  ),
                  child: Slider(
                    value: v,
                    onChanged: (double val) {
                      widget.scope.settings
                          .update((s) => s.copyWith(volume: val));
                      widget.scope.player.setVolume(val);
                    },
                  ),
                )
              : null,
        ),
      ],
    );
  }
}
