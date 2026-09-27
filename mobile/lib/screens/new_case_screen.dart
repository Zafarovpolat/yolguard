import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/api_client.dart';
import '../core/glass.dart';
import '../core/location.dart';
import '../core/motion.dart';
import '../core/theme.dart';
import '../models.dart';
import '../state/app_state.dart';
import '../widgets/ui.dart';
import 'eligibility_wizard_screen.dart';

/// Создание нового дела: выбираем авто, ловим GPS, затем — визард права.
class NewCaseScreen extends StatefulWidget {
  const NewCaseScreen({super.key});

  @override
  State<NewCaseScreen> createState() => _NewCaseScreenState();
}

class _NewCaseScreenState extends State<NewCaseScreen> {
  late Future<List<Vehicle>> _vehicles;
  final _address = TextEditingController();
  int? _vehicleId;
  GpsFix? _gps;
  bool _locating = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _vehicles = context.read<AppState>().vehicles.list();
    _detectLocation();
  }

  @override
  void dispose() {
    _address.dispose();
    super.dispose();
  }

  Future<void> _detectLocation() async {
    final fix = await tryGetLocation();
    if (mounted)
      setState(() {
        _gps = fix;
        _locating = false;
      });
  }

  Future<void> _start() async {
    setState(() => _busy = true);
    try {
      final c = await context.read<AppState>().cases.create(
            vehicleId: _vehicleId,
            address: _address.text.trim(),
            lat: _gps?.lat,
            lng: _gps?.lng,
          );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
            builder: (_) => EligibilityWizardScreen(caseId: c.id)),
      );
    } on ApiException catch (e) {
      if (mounted) showSnack(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const GlassAppBar(title: 'Новое дело'),
      body: SafeArea(
        child: FadeSlideIn(
          child: ListView(
            padding: kPagePadding,
            children: [
              const SectionLabel('Место'),
              AppCard(
                child: Row(
                  children: [
                    Icon(
                      _gps?.ok == true
                          ? Icons.location_on_rounded
                          : Icons.location_off_rounded,
                      color: _gps?.ok == true ? AppTheme.green : AppTheme.muted,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _locating
                          ? const Text('Определяем координаты…',
                              style: TextStyle(color: AppTheme.muted))
                          : Text(
                              _gps?.ok == true
                                  ? 'Координаты получены: '
                                      '${_gps!.lat!.toStringAsFixed(5)}, ${_gps!.lng!.toStringAsFixed(5)}'
                                  : (_gps?.error ?? 'Координаты недоступны'),
                              style: const TextStyle(fontSize: 13),
                            ),
                    ),
                    if (!_locating)
                      IconButton(
                        onPressed: () {
                          setState(() => _locating = true);
                          _detectLocation();
                        },
                        icon: const Icon(Icons.refresh_rounded),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _address,
                decoration: const InputDecoration(
                    hintText: 'Адрес / ориентир (необязательно)'),
              ),
              const SizedBox(height: 20),
              const SectionLabel('Ваш автомобиль'),
              FutureBuilder<List<Vehicle>>(
                future: _vehicles,
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  final items = snap.data ?? [];
                  if (items.isEmpty) {
                    return const AppCard(
                      child: Text(
                        'Нет добавленных авто. Можно продолжить без выбора — '
                        'указать позже в деле.',
                        style: TextStyle(color: AppTheme.muted, fontSize: 13),
                      ),
                    );
                  }
                  return Column(
                    children: [
                      for (final v in items)
                        RadioListTile<int>(
                          value: v.id,
                          groupValue: _vehicleId,
                          onChanged: (val) => setState(() => _vehicleId = val),
                          title: Text(v.title),
                          subtitle: Text(v.plate),
                          contentPadding: EdgeInsets.zero,
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _busy ? null : _start,
                child: _busy
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Начать разбор'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
