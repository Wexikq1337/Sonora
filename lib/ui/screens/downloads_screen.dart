import 'package:flutter/material.dart';

import '../../app_scope.dart';
import '../../core/palette.dart';
import '../../models/demo_library.dart';
import '../../models/track.dart';
import '../animations/motion.dart';
import '../glass/glass.dart';
import '../widgets/artwork.dart';

class DownloadsScreen extends StatelessWidget {
  const DownloadsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final SonoraScope scope = SonoraScope.of(context);
    final AppPalette pal = scope.palette;
    const double totalMb = 2048;
    final double usedMb = DemoLibrary.tracks.length * 0.7;

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 100),
      children: <Widget>[
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Appear(
                  child: Text('Загрузки',
                      style: TextStyle(
                          color: pal.text,
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.6)),
                ),
                const SizedBox(height: 3),
                Appear(
                  delayMs: 40,
                  child: Text('Оффлайн-копии треков и кэш стриминга',
                      style: TextStyle(color: pal.muted, fontSize: 12.5)),
                ),
                const SizedBox(height: 16),
                Appear(
                  delayMs: 80,
                  child: LiquidGlass(
                    radius: 20,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Icon(Icons.sd_storage_rounded,
                                size: 18, color: pal.accent),
                            const SizedBox(width: 8),
                            Text('Хранилище',
                                style: TextStyle(
                                    color: pal.text,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700)),
                            const Spacer(),
                            Text(
                              '${usedMb.toStringAsFixed(1)} МБ из ${totalMb.toStringAsFixed(0)} МБ',
                              style: TextStyle(
                                  color: pal.muted, fontSize: 11.5),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        GlassProgressBar(
                          value: (usedMb / totalMb).clamp(0.0, 1.0).toDouble(),
                          height: 8,
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: <Widget>[
                            GlassChip(
                              label: 'Скачать всё',
                              icon: Icons.download_rounded,
                              selected: true,
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    backgroundColor: pal.bg1,
                                    content: Text(
                                      'Демо: все треки уже лежат в памяти устройства (assets/audio)',
                                      style: TextStyle(color: pal.text),
                                    ),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(width: 8),
                            GlassChip(
                              label: 'Очистить кэш',
                              icon: Icons.cleaning_services_rounded,
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    backgroundColor: pal.bg1,
                                    content: Text('Кэш очищен (демо)',
                                        style: TextStyle(color: pal.text)),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Appear(
                  delayMs: 120,
                  child: Row(
                    children: <Widget>[
                      Icon(Icons.offline_pin_rounded,
                          size: 16, color: pal.accent),
                      const SizedBox(width: 8),
                      Text('Доступно оффлайн',
                          style: TextStyle(
                              color: pal.text,
                              fontSize: 16,
                              fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                for (int i = 0; i < DemoLibrary.tracks.length; i++)
                  Appear(
                    delayMs: 160 + i * 45,
                    child: _DownloadRow(track: DemoLibrary.tracks[i]),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _DownloadRow extends StatelessWidget {
  const _DownloadRow({required this.track});
  final Track track;

  @override
  Widget build(BuildContext context) {
    final SonoraScope scope = SonoraScope.of(context);
    final AppPalette pal = scope.palette;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 4),
      child: LiquidGlass(
        radius: 14,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          children: <Widget>[
            Artwork(track: track, width: 40, height: 40, radius: 10, glow: false),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(track.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: pal.text,
                          fontSize: 13,
                          fontWeight: FontWeight.w600)),
                  Text('${track.artist} · WAV 22 кГц · 0.7 МБ',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: pal.muted, fontSize: 11)),
                ],
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: const Color(0xFF57F287).withOpacity(0.14),
                border: Border.all(
                    color: const Color(0xFF57F287).withOpacity(0.35),
                    width: 0.8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Icon(Icons.check_rounded,
                      size: 12, color: Color(0xFF57F287)),
                  const SizedBox(width: 4),
                  Text('в памяти',
                      style: TextStyle(
                          color: const Color(0xFF57F287),
                          fontSize: 10,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            const SizedBox(width: 6),
            GlassIconButton(
              icon: Icons.play_arrow_rounded,
              size: 34,
              iconSize: 18,
              onTap: () => scope.player.playQueue(DemoLibrary.tracks),
            ),
          ],
        ),
      ),
    );
  }
}
