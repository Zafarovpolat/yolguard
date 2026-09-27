import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../core/api_client.dart';
import '../core/case_labels.dart';
import '../core/glass.dart';
import '../core/location.dart';
import '../core/motion.dart';
import '../core/theme.dart';
import '../models.dart';
import '../state/app_state.dart';
import '../widgets/ui.dart';

/// Сбор доказательств по категориям (общий план, повреждения, номера, документы, VIN).
class CaptureScreen extends StatefulWidget {
  const CaptureScreen({super.key, required this.caseId});
  final int caseId;

  @override
  State<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends State<CaptureScreen> {
  late Future<List<Evidence>> _future;
  final _picker = ImagePicker();
  String _category = Labels.evidenceCategories.first.$1;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() =>
      _future = context.read<AppState>().evidence.list(widget.caseId);

  Future<void> _capture(ImageSource source) async {
    final picked = await _picker.pickImage(source: source, imageQuality: 90);
    if (picked == null) return;
    // Берём сервис до await'ов, чтобы не трогать context после асинхронных пауз.
    final evidenceService = context.read<AppState>().evidence;
    setState(() => _busy = true);
    try {
      final gps = await tryGetLocation(); // мягко: без координат тоже грузим
      final ev = await evidenceService.upload(
        widget.caseId,
        file: File(picked.path),
        category: _category,
        gpsLat: gps.lat,
        gpsLng: gps.lng,
      );
      if (!mounted) return;
      if (ev.isRejected) {
        showSnack(
            context, 'Фото отклонено: ${ev.qualityReason ?? 'низкое качество'}',
            error: true);
      } else {
        showSnack(context, 'Фото добавлено');
      }
      setState(_reload);
    } on ApiException catch (e) {
      if (mounted) showSnack(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const GlassAppBar(title: 'Доказательства'),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionLabel('Что снимаем'),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final cat in Labels.evidenceCategories)
                        ChoiceChip(
                          label: Text(cat.$2),
                          selected: _category == cat.$1,
                          onSelected: (_) => setState(() => _category = cat.$1),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed:
                              _busy ? null : () => _capture(ImageSource.camera),
                          icon: const Icon(Icons.photo_camera_rounded),
                          label: const Text('Камера'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _busy
                              ? null
                              : () => _capture(ImageSource.gallery),
                          icon: const Icon(Icons.photo_library_rounded),
                          label: const Text('Галерея'),
                        ),
                      ),
                    ],
                  ),
                  if (_busy)
                    const Padding(
                      padding: EdgeInsets.only(top: 12),
                      child: LinearProgressIndicator(),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: FutureBuilder<List<Evidence>>(
                future: _future,
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Padding(
                        padding: kPagePadding, child: LoadingView(rows: 2));
                  }
                  if (snap.hasError) {
                    return Padding(
                      padding: kPagePadding,
                      child: Center(
                        child: ErrorView('Ошибка: ${snap.error}',
                            onRetry: () => setState(_reload)),
                      ),
                    );
                  }
                  final items = snap.data ?? [];
                  if (items.isEmpty) {
                    return const Padding(
                      padding: kPagePadding,
                      child: Center(
                        child: EmptyState(
                          icon: Icons.add_a_photo_rounded,
                          title: 'Пока нет снимков',
                          subtitle:
                              'Выберите категорию выше и снимите первое фото.',
                        ),
                      ),
                    );
                  }
                  return ListView.separated(
                    padding: kPagePadding,
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final e = items[i];
                      return FadeSlideIn(
                        delay: AppMotion.stagger(i),
                        child: AppCard(
                          child: Row(
                            children: [
                              Icon(
                                e.isRejected
                                    ? Icons.error_rounded
                                    : Icons.check_circle_rounded,
                                color: e.isRejected
                                    ? AppTheme.red
                                    : AppTheme.green,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                        Labels.evidenceCategoryLabel(
                                            e.category),
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w700)),
                                    if (e.qualityReason != null) ...[
                                      const SizedBox(height: 2),
                                      Text(e.qualityReason!,
                                          style: const TextStyle(
                                              color: AppTheme.muted,
                                              fontSize: 12)),
                                    ],
                                  ],
                                ),
                              ),
                              StatusPill(
                                e.isRejected ? 'Отклонено' : 'OK',
                                color: e.isRejected
                                    ? AppTheme.red
                                    : AppTheme.green,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
