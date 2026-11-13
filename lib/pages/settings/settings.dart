import 'dart:async';
import 'dart:ui';

import 'package:arcane/arcane.dart';
import 'package:arcane/generated/arcane_shadcn/shadcn_flutter.dart'
    hide IconButton, Card;
import 'package:arcane/generated/arcane_shadcn/src/components/overlay/toast.dart';
import 'package:flutter_client/logics/data/global_logics.dart';
import 'package:flutter_client/logics/data/helpers/general_utils.dart';
import 'package:flutter_client/logics/data/repositories/authentication.dart';
import 'package:flutter_client/pages/home/sidebar/common/sub_header.dart';
import 'package:flutter_client/pages/settings/billing.dart';
import 'package:flutter_client/pages/settings/components/context_memory_view.dart';
import 'package:flutter_client/pages/expanded/llm/forms/llm_provider_form.dart';
import 'package:flutter_client/pages/expanded/llm/main.dart';
import 'package:flutter_client/pages/expanded/mcp/components/mcp_config_view.dart';
import 'package:flutter_client/pages/home/sidebar/base.dart';
import 'package:flutter_client/pages/test/api_test_page.dart';
import 'package:flutter_client/widgets/texts/settings_text_field.dart';
import 'package:flutter_client/widgets/animations/animations.dart';

import '../../logics/domain/usecases/memory/memory_usecase.dart';
import '../../logics/domain/usecases/workspace/workspace_usecase.dart';
import '../expanded/mcp/main.dart';
import '../expanded/schedule/main.dart';
import '../navigator.dart';
import '../home/home.dart';
import '../home/sidebar/common/header.dart';
import 'components/avatar.dart';

/// A widget that displays the settings page.
///
/// This widget allows the user to change the theme, modify their account details,
/// change the LLM provider, and view the privacy policy and terms and conditions.
class Settings extends StatefulWidget {
  /// Creates a new [Settings] widget.
  final VoidCallback? onBack;
  final bool notAsSidebar;
  const Settings({super.key, this.onBack, this.notAsSidebar = false});

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  static const String _modeBase = "base";

  // Main Categories
  static const String _general = "general";
  static const String _customise = "customise";
  static const String _account = "account";
  static const String _agent = "agent";
  static const String _notifications = "notifications";
  static const String _dataControls = "data_controls";
  static const String _advanced = "advanced";
  static const String _billing = "billing";

  // Sub-modes

  static const String _modeModifyAccount = "modifyAccount";
  static const String _modeChangeLLM = "changeLLM";
  static const String _modeMcpConfig = "mcpConfig";
  static const String _modeContextMemory = "contextMemory";
  static const String _modeChangeCompressionLLM = "changeCompressionLLM";

  static const int _defaultCompressionTrigger = 156000;

  String mode = _modeBase;

  late final TextEditingController _nameController;
  late final TextEditingController _mailController;
  late final TextEditingController _compressionTriggerController;
  late final TextEditingController _backendUrlController;

  String toastMessage = '';
  String toastDescription = '';

  // Customise section things
  final TextEditingController _customInstructions = TextEditingController();
  final TextEditingController _nickname = TextEditingController();
  final TextEditingController _occupation = TextEditingController();
  final TextEditingController _moreAboutYou = TextEditingController();

  bool _webSearch = true;
  bool _browser = true;
  bool _shellCommands = true;
  bool _complexReasoning = true;
  bool _computerUse = true;

  // Notifications
  bool _responses = true;
  bool _taskCompletion = true;
  bool _suggestions = true;
  bool _computerUseNotification = true;

  //Data controls
  bool _sendProductUsageAnalytics = true;
  bool _sendErrorUpdates = true;
  bool _useSystemWideMemory = true;

  bool _isLoading = true;
  Timer? _saveDebounce;

  void _debouncedSave() {
    _saveDebounce?.cancel();
    _saveDebounce = Timer(Duration(milliseconds: 500), _saveSettings);
  }

  @override
  void initState() {
    super.initState();
    final user = AuthenticationProvider().loggedInUser;
    _nameController = TextEditingController(text: user?.name ?? '');
    _mailController = TextEditingController(text: user?.email ?? '');
    _compressionTriggerController = TextEditingController(text: '$_defaultCompressionTrigger');
    _backendUrlController = TextEditingController(text: DataConstants.url);
    _loadSettings();
    _customInstructions.addListener(_debouncedSave);
    _nickname.addListener(_debouncedSave);
    _occupation.addListener(_debouncedSave);
    _moreAboutYou.addListener(_debouncedSave);
    _backendUrlController.addListener(_debouncedSave);
    _nameController.addListener(_debouncedSave);
    _mailController.addListener(_debouncedSave);
  }

  Future<void> _loadSettings() async {
    final user = AuthenticationProvider().loggedInUser;
    if (user == null || user.email == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    final key = 'settings_${user.email}';
    final settings = DataConstants.settingsBox?.get(key);

    if (settings != null && settings is Map) {
      if (settings['customise'] != null) {
        final cust = settings['customise'];
        _customInstructions.text = cust['custom_instructions'] ?? '';
        _nickname.text = cust['nickname'] ?? '';
        _occupation.text = cust['occupation'] ?? '';
        _moreAboutYou.text = cust['more_about_you'] ?? '';
        _webSearch = cust['web_search'] ?? true;
        _browser = cust['browser'] ?? true;
        _shellCommands = cust['shell_commands'] ?? true;
        _complexReasoning = cust['complex_reasoning'] ?? true;
        _computerUse = cust['computer_use'] ?? true;
      }

      if (settings['notifications'] != null) {
        final notif = settings['notifications'];
        _responses = notif['responses'] ?? true;
        _taskCompletion = notif['task_completion'] ?? true;
        _suggestions = notif['suggestions'] ?? true;
        _computerUseNotification = notif['computer_use_notification'] ?? true;
      }

      if (settings['data_controls'] != null) {
        final data = settings['data_controls'];
        _sendProductUsageAnalytics =
            data['send_product_usage_analytics'] ?? true;
        _sendErrorUpdates = data['send_error_updates'] ?? true;
        _useSystemWideMemory = data['use_system_wide_memory'] ?? true;
      }

      if (settings['advanced'] != null) {
        final adv = settings['advanced'];
        _backendUrlController.text = adv['backend_url'] ?? DataConstants.url;
      }

      // Load General Settings (Theme/Accent)
      if (settings['general'] != null) {
        final general = settings['general'];
        if (general['theme'] != null) {
          final themeMode = general['theme'] == 'Dark'
              ? ThemeMode.dark
              : ThemeMode.light;
          if (themeMode != DataConstants.currentTheme) {
            // We rely on DataConstants being correct or BaseApp handling it.
          }
        }
      }
    }

    setState(() {
      _isLoading = false;
    });
  }

  void _saveSettings() {
    if (_isLoading) return;
    final user = AuthenticationProvider().loggedInUser;
    if (user == null || user.email == null) return;

    final key = 'settings_${user.email}';

    // Get current theme/accent string
    final themeString = DataConstants.currentTheme == ThemeMode.dark
        ? 'Dark'
        : 'Light';
    final accentString = DataConstants.activeAccent['color'];

    final settings = {
      'general': {'theme': themeString, 'accent': accentString},
      'customise': {
        'custom_instructions': _customInstructions.text,
        'nickname': _nickname.text,
        'occupation': _occupation.text,
        'more_about_you': _moreAboutYou.text,
        'web_search': _webSearch,
        'browser': _browser,
        'shell_commands': _shellCommands,
        'complex_reasoning': _complexReasoning,
        'computer_use': _computerUse,
      },
      'notifications': {
        'responses': _responses,
        'task_completion': _taskCompletion,
        'suggestions': _suggestions,
        'computer_use_notification': _computerUseNotification,
      },
      'data_controls': {
        'send_product_usage_analytics': _sendProductUsageAnalytics,
        'send_error_updates': _sendErrorUpdates,
        'use_system_wide_memory': _useSystemWideMemory,
      },
      'advanced': {'backend_url': _backendUrlController.text},
    };

    DataConstants.settingsBox?.put(key, settings);
  }

  void _navigateTo(String newMode, String title,
      {String? backMode, String? backTitle}) {
    setState(() => mode = newMode);
    if (Toolkit.isMobile(context)) {
      if (newMode == _modeBase) {
        RootShell.updateAppbar(
            const ValueKey('main'), "Settings", LucideIcons.cog);
        RootShell.setCustomLeading(const ValueKey('main'), null);
      } else {
        RootShell.updateAppbar(const ValueKey('main'), title, LucideIcons.cog);
        RootShell.setCustomLeading(
          const ValueKey('main'),
          IconButton.ghost(
            density: ButtonDensity.iconDense,
            icon: Icon(LucideIcons.arrowLeft),
            onPressed: () => _navigateTo(
                backMode ?? _modeBase, backTitle ?? "Settings"),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    if (Toolkit.isMobile(context)) {
      RootShell.setCustomLeading(const ValueKey('main'), null);
    }
    _saveDebounce?.cancel();
    _customInstructions.removeListener(_debouncedSave);
    _nickname.removeListener(_debouncedSave);
    _occupation.removeListener(_debouncedSave);
    _moreAboutYou.removeListener(_debouncedSave);
    _backendUrlController.removeListener(_debouncedSave);
    _nameController.removeListener(_debouncedSave);
    _mailController.removeListener(_debouncedSave);
    _nameController.dispose();
    _mailController.dispose();
    _compressionTriggerController.dispose();
    _customInstructions.dispose();
    _nickname.dispose();
    _occupation.dispose();
    _moreAboutYou.dispose();
    _backendUrlController.dispose();
    super.dispose();
  }

  /// Shows a toast message.

  void _showToast(String title, String message, {bool useSetState = false}) {
    toastMessage = title;
    toastDescription = message;
    if (useSetState) {
      setState(() {});
    }
    showToast(
      context: context,
      builder: buildToast,
      location: ToastLocation.topCenter,
    );
  }

  Widget buildToast(BuildContext context, ToastOverlay overlay) {
    return SurfaceCard(
      child: Basic(
        title: Text(toastMessage),
        subtitle: Text(toastDescription),
        trailingAlignment: Alignment.center,
      ),
    );
  }

  Future<void> _updateUser() async {
    try {
      final user = AuthenticationProvider().loggedInUser;
      if (user?.id == null) throw Exception("User ID missing");

      await WorkSpace.updateUser(
        userName: _nameController.text,
        userEmail: _mailController.text,
        userId: user!.id!,
      );
      _showToast('Success', 'User details updated successfully.');
    } catch (e) {
      _showToast('Error', 'Failed to update user details.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (!constraints.hasBoundedWidth || constraints.maxWidth >= 500) {
          return _buildDesktopLayout();
        }
        return _buildMobileLayout();
      },
    );
  }

  // --- Mobile Layout Methods ---

  Widget _buildMobileLayout() {
    if (widget.notAsSidebar) {
      return _buildMobileContent();
    }
    return SideBarBase(child: _buildMobileContent());
  }

  Widget _buildMobileContent() {
    // If we are in a sub-mode that belongs to a category, we might want to keep it?

    // But for mobile, we treat categories as pages.

    Widget content;
    switch (mode) {
      case _modeBase:
        content = _mobileBase();
        break;
      case _general:
        content = _buildCategoryPage("General", _buildGeneralContent(), _modeBase);
        break;
      case _customise:
        content = _buildCategoryPage(
          "Customise",
          _buildCustomiseContent(),
          _modeBase,
        );
        break;
      case _account:
        content = _buildCategoryPage("Account", _buildAccountContent(), _modeBase);
        break;
      case _agent:
        content = _buildCategoryPage("Finetune", _buildAgentContent(), _modeBase);
        break;
      case _notifications:
        content = _buildCategoryPage(
          "Notifications",
          _buildNotificationsContent(),
          _modeBase,
        );
        break;
      case _dataControls:
        content = _buildCategoryPage(
          "Data Controls",
          _buildDataControlsContent(),
          _modeBase,
        );
        break;
      case _advanced:
        content = _buildCategoryPage(
          "Advanced",
          _buildAdvancedContent(),
          _modeBase,
        );
        break;
      case _modeModifyAccount:
        content = ModifyAccountForm(
          onGoBack: () => _navigateTo(_account, "Account"),
          nameController: _nameController,
          mailController: _mailController,
          onSave: _updateUser,
        );
        break;
      case _modeChangeLLM:
        content = LlmProviderForm(
          type: 'default',
          onGoBack: () => _navigateTo(_agent, "Finetune"),
          showToast: _showToast,
        );
        break;

      case _modeChangeCompressionLLM:
        content = LlmProviderForm(
          type: 'compression',
          onGoBack: () => _navigateTo(
              _modeContextMemory, "Context and Memory",
              backMode: _agent, backTitle: "Finetune"),
          showToast: _showToast,
        );
        break;

      case _modeMcpConfig:
        content = McpConfigView(
          onGoBack: () => _navigateTo(_agent, "Finetune"),
          showToast: _showToast,
        );
        break;

      case _modeContextMemory:
        content = ContextMemoryView(
          onGoBack: () => _navigateTo(_agent, "Finetune"),
          compressionTriggerController: _compressionTriggerController,
          showToast: _showToast,
          onShowCompressionModelForm: () => _navigateTo(
              _modeChangeCompressionLLM, "Compression LLM",
              backMode: _modeContextMemory, backTitle: "Context and Memory"),
        );
        break;

      case _billing:
        content = _buildBilling();
        break;

      default:
        content = _mobileBase();
    }

    return AnimatedSwitcher(
      duration: AnimationConstants.contentSwitch,
      switchInCurve: AnimationConstants.entranceCurve,
      switchOutCurve: AnimationConstants.exitCurve,
      transitionBuilder: (child, animation) {
        final slideAnimation = Tween<Offset>(
          begin: AnimationConstants.slideFromRight,
          end: Offset.zero,
        ).animate(animation);
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: slideAnimation,
            child: child,
          ),
        );
      },
      child: KeyedSubtree(
        key: ValueKey(mode),
        child: content,
      ),
    );
  }

  Widget _mobileBase() {
    final items = <Widget Function(int index)>[
      (i) => !widget.notAsSidebar && !Toolkit.isMobile(context)
          ? AnimatedListItem(
              index: i,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: SidebarHeader(
                        title: 'Settings',
                        onBack: widget.onBack,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Divider(),
                  ],
                ),
              ),
            )
          : const SizedBox(height: 0),
      (_) => const SizedBox(height: 16),
      (i) => AnimatedListItem(
        index: i,
        child: _settingsItem(
          LucideIcons.cog,
          "General",
          () => _navigateTo(_general, "General"),
        ),
      ),
      (i) => AnimatedListItem(
        index: i,
        child: _settingsItem(
          LucideIcons.settings2,
          "Customise",
          () => _navigateTo(_customise, "Customise"),
        ),
      ),
      (i) => AnimatedListItem(
        index: i,
        child: _settingsItem(
          LucideIcons.userRound,
          "Account",
          () => _navigateTo(_account, "Account"),
        ),
      ),
      (i) => AnimatedListItem(
        index: i,
        child: _settingsItem(
          LucideIcons.bell,
          "Notifications",
          () => _navigateTo(_notifications, "Notifications"),
        ),
      ),
      (i) => AnimatedListItem(
        index: i,
        child: _settingsItem(
          LucideIcons.database,
          "Data controls",
          () => _navigateTo(_dataControls, "Data controls"),
        ),
      ),
      (i) => AnimatedListItem(
        index: i,
        child: _settingsItem(
          LucideIcons.clock,
          "Scheduled Tasks",
          () {
            RootShell.updateAndRefresh(
              ValueKey('main'),
              ExpandedScheduleView(key: ValueKey(DateTime.now().millisecondsSinceEpoch)),
              "Scheduled Tasks",
              LucideIcons.clock,
            );
            closeOverlay(context);
          },
        ),
      ),
      (i) => AnimatedListItem(
        index: i,
        child: _settingsItem(
          LucideIcons.code,
          "Advanced",
          () => _navigateTo(_advanced, "Advanced"),
        ),
      ),
      (i) => AnimatedListItem(index: i, child: _buildProductInfo()),
    ];

    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, index) => items[index](index),
    );
  }

  Widget _buildCategoryPage(String title, Widget content, String backMode) {
    if (Toolkit.isMobile(context)) {
      return Column(
        children: [
          Divider(),
          Expanded(child: content),
        ],
      );
    }
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: SidebarHeader(
            title: title,
            onBack: () => setState(() => mode = backMode),
          ),
        ),
        Divider(),
        Expanded(child: content),
      ],
    );
  }

  // --- Desktop Layout Methods ---

  Widget _buildDesktopLayout() {
    // Default to 'general' category if in base mode or unknown

    return Row(
      children: [
        SizedBox(width: 175, child: _desktopBase()),
        VerticalDivider(),
        Expanded(child: _buildDesktopContent()),
      ],
    );
  }

  Widget _desktopBase() {
    int i = 0;
    return ListView(
      children: [
        if (!Toolkit.isMobile(context)) AnimatedListItem(
          index: i++,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6),
            child: Row(
              children: [
                IconButton.ghost(
                  icon: Icon(LucideIcons.x),
                  onPressed: () {
                    closeOverlay(context);
                  },
                ),
              ],
            ),
          ),
        ),

       const SizedBox(
          height: 8,
        ),
        AnimatedListItem(
          index: i++,
          child: _settingsItem(
            LucideIcons.cog,
            "General",
            () => setState(() => mode = _general),
            alternate: true,
            modeKey: _general,
          ),
        ),
        AnimatedListItem(
          index: i++,
          child: _settingsItem(
            LucideIcons.settings2,
            "Customise",
            () => setState(() => mode = _customise),
            alternate: true,
            modeKey: _customise,
          ),
        ),
        AnimatedListItem(
          index: i++,
          child: _settingsItem(
            LucideIcons.userRound,
            "Account",
            () => setState(() => mode = _account),
            alternate: true,
            modeKey: _account,
          ),
        ),
        AnimatedListItem(
          index: i++,
          child: _settingsItem(
            LucideIcons.bell,
            "Notifications",
            () => setState(() => mode = _notifications),
            alternate: true,
            modeKey: _notifications,
          ),
        ),
        AnimatedListItem(
          index: i++,
          child: _settingsItem(
            LucideIcons.database,
            "Data controls",
            () => setState(() => mode = _dataControls),
            alternate: true,
            modeKey: _dataControls,
          ),
        ),
        AnimatedListItem(
          index: i++,
          child: _settingsItem(
            LucideIcons.clock,
            "Scheduled Tasks",
            () {
              RootShell.updateAndRefresh(
                ValueKey('main'),
                ExpandedScheduleView(key: ValueKey(DateTime.now().millisecondsSinceEpoch)),
                "Scheduled Tasks",
                LucideIcons.clock,
              );
              closeOverlay(context);
            },
            alternate: true,
          ),
        ),
        AnimatedListItem(
          index: i++,
          child: _settingsItem(
            LucideIcons.code,
            "Advanced",
            () => setState(() => mode = _advanced),
            alternate: true,
            modeKey: _advanced,
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopContent() {
    Widget content;
    switch (mode) {
      case _general:
        content = _buildGeneralContent();
        break;
      case _customise:
        content = _buildCustomiseContent();
        break;
      case _account:
        content = _buildAccountContent();
        break;
      case _agent:
        content = _buildAgentContent();
        break;
      case _notifications:
        content = _buildNotificationsContent();
        break;
      case _dataControls:
        content = _buildDataControlsContent();
        break;
      case _advanced:
        content = _buildAdvancedContent();
        break;

      case _billing:
        content = _buildBilling();
        break;

      // Sub-modes in Desktop

      case _modeModifyAccount:
        content = ModifyAccountForm(
          onGoBack: () => setState(() => mode = _account),
          nameController: _nameController,
          mailController: _mailController,
          onSave: _updateUser,
        );
        break;

      case _modeChangeLLM:
        content = Column(
          children: [
            Expanded(
              child: LlmProviderForm(
                type: 'default',
                onGoBack: () => setState(() => mode = _agent),
                showToast: _showToast,
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: GhostButton(
                child: const Text('Manage LLM Providers'),
                onPressed: () {
                  RootShell.updateAndRefresh(
                    const ValueKey('main'),
                    ExpandedLlmView(
                      key: ValueKey(DateTime.now().millisecondsSinceEpoch),
                    ),
                    'Available LLMs',
                    LucideIcons.brain,
                  );
                },
              ),
            ),
          ],
        );
        break;

      case _modeChangeCompressionLLM:
        content = LlmProviderForm(
          type: 'compression',
          onGoBack: () => setState(() => mode = _modeContextMemory),
          showToast: _showToast,
        );
        break;

      case _modeMcpConfig:
        content = McpConfigView(
          onGoBack: () => setState(() => mode = _agent),
          showToast: _showToast,
        );
        break;

      case _modeContextMemory:
        content = ContextMemoryView(
          onGoBack: () => setState(() => mode = _agent),
          compressionTriggerController: _compressionTriggerController,
          showToast: _showToast,
          onShowCompressionModelForm: () =>
              setState(() => mode = _modeChangeCompressionLLM),
        );
        break;

      default:
        content = _buildGeneralContent();
    }

    return AnimatedSwitcher(
      duration: AnimationConstants.contentSwitch,
      switchInCurve: AnimationConstants.entranceCurve,
      switchOutCurve: AnimationConstants.exitCurve,
      transitionBuilder: (child, animation) {
        final slideAnimation = Tween<Offset>(
          begin: AnimationConstants.slideFromRight,
          end: Offset.zero,
        ).animate(animation);
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: slideAnimation,
            child: child,
          ),
        );
      },
      child: KeyedSubtree(
        key: ValueKey(mode),
        child: content,
      ),
    );
  }

  // --- Category Content Builders ---

  Widget _buildGeneralContent() {
    int i = 0;
    return ListView(
      children: [
        AnimatedListItem(index: i++, child: customHeader(context, 'General', LucideIcons.info)),
        AnimatedListItem(
          index: i++,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Column(children: [_themeSwitcher(), Divider()]),
          ),
        ),
        AnimatedListItem(
          index: i++,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Column(children: [_accentSwitcher(), Divider()]),
          ),
        ),
        AnimatedListItem(index: i++, child: _settingsItem(LucideIcons.shieldQuestion, "Privacy policy", () {})),
        AnimatedListItem(index: i++, child: _settingsItem(LucideIcons.handshake, "Terms and Conditions", () {})),
        AnimatedListItem(index: i++, child: _buildProductInfo()),
      ],
    );
  }

  Widget _buildCustomiseContent() {
    final colors = Theme.of(context).colorScheme;
    final labelStyle = TextStyle(color: colors.accentForeground);
    int i = 0;
    return ListView(
      children: [
        AnimatedListItem(index: i++, child: customHeader(context, 'Customise', LucideIcons.triangleAlert)),
        AnimatedListItem(
          index: i++,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text("Custom instructions", style: labelStyle).small,
              ),
              SettingsTextField(
                icon: LucideIcons.user,
                controller: _customInstructions,
                label: "Additional behaviour, style and tonal preferences",
              ),
            ],
          ),
        ),
        AnimatedListItem(
          index: i++,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Gap(16),
              SidebarSubHeader(icon: LucideIcons.appWindow, title: "About you"),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text("Nickname", style: labelStyle).small,
              ),
              SettingsTextField(
                icon: LucideIcons.lightbulb,
                controller: _nickname,
                label: "What should agent call you?",
              ),
            ],
          ),
        ),
        AnimatedListItem(
          index: i++,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Gap(16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text("Occupation", style: labelStyle).small,
              ),
              SettingsTextField(
                icon: LucideIcons.briefcase,
                controller: _occupation,
                label: "Researcher",
              ),
            ],
          ),
        ),
        AnimatedListItem(
          index: i++,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Gap(16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text("More about you", style: labelStyle).small,
              ),
              SettingsTextField(
                icon: LucideIcons.info,
                controller: _moreAboutYou,
                label: "Interests, values and preferences to keep in mind",
              ),
            ],
          ),
        ),
        AnimatedListItem(
          index: i++,
          child: Column(
            children: [
              Gap(16),
              SidebarSubHeader(icon: LucideIcons.appWindow, title: "Tools"),
            ],
          ),
        ),
        AnimatedListItem(
          index: i++,
          child: _settingsSwitch(
            "Web search",
            _webSearch,
            (value) {
              setState(() {
                _webSearch = value;
                _saveSettings();
              });
            },
            description: "Let agent use Google search when required",
          ),
        ),
        AnimatedListItem(
          index: i++,
          child: _settingsSwitch(
            "Browser",
            _browser,
            (value) {
              setState(() {
                _browser = value;
                _saveSettings();
              });
            },
            description:
                "Agent will use a headless browser to interact with websites",
          ),
        ),
        AnimatedListItem(
          index: i++,
          child: _settingsSwitch(
            "Shell commands",
            _shellCommands,
            (value) {
              setState(() {
                _shellCommands = value;
                _saveSettings();
              });
            },
            description:
                "Agent will use shell commands to do terminal based tasks",
          ),
        ),
        AnimatedListItem(
          index: i++,
          child: _settingsSwitch(
            "Complex reasoning",
            _complexReasoning,
            (value) {
              setState(() {
                _complexReasoning = value;
                _saveSettings();
              });
            },
            description:
                "Agent will ask another agent with a better reasoning LLM you have configured for solving complex tasks",
          ),
        ),
        AnimatedListItem(
          index: i++,
          child: Column(
            children: [
              Gap(16),
              SidebarSubHeader(
                icon: BootstrapIcons.ladder,
                title: "Models and tools",
              ),
            ],
          ),
        ),
        AnimatedListItem(
          index: i++,
          child: _settingsItem(LucideIcons.shieldPlus, "Add / Modify MCP servers", () {
            RootShell.updateAndRefresh(
              const ValueKey('main'),
              ExpandedMcpView(
                key: ValueKey(DateTime.now().millisecondsSinceEpoch),
              ),
              'Add / Modify MCP servers',
              LucideIcons.wrench,
            );
            closeOverlay(context);
          }),
        ),
        AnimatedListItem(
          index: i++,
          child: _settingsItem(
            LucideIcons.shieldPlus,
            "Add / Modify LLMs for your agent",
                () {
              RootShell.updateAndRefresh(
                const ValueKey('main'),
                ExpandedLlmView(
                  key: ValueKey(DateTime.now().millisecondsSinceEpoch),
                ),

                'Available LLMs',
                LucideIcons.brain,
              );
              closeOverlay(context);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAccountContent() {
    int i = 0;
    return ListView(
      children: [
        AnimatedListItem(index: i++, child: customHeader(context, 'Account', LucideIcons.info)),
        AnimatedListItem(
          index: i++,
          child: SidebarSubHeader(
            icon: LucideIcons.appWindow,
            title: "Update user information",
          ),
        ),
        AnimatedListItem(
          index: i++,
          child: Column(
            children: [
              SizedBox(height: 16),
              _userHeader(),
            ],
          ),
        ),
        AnimatedListItem(
          index: i++,
          child: Column(
            children: [
              SizedBox(height: 32),
              SidebarSubHeader(icon: LucideIcons.appWindow, title: "Account actions"),
            ],
          ),
        ),
        AnimatedListItem(index: i++, child: _settingsItem(LucideIcons.shieldPlus, "Reset password", () {})),
        AnimatedListItem(
          index: i++,
          child: _settingsItem(LucideIcons.bug, 'Subscription and usage', () {
            RootShell.updateAndRefresh(
              ValueKey('main'),
              BillingScreen(),
              "Subscription and usage",
              LucideIcons.info,
            );
            closeOverlay(context);
          }),
        ),
        AnimatedListItem(
          index: i++,
          child: Column(
            children: [
              SizedBox(height: 16),
              _buildLogOut(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAgentContent() {
    int i = 0;
    return ListView(
      children: [
        AnimatedListItem(index: i++, child: customHeader(context, 'Configuration', LucideIcons.bot)),
        AnimatedListItem(index: i++, child: SizedBox(height: 16)),

      ],
    );
  }

  Widget _buildNotificationsContent() {
    int i = 0;
    return ListView(
      children: [
        AnimatedListItem(index: i++, child: customHeader(context, 'Notifications', LucideIcons.triangleAlert)),
        AnimatedListItem(
          index: i++,
          child: _settingsSwitch(
            "Responses ",
            _responses,
            (value) {
              setState(() {
                _responses = value;
                _saveSettings();
              });
            },
            description:
                "Midsphere Studio will notify you when you receive any new updates from agent ",
          ),
        ),
        AnimatedListItem(
          index: i++,
          child: _settingsSwitch(
            "Task completion ",
            _taskCompletion,
            (value) {
              setState(() {
                _taskCompletion = value;
                _saveSettings();
              });
            },
            description:
                "Midsphere Studio will notify you when your task is completed",
          ),
        ),
        AnimatedListItem(
          index: i++,
          child: _settingsSwitch(
            "Suggestions ",
            _suggestions,
            (value) {
              setState(() {
                _suggestions = value;
                _saveSettings();
              });
            },
            description:
                "Midsphere Studio will notify you when agent wants to use your computer",
          ),
        ),
        AnimatedListItem(
          index: i++,
          child: _settingsSwitch(
            "Computer use",
            _computerUseNotification,
            (value) {
              setState(() {
                _computerUseNotification = value;
                _saveSettings();
              });
            },
            description:
                "Midsphere Studio will notify you when agent wants your suggestions to complete the task",
          ),
        ),
      ],
    );
  }

  Widget _buildDataControlsContent() {
    int i = 0;
    return ListView(
      children: [
        AnimatedListItem(index: i++, child: customHeader(context, 'Data controls', LucideIcons.triangleAlert)),
        AnimatedListItem(
          index: i++,
          child: _settingsSwitch(
            "Send product usage analytics ",
            _sendProductUsageAnalytics,
            (value) {
              setState(() {
                _sendProductUsageAnalytics = value;
                _saveSettings();
              });
            },
            description:
                "None of the information about you will be collected expect how you use the platform so that we can improve your experience",
          ),
        ),
        AnimatedListItem(
          index: i++,
          child: _settingsSwitch(
            "Send error updates back to Midsphere",
            _sendErrorUpdates,
            (value) {
              setState(() {
                _sendErrorUpdates = value;
                _saveSettings();
              });
            },
            description:
                "Midsphere will send back any errors happening on backend and studio app to our sentry servers to fix your issues.",
          ),
        ),
        AnimatedListItem(
          index: i++,
          child: _settingsSwitch(
            "Use system wide memory for all chats",
            _useSystemWideMemory,
            (value) {
              setState(() {
                _useSystemWideMemory = value;
                _saveSettings();
              });
            },
            description:
                "Agent will remember important things about you and will refer to it when needed",
          ),
        ),
        AnimatedListItem(
          index: i++,
          child: Column(
            children: [
              SizedBox(height: 16),
              SidebarSubHeader(icon: LucideIcons.appWindow, title: "Danger zone"),
            ],
          ),
        ),
        AnimatedListItem(
          index: i++,
          child: _settingsItem(LucideIcons.grid2x2, "Remove all addons", () {
            DialogConfirmText(
              title: "Are you absolutely sure?",
              description:
                  "This action cannot be undone. This will permanently delete all your chats.",
              verificationText: 'delete',
              onConfirm: () async {
                try {
                  await Memory.deleteAllChats();

                  _showToast('Success', 'All chats deleted successfully.');
                } catch (e) {
                  _showToast('Error', 'Failed to delete chats.');
                }
              },
            ).open(context);
          }),
        ),
        AnimatedListItem(
          index: i++,
          child: _settingsItem(LucideIcons.delete, "Delete all chats", () {
            DialogConfirmText(
              title: "Are you absolutely sure?",
              description:
                  "This action cannot be undone. This will permanently delete all your chats.",
              verificationText: 'delete',
              onConfirm: () async {
                try {
                  await Memory.deleteAllChats();

                  _showToast('Success', 'All chats deleted successfully.');
                } catch (e) {
                  _showToast('Error', 'Failed to delete chats.');
                }
              },
            ).open(context);
          }),
        ),
      ],
    );
  }

  Widget _buildBilling() {
    int i = 0;
    return ListView(
      children: [
        AnimatedListItem(index: i++, child: customHeader(context, 'Subscriptions', LucideIcons.triangleAlert)),
        AnimatedListItem(
          index: i++,
          child: Column(
            children: [
              Gap(8),
              _buildBillingsHeader(),
            ],
          ),
        ),
        AnimatedListItem(index: i++, child: SidebarSubHeader(icon: LucideIcons.arrowRight, title: "Manage")),
        AnimatedListItem(
          index: i++,
          child: _settingsItem(LucideIcons.bug, 'Upgrade subscription', () {
            RootShell.updateAndRefresh(
              ValueKey('main'),
              BillingScreen(),
              "Billing",
              LucideIcons.info,
            );
            closeOverlay(context);
          }),
        ),
        AnimatedListItem(
          index: i++,
          child: _settingsItem(LucideIcons.bug, 'Cancel subscription', () {
            RootShell.updateAndRefresh(
              ValueKey('main'),
              BillingScreen(),
              "Billing",
              LucideIcons.info,
            );
            closeOverlay(context);
          }),
        ),
        AnimatedListItem(
          index: i++,
          child: _settingsItem(LucideIcons.bug, 'View previous transactions', () {
            RootShell.updateAndRefresh(
              ValueKey('main'),
              BillingScreen(),
              "Billing",
              LucideIcons.info,
            );
            closeOverlay(context);
          }),
        ),
      ],
    );
  }

  Widget _buildAdvancedContent() {
    final colors = Theme.of(context).colorScheme;
    final labelStyle = TextStyle(color: colors.accentForeground);
    int i = 0;
    return ListView(
      children: [
        AnimatedListItem(index: i++, child: customHeader(context, 'Advanced controls', LucideIcons.triangleAlert)),
        AnimatedListItem(
          index: i++,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text("Backend URL", style: labelStyle).small,
              ),
              SettingsTextField(
                icon: LucideIcons.user,
                label: "Backend URL",
                controller: _backendUrlController,
              ),
            ],
          ),
        ),
        AnimatedListItem(
          index: i++,
          child: Column(
            children: [
              Gap(16),
              _settingsItem(LucideIcons.bug, 'Test API endpoints', () {
                RootShell.updateAndRefresh(
                  ValueKey('main'),
                  ApiTestPage(),
                  "Test API endpoints",
                  LucideIcons.info,
                );
                closeOverlay(context);
              }),
            ],
          ),
        ),
        AnimatedListItem(
          index: i++,
          child: _settingsItem(LucideIcons.bug, 'Billing', () {
            RootShell.updateAndRefresh(
              ValueKey('main'),
              BillingScreen(),
              "Billing",
              LucideIcons.info,
            );
            closeOverlay(context);
          }),
        ),
      ],
    );
  }

  // --- Shared Widgets ---

  Widget _buildProductInfo() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Midsphere AI - V${DataConstants.version}").small.muted,
          Text("Build type: ${DataConstants.build}").muted.small,
        ],
      ),
    );
  }

  Widget _buildLogOut() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),

      child: DestructiveButton(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,

          children: [Text("Logout now")],
        ),

        onPressed: () async {
          String message = await WorkSpace.logout();
          if (!mounted) return;

          if (message == 'success') {
            showToast(
              context: RootShell.context(ValueKey('main')),

              builder: logoutToastBuilder,
            );

            BaseApp.router(ValueKey('mainKey')).pushReplacement('/');
          }
        },
      ),
    );
  }

  Widget logoutToastBuilder(BuildContext context, ToastOverlay overlay) {
    return SurfaceCard(
      child: Basic(
        title: Text("Logout successful"),
        subtitle: Text("We will be waiting for you"),
        trailingAlignment: Alignment.center,
      ),
    );
  }

  Widget _themeSwitcher() {
    final availableThemes = ["Dark", "Light"];
    return ListTile(
      title: Text(
        "Appearance",
        style: TextStyle(color: Theme.of(context).colorScheme.primary),
      ),
      trailing: Select<String>(
        itemBuilder: (context, item) {
          return Text(item);
        },
        popup: SelectPopup(
          items: SelectItemList(
            children: availableThemes
                .map((e) => SelectItemButton(value: e, child: Text(e)))
                .toList(),
          ),
        ).call,
        onChanged: (value) {
          if (value == "Light") {
            BaseApp.changeTheme(ValueKey("mainKey"), ThemeMode.light);
          }

          if (value == "Dark") {
            BaseApp.changeTheme(ValueKey("mainKey"), ThemeMode.dark);
          }
          Future.delayed(Duration.zero, () {
            _saveSettings();
          });
        },
        constraints: const BoxConstraints(minWidth: 200),
        value: DataConstants.currentTheme == ThemeMode.dark ? "Dark" : "Light",
        placeholder: const Text('Select a theme'),
      ),
    );
  }

  Widget _accentSwitcher() {
    return ListTile(
      title: Text(
        "Accent",
        style: TextStyle(color: Theme.of(context).colorScheme.primary),
      ),
      trailing: Select<Map<String, dynamic>>(
        // Explicitly type the Select widget if possible
        value: DataConstants.activeAccent,
        constraints: const BoxConstraints(minWidth: 200),
        placeholder: const Text('Select a theme'),
        itemBuilder: (context, item) {
          return Text(item['color']);
        },
        popup: SelectPopup(
          items: SelectItemList(
            children: DataConstants.availableAccents
                .map((e) => SelectItemButton(value: e, child: Text(e['color'])))
                .toList(),
          ),
        ).call,
        onChanged: (value) {
          if (value != null) {
            BaseApp.changeAccent(const ValueKey("mainKey"), value);
            Future.delayed(Duration.zero, () {
              _saveSettings();
            });
          }
        },
      ),
    );
  }

  Widget _userHeader() {
    final user = AuthenticationProvider().loggedInUser;
    final name = user?.name?.trim();
    final userName = (name != null && name.isNotEmpty) ? name : "Default Account";

    final colors = Theme.of(context).colorScheme;

    return ModifyAccountForm(
      nameController: _nameController,
      mailController: _mailController,
      onSave: _updateUser,
    );
  }

  Widget _settingsSwitch(
    String label,
    bool condition,
    ValueChanged<bool>? onChanged, {
    String? description,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        spacing: 8,
        children: [
          SizedBox.shrink(),
          ListTile(
            title: Text(
              label,
              style: TextStyle(
                color: Theme.of(context).colorScheme.accentForeground,
              ),
            ).bold,
            subtitleText: description,
            trailing: Switch(value: condition, onChanged: onChanged),
          ),
          Divider(),
        ],
      ),
    );
  }

  Widget _settingsItem(
    IconData icon,
    String label,
    VoidCallback onTap, {
    bool alternate = false,
    String? modeKey,
  }) {
    final isSelected = modeKey != null && mode == modeKey;

    Widget child = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: AnimatedContainer(
        duration: AnimationConstants.pressHover,
        curve: AnimationConstants.pressHoverCurve,
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.accent.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: Theme.of(context).borderRadiusMd,
        ),
        child: GhostButton(
          onPressed: onTap,
          leading: Icon(
            icon,
            color: isSelected
                ? Theme.of(context).colorScheme.accent
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: isSelected
                      ? Theme.of(context).colorScheme.accent
                      : null,
                  fontWeight: isSelected ? FontWeight.w600 : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (alternate) {
      return child;
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        spacing: 8,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox.shrink(),
          GhostButton(
            onPressed: onTap,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
          Divider(),
        ],
      ),
    );
  }

  Widget customHeader(BuildContext context, String label, IconData icon) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 10, 4),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              color: Theme.of(context).colorScheme.accentForeground,
            ),
          ).h4,
        ],
      ),
    );
  }

  Widget _buildBillingsHeader() {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(borderRadius: Theme.of(context).borderRadiusMd,),
      child: Stack(
        children: [
          Container(
            height: 200,
            decoration: BoxDecoration(
              borderRadius: Theme.of(context).borderRadiusMd,
              image: DecorationImage(
                image: NetworkImage(
                  'https://images.unsplash.com/photo-1523821741446-edb2b68bb7a0',
                ),
                fit: BoxFit.cover, // optional but usually needed
              ),
            ),
          ).withOpacity(0.9),
          Container(
            height: 200,
            padding: EdgeInsets.all(16),

            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "You are using",
                  style: TextStyle(color: Colors.white),
                ).muted,
                Row(
                  spacing: 4,
                  children: [
                    Text("Midsphere", style: TextStyle(color: Colors.white)).h3,
                    Text("Pro", style: TextStyle(color: Colors.amber)).h3,
                  ],
                ),
                Gap(16),
                Text("Pro user since today"),
                Row(
                  spacing: 8,
                  children: [
                    Text("Started on 17 december, 2025").muted.xSmall,
                    Container(
                      height: 30,
                      width: 1,
                      color: Theme.of(context).colorScheme.border,
                    ),
                    Text("Ends on 17 January, 2025").muted.xSmall,
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A form for modifying the user's account details.
class ModifyAccountForm extends StatelessWidget {
  /// A callback function that is called when the user taps the "Go back" button.
  final VoidCallback? onGoBack;
  final TextEditingController nameController;
  final TextEditingController mailController;
  final VoidCallback onSave;

  /// Creates a new [ModifyAccountForm] widget.
  ///
  /// The [onGoBack] parameter is required.
  const ModifyAccountForm({
    super.key,
    this.onGoBack,
    required this.nameController,
    required this.mailController,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      shrinkWrap: true,
      children: [
        if (onGoBack != null && !Toolkit.isMobile(context))
          Padding(
            padding: const EdgeInsets.all(7.0),
            child: SidebarHeader(
              title: 'Change account details',
              onBack: onGoBack,
            ),
          ),
        if (onGoBack != null) Divider(),
        if (onGoBack != null) SizedBox(height: 16),
        SettingsTextField(
          icon: LucideIcons.user,
          label: "Name",
          controller: nameController,
        ),
        SettingsTextField(
          icon: LucideIcons.mail,
          label: "Mail",
          controller: mailController,
        ),
        SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              SecondaryButton(
                onPressed: onSave,
                child: Text("Update information").bold,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
