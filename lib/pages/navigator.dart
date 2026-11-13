import 'package:arcane/arcane.dart';
import 'package:flutter/material.dart' show MaterialApp;
import 'package:flutter_client/logics/data/global_logics.dart';
import 'package:flutter_client/pages/expanded/search/main.dart';
import 'package:flutter_client/pages/expanded/spaces/main.dart';
import 'package:flutter_client/pages/home/home.dart';
import 'package:flutter_client/pages/login/login.dart';
import 'package:flutter_client/pages/support/support.dart';
import 'package:flutter_client/widgets/texts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:posthog_flutter/posthog_flutter.dart';

import '../logics/data/helpers/themes.dart';
import '../logics/data/repositories/authentication.dart';
import '../widgets/errors/404.dart';
import 'expanded/addons/home.dart';
import 'test/api_test_page.dart';
import 'chat/demo.dart';

/// The base widget for the application.
///
/// This widget sets up the GoRouter and the Arcane theme.
class BaseApp extends StatefulWidget {
  /// A map of all the instances of this widget.
  static final Map<Key, _BaseAppState> _instances = {};

  /// Creates a new [BaseApp] widget.
  const BaseApp({super.key});

  @override
  State<BaseApp> createState() => _BaseAppState();

  /// Returns the [GoRouter] for the specified instance of this widget.
  static GoRouter router(Key key) {
    if (!_instances.containsKey(key)) {
      throw Exception('No RunFunctionWidget found with key: $key');
    }
    return _instances[key]!._router;
  }

  /// Returns the [BuildContext] for the specified instance of this widget.
  static BuildContext context(Key key) {
    if (!_instances.containsKey(key)) {
      throw Exception('No RunFunctionWidget found with key: $key');
    }
    return _instances[key]!.context;
  }

  /// Changes the theme for the specified instance of this widget.
  static void changeTheme(Key key, ThemeMode mode) {
    if (!_instances.containsKey(key)) {
      throw Exception('No RunFunctionWidget found with key: $key');
    }
    return _instances[key]!._changeTheme(mode);
  }

  static void changeAccent(Key key, Map<String, dynamic> accentMap) {
    if (!_instances.containsKey(key)) {
      throw Exception('No RunFunctionWidget found with key: $key');
    }
    return _instances[key]!._changeAccent(accentMap);
  }
}

class _BaseAppState extends State<BaseApp> {
  late List<RouteBase> _routes;
  late GoRouter _router;

  ThemeMode themeMode = DataConstants.currentTheme;

  @override
  void initState() {
    setupRouter();
    if (widget.key != null) {
      BaseApp._instances[widget.key!] = this;
    }

    final user = AuthenticationProvider().loggedInUser;
    if (user != null && user.email != null) {
      final key = 'settings_${user.email}';
      final settings = DataConstants.settingsBox?.get(key);

      if (settings != null && settings is Map && settings['general'] != null) {
        final general = settings['general'];
        if (general['theme'] != null) {
          final savedTheme = general['theme'] == 'Dark'
              ? ThemeMode.dark
              : ThemeMode.light;
          DataConstants.currentTheme = savedTheme;
          themeMode = savedTheme;
        }
        if (general['accent'] != null) {
          final savedAccentName = general['accent'];
          final accent = DataConstants.availableAccents.firstWhere(
            (element) => element['color'] == savedAccentName,
            orElse: () => DataConstants.availableAccents.first,
          );
          DataConstants.activeAccent = accent;
          DataConstants.colorScheme = accent['scheme'];
        }
      }
    }

    super.initState();
  }

  /// Changes the theme of the application.
  void _changeTheme(ThemeMode mode) {
    setState(() {
      DataConstants.currentTheme = mode;
      themeMode = mode;
    });
  }

  void _changeAccent(Map<String, dynamic> accentMap) {
    setState(() {
      DataConstants.colorScheme = accentMap['scheme'];
      DataConstants.activeAccent = accentMap;
    });
  }

  /// Sets up the GoRouter.
  void setupRouter() {
    _routes = [
      GoRoute(
        path: '/',
        builder: (BuildContext context, GoRouterState state) {
          return LoginPage();
        },
      ),
      GoRoute(
        path: '/404',
        builder: (BuildContext context, GoRouterState state) {
          return ErrorPage();
        },
      ),
      GoRoute(
        path: '/library',
        builder: (BuildContext context, GoRouterState state) {
          return ExpandedSearchView();
        },
      ),
      GoRoute(
        path: '/addons/:id',
        builder: (BuildContext context, GoRouterState state) {
          final String id = state.pathParameters['id'] ?? "1";
          if (id == "1") {
            return ErrorPage();
          }

          return AddonsHome();
        },
      ),
      GoRoute(
        path: '/spaces/:id',
        builder: (BuildContext context, GoRouterState state) {
          final String id = state.pathParameters['id'] ?? "1";
          if (id == "1") {
            return ErrorPage();
          }
          return ExpandedSpaces(spaceId: id);
        },
      ),
      GoRoute(
        path: '/home',
        builder: (BuildContext context, GoRouterState state) {
          return HomePage();
        },
      ),
      GoRoute(
        path: '/support',
        builder: (BuildContext context, GoRouterState state) {
          return const SupportPage();
        },
      ),
      GoRoute(
        path: '/api-test',
        builder: (BuildContext context, GoRouterState state) {
          return const ApiTestPage();
        },
      ),
      GoRoute(
        path: '/chat-demo',
        builder: (BuildContext context, GoRouterState state) {
          return const ChatDemoPage();
        },
      ),
    ];

    _router = GoRouter(
      observers: [PosthogObserver()],
      errorBuilder: (context, state) => ErrorPage(),
      initialLocation: AuthenticationProvider().loggedInUser != null
          ? '/home'
          : '/',
      routes: _routes,
    );
  }

  @override
  Widget build(BuildContext context) {

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      routerDelegate: _router.routerDelegate,
      color: Colors.black,
      routeInformationParser: _router.routeInformationParser,
      routeInformationProvider: _router.routeInformationProvider,
      builder: (context, child) {
        return ArcaneApp(
          debugShowCheckedModeBanner: false,
          title: 'Midsphere App',
          color: Colors.black,
          navigatorObservers: [
            PosthogObserver(),
          ],
          theme: ArcaneTheme(
            scheme: ContrastedColorScheme.fromScheme(
              DataConstants.colorScheme,
            ),
            surfaceEffect: BlurSurfaceEffect(),
            shadThemeBuilder: themeBuilder,
            themeMode: themeMode,
          ),
          home: child, // let GoRouter decide current screen
        );
      },
    );
  }

  /// Builds the theme data for the application.
  ThemeData themeBuilder(ArcaneTheme theme, Brightness brightness) {
    return ThemeData(
      colorScheme: DataConstants.currentTheme == ThemeMode.dark
          ? Themes.getDarkTheme(defaultColorScheme: DataConstants.colorScheme)
          : Themes.getLightTheme(defaultColorScheme: DataConstants.colorScheme),
      radius: 0.7,
      typography: GoogleTypography.inter(),
    );
  }
}
