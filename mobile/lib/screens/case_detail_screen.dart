import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../core/api_client.dart';
import '../core/case_labels.dart';
import '../core/glass.dart';
import '../core/motion.dart';
import '../core/theme.dart';
import '../models.dart';
import '../state/app_state.dart';
import '../widgets/ui.dart';
import 'capture_screen.dart';
import 'claim_package_screen.dart';

/// Карточка дела: статус, право, код для второй стороны (QR), участники,
/// доказательства и действия (сбор фото, подтверждение, пакет для страховой).
class CaseDetailScreen extends StatefulWidget {
  const CaseDetailScreen({super.key, required this.caseId});
  final int caseId;

  @override
  State<CaseDetailScreen> createState() => _CaseDetailScreenState();
}

class _CaseDetailScreenState extends State<CaseDetailScreen> {
  late Future<AccidentCase> _future;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() => _future = context.read<AppState>().cases.get(widget.caseId);

  Future<void> _refresh() async {
    setState(_reload);
    await _future;
  }

  Future<void> _openCapture() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => CaptureScreen(caseId: widget.caseId)),
    );
    if (mounted) setState(_reload);
  }

  Future<void> _confirm() async {
    final result = await showDialog<bool?>(
      context: context,
      builder: (ctx) => const _ConfirmDialog(),
    );
    // null — отменили диалог; иначе result = признание вины (true/false)
    if (result == null || !mounted) return;
    try {
      await context
          .read<AppState>()
          .cases
          .confirm(widget.caseId, acceptsFault: result);
      if (mounted) {
        showSnack(context, 'Ваше участие подтверждено');
        setState(_reload);
      }
    } on ApiException catch (e) {
      if (mounted) showSnack(context, e.message, error: true);
    }
  }

  Future<void> _claimPackage() async {
    try {
      final pkg =
          await context.read<AppState>().cases.claimPackage(widget.caseId);
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => ClaimPackageScreen(package: pkg)),
      );
    } on ApiException catch (e) {
      if (mounted) showSnack(context, e.message, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GlassAppBar(title: 'Дело №${widget.caseId}'),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: FutureBuilder<AccidentCase>(
            future: _future,
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting)
                return const LoadingView();
              if (snap.hasError) {
                return ErrorView('Ошибка: ${snap.error}',
                    onRetry: () => setState(_reload));
              }
              final c = snap.data!;
              return _Detail(
                c: c,
                onCapture: _openCapture,
                onConfirm: _confirm,
                onClaimPackage: _claimPackage,
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Диалог подтверждения участия с необязательным признанием вины.
class _ConfirmDialog extends StatefulWidget {
  const _ConfirmDialog();

  @override
  State<_ConfirmDialog> createState() => _ConfirmDialogState();
}

class _ConfirmDialogState extends State<_ConfirmDialog> {
  bool _acceptsFault = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Подтвердить участие'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Подтвердите, что данные по делу верны.',
              style: TextStyle(color: AppTheme.muted, fontSize: 14)),
          const SizedBox(height: 8),
          CheckboxListTile(
            value: _acceptsFault,
            onChanged: (v) => setState(() => _acceptsFault = v ?? false),
            title: const Text('Признаю свою вину'),
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
          ),
        ],
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена')),
        FilledButton(
          onPressed: () => Navigator.pop(context, _acceptsFault),
          child: const Text('Подтвердить'),
        ),
      ],
    );
  }
}

/// Содержимое карточки дела.
class _Detail extends StatelessWidget {
  const _Detail({
    required this.c,
    required this.onCapture,
    required this.onConfirm,
    required this.onClaimPackage,
  });

  final AccidentCase c;
  final VoidCallback onCapture;
  final VoidCallback onConfirm;
  final VoidCallback onClaimPackage;

  @override
  Widget build(BuildContext context) {
    final canCapture =
        c.isGreen; // сбор доказательств доступен при «зелёном» праве
    final acceptedOk = c.evidence.where((e) => !e.isRejected).length;

    return FadeSlideIn(
      child: ListView(
        padding: kPagePadding,
        children: [
          // Статус + право
          Row(
            children: [
              StatusPill(Labels.caseStatusLabel(c.status),
                  color: Labels.caseStatusColor(c.status)),
              const SizedBox(width: 8),
              StatusPill(Labels.eligibilityLabel(c.eligibility),
                  color: Labels.eligibilityColor(c.eligibility)),
            ],
          ),
          const SizedBox(height: 16),

          // Код присоединения + QR — показываем создателю, пока второй не вошёл
          if (c.joinCode != null && !c.hasSecondParty) ...[
            const SectionLabel('Пригласить вторую сторону'),
            AppCard(
              child: Column(
                children: [
                  const Text(
                    'Покажите этот QR-код или продиктуйте код второму водителю.',
                    style: TextStyle(color: AppTheme.muted, fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: QrImageView(
                      data: c.joinCode!,
                      version: QrVersions.auto,
                      size: 180,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SelectableText(
                    c.joinCode!,
                    style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Место
          if (c.address != null || c.locationLat != null) ...[
            const SectionLabel('Место'),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (c.address != null && c.address!.isNotEmpty)
                    InfoRow('Адрес', c.address!),
                  if (c.locationLat != null && c.locationLng != null)
                    InfoRow('Координаты',
                        '${c.locationLat!.toStringAsFixed(5)}, ${c.locationLng!.toStringAsFixed(5)}'),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Участники
          const SectionLabel('Участники'),
          AppCard(
            child: Column(
              children: [
                for (final p in c.participants) ...[
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor:
                            AppTheme.accent.withValues(alpha: 0.12),
                        child: Text(p.role,
                            style: const TextStyle(
                                color: AppTheme.accent,
                                fontWeight: FontWeight.w800)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text('Сторона ${p.role}',
                            style:
                                const TextStyle(fontWeight: FontWeight.w600)),
                      ),
                      if (p.acceptsFault)
                        const StatusPill('Признал вину', color: AppTheme.amber)
                      else if (p.confirmed)
                        const StatusPill('Подтвердил', color: AppTheme.green)
                      else
                        const StatusPill('Ожидает'),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
                if (!c.hasSecondParty)
                  const Text('Вторая сторона ещё не присоединилась.',
                      style: TextStyle(color: AppTheme.muted, fontSize: 13)),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Доказательства
          const SectionLabel('Доказательства'),
          AppCard(
            onTap: canCapture ? onCapture : null,
            child: Row(
              children: [
                const Icon(Icons.photo_library_rounded, color: AppTheme.muted),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    c.evidence.isEmpty
                        ? 'Нет загруженных фото'
                        : 'Загружено: ${c.evidence.length}, принято: $acceptedOk',
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
                if (canCapture)
                  const Icon(Icons.chevron_right_rounded,
                      color: AppTheme.muted),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Действия
          if (canCapture)
            FilledButton.icon(
              onPressed: onCapture,
              icon: const Icon(Icons.photo_camera_rounded),
              label: const Text('Собрать доказательства'),
            ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: onConfirm,
            icon: const Icon(Icons.how_to_reg_rounded),
            label: const Text('Подтвердить участие'),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: onClaimPackage,
            icon: const Icon(Icons.description_rounded),
            label: const Text('Пакет для страховой'),
          ),
        ],
      ),
    );
  }
}
