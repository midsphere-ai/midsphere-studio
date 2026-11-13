import 'dart:async';
import 'dart:math';

import 'package:arcane/arcane.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dice_bear/dice_bear.dart';
import 'package:dio/dio.dart';

import 'package:flutter_client/logics/data/helpers/general_utils.dart';
import 'package:flutter_client/widgets/backgrounds/constrained_box.dart';
import 'package:flutter_client/widgets/state/simple_bloc.dart';
import 'package:flutter_client/widgets/state/toast_helper.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../logics/data/global_logics.dart';
import '../../../logics/domain/blocs/simple/simple_bloc.dart';
import '../../../logics/domain/entities/memory/misc/schemas.dart';
import '../../../logics/domain/usecases/memory/memory_usecase.dart';
import '../../../main.dart';

class ExpandedAddonPage extends StatefulWidget {
  final String addonId;
  const ExpandedAddonPage({super.key, required this.addonId});

  @override
  State<ExpandedAddonPage> createState() => _ExpandedAddonPageState();
}

class _ExpandedAddonPageState extends State<ExpandedAddonPage> {
  int index = 0;
  String addonName = "GitHub";
  String addonLogo =
      'https://images.icon-icons.com/3685/PNG/512/github_logo_icon_229278.png';
  String addonLink = "https://github.com";
  String addonDescription =
      "GitHub is a code hosting platform for version control and collaboration, offering Git-based repository management, issue tracking, and continuous integration features";

  bool addonAuthComplete = false;
  String? userAddonId;
  bool _isAuthorising = false;
  bool _isCheckingStatus = false;
  Timer? _authCheckTimer;
  SimpleBloc? _simpleBloc;

  AddonStatus? _currentStatus;
  AddonStatus? _persistedStatus; // Status from server (not polling)
  DateTime? _pollingStartTime;
  int _retryCount = 0;
  static const int _maxRetries = 3;
  static const Duration _pollingTimeout = Duration(minutes: 5);
  static const Duration _initialPollInterval = Duration(seconds: 3);
  static const Duration _slowPollInterval = Duration(seconds: 5);
  static const Duration _slowPollThreshold = Duration(seconds: 30);

  List<Map> addonTools = [
    {
      "name": "GMAIL_SEARCH_PEOPLE",
      "description": "Search for people in Gmail by name or email.",
    },
    {
      "name": "GMAIL_SEND_DRAFT",
      "description": "Send an existing draft email.",
    },
    {
      "name": "GMAIL_SEND_EMAIL",
      "description": "Compose and send a new email.",
    },
    {
      "name": "GMAIL_ADD_LABEL_TO_EMAIL",
      "description": "Add a label to a specific email.",
    },
    {
      "name": "GMAIL_CREATE_LABEL",
      "description": "Create a new label in Gmail.",
    },
    {
      "name": "GMAIL_FETCH_MESSAGE_BY_THREAD_ID",
      "description": "Retrieve a message using its thread ID.",
    },
    {
      "name": "GMAIL_GET_CONTACTS",
      "description": "Get a list of saved contacts.",
    },
    {
      "name": "GMAIL_GET_PEOPLE",
      "description": "Fetch people details linked to the account.",
    },
    {
      "name": "GMAIL_GET_PROFILE",
      "description": "Get profile information of the Gmail account.",
    },
    {
      "name": "GMAIL_LIST_LABELS",
      "description": "List all labels in the Gmail account.",
    },
    {
      "name": "GMAIL_LIST_THREADS",
      "description": "List all email threads from the mailbox.",
    },
    {
      "name": "GMAIL_MODIFY_THREAD_LABELS",
      "description": "Modify labels assigned to a thread.",
    },
    {
      "name": "GMAIL_REMOVE_LABEL",
      "description": "Remove a label from an email or thread.",
    },
  ];

  @override
  void dispose() {
    _authCheckTimer?.cancel();
    super.dispose();
  }

  void _refreshAddonData() {
    _simpleBloc?.run(
      function: Memory.getExpandedAddon,
      args: {'addon_id': widget.addonId},
      errorType: ErrorType.widget,
      successType: SuccessType.widget,
    );
  }

  Future<void> _fetchConnectionStatus() async {
    if (userAddonId == null) {
      setState(() => _persistedStatus = null);
      return;
    }
    try {
      final status = await Memory.getConnectionStatus(userAddonId: userAddonId!);
      if (mounted) {
        setState(() => _persistedStatus = status.status);
      }
    } catch (e) {
      debugPrint('Failed to fetch connection status: $e');
    }
  }

  Future<void> _checkAuthStatus() async {
    if (userAddonId == null) {
      return;
    }

    setState(() {
      _isCheckingStatus = true;
    });

    try {
      await postHogInstance.capture(
        eventName: 'check_addon_auth_status',
        properties: {'addon_id': userAddonId!},
      );

      final status = await Memory.getConnectionStatus(userAddonId: userAddonId!);

      if (mounted) {
        final wasAuthorized = addonAuthComplete;
        setState(() {
          _persistedStatus = status.status;
          addonAuthComplete = status.authComplete;
        });

        // Show appropriate feedback based on status
        if (status.authComplete || status.status == AddonStatus.active) {
          ToastHelper.show(context, 'Addon is authorized', LucideIcons.check);
          // Refresh addon data if authorization status changed
          if (!wasAuthorized && status.authComplete) {
            _refreshAddonData();
          }
        } else {
          ToastHelper.show(context, 'Status: ${status.status.displayText}', LucideIcons.info);
        }
      }
    } catch (e, s) {
      debugPrint('[CheckStatus] Error: $e');
      debugPrint('[CheckStatus] Stack: $s');
      await postHogInstance.captureException(
        error: e,
        stackTrace: s,
        properties: {'error_type': 'check_auth_status'},
      );
      if (mounted) {
        ToastHelper.show(context, 'Failed to check status: $e', LucideIcons.x);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCheckingStatus = false;
        });
      }
    }
  }

  Future<void> _registerAddon() async {
    setState(() {
      _isAuthorising = true;
    });
    try {
      await postHogInstance.capture(
        eventName: 'register_addon',
        properties: {'addon_id': userAddonId ?? widget.addonId},
      );
      await Memory.registerAddon(addonId: widget.addonId);
      _refreshAddonData();
    } catch (e, s) {
      debugPrint('$e');
      debugPrint('$s');
      await postHogInstance.captureException(
        error: e,
        stackTrace: s,
        properties: {'addon_id': userAddonId!},
      );
      if (mounted) {
        ToastHelper.show(context, "Failed to install Addon: $e", LucideIcons.badgeAlert);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isAuthorising = false;
        });
      }
    }
  }

  Future<void> _authoriseAddon() async {
    if (userAddonId == null) return;
    setState(() {
      _isAuthorising = true;
    });
    await postHogInstance.capture(
      eventName: 'user_authorised_addon',
      properties: {'addon_id': userAddonId!},
    );
    try {
      final response = await Memory.getAddonAuthLink(userAddonId: userAddonId!);
      final authUrl = response;
      if (await canLaunchUrl(Uri.parse(authUrl.authLink))) {
        await launchUrl(
          Uri.parse(authUrl.authLink),
          webOnlyWindowName: '_blank',
        );
        _startAuthStatusPolling();
      } else {
        throw 'Could not launch $authUrl';
      }
    } catch (e, s) {
      await postHogInstance.captureException(
        error: e,
        stackTrace: s,
        properties: {'error_type': 'addon_authorisation'},
      );
      if (mounted) {
        ToastHelper.show(context, 'An error occurred: $e', LucideIcons.x);
        setState(() {
          _isAuthorising = false;
        });
      }
    }
  }

  Future<void> _regenerateAndAuthorize() async {
    if (userAddonId == null) return;
    setState(() {
      _isAuthorising = true;
    });

    try {
      await postHogInstance.capture(
        eventName: 'regenerate_auth_link',
        properties: {'addon_id': userAddonId!},
      );

      final response = await Memory.regenerateAuthLink(userAddonId: userAddonId!);

      if (await canLaunchUrl(Uri.parse(response.authLink))) {
        await launchUrl(
          Uri.parse(response.authLink),
          webOnlyWindowName: '_blank',
        );
        _startAuthStatusPolling();
      } else {
        throw 'Could not launch auth link';
      }
    } on DioException catch (e) {
      final errorCode = e.response?.data?['error'] as String?;
      final error = RegenerateAuthError.fromErrorCode(errorCode);

      if (error == RegenerateAuthError.alreadyAuthorised) {
        // Already authorized - refresh to show connected state
        _refreshAddonData();
      } else if (error == RegenerateAuthError.authLinkNotExpired) {
        // Still in progress - show message
        ToastHelper.show(context, error!.displayText, LucideIcons.info);
      } else {
        ToastHelper.show(context, error?.displayText ?? 'An error occurred', LucideIcons.x);
      }

      setState(() {
        _isAuthorising = false;
      });
    } catch (e, s) {
      await postHogInstance.captureException(
        error: e,
        stackTrace: s,
        properties: {'error_type': 'regenerate_auth_link'},
      );
      if (mounted) {
        ToastHelper.show(context, 'An error occurred: $e', LucideIcons.x);
        setState(() {
          _isAuthorising = false;
        });
      }
    }
  }

  void _startAuthStatusPolling() {
    _authCheckTimer?.cancel();
    _pollingStartTime = DateTime.now();
    _retryCount = 0;
    _currentStatus = AddonStatus.initiated;

    _pollConnectionStatus();
  }

  Future<void> _pollConnectionStatus() async {
    if (userAddonId == null || !mounted) {
      _stopPolling();
      return;
    }

    // Check timeout
    final elapsed = DateTime.now().difference(_pollingStartTime!);
    if (elapsed > _pollingTimeout) {
      _handlePollingTimeout();
      return;
    }

    try {
      await postHogInstance.capture(
        eventName: 'addon_auth_polling',
        properties: {'addon_id': userAddonId!},
      );
      final response = await Memory.getConnectionStatus(userAddonId: userAddonId!);

      if (!mounted) return;

      setState(() {
        _currentStatus = response.status;
      });

      if (response.isActive || response.authComplete) {
        // Success - persist to DB and refresh
        await _persistAuthStatus();
        _stopPolling();
        _refreshAddonData();
        return;
      }

      if (response.status == AddonStatus.expired ||
          response.status == AddonStatus.failed) {
        _stopPolling();
        setState(() {
          _persistedStatus = response.status; // Store for UI
        });
        ToastHelper.show(context, response.status.displayText, LucideIcons.x);
        return;
      }

      if (response.status.shouldContinuePolling) {
        // Schedule next poll with adaptive interval
        _retryCount = 0; // Reset retry count on success
        final interval = elapsed > _slowPollThreshold
            ? _slowPollInterval
            : _initialPollInterval;
        _authCheckTimer = Timer(interval, _pollConnectionStatus);
      } else {
        _stopPolling();
      }
    } catch (e, s) {
      _retryCount++;
      debugPrint('Connection status check failed (attempt $_retryCount): $e');
      await postHogInstance.captureException(
        error: e,
        stackTrace: s,
        properties: {'error': 'auth_polling_failed', 'addon_id': userAddonId!, 'retry_count': _retryCount},
      );

      if (_retryCount >= _maxRetries) {
        if (mounted) {
          ToastHelper.show(context, 'Network error. Please try again.', LucideIcons.wifiOff);
          _stopPolling();
        }
        return;
      }

      // Exponential backoff for retries
      final backoffDelay = Duration(seconds: pow(2, _retryCount).toInt());
      _authCheckTimer = Timer(backoffDelay, _pollConnectionStatus);
    }
  }

  Future<void> _persistAuthStatus() async {
    if (userAddonId == null) return;
    try {
      await Memory.checkAndUpdateAuthStatus(userAddonId: userAddonId!);
    } catch (e) {
      debugPrint('Failed to persist auth status: $e');
    }
  }

  void _handlePollingTimeout() {
    _stopPolling();
    if (mounted) {
      ToastHelper.show(
        context,
        'Authorization timed out. Please try again.',
        LucideIcons.clock,
      );
    }
  }

  void _stopPolling() {
    _authCheckTimer?.cancel();
    _authCheckTimer = null;
    if (mounted) {
      setState(() {
        _isAuthorising = false;
        _currentStatus = null;
      });
    }
  }

  void _cancelAuthorization() {
    _stopPolling();
  }

  Future<void> _unregisterAddon() async {
    if (userAddonId == null) return;
    setState(() {
      _isAuthorising = true;
    });
    try {
      await postHogInstance.capture(
        eventName: 'unregistered_addon',
        properties: {'addon_id': userAddonId!},
      );
      await Memory.unregisterAddon(userAddonId: userAddonId!);
      _refreshAddonData();
    } catch (e, s) {
      await postHogInstance.captureException(
        error: e,
        stackTrace: s,
        properties: {'addon_id': userAddonId!},
      );
      if (mounted) {
      }
    } finally {
      if (mounted) {
        setState(() {
          _isAuthorising = false;
        });
      }
    }
  }

  TableCell buildHeaderCell(String text, [bool alignRight = false]) {
    return TableCell(
      child: Container(
        padding: const EdgeInsets.all(8),
        alignment: alignRight ? Alignment.centerRight : Alignment.centerLeft,
        child: Text(text).small.bold,
      ),
    );
  }

  TableCell buildCell(String text, [bool alignRight = false]) {
    return TableCell(
      child: Container(
        padding: const EdgeInsets.all(8),
        alignment: alignRight ? Alignment.centerRight : Alignment.centerLeft,
        child: Text(text).small.normal,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: SimpleBlocWidget(
        key: ValueKey('expandedAddon'),
        errorWidgetBuilder: (error) {
          return _buildMainContent(error: error);
        },
        loadingWidget: _buildMainContent().asSkeleton(),
        successWidgetBuilder: (response) {
          addonName = response.marketplaceAddon['name'];
          addonDescription = response.marketplaceAddon['description'];
          addonLink = response.marketplaceAddon['link'];
          addonLogo = response.marketplaceAddon['logo'];

          if (response.userAddon != null) {
            userAddonId = response.userAddon['id'];
            addonAuthComplete = response.userAddon['auth_complete'];
            // Fetch connection status for UI state
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _fetchConnectionStatus();
            });
          } else {
            userAddonId = null;
            addonAuthComplete = false;
            _persistedStatus = null;
          }
          addonTools = response.features;
          return _buildMainContent();
        },
        blocInit: (SimpleBloc bloc) {
          _simpleBloc = bloc;
          bloc.run(
            function: Memory.getExpandedAddon,
            args: {'addon_id': widget.addonId},
            errorType: ErrorType.widget,
            successType: SuccessType.widget,
          );
        },
        child: _buildMainContent(),
      ),
    );
  }

  Widget _buildMainContent({String error = ""}) {
    return Scaffold(
      child: Stack(
        children: [
          error.isEmpty
              ? _buildAddonContent()
              : CenterBody(
                  icon: LucideIcons.badgeAlert,
                  message: "Failed to fetch addon details: $error",
                ),
        ],
      ),
    );
  }

  Widget _buildAddonContent() {
    return LimitedWindowBox(
      customWidth: DataConstants.pageWidth,
      child: ListView(
        children: [
          SizedBox(height: 16),
          _buildLogoAndHeader(),
          SizedBox(height: 16),
          _buildTabs(),
          SizedBox(height: 16),
          _buildIndexedStacks(),
          SizedBox(height: 32),
          _buildSupportText(),
          SizedBox(height: 64),
        ],
      ),
    );
  }

  Widget _buildSupportText() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Flexible(
          child: Text(
            "Having issues with this addon? Reach us out at support@midsphere.ai",
          ).small.muted,
        ),
      ],
    );
  }

  Widget _buildLogoAndHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: CachedNetworkImage(
            imageUrl: addonLogo,
            height: 128,
            width: 128,
            fit: BoxFit.cover,
            memCacheHeight: 128, // Cache at 2x for retina displays
            memCacheWidth: 128,
            maxHeightDiskCache: 128,
            maxWidthDiskCache: 128,
            fadeInDuration: Duration.zero, // Instant display
            placeholder: (context, url) => Container(
              height: 64,
              width: 64,
              color: Theme.of(context).colorScheme.card,
            ).asSkeleton()
          ),
        ),
        SizedBox(height: 16),
        _buildHeader(),
      ],
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(addonName).h3,
        SizedBox(height: 6),
        Text(addonDescription, textAlign: TextAlign.center).small,
        SizedBox(height: 24),
        _buildAuthButtons(),
      ],
    );
  }

  Widget _buildAuthButtons() {
    if (_isAuthorising) {
      return Column(
        children: [
          const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          if (_currentStatus != null) ...[
            const SizedBox(height: 8),
            Text(_currentStatus!.displayText).small.muted,
            const SizedBox(height: 8),
            TextButton(
              onPressed: _cancelAuthorization,
              child: const Text('Cancel'),
            ),
          ],
        ],
      );
    }

    if (userAddonId == null) {
      // Not installed
      return PrimaryButton(
        onPressed: _registerAddon,
        child: const Text("Install").bold,
      );
    }

    // Check for status-specific states
    if (_persistedStatus == AddonStatus.expired) {
      return _buildStatusUI(
        icon: LucideIcons.clock,
        message: 'Authorization expired',
        buttonText: 'Reconnect',
        onPressed: _regenerateAndAuthorize,
      );
    }

    if (_persistedStatus == AddonStatus.failed) {
      return _buildStatusUI(
        icon: LucideIcons.circleAlert,
        message: 'Authorization failed',
        buttonText: 'Try Again',
        onPressed: _regenerateAndAuthorize,
      );
    }

    if (_persistedStatus == AddonStatus.inactive) {
      return _buildStatusUI(
        icon: LucideIcons.circleStop,
        message: 'Connection inactive',
        buttonText: 'Reactivate',
        onPressed: _regenerateAndAuthorize,
      );
    }

    // Normal installed state
    // Consider authorized if either the addon data says so OR the persisted status is active
    final isAuthorized = addonAuthComplete || _persistedStatus == AddonStatus.active;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (!isAuthorized)
              PrimaryButton(
                onPressed: _authoriseAddon,
                child: const Text("Authorise").bold,
              ),
            if (isAuthorized)
              OutlineButton(
                onPressed: null,
                child: const Text("Authorised").bold,
              ),
            const SizedBox(width: 8),
            SecondaryButton(
              onPressed: _unregisterAddon,
              child: const Text("Uninstall"),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildCheckStatusButton(),
      ],
    );
  }

  Widget _buildCheckStatusButton() {
    return GhostButton(
      onPressed: _isCheckingStatus ? null : _checkAuthStatus,
      density: ButtonDensity.compact,
      child: _isCheckingStatus
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(LucideIcons.refreshCw, size: 14),
                const SizedBox(width: 6),
                const Text("Check Status"),
              ],
            ),
    );
  }

  Widget _buildStatusUI({
    required IconData icon,
    required String message,
    required String buttonText,
    required VoidCallback onPressed,
  }) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: Theme.of(context).colorScheme.destructive),
            const SizedBox(width: 8),
            Text(message).small.muted,
          ],
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            PrimaryButton(
              onPressed: onPressed,
              child: Text(buttonText).bold,
            ),
            const SizedBox(width: 8),
            SecondaryButton(
              onPressed: _unregisterAddon,
              child: const Text("Uninstall"),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildCheckStatusButton(),
      ],
    );
  }

  Widget _buildTabs() {
    return TabList(
      index: index,
      onChanged: (value) {
        setState(() {
          index = value;
        });
      },
      children: const [
        TabItem(child: Text('Features')),
        TabItem(child: Text('Addon info')),
      ],
    );
  }

  Widget _buildIndexedStacks() {
    return IndexedStack(
      index: index,
      children: [
        _buildFeatureTable(),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 4,
          children: [
            Text("Addon Provider").muted.small,
            Text("Composio"),
            SizedBox(height: 4),
            Text("Platform link").muted.small,
            LinkButton(
              density: ButtonDensity.compact,
              child: Text(
                addonLink,
                style: TextStyle(color: Colors.blue.shade400),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFeatureTable() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...addonTools.map((tool) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 8),
              OutlineBadge(child: Text("TOOL")),
              SizedBox(height: 6),
              Basic(
                title: Text(tool['name']).medium,
                content: Text(tool['description']).muted.small,
              ),
              SizedBox(height: 8),
              Divider(),
            ],
          );
        }),
      ],
    );
  }

  Widget error(BuildContext context, Object error, StackTrace? stackTrace) {
    final avatar = DiceBearBuilder(
      seed: addonName,
      radius: 49,
      size: 16,
      backgroundColor: Toolkit.pastelColorLight(),
      sprite: DiceBearSprite.icons,
    ).build();
    return avatar.toImage(
      height: Toolkit.isMobile(context) ? 64 : 124,
      width: Toolkit.isMobile(context) ? 64 : 124,
    );
  }
}
