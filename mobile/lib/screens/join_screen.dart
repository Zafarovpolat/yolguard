import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

import '../core/api_client.dart';
import '../core/glass.dart';
import '../core/theme.dart';
import '../state/app_state.dart';
import '../widgets/ui.dart';
import 'case_detail_screen.dart';

/// Присоединение ко второй стороне ДТП: скан QR или ввод кода вручную.
class JoinScreen extends StatefulWidget {
  const JoinScreen({super.key});

  @override
  State<JoinScreen> createState() => _JoinScreenState();
}

class _JoinScreenState extends State<JoinScreen> {
  final _code = TextEditingController();
  final _scanner = MobileScannerController();
  bool _busy = false;
  bool _handled = false; // защита от повторного срабатывания onDetect

  @override
  void dispose() {
    _code.dispose();
    _scanner.dispose();
    super.dispose();
  }

  Future<void> _join(String rawCode) async {
    final code = rawCode.trim();
    if (code.isEmpty || _busy) return;
    setState(() => _busy = true);
    try {
      final c = await context.read<AppState>().cases.join(joinCode: code);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => CaseDetailScreen(caseId: c.id)),
      );
    } on ApiException catch (e) {
      _handled = false; // разрешим повторный скан после ошибки
      if (mounted) showSnack(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _onDetect(BarcodeCapture capture) {
    if (_handled) return;
    final raw =
        capture.barcodes.isNotEmpty ? capture.barcodes.first.rawValue : null;
    if (raw == null || raw.isEmpty) return;
    _handled = true;
    _join(raw);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const GlassAppBar(title: 'Присоединиться'),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  MobileScanner(controller: _scanner, onDetect: _onDetect),
                  // Затемнение по краям, чтобы рамка читалась на любом фоне.
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0x33000000),
                          Color(0x00000000),
                          Color(0x55000000)
                        ],
                        stops: [0.0, 0.4, 1.0],
                      ),
                    ),
                  ),
                  // Рамка-подсказка по центру.
                  Center(
                    child: Container(
                      width: 224,
                      height: 224,
                      decoration: BoxDecoration(
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.9),
                            width: 3),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: const [
                          BoxShadow(color: Color(0x33000000), blurRadius: 16),
                        ],
                      ),
                    ),
                  ),
                  // «Жидкое стекло» поверх живой камеры — здесь оно уместно.
                  Positioned(
                    left: 20,
                    right: 20,
                    bottom: 20,
                    child: GlassSurface(
                      dark: true,
                      radius: 16,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.qr_code_2_rounded,
                              color: Colors.white, size: 22),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Наведите камеру на QR-код второй стороны',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const SectionLabel('Или введите код вручную'),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _code,
                          textCapitalization: TextCapitalization.characters,
                          style:
                              AppTheme.mono(size: 16, weight: FontWeight.w700),
                          decoration:
                              const InputDecoration(hintText: 'Код дела'),
                          onSubmitted: _join,
                        ),
                      ),
                      const SizedBox(width: 10),
                      FilledButton(
                        onPressed: _busy ? null : () => _join(_code.text),
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
