import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'di/app_di.dart';
import 'navigation_cubit.dart';
import 'model_cubit.dart';
import 'quick_command_cubit.dart';
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
import '../presentation/views/reminder_list_page.dart';
import '../presentation/views/ai_permission_view.dart';
import '../presentation/views/quick_commands_view.dart';
import '../presentation/views/storage_view.dart';
import '../presentation/views/file_manager_view.dart';
import '../presentation/views/my_id_view.dart';
import '../presentation/views/about_view.dart';
import '../presentation/views/create_group_view.dart';
import '../presentation/views/privacy_policy_view.dart';
import '../presentation/views/terms_of_service_view.dart';
import '../presentation/views/faq_view.dart';
import '../features/contacts/presentation/pages/contacts_page.dart';
import '../features/settings/presentation/pages/settings_page.dart';
import '../features/call/presentation/pages/call_page.dart';
import '../presentation/views/home_view.dart';

CustomTransitionPage<void> _fadeTransitionPage({
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) =>
        FadeTransition(opacity: animation, child: child),
    transitionDuration: const Duration(milliseconds: 200));
}

GoRouter createAppRouter({
  required GlobalKey<NavigatorState> navigatorKey,
  required String initialLocation,
  required Widget shellChild,
}) {
  return GoRouter(
    navigatorKey: navigatorKey,
    initialLocation: initialLocation,
    routes: [
      ShellRoute(
        builder: (context, state, child) => shellChild,
        routes: [
          GoRoute(
            path: '/',
            name: 'home',
            builder: (context, state) => const HomeView(),
          ),
      GoRoute(
        path: '/discover',
        name: 'discover',
        builder: (context, state) => const DiscoverView(),
      ),
      GoRoute(
        path: '/search',
        name: 'search',
        builder: (context, state) => const SearchView(),
      ),
      GoRoute(
        path: '/reminders',
        name: 'reminders',
        builder: (context, state) => const ReminderListPage(),
      ),
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (context, state) => SettingsPage(
          onClose: () => context.pop(),
        ),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const UnifiedLoginPage(),
      ),
      GoRoute(
        path: '/messages',
        name: 'messages',
        builder: (context, state) => const MessageListView(),
      ),
      GoRoute(
        path: '/chat',
        name: 'chat',
        builder: (context, state) {
          final roomId = state.uri.queryParameters['roomId'] ?? '';
          return FriendProfileView(roomId: roomId);
        },
      ),
      GoRoute(
        path: '/key-verification',
        name: 'key-verification',
        builder: (context, state) {
          final verification = state.extra as Map<String, dynamic>?;
          return KeyVerificationView(verification: verification);
        },
      ),
      GoRoute(
        path: '/notifications',
        name: 'notifications',
        builder: (context, state) => const NotificationView(),
      ),
      GoRoute(
        path: '/workbench',
        name: 'workbench',
        builder: (context, state) => const AIWorkbenchView(),
      ),
      GoRoute(
        path: '/productivity',
        name: 'productivity',
        builder: (context, state) => const ProductivityView(),
      ),
      GoRoute(
        path: '/replay',
        name: 'replay',
        builder: (context, state) =>
            AgentReplayView(orchestrator: getIt<AgentOrchestrator>()),
      ),
      GoRoute(
        path: '/operation-log',
        name: 'operation-log',
        builder: (context, state) => const AiOperationLogView(),
      ),
      GoRoute(
        path: '/permissions',
        name: 'permissions',
        builder: (context, state) => const AiPermissionView(),
      ),
      GoRoute(
        path: '/commands',
        name: 'commands',
        builder: (context, state) =>
            QuickCommandsView(provider: getIt<QuickCommandCubit>()),
      ),
      GoRoute(
        path: '/storage',
        name: 'storage',
        builder: (context, state) => const StorageView(),
      ),
      GoRoute(
        path: '/files',
        name: 'files',
        builder: (context, state) {
          final tab =
              int.tryParse(state.uri.queryParameters['tab'] ?? '') ?? 0;
          return FileManagerView(initialTab: tab);
        },
      ),
      GoRoute(
        path: '/my-id',
        name: 'my-id',
        builder: (context, state) => const MyIdView(),
      ),
      GoRoute(
        path: '/create-group',
        name: 'create-group',
        builder: (context, state) => const CreateGroupView(),
      ),
      GoRoute(
        path: '/about',
        name: 'about',
        builder: (context, state) => const AboutView(),
      ),
      GoRoute(
        path: '/contacts',
        name: 'contacts',
        builder: (context, state) => const ContactsPage(),
      ),
      GoRoute(
        path: '/call',
        name: 'call',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return CallPage(
            roomId: extra['roomId'] as String? ?? '',
            userId: extra['userId'] as String? ?? '',
            isVideo: extra['isVideo'] as bool? ?? false,
          );
        },
      ),
      GoRoute(
        path: '/privacy-policy',
        name: 'privacy-policy',
        builder: (context, state) => const PrivacyPolicyView(),
      ),
      GoRoute(
        path: '/terms-of-service',
        name: 'terms-of-service',
        builder: (context, state) => const TermsOfServiceView(),
      ),
      GoRoute(
        path: '/faq',
        name: 'faq',
        builder: (context, state) => const FaqView(),
      ),
    ],
    ),
  ],
  );
}
