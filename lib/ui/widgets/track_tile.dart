import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';

import '../../app_scope.dart';
import '../../core/format.dart';
import '../../core/palette.dart';
import '../../models/track.dart';
import '../animations/motion.dart';
import '../glass/glass.dart';
import 'artwork.dart';

/// A list row. Hover uses a cheap translucent fill (not a backdrop filter) so
/// long lists stay at 120 fps; the *playing* row is real glass.
class TrackTile extends StatefulWidget {
  const TrackTile({
    super.key,
    required this.track,
    required this.playing,
    required this.onPlay,
    this.index,
    this.showSource = true,
    this.trailing,
  });

  final Track track;
  final bool playing;
  final VoidCallback onPlay;
  final int? index;
  final bool showSource;
  final Widget? trailing;

  @override
  State<TrackTile> createState() => _TrackTileState();
}

class _TrackTileState extends State<TrackTile> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final SonoraScope scope = SonoraScope.of(context);
    final AppPalette pal = scope.palette;
    final bool liked = scope.player.isLiked(widget.track.id);
    final Duration d = motionDuration(context, 180);

    final Widget row = Row(
      children: <Widget>[
        SizedBox(
          width: 34,
          child: AnimatedSwitcher(
            duration: d,
            child: widget.playing
                ? Icon(Icons.graphic_eq_rounded,
                    key: const ValueKey<String>('eq'),
                    size: 18,
                    color: pal.accent)
                : Text(
                    widget.index == null ? '' : '${widget.index! + 1}',
                    key: ValueKey<int>(widget.index ?? -1),
                    style: TextStyle(
                        color: pal.muted, fontSize: 13, fontFeatures: const <FontFeature>[
                      FontFeature.tabularFigures()
                    ]),
                  ),
          ),
        ),
        Artwork(track: widget.track, width: 44, height: 44, radius: 10, glow: false),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                widget.track.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: widget.playing ? pal.accent : pal.text,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                children: <Widget>[
                  Flexible(
                    child: Text(
                      widget.track.artist,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: pal.muted, fontSize: 12),
                    ),
                  ),
                  if (widget.showSource) ...<Widget>[
                    const SizedBox(width: 8),
                    _SourceTag(track: widget.track),
                  ],
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        if (widget.trailing != null) widget.trailing!,
        HeartButton(
          liked: liked,
          onTap: () => scope.player.toggleLike(widget.track.id),
        ),
        SizedBox(
          width: 44,
          child: Text(
            fmtDuration(widget.track.duration),
            textAlign: TextAlign.right,
            style: TextStyle(
                color: pal.muted,
                fontSize: 12,
                fontFeatures: const <FontFeature>[FontFeature.tabularFigures()]),
          ),
        ),
      ],
    );

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onPlay,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 4),
          child: widget.playing
              ? LiquidGlass(
                  radius: 14,
                  tint: pal.accent,
                  opacityScale: 1.5,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 8),
                  child: row,
                )
              : AnimatedContainer(
                  duration: d,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    color: _hover
                        ? Colors.white.withOpacity(0.055)
                        : Colors.transparent,
                    border: Border.all(
                      color: _hover
                          ? Colors.white.withOpacity(0.09)
                          : Colors.transparent,
                    ),
                  ),
                  child: row,
                ),
        ),
      ),
    );
  }
}

class _SourceTag extends StatelessWidget {
  const _SourceTag({required this.track});
  final Track track;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        color: track.source.color.withOpacity(0.16),
        border: Border.all(color: track.source.color.withOpacity(0.35), width: 0.8),
      ),
      child: Text(
        track.source.short,
        style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
            color: track.source.color),
      ),
    );
  }
}

/// Large cover card used on Home.
class CollectionCard extends StatefulWidget {
  const CollectionCard({
    super.key,
    required this.track,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.width = 168,
  });

  final Track track;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final double width;

  @override
  State<CollectionCard> createState() => _CollectionCardState();
}

class _CollectionCardState extends State<CollectionCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final AppPalette pal = SonoraScope.of(context).palette;
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: SizedBox(
          width: widget.width,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              AnimatedScale(
                scale: _hover ? 1.035 : 1.0,
                duration: motionDuration(context, 220),
                curve: Curves.easeOutCubic,
                child: Artwork(
                  track: widget.track,
                  width: widget.width,
                  height: widget.width,
                  radius: 18,
                  badge: true,
                  glow: _hover,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                widget.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    color: pal.text,
                    fontSize: 14,
                    fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 2),
              Text(
                widget.subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: pal.muted, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
    this.icon,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final AppPalette pal = SonoraScope.of(context).palette;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 4),
      child: Row(
        children: <Widget>[
          if (icon != null) ...<Widget>[
            Icon(icon, size: 17, color: pal.accent),
            const SizedBox(width: 8),
          ],
          Text(
            title,
            style: TextStyle(
                color: pal.text, fontSize: 17, fontWeight: FontWeight.w700),
          ),
          const Spacer(),
          if (actionLabel != null && onAction != null)
            GlassChip(label: actionLabel!, onTap: onAction, dense: true),
        ],
      ),
    );
  }
}
