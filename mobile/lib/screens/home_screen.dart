import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/case_labels.dart';
import '../core/glass.dart';
import '../core/motion.dart';
import '../core/theme.dart';
import '../models.dart';
import '../state/app_state.dart';
import '../widgets/ui.dart';
import 'join_screen.dart';
import 'new_case_screen.dart';
import 'case_detail_screen.dart';
import 'vehicle_screen.dart';

/// Главный экран: точка входа во все сценарии.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<AccidentCase>> _future;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _future = context.read<AppState>().cases.list();
  }

  Future<void> _refresh() async {
    setState(_reload);
    await _future;
  }

  Future<void> _open(Widget screen) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
    if (mounted) setState(_reload); // вернулись — обновим список дел
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    return Scaffold(
      appBar: GlassAppBar(
        title: 'Yo\'lGuard',
        actions: [
          IconButton(
            tooltip: 'Моя машина',
            onPressed: () => _open(const VehicleScreen()),
            icon: const Icon(Icons.directions_car_rounded),
          ),
          IconButton(
            tooltip: 'Выйти',
            onPressed: () => app.logout(),
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            padding: kPagePadding,
            children: [
              FadeSlideIn(
                child:
                    _EmergencyButton(onTap: () => _open(const NewCaseScreen())),
              ),
              const SizedBox(height: 12),
              FadeSlideIn(
                delay: AppMotion.stagger(1),
                child: OutlinedButton.icon(
                  onPressed: () => _open(const JoinScreen()),
                  icon: const Icon(Icons.qr_code_scanner_rounded),
                  label: const Text('Присоединиться по коду / QR'),
                ),
              ),
              const SizedBox(height: 28),
              const SectionLabel('Мои дела'),
              _CasesList(
                  future: _future,
                  onOpen: (c) => _open(CaseDetailScreen(caseId: c.id))),
            ],
          ),
        ),
      ),
    );
  }
}

/// Крупная главная кнопка «У меня авария».
class _EmergencyButton extends StatelessWidget {
  const _EmergencyButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      scale: 0.98,
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppTheme.accent, AppTheme.accentDark],
          ),
          borderRadius: BorderRadius.circular(AppTheme.rCard),
          boxShadow: [
            BoxShadow(
              color: AppTheme.accent.withValues(alpha: 0.35),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.warning_amber_rounded,
                  color: Colors.white, size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('У меня авария',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3)),
                  SizedBox(height: 4),
                  Text('Пошаговый разбор: право → доказательства → пакет',
                      style: TextStyle(
                          color: Colors.white70, fontSize: 13, height: 1.35)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.white),
          ],
        ),
      ),
    );
  }
}

/// Список дел пользователя с состояниями загрузки/ошибки/пустоты.
class _CasesList extends StatelessWidget {
  const _CasesList({required this.future, required this.onOpen});
  final Future<List<AccidentCase>> future;
  final void Function(AccidentCase) onOpen;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<AccidentCase>>(
      future: future,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting)
          return const LoadingView();
        if (snap.hasError) {
          return ErrorView('Не удалось загрузить дела.\n${snap.error}');
        }
        final cases = snap.data ?? [];
        if (cases.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 28),
            child: EmptyState(
              icon: Icons.inbox_rounded,
              title: 'Пока нет дел',
              subtitle: 'Нажмите «У меня авария», чтобы начать разбор.',
            ),
          );
        }
        return Column(
          children: [
            for (var i = 0; i < cases.length; i++) ...[
              FadeSlideIn(
                delay: AppMotion.stagger(i),
                child: AppCard(
                  onTap: () => onOpen(cases[i]),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Дело №${cases[i].id}',
                                style: const TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w700)),
                            const SizedBox(height: 4),
                            Text(cases[i].address ?? 'Без адреса',
                                style: const TextStyle(
                                    color: AppTheme.muted, fontSize: 13)),
                          ],
                        ),
                      ),
                      StatusPill(Labels.caseStatusLabel(cases[i].status),
                          color: Labels.caseStatusColor(cases[i].status)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ],
        );
      },
    );
  }
}
