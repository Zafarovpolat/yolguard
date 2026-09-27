import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/glass.dart';
import '../core/motion.dart';
import '../core/theme.dart';
import '../models.dart';
import '../widgets/ui.dart';

/// Показ пакета для страховой — «сырой» JSON, собранный на бэкенде.
/// Пока структура MVP: показываем аккуратно отформатированный JSON + копирование.
class ClaimPackageScreen extends StatelessWidget {
  const ClaimPackageScreen({super.key, required this.package});
  final Map<String, dynamic> package;

  @override
  Widget build(BuildContext context) {
    final pretty = AccidentCase.pretty(package);
    return Scaffold(
      appBar: GlassAppBar(
        title: 'Пакет для страховой',
        actions: [
          IconButton(
            tooltip: 'Скопировать',
            onPressed: () {
              Clipboard.setData(ClipboardData(text: pretty));
              showSnack(context, 'Скопировано в буфер обмена');
            },
            icon: const Icon(Icons.copy_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: kPagePadding,
          children: [
            FadeSlideIn(
              child: const Text(
                'Готовый пакет с делом, участниками и доказательствами. '
                'Его можно передать страховой компании.',
                style: TextStyle(color: AppTheme.muted, fontSize: 13),
              ),
            ),
            const SizedBox(height: 12),
            FadeSlideIn(
              delay: AppMotion.stagger(1),
              child: AppCard(
                child: SelectableText(
                  pretty,
                  style: const TextStyle(
                      fontFamily: 'monospace', fontSize: 12, height: 1.4),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
