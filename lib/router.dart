import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'features/auth/presentation/pages/login_page.dart';
import 'features/auth/presentation/pages/register_page.dart';
import 'features/rooms/presentation/add_room_page.dart';
import 'features/rooms/presentation/browser_page.dart';
import 'features/rooms/presentation/home_page.dart';
import 'features/rooms/presentation/room_page.dart';
import 'features/settings/settings_page.dart';

/// يُعيد بناء المسارات عند تغيّر حالة المصادقة
class _AuthRefreshNotifier extends ChangeNotifier {
  _AuthRefreshNotifier(Stream<User?> stream) {
    _sub = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final StreamSubscription<User?> _sub;

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

GoRouter buildRouter() {
  final refresh =
      _AuthRefreshNotifier(FirebaseAuth.instance.authStateChanges());

  return GoRouter(
    initialLocation: '/',
    refreshListenable: refresh,
    redirect: (context, state) {
      final loggedIn = FirebaseAuth.instance.currentUser != null;
      final loc = state.matchedLocation;
      final onAuthPage = loc == '/login' || loc == '/register';

      if (!loggedIn && !onAuthPage) return '/login';
      if (loggedIn && onAuthPage) return '/';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        path: '/',
        builder: (context, state) => const HomePage(),
      ),
      GoRoute(
        path: '/room/new',
        builder: (context, state) => const AddRoomPage(),
      ),
      GoRoute(
        path: '/browser',
        builder: (context, state) {
          final initialUrl = state.uri.queryParameters['url'];
          return BrowserPage(initialUrl: initialUrl);
        },
      ),
      GoRoute(
        path: '/room/:id',
        builder: (context, state) =>
            RoomPage(roomId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsPage(),
      ),
    ],
  );
}
