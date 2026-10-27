import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app_scope.dart';
import '../../core/palette.dart';
import '../glass/glass.dart';

Future<void> showEqualizerSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    barrierColor: Colors.black.withOpacity(0.55),
    builder: (BuildContext ctx) => const BlurDepth(
      value: 2,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[EqualizerSheet()],
        ),
      ),
    ),
  );
}

class EqPresetData {
  const EqPresetData(this.name, this.gains, [this.reverb = 0]);
  final String name;
  final List<double> gains;
  final int reverb;
}

const List<EqPresetData> kEqPresets = <EqPresetData>[
  EqPresetData('Flat', <double>[0, 0, 0, 0, 0, 0, 0, 0, 0, 0]),
  EqPresetData('Rock', <double>[5, 4, 2, -1, -2, 0, 2, 4, 5, 4]),
  EqPresetData('Pop', <double>[-1, 0, 2, 4, 4, 2, 0, -1, -1, 0]),
  EqPresetData('Jazz', <double>[3, 2, 0, 2, -1, -1, 0, 2, 3, 4]),
  EqPresetData('Bass Boost', <double>[8, 7, 5, 2, 0, 0, 0, 0, 0, 0]),
  EqPresetData('Vocal', <double>[-3, -2, 0, 2, 4, 5, 4, 2, 0, -1]),
  EqPresetData('Podcast', <double>[-6, -4, 0, 3, 5, 4, 2, 0, -2, -4]),
  EqPresetData('Night', <double>[2, 1, 0, 0, -1, -2, -2, -1, 1, 2], 1),
];

class EqualizerSheet extends StatefulWidget {
  const EqualizerSheet({super.key});

  @override
  State<EqualizerSheet> createState() => _EqualizerSheetState();
}

class _EqualizerSheetState extends State<EqualizerSheet> {
  static const List<double> _freqs = <double>[
    31, 62, 125, 250, 500, 1000, 2000, 4000, 8000, 16000
  ];

  List<double> _gains = List<double>.from(kEqPresets.first.gains);
  String _preset = 'Flat';
  bool _enabled = true;
  double _preamp = 0;
  double _bass = 0;
  double _virtual = 0;
  int _reverb = 0;

  void _applyPreset(EqPresetData p) {
    setState(() {
      _gains = List<double>.from(p.gains);
      _preset = p.name;
      _reverb = p.reverb;
      _bass = p.name == 'Bass Boost' ? 6 : 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette pal = SonoraScope.of(context).palette;
    final double maxHeight = MediaQuery.sizeOf(context).height * 0.92;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight, maxWidth: 780),
      child: LiquidGlass(
        radius: 28,
        blurScale: 1.15,
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Icon(Icons.equalizer_rounded, color: pal.accent, size: 20),
                  const SizedBox(width: 10),
                  Text('Эквалайзер',
                      style: TextStyle(
                          color: pal.text,
                          fontSize: 18,
                          fontWeight: FontWeight.w700)),
                  const Spacer(),
                  GlassSwitch(
                    value: _enabled,
                    onChanged: (bool v) => setState(() => _enabled = v),
                  ),
                  const SizedBox(width: 8),
                  GlassIconButton(
                    icon: Icons.close_rounded,
                    size: 36,
                    iconSize: 18,
                    onTap: () => Navigator.of(context).maybePop(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  for (final EqPresetData p in kEqPresets)
                    GlassChip(
                      label: p.name,
                      dense: true,
                      selected: _preset == p.name,
                      onTap: () => _applyPreset(p),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: 130,
                child: CustomPaint(
                  painter: _EqCurvePainter(
                    gains: _enabled ? _gains : List<double>.filled(10, 0),
                    accent: pal.accent,
                    accent2: pal.accent2,
                    grid: Colors.white.withOpacity(0.08),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              SizedBox(
                height: 190,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: List<Widget>.generate(10, (int i) {
                    final double gain = _gains[i];
                    return Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Text(
                            gain.toStringAsFixed(0),
                            style: TextStyle(
                                color: gain == 0 ? pal.muted : pal.accent,
                                fontSize: 10,
                                fontWeight: FontWeight.w600),
                          ),
                          SizedBox(
                            height: 130,
                            child: RotatedBox(
                              quarterTurns: 3,
                              child: SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  trackHeight: 3,
                                  thumbShape: const RoundSliderThumbShape(
                                      enabledThumbRadius: 6),
                                  overlayShape:
                                      const RoundSliderOverlayShape(
                                          overlayRadius: 14),
                                  activeTrackColor: pal.accent,
                                  inactiveTrackColor:
                                      Colors.white.withOpacity(0.12),
                                  thumbColor: Colors.white,
                                  overlayColor: pal.accent.withOpacity(0.18),
                                ),
                                child: Slider(
                                  min: -12,
                                  max: 12,
                                  value: gain,
                                  onChanged: _enabled
                                      ? (double v) => setState(() {
                                            _gains[i] = v;
                                            _preset = 'Custom';
                                          })
                                      : null,
                                ),
                              ),
                            ),
                          ),
                          Text(
                            _freqs[i] >= 1000
                                ? '${(_freqs[i] / 1000).toStringAsFixed(0)}k'
                                : _freqs[i].toStringAsFixed(0),
                            style: TextStyle(color: pal.muted, fontSize: 9),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 8),
              Divider(color: Colors.white.withOpacity(0.08), height: 1),
              const SizedBox(height: 12),
              _EffectRow(
                label: 'Preamp',
                value: _preamp,
                min: -12,
                max: 12,
                suffix: 'dB',
                onChanged: (double v) => setState(() => _preamp = v),
              ),
              _EffectRow(
                label: 'Bass Boost',
                value: _bass,
                min: 0,
                max: 12,
                suffix: 'dB',
                onChanged: (double v) => setState(() => _bass = v),
              ),
              _EffectRow(
                label: 'Virtualizer',
                value: _virtual,
                min: 0,
                max: 1,
                percent: true,
                onChanged: (double v) => setState(() => _virtual = v),
              ),
              const SizedBox(height: 8),
              LayoutBuilder(
                builder: (BuildContext context, BoxConstraints c) => Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: <Widget>[
                    Text('Reverb',
                        style: TextStyle(color: pal.muted, fontSize: 12)),
                    const SizedBox(width: 6),
                    for (int i = 0; i < 4; i++)
                      GlassChip(
                        label: <String>['Off', 'Room', 'Hall', 'Cathedral'][i],
                        dense: true,
                        selected: _reverb == i,
                        onTap: () => setState(() => _reverb = i),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: <Widget>[
                  Icon(Icons.info_rounded,
                      size: 14, color: pal.muted.withOpacity(0.8)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Значения применяются к профилю. DSP-мост к libmpv '
                      '(af-граф) — заглушка в этой сборке.',
                      style: TextStyle(color: pal.muted.withOpacity(0.85), fontSize: 11),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EffectRow extends StatelessWidget {
  const _EffectRow({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.suffix = '',
    this.percent = false,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;
  final String suffix;
  final bool percent;

  @override
  Widget build(BuildContext context) {
    final AppPalette pal = SonoraScope.of(context).palette;
    return Row(
      children: <Widget>[
        SizedBox(
          width: 92,
          child: Text(label,
              style: TextStyle(color: pal.muted, fontSize: 12)),
        ),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 3,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              overlayShape:
                  const RoundSliderOverlayShape(overlayRadius: 14),
              activeTrackColor: pal.accent,
              inactiveTrackColor: Colors.white.withOpacity(0.12),
              thumbColor: Colors.white,
            ),
            child: Slider(
                min: min,
                max: max,
                value: value,
                onChanged: onChanged),
          ),
        ),
        SizedBox(
          width: 48,
          child: Text(
            percent
                ? '${(value * 100).round()}%'
                : '${value.toStringAsFixed(1)}$suffix',
            textAlign: TextAlign.right,
            style: TextStyle(color: pal.text, fontSize: 11),
          ),
        ),
      ],
    );
  }
}

class _EqCurvePainter extends CustomPainter {
  _EqCurvePainter({
    required this.gains,
    required this.accent,
    required this.accent2,
    required this.grid,
  });

  final List<double> gains;
  final Color accent;
  final Color accent2;
  final Color grid;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint gridPaint = Paint()
      ..color = grid
      ..strokeWidth = 1;
    for (int i = 0; i <= 4; i++) {
      final double y = size.height * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
    final double mid = size.height / 2;
    canvas.drawLine(
      Offset(0, mid),
      Offset(size.width, mid),
      Paint()
        ..color = Colors.white.withOpacity(0.16)
        ..strokeWidth = 1,
    );

    if (gains.isEmpty) return;

    final List<Offset> pts = <Offset>[];
    for (int i = 0; i < gains.length; i++) {
      final double x = size.width * i / (gains.length - 1);
      final double y = mid - gains[i] / 12.0 * (size.height / 2 - 6);
      pts.add(Offset(x, y));
    }

    final Path path = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (int i = 0; i < pts.length - 1; i++) {
      final Offset p0 = pts[i];
      final Offset p1 = pts[i + 1];
      final Offset c = Offset((p0.dx + p1.dx) / 2, (p0.dy + p1.dy) / 2);
      path.quadraticBezierTo(p0.dx, p0.dy, c.dx, c.dy);
    }
    path.lineTo(pts.last.dx, pts.last.dy);

    final Path fill = Path.from(path)
      ..lineTo(size.width, mid)
      ..lineTo(0, mid)
      ..close();

    canvas.drawPath(
      fill,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            accent.withOpacity(0.35),
            accent2.withOpacity(0.02),
          ],
        ).createShader(Offset.zero & size),
    );
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round
        ..shader = LinearGradient(
          colors: <Color>[accent, accent2],
        ).createShader(Offset.zero & size),
    );

    // glow dots
    for (int i = 0; i < pts.length; i++) {
      final double r = math.max(1.6, 3.2 - i * 0.1);
      canvas.drawCircle(
        pts[i],
        r,
        Paint()
          ..color = Colors.white.withOpacity(0.9)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      );
      canvas.drawCircle(pts[i], r * 0.6, Paint()..color = Colors.white);
    }
  }

  @override
  bool shouldRepaint(_EqCurvePainter old) =>
      old.accent != accent || !_listEq(old.gains, gains);

  static bool _listEq(List<double> a, List<double> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
