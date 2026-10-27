import 'dart:convert';

double _d(dynamic v, double fallback) =>
    v is num ? v.toDouble() : (v is String ? double.tryParse(v) ?? fallback : fallback);
int _i(dynamic v, int fallback) => v is num ? v.toInt() : fallback;
bool _b(dynamic v, bool fallback) => v is bool ? v : fallback;
String _s(dynamic v, String fallback) => v is String ? v : fallback;

/// Glass / blur look & feel.
class GlassSettings {
  const GlassSettings({
    this.enabled = true,
    this.opacity = 0.22,
    this.blur = 18,
    this.refraction = 0.55,
    this.borderAlpha = 0.30,
    this.shadow = 0.55,
    this.noise = true,
    this.particles = false,
    this.highlightHex = '#FFFFFF',
    this.pressAnim = 'spring',
  });

  final bool enabled;
  final double opacity; // 0.10 .. 0.50
  final double blur; // 0 .. 30
  final double refraction; // 0 .. 1
  final double borderAlpha; // 0.05 .. 0.60
  final double shadow; // 0 .. 1
  final bool noise;
  final bool particles;
  final String highlightHex;
  final String pressAnim; // spring | bounce | smooth | none

  GlassSettings copyWith({
    bool? enabled,
    double? opacity,
    double? blur,
    double? refraction,
    double? borderAlpha,
    double? shadow,
    bool? noise,
    bool? particles,
    String? highlightHex,
    String? pressAnim,
  }) =>
      GlassSettings(
        enabled: enabled ?? this.enabled,
        opacity: opacity ?? this.opacity,
        blur: blur ?? this.blur,
        refraction: refraction ?? this.refraction,
        borderAlpha: borderAlpha ?? this.borderAlpha,
        shadow: shadow ?? this.shadow,
        noise: noise ?? this.noise,
        particles: particles ?? this.particles,
        highlightHex: highlightHex ?? this.highlightHex,
        pressAnim: pressAnim ?? this.pressAnim,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'enabled': enabled,
        'opacity': opacity,
        'blur': blur,
        'refraction': refraction,
        'borderAlpha': borderAlpha,
        'shadow': shadow,
        'noise': noise,
        'particles': particles,
        'highlightHex': highlightHex,
        'pressAnim': pressAnim,
      };

  factory GlassSettings.fromJson(Map<String, dynamic> j) => GlassSettings(
        enabled: _b(j['enabled'], true),
        opacity: _d(j['opacity'], 0.22),
        blur: _d(j['blur'], 18),
        refraction: _d(j['refraction'], 0.55),
        borderAlpha: _d(j['borderAlpha'], 0.30),
        shadow: _d(j['shadow'], 0.55),
        noise: _b(j['noise'], true),
        particles: _b(j['particles'], false),
        highlightHex: _s(j['highlightHex'], '#FFFFFF'),
        pressAnim: _s(j['pressAnim'], 'spring'),
      );
}

class AnimationSettings {
  const AnimationSettings({
    this.speed = 1.0,
    this.reduceMotion = false,
    this.springButtons = true,
    this.shimmer = true,
    this.hero = true,
    this.staggered = true,
    this.backgroundMotion = true,
    this.visualizer = true,
    this.morphIcons = true,
    this.parallax = true,
  });

  final double speed; // 0.5 .. 2.0
  final bool reduceMotion;
  final bool springButtons;
  final bool shimmer;
  final bool hero;
  final bool staggered;
  final bool backgroundMotion;
  final bool visualizer;
  final bool morphIcons;
  final bool parallax;

  AnimationSettings copyWith({
    double? speed,
    bool? reduceMotion,
    bool? springButtons,
    bool? shimmer,
    bool? hero,
    bool? staggered,
    bool? backgroundMotion,
    bool? visualizer,
    bool? morphIcons,
    bool? parallax,
  }) =>
      AnimationSettings(
        speed: speed ?? this.speed,
        reduceMotion: reduceMotion ?? this.reduceMotion,
        springButtons: springButtons ?? this.springButtons,
        shimmer: shimmer ?? this.shimmer,
        hero: hero ?? this.hero,
        staggered: staggered ?? this.staggered,
        backgroundMotion: backgroundMotion ?? this.backgroundMotion,
        visualizer: visualizer ?? this.visualizer,
        morphIcons: morphIcons ?? this.morphIcons,
        parallax: parallax ?? this.parallax,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'speed': speed,
        'reduceMotion': reduceMotion,
        'springButtons': springButtons,
        'shimmer': shimmer,
        'hero': hero,
        'staggered': staggered,
        'backgroundMotion': backgroundMotion,
        'visualizer': visualizer,
        'morphIcons': morphIcons,
        'parallax': parallax,
      };

  factory AnimationSettings.fromJson(Map<String, dynamic> j) => AnimationSettings(
        speed: _d(j['speed'], 1.0),
        reduceMotion: _b(j['reduceMotion'], false),
        springButtons: _b(j['springButtons'], true),
        shimmer: _b(j['shimmer'], true),
        hero: _b(j['hero'], true),
        staggered: _b(j['staggered'], true),
        backgroundMotion: _b(j['backgroundMotion'], true),
        visualizer: _b(j['visualizer'], true),
        morphIcons: _b(j['morphIcons'], true),
        parallax: _b(j['parallax'], true),
      );
}

class AppearanceSettings {
  const AppearanceSettings({
    this.themeId = 'midnight',
    this.backgroundIntensity = 0.85,
    this.noiseOverlay = 0.35,
    this.glowCursor = true,
    this.compactUi = false,
  });

  final String themeId;
  final double backgroundIntensity;
  final double noiseOverlay;
  final bool glowCursor;
  final bool compactUi;

  AppearanceSettings copyWith({
    String? themeId,
    double? backgroundIntensity,
    double? noiseOverlay,
    bool? glowCursor,
    bool? compactUi,
  }) =>
      AppearanceSettings(
        themeId: themeId ?? this.themeId,
        backgroundIntensity: backgroundIntensity ?? this.backgroundIntensity,
        noiseOverlay: noiseOverlay ?? this.noiseOverlay,
        glowCursor: glowCursor ?? this.glowCursor,
        compactUi: compactUi ?? this.compactUi,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'themeId': themeId,
        'backgroundIntensity': backgroundIntensity,
        'noiseOverlay': noiseOverlay,
        'glowCursor': glowCursor,
        'compactUi': compactUi,
      };

  factory AppearanceSettings.fromJson(Map<String, dynamic> j) => AppearanceSettings(
        themeId: _s(j['themeId'], 'midnight'),
        backgroundIntensity: _d(j['backgroundIntensity'], 0.85),
        noiseOverlay: _d(j['noiseOverlay'], 0.35),
        glowCursor: _b(j['glowCursor'], true),
        compactUi: _b(j['compactUi'], false),
      );
}

/// A saved Discord presence profile (background/GIF/text/buttons combo).
class DiscordProfile {
  const DiscordProfile({
    required this.name,
    required this.stateTemplate,
    required this.signature,
    this.largeImageKey = '',
    this.smallImageKey = '',
  });

  final String name;
  final String stateTemplate;
  final String signature;
  final String largeImageKey;
  final String smallImageKey;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'name': name,
        'stateTemplate': stateTemplate,
        'signature': signature,
        'largeImageKey': largeImageKey,
        'smallImageKey': smallImageKey,
      };

  factory DiscordProfile.fromJson(Map<String, dynamic> j) => DiscordProfile(
        name: _s(j['name'], 'Профиль'),
        stateTemplate: _s(j['stateTemplate'], '{artist}'),
        signature: _s(j['signature'], ''),
        largeImageKey: _s(j['largeImageKey'], ''),
        smallImageKey: _s(j['smallImageKey'], ''),
      );
}

class DiscordSettings {
  const DiscordSettings({
    this.enabled = true,
    this.appId = '',
    this.showProgress = true,
    this.showSource = true,
    this.showButtons = true,
    this.button1Label = 'Открыть Sonora',
    this.button1Url = 'https://github.com/',
    this.button2Label = '',
    this.button2Url = '',
    this.stateTemplate = '{artist}',
    this.signature = '',
    this.largeImageKey = '',
    this.smallImageKey = '',
    this.listeningType = true,
    this.profileName = 'Default',
    this.profiles = const <DiscordProfile>[],
    this.bgPreset = 'aurora',
  });

  final bool enabled;
  final String appId;
  final bool showProgress;
  final bool showSource;
  final bool showButtons;
  final String button1Label;
  final String button1Url;
  final String button2Label;
  final String button2Url;

  /// Editable second line template. Supports {artist} {album} {source}
  /// {year} {bpm}. The *track title* is intentionally NOT available here —
  /// it lives in `details` and is never user-editable.
  final String stateTemplate;

  /// Free-form extra text appended after the state line.
  final String signature;

  final String largeImageKey;
  final String smallImageKey;
  final bool listeningType; // true => "Listening to", false => "Playing"
  final String profileName;
  final List<DiscordProfile> profiles;
  final String bgPreset;

  DiscordSettings copyWith({
    bool? enabled,
    String? appId,
    bool? showProgress,
    bool? showSource,
    bool? showButtons,
    String? button1Label,
    String? button1Url,
    String? button2Label,
    String? button2Url,
    String? stateTemplate,
    String? signature,
    String? largeImageKey,
    String? smallImageKey,
    bool? listeningType,
    String? profileName,
    List<DiscordProfile>? profiles,
    String? bgPreset,
  }) =>
      DiscordSettings(
        enabled: enabled ?? this.enabled,
        appId: appId ?? this.appId,
        showProgress: showProgress ?? this.showProgress,
        showSource: showSource ?? this.showSource,
        showButtons: showButtons ?? this.showButtons,
        button1Label: button1Label ?? this.button1Label,
        button1Url: button1Url ?? this.button1Url,
        button2Label: button2Label ?? this.button2Label,
        button2Url: button2Url ?? this.button2Url,
        stateTemplate: stateTemplate ?? this.stateTemplate,
        signature: signature ?? this.signature,
        largeImageKey: largeImageKey ?? this.largeImageKey,
        smallImageKey: smallImageKey ?? this.smallImageKey,
        listeningType: listeningType ?? this.listeningType,
        profileName: profileName ?? this.profileName,
        profiles: profiles ?? this.profiles,
        bgPreset: bgPreset ?? this.bgPreset,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'enabled': enabled,
        'appId': appId,
        'showProgress': showProgress,
        'showSource': showSource,
        'showButtons': showButtons,
        'button1Label': button1Label,
        'button1Url': button1Url,
        'button2Label': button2Label,
        'button2Url': button2Url,
        'stateTemplate': stateTemplate,
        'signature': signature,
        'largeImageKey': largeImageKey,
        'smallImageKey': smallImageKey,
        'listeningType': listeningType,
        'profileName': profileName,
        'profiles': profiles.map((DiscordProfile p) => p.toJson()).toList(),
        'bgPreset': bgPreset,
      };

  factory DiscordSettings.fromJson(Map<String, dynamic> j) => DiscordSettings(
        enabled: _b(j['enabled'], true),
        appId: _s(j['appId'], ''),
        showProgress: _b(j['showProgress'], true),
        showSource: _b(j['showSource'], true),
        showButtons: _b(j['showButtons'], true),
        button1Label: _s(j['button1Label'], 'Открыть Sonora'),
        button1Url: _s(j['button1Url'], 'https://github.com/'),
        button2Label: _s(j['button2Label'], ''),
        button2Url: _s(j['button2Url'], ''),
        stateTemplate: _s(j['stateTemplate'], '{artist}'),
        signature: _s(j['signature'], ''),
        largeImageKey: _s(j['largeImageKey'], ''),
        smallImageKey: _s(j['smallImageKey'], ''),
        listeningType: _b(j['listeningType'], true),
        profileName: _s(j['profileName'], 'Default'),
        profiles: (j['profiles'] is List)
            ? (j['profiles'] as List<dynamic>)
                .whereType<Map<String, dynamic>>()
                .map(DiscordProfile.fromJson)
                .toList()
            : const <DiscordProfile>[],
        bgPreset: _s(j['bgPreset'], 'aurora'),
      );
}

/// Self-hosted music server (Subsonic API: Navidrome, Airsonic, Gonic, …).
class ServerSettings {
  const ServerSettings({
    this.url = '',
    this.user = '',
    this.password = '',
    this.name = 'Navidrome',
    this.enabled = false,
  });

  final String url;
  final String user;

  /// Stored in settings.json as-is. Local self-hosted server: acceptable,
  /// but this is NOT a secret vault (see the warning in the UI).
  final String password;
  final String name;
  final bool enabled;

  bool get isConfigured =>
      url.trim().isNotEmpty && user.trim().isNotEmpty && enabled;

  ServerSettings copyWith({
    String? url,
    String? user,
    String? password,
    String? name,
    bool? enabled,
  }) =>
      ServerSettings(
        url: url ?? this.url,
        user: user ?? this.user,
        password: password ?? this.password,
        name: name ?? this.name,
        enabled: enabled ?? this.enabled,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'url': url,
        'user': user,
        'password': password,
        'name': name,
        'enabled': enabled,
      };

  factory ServerSettings.fromJson(Map<String, dynamic> j) => ServerSettings(
        url: _s(j['url'], ''),
        user: _s(j['user'], ''),
        password: _s(j['password'], ''),
        name: _s(j['name'], 'Navidrome'),
        enabled: _b(j['enabled'], false),
      );
}

class AppSettings {
  const AppSettings({
    this.glass = const GlassSettings(),
    this.anim = const AnimationSettings(),
    this.appearance = const AppearanceSettings(),
    this.discord = const DiscordSettings(),
    this.server = const ServerSettings(),
    this.volume = 0.8,
    this.quality = 'auto', // auto | high | balanced | low
    this.showFps = false,
    this.showMiniProgress = true,
    this.gapless = true,
    this.crossfadeSec = 0,
    this.normalize = false,
    this.seekStep = 5,
  });

  final GlassSettings glass;
  final AnimationSettings anim;
  final AppearanceSettings appearance;
  final DiscordSettings discord;
  final ServerSettings server;
  final double volume;
  final String quality;
  final bool showFps;
  final bool showMiniProgress;
  final bool gapless;
  final double crossfadeSec;
  final bool normalize;
  final int seekStep;

  /// Effective animation multiplier: 0 when reduced motion is on.
  double get motionScale =>
      anim.reduceMotion ? 0.0 : anim.speed.clamp(0.5, 2.0).toDouble();

  AppSettings copyWith({
    GlassSettings? glass,
    AnimationSettings? anim,
    AppearanceSettings? appearance,
    DiscordSettings? discord,
    ServerSettings? server,
    double? volume,
    String? quality,
    bool? showFps,
    bool? showMiniProgress,
    bool? gapless,
    double? crossfadeSec,
    bool? normalize,
    int? seekStep,
  }) =>
      AppSettings(
        glass: glass ?? this.glass,
        anim: anim ?? this.anim,
        appearance: appearance ?? this.appearance,
        discord: discord ?? this.discord,
        server: server ?? this.server,
        volume: volume ?? this.volume,
        quality: quality ?? this.quality,
        showFps: showFps ?? this.showFps,
        showMiniProgress: showMiniProgress ?? this.showMiniProgress,
        gapless: gapless ?? this.gapless,
        crossfadeSec: crossfadeSec ?? this.crossfadeSec,
        normalize: normalize ?? this.normalize,
        seekStep: seekStep ?? this.seekStep,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'glass': glass.toJson(),
        'anim': anim.toJson(),
        'appearance': appearance.toJson(),
        'discord': discord.toJson(),
        'server': server.toJson(),
        'volume': volume,
        'quality': quality,
        'showFps': showFps,
        'showMiniProgress': showMiniProgress,
        'gapless': gapless,
        'crossfadeSec': crossfadeSec,
        'normalize': normalize,
        'seekStep': seekStep,
      };

  String encode() => const JsonEncoder.withIndent('  ').convert(toJson());

  factory AppSettings.fromJson(Map<String, dynamic> j) => AppSettings(
        glass: GlassSettings.fromJson(
            (j['glass'] as Map<String, dynamic>?) ?? <String, dynamic>{}),
        anim: AnimationSettings.fromJson(
            (j['anim'] as Map<String, dynamic>?) ?? <String, dynamic>{}),
        appearance: AppearanceSettings.fromJson(
            (j['appearance'] as Map<String, dynamic>?) ?? <String, dynamic>{}),
        discord: DiscordSettings.fromJson(
            (j['discord'] as Map<String, dynamic>?) ?? <String, dynamic>{}),
        server: ServerSettings.fromJson(
            (j['server'] as Map<String, dynamic>?) ?? <String, dynamic>{}),
        volume: _d(j['volume'], 0.8),
        quality: _s(j['quality'], 'auto'),
        showFps: _b(j['showFps'], false),
        showMiniProgress: _b(j['showMiniProgress'], true),
        gapless: _b(j['gapless'], true),
        crossfadeSec: _d(j['crossfadeSec'], 0),
        normalize: _b(j['normalize'], false),
        seekStep: _i(j['seekStep'], 5),
      );

  static AppSettings decode(String raw) {
    final dynamic decoded = jsonDecode(raw);
    if (decoded is Map<String, dynamic>) return AppSettings.fromJson(decoded);
    return const AppSettings();
  }
}
