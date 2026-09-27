import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/glass.dart';
import 'core/theme.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'state/app_state.dart';

/// Корневой виджет приложения.
class YolGuardApp extends StatelessWidget {
  const YolGuardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Yo\'lGuard',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      // Глобальная амбиентная подложка под всеми экранами: на ней light liquid
      // glass читается везде (панели прозрачны, фон — тёплый bone со светом).
      builder: (context, child) =>
          AmbientBackground(child: child ?? const SizedBox()),
      home: const _Root(),
    );
  }
}

/// Развилка по статусу авторизации: заставка → вход или домашний экран.
class _Root extends StatefulWidget {
  const _Root();

  @override
  State<_Root> createState() => _RootState();
}

class _RootState extends State<_Root> {
  @override
  void initState() {
    super.initState();
    // Проверяем сохранённый токен после первого кадра.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppState>().bootstrap();
    });
  }

  @override
  Widget build(BuildContext context) {
    final status = context.watch<AppState>().status;
    return switch (status) {
      AuthStatus.unknown => const Scaffold(
          backgroundColor: Colors.transparent,
          body: Center(child: CircularProgressIndicator()),
        ),
      AuthStatus.authenticated => const HomeScreen(),
      AuthStatus.unauthenticated => const LoginScreen(),
    };
  }
}
