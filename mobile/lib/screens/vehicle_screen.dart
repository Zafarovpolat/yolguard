import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/api_client.dart';
import '../core/glass.dart';
import '../core/motion.dart';
import '../core/theme.dart';
import '../models.dart';
import '../state/app_state.dart';
import '../widgets/ui.dart';

/// «Моя машина» — список авто и добавление нового.
class VehicleScreen extends StatefulWidget {
  const VehicleScreen({super.key});

  @override
  State<VehicleScreen> createState() => _VehicleScreenState();
}

class _VehicleScreenState extends State<VehicleScreen> {
  late Future<List<Vehicle>> _future;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() => _future = context.read<AppState>().vehicles.list();

  Future<void> _addVehicle() async {
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _VehicleForm(),
    );
    if (created == true && mounted) setState(_reload);
  }

  Future<void> _delete(Vehicle v) async {
    try {
      await context.read<AppState>().vehicles.delete(v.id);
      if (mounted) setState(_reload);
    } on ApiException catch (e) {
      if (mounted) showSnack(context, e.message, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const GlassAppBar(title: 'Моя машина'),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addVehicle,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Добавить'),
      ),
      body: SafeArea(
        child: FutureBuilder<List<Vehicle>>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting)
              return const LoadingView();
            if (snap.hasError)
              return ErrorView('Ошибка: ${snap.error}',
                  onRetry: () => setState(_reload));
            final items = snap.data ?? [];
            if (items.isEmpty) {
              return const Center(
                child: Text('Нет добавленных авто',
                    style: TextStyle(color: AppTheme.muted)),
              );
            }
            return ListView.separated(
              padding: kPagePadding,
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final v = items[i];
                return FadeSlideIn(
                  delay: AppMotion.stagger(i),
                  child: AppCard(
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(v.title,
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700)),
                              const SizedBox(height: 4),
                              Text(
                                  '${v.plate}${v.year != null ? ' · ${v.year}' : ''}',
                                  style: const TextStyle(
                                      color: AppTheme.muted, fontSize: 13)),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => _delete(v),
                          icon: const Icon(Icons.delete_rounded,
                              color: AppTheme.muted),
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
    );
  }
}

/// Форма добавления авто (нижний лист).
class _VehicleForm extends StatefulWidget {
  const _VehicleForm();

  @override
  State<_VehicleForm> createState() => _VehicleFormState();
}

class _VehicleFormState extends State<_VehicleForm> {
  final _make = TextEditingController();
  final _model = TextEditingController();
  final _plate = TextEditingController();
  final _year = TextEditingController();
  final _insurance = TextEditingController();
  final _policy = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _busy = false;

  @override
  void dispose() {
    _make.dispose();
    _model.dispose();
    _plate.dispose();
    _year.dispose();
    _insurance.dispose();
    _policy.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      await context.read<AppState>().vehicles.create({
        'make': _make.text.trim(),
        'model': _model.text.trim(),
        'plate': _plate.text.trim(),
        if (_year.text.trim().isNotEmpty)
          'year': int.tryParse(_year.text.trim()),
        if (_insurance.text.trim().isNotEmpty)
          'insurance_company': _insurance.text.trim(),
        if (_policy.text.trim().isNotEmpty)
          'policy_number': _policy.text.trim(),
      });
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (mounted) showSnack(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding:
          EdgeInsets.only(left: 20, right: 20, top: 20, bottom: bottom + 20),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Новое авто',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _make,
                    decoration: const InputDecoration(hintText: 'Марка'),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Обязательно' : null,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: _model,
                    decoration: const InputDecoration(hintText: 'Модель'),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Обязательно' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _plate,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(hintText: 'Госномер'),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Обязательно' : null,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: _year,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(hintText: 'Год'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _insurance,
              decoration: const InputDecoration(hintText: 'Страховая компания'),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _policy,
              decoration: const InputDecoration(hintText: 'Номер полиса'),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _busy ? null : _save,
              child: _busy
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Сохранить'),
            ),
          ],
        ),
      ),
    );
  }
}
