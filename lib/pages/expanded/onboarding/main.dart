import 'package:arcane/arcane.dart';
import 'package:arcane/generated/arcane_shadcn/src/components/overlay/toast.dart';
import 'package:flutter_client/pages/expanded/llm/forms/llm_provider_form.dart';

import '../../../widgets/backgrounds/constrained_box.dart';

class Onboarding extends StatefulWidget {
  const Onboarding({super.key});

  @override
  State<Onboarding> createState() => _OnboardingState();
}

class _OnboardingState extends State<Onboarding> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Track which LLMs have been configured
  bool primaryConfigured = false;
  bool reasoningConfigured = false;
  bool mediaConfigured = false;
  bool computerUseConfigured = false;

  // Data for Toast
  String toastMessage = '';
  String toastDescription = '';

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOutCubicEmphasized,
    );
  }

  void _prevPage() {
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOutCubicEmphasized,
    );
  }

  void _showToast(String title, String message) {
    toastMessage = title;
    toastDescription = message;
    showToast(
      context: context,
      builder: (context, overlay) => SurfaceCard(
        child: Basic(
          title: Text(toastMessage),
          subtitle: Text(toastDescription),
          trailingAlignment: Alignment.center,
        ),
      ),
      location: ToastLocation.topCenter,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Total pages: Intro + Concept + 4 LLMs + Completion
    const int totalPages = 7;
    final double progress = (_currentPage + 1) / totalPages;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: LimitedWindowBox(
        child: Column(
          children: [
            // Top Progress Bar
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                tween: Tween<double>(begin: 0, end: progress),
                builder: (context, value, _) => LinearProgressIndicator(
                  value: value,
                  backgroundColor: Theme.of(context).colorScheme.border,
                  minHeight: 2,
                ),
              ),
            ),

            // Main Content Area
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(), // Disable swipe
                onPageChanged: (page) => setState(() => _currentPage = page),
                children: [
                  _buildIntroStep(),
                  _buildConceptStep(),
                  _buildLlmStep(
                    stepIndex: 1,
                    title: "The Brain",
                    subtitle: "Primary Orchestration",
                    modelName: "agent-primary-llm",
                    description:
                    "The core intelligence. Handles tool orchestration, planning, and execution.",
                    recommendedModels: [
                      "moonshotai-kimi-k2",
                      "openai-gpt-5",
                      "anthropic-claude-sonnet"
                    ],
                    warning:
                    "Gemini 2.5 currently fails complex agentic benchmarks.",
                    isConfigured: primaryConfigured,
                    onSave: () => setState(() => primaryConfigured = true),
                  ),
                  _buildLlmStep(
                    stepIndex: 2,
                    title: "The Thinker",
                    subtitle: "Reasoning & Planning",
                    modelName: "agent-reasoning-llm",
                    description:
                    "Used for deep reasoning loops and multi-step trajectory verification.",
                    recommendedModels: [
                      "openai-o1",
                      "deepseek-r1",
                      "anthropic-claude-opus"
                    ],
                    isConfigured: reasoningConfigured,
                    onSave: () => setState(() => reasoningConfigured = true),
                  ),
                  _buildLlmStep(
                    stepIndex: 3,
                    title: "The Eyes",
                    subtitle: "Multimodal Perception",
                    modelName: "agent-media-llm",
                    description:
                    "Enables analysis of images, videos, documents, and audio streams.",
                    recommendedModels: [
                      "anthropic-claude-sonnet",
                      "gpt-5",
                      "qwen-2-vl"
                    ],
                    isConfigured: mediaConfigured,
                    onSave: () => setState(() => mediaConfigured = true),
                  ),
                  _buildLlmStep(
                    stepIndex: 4,
                    title: "The Hands",
                    subtitle: "Computer Use Interface",
                    modelName: "agent-computer-use-llm",
                    description:
                    "Specialized for visual grounding, GUI navigation, and file system control.",
                    recommendedModels: ["ui-tars", "gemini-2.5-cua"],
                    warning: "Requires strong visual-spatial grounding.",
                    isConfigured: computerUseConfigured,
                    onSave: () => setState(() => computerUseConfigured = true),
                  ),
                  _buildFinalStep(),
                ],
              ),
            ),

            // Bottom Navigation
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    // Determine if we can proceed based on current page requirements
    bool canProceed = true;
    if (_currentPage == 2 && !primaryConfigured) canProceed = false;
    if (_currentPage == 3 && !reasoningConfigured) canProceed = false;
    if (_currentPage == 4 && !mediaConfigured) canProceed = false;
    if (_currentPage == 5 && !computerUseConfigured) canProceed = false;

    // Last page has no navigation bar (it has its own buttons)
    if (_currentPage == 6) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Theme.of(context).colorScheme.border),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (_currentPage > 0)
            OutlineButton(
              onPressed: _prevPage,
              child: const Text("Back"),
            )
          else
            const SizedBox.shrink(),
          PrimaryButton(
            onPressed: canProceed ? _nextPage : null,
            trailing: const Icon(LucideIcons.arrowRight),
            child: Text(_currentPage == 0 ? "Get Started" : "Next").bold,
          ),
        ],
      ),
    );
  }

  // --- Step 1: Intro ---
  Widget _buildIntroStep() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              border: Border.all(color: Theme.of(context).colorScheme.border),
              borderRadius: Theme.of(context).borderRadiusMd,
            ),
            child: Text("Midsphere Studio v1.0").mono.xSmall,
          ),
          const Gap(24),
          Text("Welcome to the\nWorkforce.").h1,
          const Gap(16),
          Text(
            "You are one step away from operating a full-scale AI workforce on your own infrastructure. Midsphere is a self-hosted Agent IDE capable of reasoning, coding, and using your computer.",
            style: TextStyle(
              fontSize: 18,
              color: Theme.of(context).colorScheme.mutedForeground,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // --- Step 2: Concepts ---
  Widget _buildConceptStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Distributed Intelligence").h1,
          const Gap(12),
          Text(
            "Midsphere doesn't rely on a single model. Intelligence is split across four specialized roles to maximize performance and minimize cost.",
            style: TextStyle(
                color: Theme.of(context).colorScheme.mutedForeground,
                fontSize: 16),
          ),
          const Gap(32),
          _buildConceptRow("agent-primary-llm", "The Brain",
              "Daily orchestration & decision making."),
          const Divider(height: 32),
          _buildConceptRow("agent-reasoning-llm", "The Thinker",
              "Deep reasoning & multi-step planning."),
          const Divider(height: 32),
          _buildConceptRow("agent-media-llm", "The Eyes",
              "Vision, video, and audio understanding."),
          const Divider(height: 32),
          _buildConceptRow("agent-computer-use-llm", "The Hands",
              "Mouse, keyboard, and UI interaction."),
        ],
      ),
    );
  }

  Widget _buildConceptRow(String id, String role, String desc) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(LucideIcons.cpu,
            color: Theme.of(context).colorScheme.primary, size: 20),
        const Gap(16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(role).bold,
              Text(id).mono.xSmall.muted,
              const Gap(4),
              Text(desc).muted,
            ],
          ),
        ),
      ],
    );
  }

  // --- Generic LLM Config Step ---
  Widget _buildLlmStep({
    required int stepIndex,
    required String title,
    required String subtitle,
    required String modelName,
    required String description,
    required List<String> recommendedModels,
    String? warning,
    required bool isConfigured,
    required VoidCallback onSave,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(subtitle.toUpperCase()).mono.xSmall.muted,
                  Text(title).h1,
                ],
              ),
              if (isConfigured)
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color:
                    Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    borderRadius: Theme.of(context).borderRadiusMd,
                    border: Border.all(
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      const Icon(LucideIcons.check, size: 14),
                      const Gap(6),
                      Text("Ready").xSmall.bold,
                    ],
                  ),
                ),
            ],
          ),
          const Gap(16),
          Text(description).muted,
          const Gap(24),

          // Configuration Card
          Card(
            padding: EdgeInsets.all(8),
            filled: true,
            fillColor: Theme.of(context).colorScheme.background,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(LucideIcons.terminal, size: 16),
                      const Gap(8),
                      Text(modelName).mono.bold,
                    ],
                  ),
                  const Gap(16),
                  if (warning != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.1),
                        border: Border.all(color: Colors.amber.withOpacity(0.3)),
                        borderRadius:Theme.of(context).borderRadiusMd,
                      ),
                      child: Text(warning,
                          style: const TextStyle(
                              color: Colors.amber, fontSize: 13)),
                    ),
                    const Gap(16),
                  ],
                  LlmProviderForm(
                    type: modelName,
                    onboarding: true,
                    showToast: _showToast,
                    onSuccess: onSave,
                  ),
                ],
              ),
            ),
          ),
          const Gap(24),
          Text("Recommended Benchmarks").mono.xSmall.muted,
          const Gap(8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: recommendedModels
                .map((m) => Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                border: Border.all(
                    color: Theme.of(context).colorScheme.border),
                borderRadius: Theme.of(context).borderRadiusMd,
              ),
              child: Text(m).mono.xSmall,
            ))
                .toList(),
          ),
        ],
      ),
    );
  }

  // --- Step 5: Final ---
  Widget _buildFinalStep() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Theme.of(context).colorScheme.foreground,
            ),
            child: Icon(
              LucideIcons.zap,
              size: 48,
              color: Theme.of(context).colorScheme.background,
            ),
          ),
          const Gap(32),
          Text("Systems Online").h1,
          const Gap(16),
          Text(
            "Your distributed agent architecture is configured and ready.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Theme.of(context).colorScheme.mutedForeground,
            ),
          ),
          const Gap(48),
          PrimaryButton(
            // Placeholder for actual app navigation
            onPressed: () => _showToast("Done", "Navigating to dashboard..."),
            child: const Text("Enter Studio").bold,
          ),
          const Gap(16),
          OutlineButton(
            onPressed: () {
              // Navigate to advanced tool setup
            },
            child: const Text("Configure Tools (Optional)"),
          ),
        ],
      ),
    );
  }
}
