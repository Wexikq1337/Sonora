import 'package:flutter/material.dart';

/// A named colour palette. Themes are deliberately *not* Material ColorScheme
/// driven: glass needs precise control over background luminance.
class AppPalette {
  const AppPalette({
    required this.id,
    required this.name,
    required this.bg0,
    required this.bg1,
    required this.accent,
    required this.accent2,
    required this.text,
    required this.muted,
    this.blobA,
    this.blobB,
  });

  final String id;
  final String name;
  final Color bg0;
  final Color bg1;
  final Color accent;
  final Color accent2;
  final Color text;
  final Color muted;
  final Color? blobA;
  final Color? blobB;

  Color get glowA => blobA ?? accent;
  Color get glowB => blobB ?? accent2;

  static const List<AppPalette> all = <AppPalette>[
    AppPalette(
      id: 'midnight',
      name: 'Midnight',
      bg0: Color(0xFF05060B),
      bg1: Color(0xFF0B1224),
      accent: Color(0xFF6EE7F9),
      accent2: Color(0xFFA78BFA),
      text: Color(0xFFF2F5FF),
      muted: Color(0xFF9AA6C4),
      blobA: Color(0xFF22D3EE),
      blobB: Color(0xFF8B5CF6),
    ),
    AppPalette(
      id: 'aurora',
      name: 'Aurora',
      bg0: Color(0xFF03110E),
      bg1: Color(0xFF08211C),
      accent: Color(0xFF34D399),
      accent2: Color(0xFF22D3EE),
      text: Color(0xFFECFFF9),
      muted: Color(0xFF8FB8AD),
      blobA: Color(0xFF10B981),
      blobB: Color(0xFF06B6D4),
    ),
    AppPalette(
      id: 'sunset',
      name: 'Sunset',
      bg0: Color(0xFF140711),
      bg1: Color(0xFF2A0F1E),
      accent: Color(0xFFFB7185),
      accent2: Color(0xFFFBBF24),
      text: Color(0xFFFFF1F4),
      muted: Color(0xFFC4A0AC),
      blobA: Color(0xFFF43F5E),
      blobB: Color(0xFFF59E0B),
    ),
    AppPalette(
      id: 'ocean',
      name: 'Ocean',
      bg0: Color(0xFF03101D),
      bg1: Color(0xFF06243A),
      accent: Color(0xFF38BDF8),
      accent2: Color(0xFF818CF8),
      text: Color(0xFFEFF8FF),
      muted: Color(0xFF93AFC7),
      blobA: Color(0xFF0EA5E9),
      blobB: Color(0xFF6366F1),
    ),
    AppPalette(
      id: 'amoled',
      name: 'AMOLED',
      bg0: Color(0xFF000000),
      bg1: Color(0xFF070709),
      accent: Color(0xFFE879F9),
      accent2: Color(0xFF22D3EE),
      text: Color(0xFFF7F7FA),
      muted: Color(0xFF8B8B99),
      blobA: Color(0xFFA21CAF),
      blobB: Color(0xFF0E7490),
    ),
  ];

  static AppPalette byId(String id) =>
      all.firstWhere((AppPalette p) => p.id == id, orElse: () => all.first);
}
