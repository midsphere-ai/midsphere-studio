import 'package:google_fonts/google_fonts.dart';
import 'package:arcane/arcane.dart';

/// A [Typography] class that uses Google Fonts to create text styles.
class GoogleTypography extends Typography {
  /// Creates a new [GoogleTypography] instance.
  ///
  /// This constructor is private and should not be called directly.
  /// Use one of the factory constructors to create a new instance.
  const GoogleTypography._({
    required super.sans,
    required super.mono,
    required super.xSmall,
    required super.small,
    required super.base,
    required super.large,
    required super.xLarge,
    required super.x2Large,
    required super.x3Large,
    required super.x4Large,
    required super.x5Large,
    required super.x6Large,
    required super.x7Large,
    required super.x8Large,
    required super.x9Large,
    required super.thin,
    required super.light,
    required super.extraLight,
    required super.normal,
    required super.medium,
    required super.semiBold,
    required super.bold,
    required super.extraBold,
    required super.black,
    required super.italic,
    required super.h1,
    required super.h2,
    required super.h3,
    required super.h4,
    required super.p,
    required super.blockQuote,
    required super.inlineCode,
    required super.lead,
    required super.textLarge,
    required super.textSmall,
    required super.textMuted,
  });

  /// Creates a new [GoogleTypography] instance with the Space Grotesk font.
  ///
  /// The sans-serif font is set to 'GeistSans' and the monospace font is set to 'IBMPlexMono'.
  factory GoogleTypography.inter() {
    final sans =  GoogleFonts.bricolageGrotesque( height: 1.4);
    final serif = GoogleFonts.bricolageGrotesque(height: 1.4);
    final mono = GoogleFonts.jetBrainsMono();

    return GoogleTypography._(
      sans: sans.copyWith(fontSize: 16),
      mono: mono,
      xSmall: sans.copyWith(fontSize: 12),
      small: sans.copyWith(fontSize: 14),
      base: sans.copyWith(fontSize: 16),
      large: serif.copyWith(fontSize: 18),
      xLarge: serif.copyWith(fontSize: 20),
      x2Large: serif.copyWith(fontSize: 24),
      x3Large: serif.copyWith(fontSize: 30),
      x4Large: serif.copyWith(fontSize: 36),
      x5Large: serif.copyWith(fontSize: 48),
      x6Large: serif.copyWith(fontSize: 60),
      x7Large: serif.copyWith(fontSize: 72),
      x8Large: serif.copyWith(fontSize: 96),
      x9Large: serif.copyWith(fontSize: 144),

      thin: sans.copyWith(fontWeight: FontWeight.w100),
      extraLight: sans.copyWith(fontWeight: FontWeight.w200),
      light: sans.copyWith(fontWeight: FontWeight.w300),
      normal: sans.copyWith(fontWeight: FontWeight.w400),
      medium: sans.copyWith(fontWeight: FontWeight.w500),
      semiBold: sans.copyWith(fontWeight: FontWeight.w600),
      bold: sans.copyWith(fontWeight: FontWeight.w700),
      extraBold: sans.copyWith(fontWeight: FontWeight.w800),
      black: sans.copyWith(fontWeight: FontWeight.w900),

      italic: sans.copyWith(fontStyle: FontStyle.italic),

      h1: serif.copyWith(fontSize: 36, fontWeight: FontWeight.w500),
      h2: serif.copyWith(fontSize: 30, fontWeight: FontWeight.w400),
      h3: serif.copyWith(fontSize: 24, fontWeight: FontWeight.w400),
      h4: serif.copyWith(fontSize: 18, fontWeight: FontWeight.w400),
      p: serif.copyWith(fontSize: 16, fontWeight: FontWeight.w400),

      blockQuote: sans.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        fontStyle: FontStyle.italic,
      ),
      inlineCode: mono.copyWith(fontSize: 14, fontWeight: FontWeight.w600),
      lead: sans.copyWith(fontSize: 20),
      textLarge: sans.copyWith(fontSize: 20, fontWeight: FontWeight.w600),
      textSmall: sans.copyWith(fontSize: 14, fontWeight: FontWeight.w500),
      textMuted: sans.copyWith(fontSize: 14, fontWeight: FontWeight.w400),
    );
  }

  /// Creates a new [GoogleTypography] instance with the IBM Plex Mono font.
  ///
  /// Both the sans-serif and monospace fonts are set to 'IBMPlexMono'.
  factory GoogleTypography.ibmPlexMono() {
    final sans = GoogleFonts.ibmPlexMono();
    final mono = GoogleFonts.ibmPlexMono();
    return GoogleTypography._(
      sans: sans,
      mono: mono,
      xSmall: sans.copyWith(fontSize: 12),
      small: sans.copyWith(fontSize: 14),
      base: sans.copyWith(fontSize: 16),
      large: sans.copyWith(fontSize: 18),
      xLarge: sans.copyWith(fontSize: 20),
      x2Large: sans.copyWith(fontSize: 24),
      x3Large: sans.copyWith(fontSize: 30),
      x4Large: sans.copyWith(fontSize: 36),
      x5Large: sans.copyWith(fontSize: 48),
      x6Large: sans.copyWith(fontSize: 60),
      x7Large: sans.copyWith(fontSize: 72),
      x8Large: sans.copyWith(fontSize: 96),
      x9Large: sans.copyWith(fontSize: 144),

      thin: sans.copyWith(fontWeight: FontWeight.w100),
      extraLight: sans.copyWith(fontWeight: FontWeight.w200),
      light: sans.copyWith(fontWeight: FontWeight.w300),
      normal: sans.copyWith(fontWeight: FontWeight.w400),
      medium: sans.copyWith(fontWeight: FontWeight.w500),
      semiBold: sans.copyWith(fontWeight: FontWeight.w600),
      bold: sans.copyWith(fontWeight: FontWeight.w700),
      extraBold: sans.copyWith(fontWeight: FontWeight.w800),
      black: sans.copyWith(fontWeight: FontWeight.w900),

      italic: sans.copyWith(fontStyle: FontStyle.italic),

      h1: sans.copyWith(fontSize: 36, fontWeight: FontWeight.w800),
      h2: sans.copyWith(fontSize: 30, fontWeight: FontWeight.w600),
      h3: sans.copyWith(fontSize: 24, fontWeight: FontWeight.w600),
      h4: sans.copyWith(fontSize: 18, fontWeight: FontWeight.w600),
      p: sans.copyWith(fontSize: 16, fontWeight: FontWeight.w400),

      blockQuote: sans.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        fontStyle: FontStyle.italic,
      ),
      inlineCode: mono.copyWith(fontSize: 14, fontWeight: FontWeight.w600),
      lead: sans.copyWith(fontSize: 20),
      textLarge: sans.copyWith(fontSize: 20, fontWeight: FontWeight.w600),
      textSmall: sans.copyWith(fontSize: 14, fontWeight: FontWeight.w500),
      textMuted: sans.copyWith(fontSize: 14, fontWeight: FontWeight.w400),
    );
  }
}

/// A [TextModifier] that applies the x2Large text style from the theme's typography.
TextModifier google(text) => WrappedText(
  style: (context, theme) => theme.typography.x2Large,
  child: text,
);
