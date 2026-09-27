import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/api_client.dart';
import '../core/glass.dart';
import '../core/motion.dart';
import '../core/theme.dart';
import '../models.dart';
import '../state/app_state.dart';
import '../widgets/ui.dart';
import 'case_detail_screen.dart';

/// Визард проверки права на упрощённое оформление (Европротокол).
/// Вопросы приходят с бэкенда — решение детерминированное (не ИИ).
class EligibilityWizardScreen extends StatefulWidget {
  const EligibilityWizardScreen({super.key, required this.caseId});
  final int caseId;

  @override
  State<EligibilityWizardScreen> createState() =>
      _EligibilityWizardScreenState();
}

class _EligibilityWizardScreenState extends State<EligibilityWizardScreen> {
  late Future<List<WizardQuestion>> _future;
  final Map<String, dynamic> _answers = {};
  bool _busy = false;
  EligibilityResult? _result;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<WizardQuestion>> _load() async {
    final qs = await context.read<AppState>().cases.eligibilityQuestions();
    for (final q in qs) {
      _answers[q.key] = q.defaultValue ??
          (q.type == 'bool' ? false : (q.type == 'int' ? 2 : null));
    }
    return qs;
  }

  Future<void> _submit() async {
    setState(() => _busy = true);
    try {
      final res = await context
          .read<AppState>()
          .cases
          .submitEligibility(widget.caseId, _answers);
      if (!mounted) return;
      setState(() => _result = res);
    } on ApiException catch (e) {
      if (mounted) showSnack(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const GlassAppBar(title: 'Проверка права'),
      body: SafeArea(
        child: _result != null
            ? _ResultView(
                result: _result!,
                caseId: widget.caseId,
                onRetry: () => setState(() => _result = null),
              )
            : FutureBuilder<List<WizardQuestion>>(
                future: _future,
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Padding(
                        padding: kPagePadding, child: LoadingView());
                  }
                  if (snap.hasError) {
                    return Padding(
                      padding: kPagePadding,
                      child: Center(
                        child: ErrorView('Ошибка: ${snap.error}',
                            onRetry: () => setState(() => _future = _load())),
                      ),
                    );
                  }
                  final questions = snap.data ?? [];
                  return ListView(
                    padding: kPagePadding,
                    children: [
                      FadeSlideIn(
                        child: AppCard(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: AppTheme.accentSoft,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.fact_check_rounded,
                                    color: AppTheme.accent, size: 22),
                              ),
                              const SizedBox(width: 14),
                              const Expanded(
                                child: Text(
                                  'Ответьте на несколько вопросов — по ним определим, '
                                  'можно ли оформить ДТП упрощённо, без вызова инспектора.',
                                  style: TextStyle(
                                      color: AppTheme.inkSoft,
                                      fontSize: 13.5,
                                      height: 1.4),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      for (var i = 0; i < questions.length; i++)
                        FadeSlideIn(
                          delay: AppMotion.stagger(i + 1),
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _QuestionField(
                              question: questions[i],
                              value: _answers[questions[i].key],
                              onChanged: (v) => setState(
                                  () => _answers[questions[i].key] = v),
                            ),
                          ),
                        ),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: _busy ? null : _submit,
                        child: _busy
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2))
                            : const Text('Проверить'),
                      ),
                    ],
                  );
                },
              ),
      ),
    );
  }
}

/// Поле одного вопроса: переключатель для bool, счётчик для int.
class _QuestionField extends StatelessWidget {
  const _QuestionField(
      {required this.question, required this.value, required this.onChanged});
  final WizardQuestion question;
  final dynamic value;
  final ValueChanged<dynamic> onChanged;

  @override
  Widget build(BuildContext context) {
    if (question.type == 'int') {
      final n = (value as int?) ?? 2;
      return AppCard(
        child: Row(
          children: [
            Expanded(
                child:
                    Text(question.label, style: const TextStyle(fontSize: 15))),
            IconButton(
              onPressed: n > 1 ? () => onChanged(n - 1) : null,
              icon: const Icon(Icons.remove_circle_rounded),
            ),
            Text('$n',
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            IconButton(
              onPressed: () => onChanged(n + 1),
              icon: const Icon(Icons.add_circle_rounded),
            ),
          ],
        ),
      );
    }
    // bool по умолчанию
    return AppCard(
      padding: const EdgeInsets.fromLTRB(16, 4, 8, 4),
      child: Row(
        children: [
          Expanded(
              child:
                  Text(question.label, style: const TextStyle(fontSize: 15))),
          Switch(value: (value as bool?) ?? false, onChanged: onChanged),
        ],
      ),
    );
  }
}

/// Итог проверки: зелёный — можно дальше к сбору доказательств; красный — нельзя.
class _ResultView extends StatelessWidget {
  const _ResultView(
      {required this.result, required this.caseId, required this.onRetry});
  final EligibilityResult result;
  final int caseId;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final green = result.isGreen;
    final color = green ? AppTheme.green : AppTheme.red;
    return CenteredScroll(
      child: FadeSlideIn(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  green ? Icons.check_circle_rounded : Icons.cancel_rounded,
                  color: color,
                  size: 44,
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              green ? 'Можно оформить упрощённо' : 'Упрощённо оформить нельзя',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                  color: color,
                  letterSpacing: -0.3),
            ),
            const SizedBox(height: 24),
            if (result.reasons.isNotEmpty) ...[
              const SectionLabel('Почему'),
              for (final r in result.reasons)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(r.message,
                            style: const TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w600)),
                        if (r.action.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(r.action,
                              style: const TextStyle(
                                  color: AppTheme.muted,
                                  fontSize: 13,
                                  height: 1.4)),
                        ],
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 6),
            ],
            const SizedBox(height: 8),
            if (green)
              FilledButton.icon(
                onPressed: () => Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                      builder: (_) => CaseDetailScreen(caseId: caseId)),
                ),
                icon: const Icon(Icons.photo_camera_rounded),
                label: const Text('Перейти к сбору доказательств'),
              )
            else ...[
              OutlinedButton(
                onPressed: () =>
                    Navigator.of(context).popUntil((r) => r.isFirst),
                child: const Text('На главную'),
              ),
              const SizedBox(height: 8),
              TextButton(
                  onPressed: onRetry, child: const Text('Изменить ответы')),
            ],
          ],
        ),
      ),
    );
  }
}
