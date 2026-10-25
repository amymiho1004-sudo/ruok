import 'package:flutter/material.dart';

import '../core/navigation.dart';
import '../core/strings.dart';
import '../services/local_store.dart';
import 'auth_screen.dart';
import 'dashboard_screen.dart';

/// Decides between login and dashboard based on the stored session.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _next();
  }

  Future<void> _next() async {
    final loggedIn = await LocalStore.hasSession();
    if (!mounted) return;
    context.replaceWith(loggedIn ? const DashboardScreen() : const AuthScreen());
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.health_and_safety_rounded, size: 64, color: scheme.primary),
            const SizedBox(height: 14),
            Text(S.appName, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(S.tagline),
          ],
        ),
      ),
    );
  }
}
