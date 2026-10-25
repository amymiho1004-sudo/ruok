import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/material.dart';

import 'core/strings.dart';
import 'screens/splash_screen.dart';
import 'theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  S.isKorean = PlatformDispatcher.instance.locale.languageCode == 'ko';
  runApp(const RuokGuardianApp());
}

class RuokGuardianApp extends StatelessWidget {
  const RuokGuardianApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: S.appName,
      debugShowCheckedModeBanner: false,
      theme: buildRuokTheme(),
      home: const SplashScreen(),
    );
  }
}
