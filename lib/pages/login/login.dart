import 'package:arcane/arcane.dart' hide EmailValidator;
import 'package:arcane/generated/arcane_shadcn/src/components/overlay/toast.dart';
import 'package:email_validator/email_validator.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_client/logics/data/helpers/general_utils.dart';
import 'package:flutter_client/logics/domain/blocs/login/login_bloc.dart';
import 'package:flutter_client/logics/domain/usecases/workspace/workspace_usecase.dart';
import 'package:flutter_client/widgets/headers/logo.dart';
import 'package:flutter_client/widgets/animations/animations.dart';
import 'package:go_router/go_router.dart';

import 'dart:async';

import '../../main.dart';
import '../../logics/services/google_auth/google_auth.dart';

/// A widget that displays a login and registration form with artistic animations.
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  // Mode controls: `base`, `login`, `register`
  bool isLoading = false;
  String mode = "base";

  // Animation controllers
  late AnimationController _modeAnimationController;
  late AnimationController _exitAnimationController;

  // Animations
  late Animation<double> _fadeAnimation;
  late Animation<double> _exitFadeAnimation;

  // Toast state
  String toastMessage = "Login successful";
  String toastDescription = "";

  // Form controllers
  TextEditingController username = TextEditingController();
  TextEditingController email = TextEditingController();
  TextEditingController password = TextEditingController();
  TextEditingController confirmPassword = TextEditingController();

  // Google Sign-In state
  StreamSubscription<AuthenticationEvent>? _authSubscription;

  final loginBloc = LoginBloc();

  // Track if headline typewriter has played
  bool _hasPlayedTypewriter = false;

  // Reduced motion check
  bool _prefersReducedMotion = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeGoogleAuth();
  }

  void _initializeAnimations() {
    // Mode entrance animation
    _modeAnimationController = AnimationController(
      duration: AnimationConstants.modeTransition,
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _modeAnimationController,
      curve: AnimationConstants.smoothEntrance,
    );

    // Exit animation
    _exitAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _exitFadeAnimation = CurvedAnimation(
      parent: _exitAnimationController,
      curve: AnimationConstants.smoothExit,
    );

    // Start with animation completed for initial state
    _modeAnimationController.value = 1.0;
    _exitAnimationController.value = 1.0;
  }

  void _initializeGoogleAuth() {
    if (kIsWeb) {
      _authSubscription = platform.authenticationEvents?.listen((AuthenticationEvent authEvent) async {
        switch (authEvent) {
          case AuthenticationEventSignIn():
            try {
              await WorkSpace.loginViaGoogle(authEvent.authenticationTokens.idToken);
              if (mounted) {
                _handleSignInSuccess(context);
              }
            } catch (e) {
              debugPrint("Google Login Error: $e");
              if (mounted) {
                _showToast("Login Failed", "Failed to login via Google: $e");
              }
            }
            break;
          case AuthenticationEventSignOut():
          case AuthenticationEventException():
            break;
        }
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _prefersReducedMotion = MediaQuery.of(context).disableAnimations;
  }

  @override
  void dispose() {
    _modeAnimationController.dispose();
    _exitAnimationController.dispose();
    _authSubscription?.cancel();
    email.dispose();
    password.dispose();
    username.dispose();
    confirmPassword.dispose();
    super.dispose();
  }

  /// Choreographed mode switch with exit/enter animations
  void _switchMode(String newMode) {
    if (mode == newMode) return;

    // Exit animation then enter
    _exitAnimationController.reverse().then((_) {
      if (mounted) {
        setState(() {
          mode = newMode;
        });
        _modeAnimationController.forward(from: 0.0);
        _exitAnimationController.forward();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<LoginBloc, LoginState>(
      bloc: loginBloc,
      listener: _handleLoginState,
      builder: (context, state) {
        if (state is LoadingStart) {
          return const Center(child: CircularProgressIndicator(size: 54));
        }

        final isDesktop = !Toolkit.isMobile(context);
        final screenWidth = MediaQuery.of(context).size.width;
        final usesSplitLayout = isDesktop && screenWidth > 900;

        return Scaffold(
          child: usesSplitLayout
              ? _buildDesktopSplitLayout()
              : _buildCenteredLayout(),
        );
      },
    );
  }

  /// Desktop split layout: login on left, art on right
  Widget _buildDesktopSplitLayout() {
    return Row(
      children: [
        // Left side: Login form
        Expanded(
          flex: 5,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: _buildLoginContent(),
              ),
            ),
          ),
        ),

        // Right side: Artistic display
        Expanded(
          flex: 6,
          child: _buildArtisticPanel(),
        ),
      ],
    );
  }

  /// Centered layout for mobile/tablet
  Widget _buildCenteredLayout() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Toolkit.isMobile(context)
              ? _buildLoginContent()
              : GlassCard(
                  blur: 16,
                  opacity: 0.06,
                  glowIntensity: 0.2,
                  animateGlow: !_prefersReducedMotion,
                  padding: const EdgeInsets.all(32),
                  child: _buildLoginContent(),
                ),
        ),
      ),
    );
  }

  /// The artistic panel - minimal, Claude/Zen style
  Widget _buildArtisticPanel() {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  colorScheme.primary.withValues(alpha: 0.08),
                  colorScheme.secondary.withValues(alpha: 0.04),
                ]
              : [
                  colorScheme.primary.withValues(alpha: 0.05),
                  colorScheme.secondary.withValues(alpha: 0.02),
                ],
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(64),
          child: Text(
            "Think deeper.\nBuild faster.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 56,
              fontWeight: FontWeight.w300,
              height: 1.3,
              color: colorScheme.foreground.withValues(alpha: 0.6),
              letterSpacing: -1,
            ),
          ),
        ),
      ),
    );
  }

  /// Builds the login content based on current mode
  Widget _buildLoginContent() {
    Widget content;
    if (mode == "login") {
      content = _buildEmailLogin();
    } else if (mode == "register") {
      content = _buildEmailRegistration();
    } else {
      content = _buildBaseMode();
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: FadeTransition(
        opacity: _exitFadeAnimation,
        child: content,
      ),
    );
  }

  /// Base mode with continue options
  Widget _buildBaseMode() {
    int itemIndex = 0;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Logo with hover glow (desktop only)
        AnimatedListItem(
          index: itemIndex++,
          staggerDelay: AnimationConstants.fieldStagger,
          animate: !_prefersReducedMotion,
          child: _buildAnimatedLogo(),
        ),
        const Gap(12),

        // Headline
        AnimatedListItem(
          index: itemIndex++,
          staggerDelay: AnimationConstants.fieldStagger,
          slideOffset: const Offset(0, -0.1),
          curve: AnimationConstants.bounceEntrance,
          animate: !_prefersReducedMotion,
          child: _prefersReducedMotion || _hasPlayedTypewriter
              ? Text("Welcome back").x3Large
              : TypewriterText(
                  text: "Welcome back",
                  style: Theme.of(context).typography.x3Large,
                  characterDelay: const Duration(milliseconds: 60),
                  onComplete: () {
                    _hasPlayedTypewriter = true;
                  },
                ),
        ),
        const Gap(8),

        AnimatedListItem(
          index: itemIndex++,
          staggerDelay: AnimationConstants.fieldStagger,
          animate: !_prefersReducedMotion,
          child: Text("Sign in to continue to Midsphere").muted,
        ),
        const Gap(32),

        if (kIsWeb) ...[
          AnimatedListItem(
            index: itemIndex++,
            staggerDelay: AnimationConstants.fieldStagger,
            animate: !_prefersReducedMotion,
            child: Column(
              children: _buildThirdPartyLogins(),
            ),
          ),
          AnimatedListItem(
            index: itemIndex++,
            staggerDelay: AnimationConstants.fieldStagger,
            animate: !_prefersReducedMotion,
            child: Column(
              children: [
                const Gap(16),
                Divider(child: Text("Or continue with").muted().small),
                const Gap(16),
              ],
            ),
          ),
        ],

        AnimatedListItem(
          index: itemIndex++,
          staggerDelay: AnimationConstants.fieldStagger,
          curve: AnimationConstants.bounceEntrance,
          animate: !_prefersReducedMotion,
          child: SizedBox(
            width: double.infinity,
            child: AnimatedPrimaryButton(
              onPressed: () => _switchMode("login"),
              enableHoverScale: !_prefersReducedMotion,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(LucideIcons.mail, size: 18),
                  const Gap(8),
                  Text("Continue with email"),
                ],
              ),
            ),
          ),
        ),
        const Gap(16),

        AnimatedListItem(
          index: itemIndex++,
          staggerDelay: AnimationConstants.fieldStagger,
          animate: !_prefersReducedMotion,
          child: _buildFooter(),
        ),
      ],
    );
  }

  /// Email login form
  Widget _buildEmailLogin() {
    int itemIndex = 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AnimatedListItem(
          index: itemIndex++,
          staggerDelay: AnimationConstants.fieldStagger,
          animate: !_prefersReducedMotion,
          child: _buildAnimatedLogo(),
        ),
        const Gap(12),

        AnimatedListItem(
          index: itemIndex++,
          staggerDelay: AnimationConstants.fieldStagger,
          slideOffset: const Offset(0, -0.1),
          curve: AnimationConstants.bounceEntrance,
          animate: !_prefersReducedMotion,
          child: Text("Sign in").x3Large,
        ),
        const Gap(8),

        AnimatedListItem(
          index: itemIndex++,
          staggerDelay: AnimationConstants.fieldStagger,
          animate: !_prefersReducedMotion,
          child: Text("Enter your credentials to continue").muted,
        ),
        const Gap(32),

        if (kIsWeb) ...[
          AnimatedListItem(
            index: itemIndex++,
            staggerDelay: AnimationConstants.fieldStagger,
            animate: !_prefersReducedMotion,
            child: Column(children: _buildThirdPartyLogins()),
          ),
          AnimatedListItem(
            index: itemIndex++,
            staggerDelay: AnimationConstants.fieldStagger,
            animate: !_prefersReducedMotion,
            child: Column(
              children: [
                const Gap(16),
                Divider(child: Text("Or").muted().small),
                const Gap(16),
              ],
            ),
          ),
        ],

        AnimatedListItem(
          index: itemIndex++,
          staggerDelay: AnimationConstants.fieldStagger,
          slideOffset: const Offset(0.05, 0),
          animate: !_prefersReducedMotion,
          child: TextField(
            controller: email,
            placeholder: Text("Email address"),
            features: [InputFeature.leading(Icon(LucideIcons.mail))],
          ),
        ),
        const Gap(12),

        AnimatedListItem(
          index: itemIndex++,
          staggerDelay: AnimationConstants.fieldStagger,
          slideOffset: const Offset(0.05, 0),
          animate: !_prefersReducedMotion,
          child: TextField(
            controller: password,
            placeholder: Text("Password"),
            features: [
              InputFeature.leading(Icon(LucideIcons.key)),
              InputFeature.passwordToggle(mode: PasswordPeekMode.hold),
            ],
          ),
        ),
        const Gap(24),

        AnimatedListItem(
          index: itemIndex++,
          staggerDelay: AnimationConstants.fieldStagger,
          curve: AnimationConstants.bounceEntrance,
          animate: !_prefersReducedMotion,
          child: SizedBox(
            width: double.infinity,
            child: AnimatedPrimaryButton(
              onPressed: _handleLoginSubmit,
              isLoading: isLoading,
              enableHoverScale: !_prefersReducedMotion,
              child: Text("Sign in"),
            ),
          ),
        ),
        const Gap(24),

        AnimatedListItem(
          index: itemIndex++,
          staggerDelay: AnimationConstants.fieldStagger,
          animate: !_prefersReducedMotion,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("Don't have an account?").small.muted,
              const Gap(4),
              AnimatedLinkButton(
                onPressed: () => _switchMode("register"),
                child: Text("Sign up").small,
              ),
            ],
          ),
        ),
        const Gap(16),

        AnimatedListItem(
          index: itemIndex++,
          staggerDelay: AnimationConstants.fieldStagger,
          animate: !_prefersReducedMotion,
          child: _buildFooter(),
        ),
      ],
    );
  }

  /// Email registration form
  Widget _buildEmailRegistration() {
    int itemIndex = 0;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedListItem(
          index: itemIndex++,
          staggerDelay: AnimationConstants.fieldStagger,
          animate: !_prefersReducedMotion,
          child: _buildAnimatedLogo(),
        ),
        const Gap(12),

        AnimatedListItem(
          index: itemIndex++,
          staggerDelay: AnimationConstants.fieldStagger,
          slideOffset: const Offset(0, -0.1),
          curve: AnimationConstants.bounceEntrance,
          animate: !_prefersReducedMotion,
          child: Text("Create account").x3Large,
        ),
        const Gap(8),

        AnimatedListItem(
          index: itemIndex++,
          staggerDelay: AnimationConstants.fieldStagger,
          animate: !_prefersReducedMotion,
          child: Text("Get started with Midsphere AI Studio").muted,
        ),
        const Gap(32),

        if (kIsWeb) ...[
          AnimatedListItem(
            index: itemIndex++,
            staggerDelay: AnimationConstants.fieldStagger,
            animate: !_prefersReducedMotion,
            child: Column(children: _buildThirdPartyLogins()),
          ),
          AnimatedListItem(
            index: itemIndex++,
            staggerDelay: AnimationConstants.fieldStagger,
            animate: !_prefersReducedMotion,
            child: Column(
              children: [
                const Gap(16),
                Divider(child: Text("Or").muted().small),
                const Gap(16),
              ],
            ),
          ),
        ],

        AnimatedListItem(
          index: itemIndex++,
          staggerDelay: AnimationConstants.fieldStagger,
          slideOffset: const Offset(0.05, 0),
          animate: !_prefersReducedMotion,
          child: TextField(
            controller: username,
            placeholder: Text("Full name"),
            features: [InputFeature.leading(Icon(LucideIcons.user))],
          ),
        ),
        const Gap(12),

        AnimatedListItem(
          index: itemIndex++,
          staggerDelay: AnimationConstants.fieldStagger,
          slideOffset: const Offset(0.05, 0),
          animate: !_prefersReducedMotion,
          child: TextField(
            controller: email,
            placeholder: Text("Email address"),
            features: [InputFeature.leading(Icon(LucideIcons.mail))],
          ),
        ),
        const Gap(12),

        AnimatedListItem(
          index: itemIndex++,
          staggerDelay: AnimationConstants.fieldStagger,
          slideOffset: const Offset(0.05, 0),
          animate: !_prefersReducedMotion,
          child: TextField(
            controller: password,
            placeholder: Text("Password"),
            features: [
              InputFeature.leading(Icon(LucideIcons.key)),
              InputFeature.passwordToggle(mode: PasswordPeekMode.hold),
            ],
          ),
        ),
        const Gap(12),

        AnimatedListItem(
          index: itemIndex++,
          staggerDelay: AnimationConstants.fieldStagger,
          slideOffset: const Offset(0.05, 0),
          animate: !_prefersReducedMotion,
          child: TextField(
            controller: confirmPassword,
            placeholder: Text("Confirm password"),
            features: [
              InputFeature.leading(Icon(LucideIcons.shieldCheck)),
              InputFeature.passwordToggle(mode: PasswordPeekMode.hold),
            ],
          ),
        ),
        const Gap(24),

        AnimatedListItem(
          index: itemIndex++,
          staggerDelay: AnimationConstants.fieldStagger,
          curve: AnimationConstants.bounceEntrance,
          animate: !_prefersReducedMotion,
          child: SizedBox(
            width: double.infinity,
            child: AnimatedPrimaryButton(
              onPressed: _handleRegistrationSubmit,
              isLoading: isLoading,
              enableHoverScale: !_prefersReducedMotion,
              child: Text("Create account"),
            ),
          ),
        ),
        const Gap(24),

        AnimatedListItem(
          index: itemIndex++,
          staggerDelay: AnimationConstants.fieldStagger,
          animate: !_prefersReducedMotion,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("Already have an account?").small.muted,
              const Gap(4),
              AnimatedLinkButton(
                onPressed: () => _switchMode("login"),
                child: Text("Sign in").small,
              ),
            ],
          ),
        ),
        const Gap(16),

        AnimatedListItem(
          index: itemIndex++,
          staggerDelay: AnimationConstants.fieldStagger,
          animate: !_prefersReducedMotion,
          child: _buildFooter(),
        ),
      ],
    );
  }

  Widget _buildAnimatedLogo() {
    return ClipRRect(
      borderRadius: Theme.of(context).borderRadiusMd,
      child: Image.asset(
        "assets/images/logo.png",
        height: 72,
        width: 72,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  /// Third-party login buttons
  List<Widget> _buildThirdPartyLogins() {
    if (!kIsWeb) return [];

    return [
      ClipRRect(
        borderRadius: Theme.of(context).borderRadiusMd,
        child: renderButton(
          configuration: GSIButtonConfiguration(
            minimumWidth: 400,
            logoAlignment: GSIButtonLogoAlignment.center,
            shape: GSIButtonShape.rectangular,
          ),
        ),
      ),
    ];
  }

  /// Footer with privacy and T&C links
  Widget _buildFooter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AnimatedLinkButton(
          onPressed: () {},
          child: Text("Privacy Policy").small.muted,
        ),
        const Gap(16),
        AnimatedLinkButton(
          onPressed: () {},
          child: Text("Terms of Service").small.muted,
        ),
      ],
    );
  }

  // ----------------------------------------------------------
  // Business Logic
  // ----------------------------------------------------------

  void _handleLoginState(BuildContext context, LoginState state) {
    if (state is MSignInError) {
      _handleSignInError(context, state);
    } else if (state is SignInSuccess) {
      _handleSignInSuccess(context);
    }
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

  void _handleSignInError(BuildContext context, MSignInError state) {
    setState(() => isLoading = false);
    _showToast("Error occurred", state.error);
    loginBloc.add(LoadLogin());
  }

  void _handleSignInSuccess(BuildContext context) {
    _showToast("Login successful", "Welcome back to Midsphere");
    final route = '/home';
    context.pushReplacement(route);
  }

  bool _validateData({bool forRegistration = false}) {
    bool isEmail = EmailValidator.validate(email.text);
    bool isPassword = Toolkit.passwordValidator(password.text);
    bool isConfirmPassword = Toolkit.passwordValidator(confirmPassword.text);
    bool isValidUsername = _validateName(username.text);

    if (!isEmail) {
      _showToast("Invalid email", "Please enter a valid email address");
      return false;
    }

    if (!isPassword) {
      _showToast("Weak password", "Password does not meet requirements");
      return false;
    }

    if (forRegistration) {
      if (!isValidUsername) {
        _showToast("Invalid name", "Please enter your full name");
        return false;
      }
      if (!isConfirmPassword) {
        _showToast("Invalid confirmation", "Please confirm your password");
        return false;
      }
      if (password.text != confirmPassword.text) {
        _showToast("Passwords don't match", "Please make sure passwords match");
        return false;
      }
    }

    return true;
  }

  void _handleLoginSubmit() {
    if (_validateData()) {
      setState(() => isLoading = true);
      loginBloc.add(EmailLogin(email.text, password.text));
    }
  }

  void _handleRegistrationSubmit() async {
    if (_validateData(forRegistration: true)) {
      setState(() => isLoading = true);
      final response = await WorkSpace.createUser(username.text, email.text, password.text);
      setState(() => isLoading = false);

      if (response == "Success") {
        _showToast("Account created", "Sign in with your new account");
        _switchMode("login");
      } else {
        _showToast("Registration failed", response);
      }
    }
  }

  void _showToast(String title, String message, {bool useSetState = false}) {
    toastMessage = title;
    toastDescription = message;

    if (useSetState) setState(() {});

    showToast(
      context: context,
      builder: buildToast,
      location: ToastLocation.topCenter,
    );
  }

  bool _validateName(String value) => value.length >= 2;
}
