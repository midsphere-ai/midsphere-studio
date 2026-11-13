import 'package:arcane/arcane.dart';
import 'package:google_fonts/google_fonts.dart';

class TerminalView extends StatelessWidget {
  final String inputCommand;
  final String output;
  final String prompt;
  final Color backgroundColor;
  final Color defaultTextColor;
  final Color promptColor;
  final Color cursorColor;
  final double fontSize;
  final bool showCursor;

  const TerminalView({
    super.key,
    required this.inputCommand,
    required this.output,
    this.prompt = 'sandbox@midsphere:~\$ ',
    this.backgroundColor = const Color(0xFF1E1E1E),
    this.defaultTextColor = const Color(0xFFD4D4D4), // Light grey text
    this.promptColor = const Color(0xFF6A9DCB), // Often blue/greenish
    this.cursorColor = const Color(0xFF60F87E), // Often bright green
    this.fontSize = 14.0,
    this.showCursor = true,
  });

  @override
  Widget build(BuildContext context) {
    // Use a monospaced font like Source Code Pro, Fira Code, Monaco, etc.
    final textStyle = GoogleFonts.ibmPlexMono(
      fontSize: fontSize,
      color: defaultTextColor,
      height: 1.3, // Adjust line height for readability
    );

    final promptStyle = textStyle.copyWith(
      color: promptColor,
      fontWeight: FontWeight.bold, // Prompts are often bold
    );

    return Container(
      color: backgroundColor,
      width: double.infinity, // Occupy available width
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            RichText(
              text: TextSpan(
                style: textStyle, // Default style for the line
                children: [
                  // Prompt
                  TextSpan(text: prompt, style: promptStyle),
                  // Input Command
                  TextSpan(text: inputCommand),
                  // Simulated Cursor (non-blinking block)
                  if (showCursor)
                    TextSpan(
                      text: '█', // Unicode FULL BLOCK character
                      style: textStyle.copyWith(color: cursorColor),
                    ),
                ],
              ),
            ),

            // --- Output Lines ---
            // Add a small gap if there is output
            if (output.isNotEmpty) const SizedBox(height: 8),

            // Display output text
            if (output.isNotEmpty)
              Text(
                output,
                softWrap: true, // Allow text to wrap if it exceeds width
              ).mono.small.muted,
          ],
        ),
      ),
    );
  }
}
