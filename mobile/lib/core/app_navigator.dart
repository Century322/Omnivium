import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'di/app_di.dart';
import 'navigation_cubit.dart';
import 'model_cubit.dart';
import 'quick_command_cubit.dart';
import 'note_cubit.dart';
import 'agent/agent_orchestrator.dart';
import '../presentation/views/discover_view.dart';
import '../presentation/views/search_view.dart';
import '../features/auth/presentation/pages/unified_login_page.dart';
import '../presentation/views/message_list_view.dart';
import '../presentation/views/friend_profile_view.dart';
import '../presentation/views/key_verification_view.dart';
import '../presentation/views/notification_view.dart';
import '../presentation/views/ai_workbench_view.dart';
import '../presentation/views/productivity_view.dart';
import '../presentation/views/agent_replay_view.dart';
import '../presentation/views/ai_operation_log_view.dart';
import '../presentation/views/ai_permission_view.dart';
import '../presentation/views/quick_commands_view.dart';
import '../presentation/views/storage_view.dart';
import '../presentation/views/file_manager_view.dart';
import '../presentation/views/my_id_view.dart';
import '../presentation/views/about_view.dart';
import '../presentation/views/create_group_view.dart';
import '../features/contacts/presentation/pages/contacts_page.dart';
import '../features/settings/presentation/pages/settings_page.dart';
import '../features/call/presentation/pages/call_page.dart';

class AppNavigator {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    final uri = Uri.parse(settings.name ?? '/');
    final path = uri.path;
    final args = settings.arguments as Map<String, dynamic>?;

    final Widget page;
    switch (path) {
      case '/discover':
        page = const DiscoverView();
      case '/search':
        page = const SearchView();
      case '/settings':
        page = const SettingsPage();
      case '/login':
        page = const UnifiedLoginPage();
      case '/messages':
        page = const MessageListView();
      case '/chat':
        final roomId =
            args?['roomId'] as String? ?? uri.queryParameters['roomId'] ?? '';
        page = FriendProfileView(roomId: roomId);
      case '/key-verification':
        page = KeyVerificationView(verification: args?['verification']);
      case '/notifications':
        page = const NotificationView();
      case '/workbench':
        page = const AIWorkbenchView();
      case '/productivity':
        page = const ProductivityView();
      case '/replay':
        page = AgentReplayView(orchestrator: getIt<AgentOrchestrator>());
      case '/operation-log':
        page = const AiOperationLogView();
      case '/permissions':
        page = const AiPermissionView();
      case '/commands':
        page = QuickCommandsView(provider: getIt<QuickCommandCubit>());
      case '/storage':
        page = const StorageView();
      case '/files':
        final tab =
            args?['tab'] as int? ??
            int.tryParse(uri.queryParameters['tab'] ?? '') ??
            0;
        page = FileManagerView(initialTab: tab);
      case '/my-id':
        page = const MyIdView();
      case '/create-group':
        page = const CreateGroupView();
      case '/about':
        page = const AboutView();
      case '/contacts':
        page = const ContactsPage();
      case '/call':
        final roomId = args?['roomId'] as String? ?? '';
        final userId = args?['userId'] as String? ?? '';
        final isVideo = args?['isVideo'] as bool? ?? false;
        page = CallPage(roomId: roomId, userId: userId, isVideo: isVideo);
      default:
        page = Scaffold(body: Center(child: Text('Route not found: $path')));
    }

    return PageRouteBuilder<void>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) =>
          FadeTransition(opacity: animation, child: child),
      transitionDuration: const Duration(milliseconds: 200),
      settings: settings);
  }

  static Future<T?> go<T>(
    BuildContext context,
    String route, {
    Map<String, dynamic>? args,
  }) {
    try {
      final router = GoRouter.of(context);
      final uri = _buildUri(route, args);
      router.go(uri.toString());
      return Future<T>.value();
    } catch (_) {
      return Navigator.pushNamed<T>(context, route, arguments: args);
    }
  }

  static Future<T?> push<T>(
    BuildContext context,
    String route, {
    Map<String, dynamic>? args,
  }) {
    try {
      final router = GoRouter.of(context);
      final uri = _buildUri(route, args);
      final extra = _extractExtra(args);
      return router.push<T>(uri.toString(), extra: extra);
    } catch (_) {
      return Navigator.pushNamed<T>(context, route, arguments: args);
    }
  }

  static Future<T?> replace<T>(
    BuildContext context,
    String route, {
    Map<String, dynamic>? args,
  }) {
    try {
      final router = GoRouter.of(context);
      final uri = _buildUri(route, args);
      final extra = _extractExtra(args);
      router.replace(uri.toString(), extra: extra);
      return Future<T>.value();
    } catch (_) {
      return Navigator.pushReplacementNamed<T, void>(
        context,
        route,
        arguments: args);
    }
  }

  static void back<T>(BuildContext context, [T? result]) {
    try {
      final router = GoRouter.of(context);
      router.pop<T>(result);
    } catch (_) {
      Navigator.pop<T>(context, result);
    }
  }

  static String _buildUri(String route, Map<String, dynamic>? args) {
    if (args == null || args.isEmpty) return route;
    final uri = Uri.parse(route);
    final queryParams = Map<String, String>.from(uri.queryParameters);
    for (final entry in args.entries) {
      if (entry.value is String) {
        queryParams[entry.key] = entry.value as String;
      } else if (entry.value is int) {
        queryParams[entry.key] = entry.value.toString();
      } else if (entry.value is bool) {
        queryParams[entry.key] = entry.value.toString();
      }
    }
    return uri.replace(queryParameters: queryParams).toString();
  }

  static Map<String, dynamic>? _extractExtra(Map<String, dynamic>? args) {
    if (args == null) return null;
    final extra = <String, dynamic>{};
    for (final entry in args.entries) {
      if (entry.value is! String && entry.value is! int && entry.value is! bool) {
        extra[entry.key] = entry.value;
      }
    }
    return extra.isEmpty ? null : extra;
  }

  static bool handleDeepLink(Uri uri, BuildContext context) {
    final path = uri.path;
    if (path == '/add') {
      final id = uri.queryParameters['id'];
      if (id != null) {
        push<void>(context, '/chat', args: {'query': id});
        return true;
      }
    }
    if (path == '/chat') {
      final roomId = uri.queryParameters['roomId'];
      if (roomId != null) {
        push<void>(context, '/chat', args: {'roomId': roomId});
        return true;
      }
    }
    return false;
  }
}
