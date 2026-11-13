import 'package:arcane/arcane.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// A widget that displays a geometric background SVG.
class BackgroundSvg extends StatelessWidget {
  /// Creates a new [BackgroundSvg] widget.
  const BackgroundSvg({super.key});

  @override
  Widget build(BuildContext context) {
    String svgCode = """
   <svg class="mx-auto h-auto w-full min-w-[1443px] opacity-90" viewBox="0 0 1443 222" fill="none" xmlns="http://www.w3.org/2000/svg">

  <defs>
    <linearGradient id="strokeFlow" x1="0%" y1="0%" x2="100%" y2="0%">
      <stop offset="0%" style="stop-color:currentColor;stop-opacity:0.3" />
      <stop offset="25%" style="stop-color:currentColor;stop-opacity:0.8" />
      <stop offset="75%" style="stop-color:currentColor;stop-opacity:0.8" />
      <stop offset="100%" style="stop-color:currentColor;stop-opacity:0.3" />
    </linearGradient>

    <filter id="glow">
      <feGaussianBlur stdDeviation="1" result="coloredBlur"/>
      <feMerge>
        <feMergeNode in="coloredBlur"/>
        <feMergeNode in="SourceGraphic"/>
      </feMerge>
    </filter>
  </defs>

  <g stroke="currentColor" fill="none">

    <!-- Main architectural framework - the backbone -->
    <g stroke-width="2" opacity="0.6" stroke="url(#strokeFlow)">
      <!-- Top horizon line -->
      <path d="M0,86.77 L1442.81,86.77"/>
      <!-- Bottom cascade line -->
      <path d="M0,122.76 L37.92,85.77 L122.26,122.40 L207.81,86.77 L293.26,172.40 L378.69,122.76 L465.45,209.71 L551.00,86.40 L636.44,170.80 L720.82,122.76 L807.58,209.71 L893.13,86.40 L978.58,170.68 L1062.8,122.76 L1149.56,209.71 L1235.11,86.40 L1320.54,170.80 L1406.1,86.77 L1442.81,86.77"/>
    </g>

    <!-- Precise vertical rhythm -->
    <g stroke-width="1.5" opacity="0.5">
      <line x1="122.26" y1="0" x2="122.26" y2="222"/>
      <line x1="293.26" y1="0" x2="293.26" y2="222"/>
      <line x1="465.45" y1="0" x2="465.45" y2="222"/>
      <line x1="636.44" y1="0" x2="636.44" y2="222"/>
      <line x1="807.58" y1="0" x2="807.58" y2="222"/>
      <line x1="978.58" y1="0" x2="978.58" y2="222"/>
      <line x1="1149.56" y1="0" x2="1149.56" y2="222"/>
      <line x1="1320.54" y1="0" x2="1320.54" y2="222"/>
    </g>

    <!-- The intricate stepped pyramids - stroke outlines -->
    <g stroke-width="1.2" opacity="0.7">
      <!-- Section 1 -->
      <path d="M0,0 L245.73,0 L245.73,11.22 L256.95,0 L258.66,0 L245.73,12.93 L245.73,122.76 L209.02,122.76 L209.02,170.69 L293.26,86.40 L293.26,0"/>

      <!-- Section 2 -->
      <path d="M293.26,0 L294.47,0 L294.47,86.40 L378.69,170.68 L378.69,122.76 L341.98,122.76 L341.98,12.93 L329.06,0 L330.77,0 L341.98,11.22 L341.98,0 L587.71,0"/>

      <!-- Section 3 -->
      <path d="M587.71,0 L587.71,11.22 L598.93,0 L600.64,0 L587.71,12.93 L587.71,122.76 L551.00,122.76 L551.00,170.68 L635.23,86.40 L635.23,0 L636.44,0"/>

      <!-- Section 4 -->
      <path d="M636.44,0 L636.44,86.40 L720.78,170.80 L720.78,122.76 L684.11,122.76 L684.11,13.09 L671.03,0 L672.74,0 L684.11,11.38 L684.11,0 L929.84,0"/>

      <!-- Section 5 -->
      <path d="M929.84,0 L929.84,11.22 L941.06,0 L942.77,0 L929.84,12.93 L929.84,122.76 L893.13,122.76 L893.13,170.69 L977.37,86.40 L977.37,0 L978.58,0"/>

      <!-- Section 6 -->
      <path d="M978.58,0 L978.58,86.40 L1062.8,170.68 L1062.8,122.76 L1026.09,122.76 L1026.09,12.93 L1013.17,0 L1014.88,0 L1026.09,11.22 L1026.09,0 L1271.83,0"/>

      <!-- Section 7 -->
      <path d="M1271.83,0 L1271.83,11.22 L1283.04,0 L1284.75,0 L1271.83,12.93 L1271.83,122.76 L1235.11,122.76 L1235.11,170.68 L1319.34,86.40 L1319.34,0 L1320.54,0"/>

      <!-- Final section -->
      <path d="M1320.54,0 L1320.54,86.40 L1404.88,170.80 L1404.88,49.78 L1355.13,0 L1356.85,0 L1406.1,49.28 L1406.1,85.56 L1441.59,85.56 L1441.59,0 L1442.81,0 L1442.81,86.77"/>
    </g>

    <!-- Detailed angular transitions -->
    <g stroke-width="0.8" opacity="0.6">
      <path d="M37.92,85.77 L122.26,122.40 L207.81,206.79 L207.81,173.72 L207.70,173.61 L207.81,86.77"/>
      <path d="M380.02,206.79 L464.24,122.40 L549.79,173.60 L549.67,173.72 L549.79,86.77"/>
      <path d="M722.03,206.79 L806.37,122.40 L891.92,173.61 L891.81,173.72 L891.92,86.77"/>
      <path d="M1064.01,206.79 L1148.35,122.40 L1233.9,173.60 L1233.78,173.72 L1233.9,86.77"/>
    </g>

    <!-- Micro-geometric details -->
    <g stroke-width="0.6" opacity="0.4">
      <path d="M172.20,48.43 L207.70,83.95 L207.70,49.28 L244.52,12.43"/>
      <path d="M856.31,48.43 L891.81,83.95 L891.81,49.28 L928.64,12.43"/>
      <path d="M514.17,48.42 L549.67,83.95 L549.67,49.28 L586.50,12.43"/>
      <path d="M1198.28,48.42 L1233.78,83.95 L1233.78,49.28 L1270.61,12.43"/>
    </g>

    <!-- Ultra-fine architectural details -->
    <g stroke-width="0.4" opacity="0.3">
      <path d="M170.99,47.22 L124.33,0.52"/>
      <path d="M855.10,47.22 L808.44,0.52"/>
      <path d="M416.73,47.21 L463.39,0.52"/>
      <path d="M1100.83,47.21 L1147.5,0.52"/>
      <path d="M512.96,47.21 L466.31,0.52"/>
      <path d="M1197.07,47.21 L1150.42,0.52"/>
      <path d="M758.70,47.37 L805.52,0.52"/>
    </g>

    <!-- Border frame -->
    <rect x="0" y="0" width="1443" height="222" stroke-width="1.8" opacity="0.7"/>

  </g>
</svg>
    """;

    final colors = Theme.of(context).colorScheme;
    return ShaderMask(
      shaderCallback: (Rect bounds) {
        // Create a linear gradient shader for the mask
        return LinearGradient(
          colors: [colors.secondary, colors.background],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(bounds);
      },
      blendMode: BlendMode.srcIn,
      child: SvgPicture.string(
        svgCode,
        fit: BoxFit.cover,
        colorFilter: ColorFilter.mode(
          Theme.of(context).colorScheme.muted,
          BlendMode.srcIn,
        ),
      ),
    );
  }
}
