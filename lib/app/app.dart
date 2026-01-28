import 'package:flutter/material.dart';
import '../screens/home_screen.dart';
import 'app_theme.dart';

class LGApp extends StatelessWidget {
  const LGApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Liquid Galaxy Controller',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: const HomeScreen(),
    );
  }
}
