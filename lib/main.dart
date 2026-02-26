import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vigilante_app/features/main/presentation/screens/main_layout.dart';
import 'core/theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // En tu MyApp dentro de main.dart
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Vigilante App',
      theme: AppTheme.lightTheme,
      home: const MainLayout(), // <-- AHORA LA APP ARRANCA DESDE EL LAYOUT
    );
  }
}