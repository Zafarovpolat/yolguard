import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/api_client.dart';
import '../core/motion.dart';
import '../core/theme.dart';
import '../state/app_state.dart';
import '../widgets/ui.dart';
import 'register_screen.dart';

/// Вход по номеру телефона + пароль.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _busy = false;

  @override
  void dispose() {
    _phone.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      await context.read<AppState>().login(_phone.text.trim(), _password.text);
    } on ApiException catch (e) {
      if (mounted) showSnack(context, e.message, error: true);
    } catch (_) {
      if (mounted)
        showSnack(context, 'Не удалось подключиться к серверу', error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: CenteredScroll(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: FadeSlideIn(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Бренд-марка: знак-щит в тонированном квадрате.
                Center(
                  child: Container(
                    width: 66,
                    height: 66,
                    decoration: BoxDecoration(
                      color: AppTheme.accentSoft,
                      borderRadius: BorderRadius.circular(AppTheme.rCard),
                    ),
                    child: const Icon(Icons.shield_rounded,
                        color: AppTheme.accent, size: 34),
                  ),
                ),
                const SizedBox(height: 20),
                const Center(child: AppWordmark(size: 40)),
                const SizedBox(height: 8),
                const Text(
                  'Разбор мелких ДТП по Европротоколу',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 15, color: AppTheme.muted, height: 1.4),
                ),
                const SizedBox(height: 32),
                AppCard(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _phone,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            labelText: 'Телефон',
                            hintText: '+998 90 000 00 00',
                          ),
                          validator: (v) => (v == null || v.trim().length < 6)
                              ? 'Введите номер'
                              : null,
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _password,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'Пароль',
                            hintText: 'Пароль',
                          ),
                          validator: (v) => (v == null || v.length < 6)
                              ? 'Минимум 6 символов'
                              : null,
                        ),
                        const SizedBox(height: 22),
                        FilledButton(
                          onPressed: _busy ? null : _submit,
                          child: _busy
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2))
                              : const Text('Войти'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: _busy
                      ? null
                      : () => Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => const RegisterScreen())),
                  child: const Text('Нет аккаунта? Зарегистрироваться'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
