import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';
import '../services/routes_lookup.dart';
import 'home_screen.dart';
import 'scores_screen.dart';
import 'account_screen.dart';
import 'about_screen.dart';
import 'chat_screen.dart';

class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    RoutesLookup.instance.load();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);

    Widget body;
    switch (_index) {
      case 0:
        body = const HomeScreen();
      case 1:
        body = const ScoresScreen();
      case 2:
        body = auth.isLoggedIn
            ? const AccountScreen()
            : _LoginPrompt(
                onLogin: () => context.push('/login'),
                onRegister: () => context.push('/register'),
              );
      case 3:
        body = const ChatScreen();
      case 4:
        body = const AboutScreen();
      default:
        body = const HomeScreen();
    }

    return Scaffold(
      body: body,
      bottomNavigationBar: NavigationBar(
        backgroundColor: const Color(0xFF0D1B2A),
        surfaceTintColor: Colors.transparent,
        indicatorColor: const Color(0xFF7FDBFF).withOpacity(0.15),
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.map_outlined, color: Colors.white38),
            selectedIcon: Icon(Icons.map, color: Color(0xFF7FDBFF)),
            label: 'Map',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined, color: Colors.white38),
            selectedIcon: Icon(Icons.bar_chart, color: Color(0xFF7FDBFF)),
            label: 'Scores',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline, color: Colors.white38),
            selectedIcon: Icon(Icons.person, color: Color(0xFF7FDBFF)),
            label: 'Account',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline, color: Colors.white38),
            selectedIcon: Icon(Icons.chat_bubble, color: Color(0xFF7FDBFF)),
            label: 'Assistant',
          ),
          NavigationDestination(
            icon: Icon(Icons.info_outline, color: Colors.white38),
            selectedIcon: Icon(Icons.info, color: Color(0xFF7FDBFF)),
            label: 'About',
          ),
        ],
      ),
    );
  }
}

// ─── Login prompt (Account tab, unauthenticated) ──────────────────────────────

class _LoginPrompt extends StatelessWidget {
  final VoidCallback onLogin;
  final VoidCallback onRegister;

  const _LoginPrompt({required this.onLogin, required this.onRegister});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.person_outline,
                    color: Color(0xFF7FDBFF), size: 64),
                const SizedBox(height: 20),
                const Text(
                  'Sign in to your account',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'View your profile, reports, and preferences.',
                  style: TextStyle(color: Colors.white54, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                FilledButton(
                  onPressed: onLogin,
                  child: const Text('Sign In'),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: onRegister,
                  child: const Text(
                    'Create Account',
                    style: TextStyle(color: Color(0xFF7FDBFF)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
