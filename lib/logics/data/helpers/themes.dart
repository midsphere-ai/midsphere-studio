import 'package:arcane/arcane.dart';

class Themes {
  // ChatGPT Dark
  static const ColorScheme chatGptDark = ColorScheme(
    brightness: Brightness.dark,

    background: Color(0xFF212121),
    foreground: Color(0xFFECECF1),

    card: Color(0xFF2F2F2F),
    cardForeground: Color(0xFFECECF1),

    popover: Color(0xFF2F2F2F),
    popoverForeground: Color(0xFFECECF1),

    primary: Color(0xFF10A37F),
    primaryForeground: Color(0xFFFFFFFF),

    secondary: Color(0xFF3E3E3E),
    secondaryForeground: Color(0xFFB4B4B4),

    muted: Color(0xFF3E3E3E),
    mutedForeground: Color(0xFF8E8E8E),

    accent: Color(0xFF3E3E3E),
    accentForeground: Color(0xFFECECF1),

    destructive: Color(0xFFEF4444),

    border: Color(0xFF4E4E4E),
    input: Color(0xFF3E3E3E),
    ring: Color(0xFF10A37F),

    chart1: Color(0xFF10A37F),
    chart2: Color(0xFF5B9BD5),
    chart3: Color(0xFFFFC107),
    chart4: Color(0xFFEF4444),
    chart5: Color(0xFFAB68FF),

    sidebar: Color(0xFF171717),
    sidebarForeground: Color(0xFFB4B4B4),
    sidebarPrimary: Color(0xFF10A37F),
    sidebarPrimaryForeground: Color(0xFFFFFFFF),
    sidebarAccent: Color(0xFF2F2F2F),
    sidebarAccentForeground: Color(0xFFECECF1),
    sidebarBorder: Color(0xFF2F2F2F),
    sidebarRing: Color(0xFF10A37F),
  );

  // ChatGPT Light
  static const ColorScheme chatGptLight = ColorScheme(
    brightness: Brightness.light,

    background: Color(0xFFFFFFFF),
    foreground: Color(0xFF374151),

    card: Color(0xFFFFFFFF),
    cardForeground: Color(0xFF374151),

    popover: Color(0xFFFFFFFF),
    popoverForeground: Color(0xFF374151),

    primary: Color(0xFF10A37F),
    primaryForeground: Color(0xFFFFFFFF),

    secondary: Color(0xFFF7F7F8),
    secondaryForeground: Color(0xFF6B7280),

    muted: Color(0xFFF7F7F8),
    mutedForeground: Color(0xFF9CA3AF),

    accent: Color(0xFFF7F7F8),
    accentForeground: Color(0xFF374151),

    destructive: Color(0xFFDC2626),

    border: Color(0xFFE5E5E5),
    input: Color(0xFFE5E5E5),
    ring: Color(0xFF10A37F),

    chart1: Color(0xFF10A37F),
    chart2: Color(0xFF3B82F6),
    chart3: Color(0xFFF59E0B),
    chart4: Color(0xFFDC2626),
    chart5: Color(0xFF8B5CF6),

    sidebar: Color(0xFFF7F7F8),
    sidebarForeground: Color(0xFF6B7280),
    sidebarPrimary: Color(0xFF10A37F),
    sidebarPrimaryForeground: Color(0xFFFFFFFF),
    sidebarAccent: Color(0xFFECECF1),
    sidebarAccentForeground: Color(0xFF374151),
    sidebarBorder: Color(0xFFE5E5E5),
    sidebarRing: Color(0xFF10A37F),
  );

  // Neutral Dark
  static const ColorScheme dark = ColorScheme(
    brightness: Brightness.dark,

    background: Color(0xFF0F0F0F),
    foreground: Color(0xFFEDEDED),

    card: Color(0xFF171717),
    cardForeground: Color(0xFFEDEDED),

    popover: Color(0xFF171717),
    popoverForeground: Color(0xFFEDEDED),

    primary: Color(0xFFEDEDED),
    primaryForeground: Color(0xFF0F0F0F),

    secondary: Color(0xFF262626),
    secondaryForeground: Color(0xFFA3A3A3),

    muted: Color(0xFF262626),
    mutedForeground: Color(0xFF737373),

    accent: Color(0xFF262626),
    accentForeground: Color(0xFFEDEDED),

    destructive: Color(0xFFDC2626),

    border: Color(0xFF262626),
    input: Color(0xFF262626),
    ring: Color(0xFFA3A3A3),

    chart1: Color(0xFF60A5FA),
    chart2: Color(0xFF4ADE80),
    chart3: Color(0xFFFBBF24),
    chart4: Color(0xFFF472B6),
    chart5: Color(0xFFF87171),

    sidebar: Color(0xFF0A0A0A),
    sidebarForeground: Color(0xFFA3A3A3),
    sidebarPrimary: Color(0xFFEDEDED),
    sidebarPrimaryForeground: Color(0xFF0F0F0F),
    sidebarAccent: Color(0xFF171717),
    sidebarAccentForeground: Color(0xFFEDEDED),
    sidebarBorder: Color(0xFF1F1F1F),
    sidebarRing: Color(0xFFA3A3A3),
  );

  // Claude Dark
  static const ColorScheme claudeDark = ColorScheme(
    brightness: Brightness.dark,

    background: Color(0xFF262624),
    foreground: Color(0xFFFAF9F5),

    card: Color(0xFF2F2F2D),
    cardForeground: Color(0xFFFAF9F5),

    popover: Color(0xFF2F2F2D),
    popoverForeground: Color(0xFFFAF9F5),

    primary: Color(0xFFD4715E),
    primaryForeground: Color(0xFFFFFFFF),

    secondary: Color(0xFF3B3B38),
    secondaryForeground: Color(0xFFC2BEB0),

    muted: Color(0xFF3B3B38),
    mutedForeground: Color(0xFF9C9990),

    accent: Color(0xFF2C84DB),
    accentForeground: Color(0xFFFFFFFF),

    destructive: Color(0xFFD94A4A),

    border: Color(0xFF3B3B38),
    input: Color(0xFF3B3B38),
    ring: Color(0xFF2C84DB),

    chart1: Color(0xFFD4715E),
    chart2: Color(0xFF4D9214),
    chart3: Color(0xFF2C84DB),
    chart4: Color(0xFFB17C05),
    chart5: Color(0xFFD94A4A),

    sidebar: Color(0xFF141413),
    sidebarForeground: Color(0xFF9C9990),
    sidebarPrimary: Color(0xFFD4715E),
    sidebarPrimaryForeground: Color(0xFFFFFFFF),
    sidebarAccent: Color(0xFF2F2F2D),
    sidebarAccentForeground: Color(0xFFFAF9F5),
    sidebarBorder: Color(0xFF1F1E1D),
    sidebarRing: Color(0xFF2C84DB),
  );

  // Claude Light
  static const ColorScheme claudeLight = ColorScheme(
    brightness: Brightness.light,

    background: Color(0xFFFAF9F5),
    foreground: Color(0xFF141413),

    card: Color(0xFFFFFFFF),
    cardForeground: Color(0xFF141413),

    popover: Color(0xFFFFFFFF),
    popoverForeground: Color(0xFF141413),

    primary: Color(0xFFD4715E),
    primaryForeground: Color(0xFFFFFFFF),

    secondary: Color(0xFFF5F3E8),
    secondaryForeground: Color(0xFF3D3D3A),

    muted: Color(0xFFEFE9DC),
    mutedForeground: Color(0xFF727067),

    accent: Color(0xFF2C84DB),
    accentForeground: Color(0xFFFFFFFF),

    destructive: Color(0xFFB5302F),

    border: Color(0xFFE6E1D0),
    input: Color(0xFFE6E1D0),
    ring: Color(0xFF2C84DB),

    chart1: Color(0xFFD4715E),
    chart2: Color(0xFF2D7613),
    chart3: Color(0xFF2C84DB),
    chart4: Color(0xFF866104),
    chart5: Color(0xFFB5302F),

    sidebar: Color(0xFFEFEBDC),
    sidebarForeground: Color(0xFF3D3D3A),
    sidebarPrimary: Color(0xFFD4715E),
    sidebarPrimaryForeground: Color(0xFFFFFFFF),
    sidebarAccent: Color(0xFFE6E1D0),
    sidebarAccentForeground: Color(0xFF141413),
    sidebarBorder: Color(0xFFE6E1D0),
    sidebarRing: Color(0xFF2C84DB),
  );

  // Notion Dark
  static const ColorScheme notionDark = ColorScheme(
    brightness: Brightness.dark,

    background: Color(0xFF191919),
    foreground: Color(0xFFE3E2E0),

    card: Color(0xFF202020),
    cardForeground: Color(0xFFE3E2E0),

    popover: Color(0xFF252525),
    popoverForeground: Color(0xFFE3E2E0),

    primary: Color(0xFF2EAADC),
    primaryForeground: Color(0xFFFFFFFF),

    secondary: Color(0xFF2F2F2F),
    secondaryForeground: Color(0xFFABABA8),

    muted: Color(0xFF2F2F2F),
    mutedForeground: Color(0xFF7F7F7D),

    accent: Color(0xFF2F2F2F),
    accentForeground: Color(0xFFE3E2E0),

    destructive: Color(0xFFEB5757),

    border: Color(0xFF373737),
    input: Color(0xFF2F2F2F),
    ring: Color(0xFF2EAADC),

    chart1: Color(0xFF2EAADC),
    chart2: Color(0xFF4DAB9A),
    chart3: Color(0xFFD9A87C),
    chart4: Color(0xFFE07D7D),
    chart5: Color(0xFF9D7CD8),

    sidebar: Color(0xFF121212),
    sidebarForeground: Color(0xFFABABA8),
    sidebarPrimary: Color(0xFFE3E2E0),
    sidebarPrimaryForeground: Color(0xFF191919),
    sidebarAccent: Color(0xFF252525),
    sidebarAccentForeground: Color(0xFFE3E2E0),
    sidebarBorder: Color(0xFF2F2F2F),
    sidebarRing: Color(0xFF2EAADC),
  );

  // Notion Light
  static const ColorScheme notionLight = ColorScheme(
    brightness: Brightness.light,

    background: Color(0xFFFFFFFF),
    foreground: Color(0xFF37352F),

    card: Color(0xFFFFFFFF),
    cardForeground: Color(0xFF37352F),

    popover: Color(0xFFFFFFFF),
    popoverForeground: Color(0xFF37352F),

    primary: Color(0xFF2EAADC),
    primaryForeground: Color(0xFFFFFFFF),

    secondary: Color(0xFFF7F6F3),
    secondaryForeground: Color(0xFF55534E),

    muted: Color(0xFFF1F1EF),
    mutedForeground: Color(0xFF787774),

    accent: Color(0xFFF7F6F3),
    accentForeground: Color(0xFF37352F),

    destructive: Color(0xFFEB5757),

    border: Color(0xFFE9E9E7),
    input: Color(0xFFE9E9E7),
    ring: Color(0xFF2EAADC),

    chart1: Color(0xFF2EAADC),
    chart2: Color(0xFF0F7B6C),
    chart3: Color(0xFFC77D48),
    chart4: Color(0xFFE03E3E),
    chart5: Color(0xFF6940A5),

    sidebar: Color(0xFFF7F6F3),
    sidebarForeground: Color(0xFF55534E),
    sidebarPrimary: Color(0xFF37352F),
    sidebarPrimaryForeground: Color(0xFFFFFFFF),
    sidebarAccent: Color(0xFFEFEEEB),
    sidebarAccentForeground: Color(0xFF37352F),
    sidebarBorder: Color(0xFFE9E9E7),
    sidebarRing: Color(0xFF2EAADC),
  );

  // Google AI Studio Dark
  static const ColorScheme googleAiDark = ColorScheme(
    brightness: Brightness.dark,

    background: Color(0xFF1E1F20),
    foreground: Color(0xFFE3E3E3),

    card: Color(0xFF282A2C),
    cardForeground: Color(0xFFE3E3E3),

    popover: Color(0xFF2D2E30),
    popoverForeground: Color(0xFFE3E3E3),

    primary: Color(0xFF8AB4F8),
    primaryForeground: Color(0xFF1E1F20),

    secondary: Color(0xFF3C4043),
    secondaryForeground: Color(0xFFBDC1C6),

    muted: Color(0xFF3C4043),
    mutedForeground: Color(0xFF9AA0A6),

    accent: Color(0xFF81C995),
    accentForeground: Color(0xFF1E1F20),

    destructive: Color(0xFFF28B82),

    border: Color(0xFF3C4043),
    input: Color(0xFF3C4043),
    ring: Color(0xFF8AB4F8),

    chart1: Color(0xFF8AB4F8),
    chart2: Color(0xFF81C995),
    chart3: Color(0xFFFDD663),
    chart4: Color(0xFFF28B82),
    chart5: Color(0xFFC58AF9),

    sidebar: Color(0xFF17181A),
    sidebarForeground: Color(0xFFBDC1C6),
    sidebarPrimary: Color(0xFF8AB4F8),
    sidebarPrimaryForeground: Color(0xFF1E1F20),
    sidebarAccent: Color(0xFF282A2C),
    sidebarAccentForeground: Color(0xFFE3E3E3),
    sidebarBorder: Color(0xFF3C4043),
    sidebarRing: Color(0xFF8AB4F8),
  );

  // Google AI Studio Light
  static const ColorScheme googleAiLight = ColorScheme(
    brightness: Brightness.light,

    background: Color(0xFFFFFFFF),
    foreground: Color(0xFF202124),

    card: Color(0xFFFFFFFF),
    cardForeground: Color(0xFF202124),

    popover: Color(0xFFFFFFFF),
    popoverForeground: Color(0xFF202124),

    primary: Color(0xFF1A73E8),
    primaryForeground: Color(0xFFFFFFFF),

    secondary: Color(0xFFF1F3F4),
    secondaryForeground: Color(0xFF5F6368),

    muted: Color(0xFFF1F3F4),
    mutedForeground: Color(0xFF80868B),

    accent: Color(0xFF1E8E3E),
    accentForeground: Color(0xFFFFFFFF),

    destructive: Color(0xFFD93025),

    border: Color(0xFFDADCE0),
    input: Color(0xFFDADCE0),
    ring: Color(0xFF1A73E8),

    chart1: Color(0xFF1A73E8),
    chart2: Color(0xFF1E8E3E),
    chart3: Color(0xFFF9AB00),
    chart4: Color(0xFFD93025),
    chart5: Color(0xFFA142F4),

    sidebar: Color(0xFFF8F9FA),
    sidebarForeground: Color(0xFF5F6368),
    sidebarPrimary: Color(0xFF1A73E8),
    sidebarPrimaryForeground: Color(0xFFFFFFFF),
    sidebarAccent: Color(0xFFE8F0FE),
    sidebarAccentForeground: Color(0xFF202124),
    sidebarBorder: Color(0xFFDADCE0),
    sidebarRing: Color(0xFF1A73E8),
  );

  // Studio Dark
  static const ColorScheme studioDark = ColorScheme(
    brightness: Brightness.dark,

    background: Color(0xFF1A1A1A),
    foreground: Color(0xFFE5E5E5),

    card: Color(0xFF252525),
    cardForeground: Color(0xFFE5E5E5),

    popover: Color(0xFF2A2A2A),
    popoverForeground: Color(0xFFE5E5E5),

    primary: Color(0xFF14B8A6),
    primaryForeground: Color(0xFFFFFFFF),

    secondary: Color(0xFF2F2F2F),
    secondaryForeground: Color(0xFFA1A1AA),

    muted: Color(0xFF2F2F2F),
    mutedForeground: Color(0xFF71717A),

    accent: Color(0xFFF59E0B),
    accentForeground: Color(0xFFFFFFFF),

    destructive: Color(0xFFEF4444),

    border: Color(0xFF3F3F46),
    input: Color(0xFF27272A),
    ring: Color(0xFF14B8A6),

    chart1: Color(0xFF14B8A6),
    chart2: Color(0xFF3B82F6),
    chart3: Color(0xFFF59E0B),
    chart4: Color(0xFFEF4444),
    chart5: Color(0xFFA855F7),

    sidebar: Color(0xFF0F0F0F),
    sidebarForeground: Color(0xFFA1A1AA),
    sidebarPrimary: Color(0xFF14B8A6),
    sidebarPrimaryForeground: Color(0xFFFFFFFF),
    sidebarAccent: Color(0xFF252525),
    sidebarAccentForeground: Color(0xFFE5E5E5),
    sidebarBorder: Color(0xFF27272A),
    sidebarRing: Color(0xFF14B8A6),
  );

  // Studio Light
  static const ColorScheme studioLight = ColorScheme(
    brightness: Brightness.light,

    background: Color(0xFFFAFAFA),
    foreground: Color(0xFF18181B),

    card: Color(0xFFFFFFFF),
    cardForeground: Color(0xFF18181B),

    popover: Color(0xFFFFFFFF),
    popoverForeground: Color(0xFF18181B),

    primary: Color(0xFF0D9488),
    primaryForeground: Color(0xFFFFFFFF),

    secondary: Color(0xFFF4F4F5),
    secondaryForeground: Color(0xFF52525B),

    muted: Color(0xFFF4F4F5),
    mutedForeground: Color(0xFF71717A),

    accent: Color(0xFFD97706),
    accentForeground: Color(0xFFFFFFFF),

    destructive: Color(0xFFDC2626),

    border: Color(0xFFE4E4E7),
    input: Color(0xFFE4E4E7),
    ring: Color(0xFF0D9488),

    chart1: Color(0xFF0D9488),
    chart2: Color(0xFF2563EB),
    chart3: Color(0xFFD97706),
    chart4: Color(0xFFDC2626),
    chart5: Color(0xFF9333EA),

    sidebar: Color(0xFFF4F4F5),
    sidebarForeground: Color(0xFF52525B),
    sidebarPrimary: Color(0xFF0D9488),
    sidebarPrimaryForeground: Color(0xFFFFFFFF),
    sidebarAccent: Color(0xFFE4E4E7),
    sidebarAccentForeground: Color(0xFF18181B),
    sidebarBorder: Color(0xFFE4E4E7),
    sidebarRing: Color(0xFF0D9488),
  );

  // Zen Dark
  static const ColorScheme zenDark = ColorScheme(
    brightness: Brightness.dark,

    background: Color(0xFF1F1F1F),
    foreground: Color(0xFFE8E6D9),

    card: Color(0xFF262626),
    cardForeground: Color(0xFFE8E6D9),

    popover: Color(0xFF262626),
    popoverForeground: Color(0xFFE8E6D9),

    primary: Color(0xFFC15D47),
    primaryForeground: Color(0xFFFFFFFF),

    secondary: Color(0xFF2A2A2A),
    secondaryForeground: Color(0xFFB8B6A9),

    muted: Color(0xFF2A2A2A),
    mutedForeground: Color(0xFF8A887D),

    accent: Color(0xFF6287F5),
    accentForeground: Color(0xFFFFFFFF),

    destructive: Color(0xFFEF4444),

    border: Color(0xFF333333),
    input: Color(0xFF2A2A2A),
    ring: Color(0xFFF76F53),

    chart1: Color(0xFFF76F53),
    chart2: Color(0xFF63F78B),
    chart3: Color(0xFF6287F5),
    chart4: Color(0xFFEF4444),
    chart5: Color(0xFFA855F7),

    sidebar: Color(0xFF1F1F1F),
    sidebarForeground: Color(0xFFB8B6A9),
    sidebarPrimary: Color(0xFFF76F53),
    sidebarPrimaryForeground: Color(0xFFFFFFFF),
    sidebarAccent: Color(0xFF2A2A2A),
    sidebarAccentForeground: Color(0xFFE8E6D9),
    sidebarBorder: Color(0xFF2A2A2A),
    sidebarRing: Color(0xFFF76F53),
  );

  // Zen Light
  static const ColorScheme zenLight = ColorScheme(
    brightness: Brightness.light,

    background: Color(0xFFFAFAF8),
    foreground: Color(0xFF2E2E2E),

    card: Color(0xFFFFFFFF),
    cardForeground: Color(0xFF2E2E2E),

    popover: Color(0xFFFFFFFF),
    popoverForeground: Color(0xFF2E2E2E),

    primary: Color(0xFFF76F53),
    primaryForeground: Color(0xFFFFFFFF),

    secondary: Color(0xFFF5F5F3),
    secondaryForeground: Color(0xFF525252),

    muted: Color(0xFFF0F0EE),
    mutedForeground: Color(0xFF737373),

    accent: Color(0xFF6287F5),
    accentForeground: Color(0xFFFFFFFF),

    destructive: Color(0xFFDC2626),

    border: Color(0xFFE5E5E3),
    input: Color(0xFFF0F0EE),
    ring: Color(0xFFF76F53),

    chart1: Color(0xFFF76F53),
    chart2: Color(0xFF63F78B),
    chart3: Color(0xFF6287F5),
    chart4: Color(0xFFDC2626),
    chart5: Color(0xFF9333EA),

    sidebar: Color(0xFFFAFAF8),
    sidebarForeground: Color(0xFF525252),
    sidebarPrimary: Color(0xFFF76F53),
    sidebarPrimaryForeground: Color(0xFFFFFFFF),
    sidebarAccent: Color(0xFFF0F0EE),
    sidebarAccentForeground: Color(0xFF2E2E2E),
    sidebarBorder: Color(0xFFE5E5E3),
    sidebarRing: Color(0xFFF76F53),
  );

  // Neutral Light
  static const ColorScheme light = ColorScheme(
    brightness: Brightness.light,

    background: Color(0xFFFFFFFF),
    foreground: Color(0xFF0F0F0F),

    card: Color(0xFFFFFFFF),
    cardForeground: Color(0xFF0F0F0F),

    popover: Color(0xFFFFFFFF),
    popoverForeground: Color(0xFF0F0F0F),

    primary: Color(0xFF171717),
    primaryForeground: Color(0xFFFAFAFA),

    secondary: Color(0xFFF5F5F5),
    secondaryForeground: Color(0xFF525252),

    muted: Color(0xFFF5F5F5),
    mutedForeground: Color(0xFF737373),

    accent: Color(0xFFF5F5F5),
    accentForeground: Color(0xFF171717),

    destructive: Color(0xFFDC2626),

    border: Color(0xFFE5E5E5),
    input: Color(0xFFE5E5E5),
    ring: Color(0xFF525252),

    chart1: Color(0xFF2563EB),
    chart2: Color(0xFF16A34A),
    chart3: Color(0xFFD97706),
    chart4: Color(0xFFDB2777),
    chart5: Color(0xFFDC2626),

    sidebar: Color(0xFFFAFAFA),
    sidebarForeground: Color(0xFF525252),
    sidebarPrimary: Color(0xFF171717),
    sidebarPrimaryForeground: Color(0xFFFAFAFA),
    sidebarAccent: Color(0xFFF5F5F5),
    sidebarAccentForeground: Color(0xFF171717),
    sidebarBorder: Color(0xFFE5E5E5),
    sidebarRing: Color(0xFF525252),
  );

  static ColorScheme getDarkTheme({
    defaultColorScheme = ColorSchemes.defaultcolor,
  }) {
    return zenDark;
  }

  static ColorScheme getLightTheme({
    defaultColorScheme = ColorSchemes.defaultcolor,
  }) {
    return zenLight;
  }

  static ColorScheme getClaudeDarkTheme({
    defaultColorScheme = ColorSchemes.defaultcolor,
  }) {
    return claudeDark;
  }

  static ColorScheme getClaudeLightTheme({
    defaultColorScheme = ColorSchemes.defaultcolor,
  }) {
    return claudeLight;
  }

  static ColorScheme getNotionDarkTheme({
    defaultColorScheme = ColorSchemes.defaultcolor,
  }) {
    return notionDark;
  }

  static ColorScheme getNotionLightTheme({
    defaultColorScheme = ColorSchemes.defaultcolor,
  }) {
    return notionLight;
  }

  static ColorScheme getGoogleAiDarkTheme({
    defaultColorScheme = ColorSchemes.defaultcolor,
  }) {
    return googleAiDark;
  }

  static ColorScheme getGoogleAiLightTheme({
    defaultColorScheme = ColorSchemes.defaultcolor,
  }) {
    return googleAiLight;
  }

  static ColorScheme getChatGptDarkTheme({
    defaultColorScheme = ColorSchemes.defaultcolor,
  }) {
    return chatGptDark;
  }

  static ColorScheme getChatGptLightTheme({
    defaultColorScheme = ColorSchemes.defaultcolor,
  }) {
    return chatGptLight;
  }

  static ColorScheme getStudioDarkTheme({
    defaultColorScheme = ColorSchemes.defaultcolor,
  }) {
    return studioDark;
  }

  static ColorScheme getStudioLightTheme({
    defaultColorScheme = ColorSchemes.defaultcolor,
  }) {
    return studioLight;
  }

  static ColorScheme getZenDarkTheme({
    defaultColorScheme = ColorSchemes.defaultcolor,
  }) {
    return zenDark;
  }

  static ColorScheme getZenLightTheme({
    defaultColorScheme = ColorSchemes.defaultcolor,
  }) {
    return zenLight;
  }
}
