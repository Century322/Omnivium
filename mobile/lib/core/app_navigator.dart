import 'package:flutter/material.dart';
import '../core/app_provider.dart';
import '../presentation/views/voice_view.dart';
import '../presentation/views/discover_view.dart';
import '../presentation/views/search_view.dart';
import '../presentation/views/settings_view.dart';
import '../presentation/views/matrix_login_view.dart';
import '../presentation/views/message_list_view.dart';
import '../presentation/views/contacts_view.dart';
import '../presentation/views/add_friend_view.dart';
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

class AppNavigator {
  static AppProvider? _provider;
  static AppProvider get provider => _provider!;

  static void init(AppProvider p) {
    _provider = p;
  }

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    final uri = Uri.parse(settings.name ?? '/');
    final path = uri.path;
    final args = settings.arguments as Map<String, dynamic>?;

    final Widget page;
    switch (path) {
      case '/voice':
        page = VoiceView(provider: provider);
      case '/discover':
        page = DiscoverView(provider: provider);
      case '/search':
        page = SearchView(provider: provider);
      case '/settings':
        page = SettingsView(provider: provider);
      case '/login':
        page = MatrixLoginView(provider: provider);
      case '/messages':
        page = MessageListView(provider: provider);
      case '/contacts':
        page = ContactsView(provider: provider);
      case '/add-friend':
        page = AddFriendView(provider: provider);
      case '/chat':
        final roomId =
            args?['roomId'] as String? ?? uri.queryParameters['roomId'] ?? '';
        page = FriendProfileView(provider: provider, roomId: roomId);
      case '/key-verification':
        page = KeyVerificationView(verification: args?['verification']);
      case '/notifications':
        page = NotificationView(provider: provider);
      case '/workbench':
        page = AIWorkbenchView(provider: provider);
      case '/productivity':
        page = ProductivityView(provider: provider.notes);
      case '/replay':
        page = AgentReplayView(orchestrator: provider.orchestrator);
      case '/operation-log':
        page = const AiOperationLogView();
      case '/permissions':
        page = const AiPermissionView();
      case '/commands':
        page = QuickCommandsView(provider: provider.quickCommands);
      case '/storage':
        page = StorageView(provider: provider);
      case '/files':
        final tab =
            args?['tab'] as int? ??
            int.tryParse(uri.queryParameters['tab'] ?? '') ??
            0;
        page = FileManagerView(provider: provider, initialTab: tab);
      case '/my-id':
        page = MyIdView(provider: provider);
      case '/about':
        page = AboutView(provider: provider);
      default:
        page = Scaffold(body: Center(child: Text('Route not found: $path')));
    }

    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) =>
          FadeTransition(opacity: animation, child: child),
      transitionDuration: const Duration(milliseconds: 200),
      settings: settings,
    );
  }

  static Future<T?> go<T>(
    BuildContext context,
    String route, {
    Map<String, dynamic>? args,
  }) {
    return Navigator.pushNamed<T>(context, route, arguments: args);
  }

  static Future<T?> replace<T>(
    BuildContext context,
    String route, {
    Map<String, dynamic>? args,
  }) {
    return Navigator.pushReplacementNamed<T, void>(
      context,
      route,
      arguments: args,
    );
  }

  static void back<T>(BuildContext context, [T? result]) {
    Navigator.pop<T>(context, result);
  }

  static bool handleDeepLink(Uri uri, BuildContext context) {
    final path = uri.path;
    if (path == '/add') {
      final id = uri.queryParameters['id'];
      if (id != null) {
        go(context, '/add-friend', args: {'query': id});
        return true;
      }
    }
    if (path == '/chat') {
      final roomId = uri.queryParameters['roomId'];
      if (roomId != null) {
        go(context, '/chat', args: {'roomId': roomId});
        return true;
      }
    }
    return false;
  }
}
