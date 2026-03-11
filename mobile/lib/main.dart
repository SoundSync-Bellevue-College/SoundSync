import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'providers/auth_provider.dart';
import 'screens/home_screen.dart';
import 'screens/route_detail_screen.dart';
import 'screens/account_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';

void main() {
  runApp(const ProviderScope(child: SoundSyncApp()));
}

final _router = GoRouter(
  routes: [
    GoRoute(path: '/', builder: (_, __) => const HomeScreen()),
    GoRoute(
      path: '/route/:id',
      builder: (_, state) =>
          RouteDetailScreen(routeId: state.pathParameters['id']!),
    ),
    GoRoute(path: '/account', builder: (_, __) => const AccountScreen()),
    GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
    GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
  ],
);

class SoundSyncApp extends ConsumerWidget {
  const SoundSyncApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Restore saved session before rendering; show splash while loading.
    final restore = ref.watch(authRestoreProvider);

    return MaterialApp.router(
      title: 'SoundSyncAI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true).copyWith(
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF7FDBFF),
          secondary: Color(0xFF7FDBFF),
          surface: Color(0xFF122340),
        ),
        scaffoldBackgroundColor: const Color(0xFF0D1B2A),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF122340),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.white12),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.white12),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF7FDBFF), width: 1.5),
          ),
          labelStyle: const TextStyle(color: Colors.white54),
          hintStyle: const TextStyle(color: Colors.white38),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF7FDBFF),
            foregroundColor: const Color(0xFF0D1B2A),
            textStyle: const TextStyle(
                fontWeight: FontWeight.bold, fontSize: 15),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            minimumSize: const Size(double.infinity, 52),
          ),
        ),
      ),
      routerConfig: _router,
      // Show a full-screen splash while restoring the session
      builder: (context, child) {
        if (restore.isLoading) {
          return const _SplashScreen();
        }
        return child ?? const SizedBox.shrink();
      },
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF0D1B2A),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.directions_transit_filled,
                size: 56, color: Color(0xFF7FDBFF)),
            SizedBox(height: 16),
            Text(
              'SoundSyncAI',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            SizedBox(height: 32),
            CircularProgressIndicator(color: Color(0xFF7FDBFF)),
          ],
        ),
      ),
    );
  }
}
