import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import 'motion.dart';
import 'theme.dart';

/// Light liquid glass: размытие фона + матовая заливка + настоящая specular-
/// фаска и 45° edge-light рамка (как в CSS-референсе: слои inset-бликов +
/// градиентная кромка + blur). Рисуется через [_LiquidGlassPainter], потому что
/// у Flutter нет нативной inset-тени. Под всем контентом лежит
/// [AmbientBackground] с тёплым светом — стеклу есть что преломлять.
class GlassSurface extends StatelessWidget {
  const GlassSurface({
    super.key,
    required this.child,
    this.radius = 20,
    this.blur = 18,
    this.padding = const EdgeInsets.all(16),
    this.dark = false,
  });

  final Widget child;
  final double radius;
  final double blur;
  final EdgeInsets padding;

  /// Тёмный вариант — для светлого текста поверх яркой камеры (сканер QR).
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: dark ? null : AppTheme.softShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: CustomPaint(
            painter: _LiquidGlassPainter(radius: radius, dark: dark),
            child: Padding(padding: padding, child: child),
          ),
        ),
      ),
    );
  }
}

/// Рисует «жидкое стекло»: матовая заливка → чернильный волосок → 45° edge-
/// light рамка → мягкая specular-фаска (ярко сверху, слабее снизу). Всё под
/// контентом (CustomPaint рисует painter до child).
class _LiquidGlassPainter extends CustomPainter {
  const _LiquidGlassPainter({required this.radius, required this.dark});

  final double radius;
  final bool dark;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(radius));

    // 1) Матовая заливка (фон под ней уже размыт BackdropFilter'ом).
    canvas.drawRRect(
      rrect,
      Paint()..color = dark ? const Color(0x6B000000) : AppTheme.glassFill,
    );

    // Тёмное стекло поверх камеры: мягкий верхний блик + светлый волосок, всё.
    if (dark) {
      final rim = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x66FFFFFF), Color(0x0DFFFFFF)],
        ).createShader(rect);
      canvas.drawRRect(rrect.deflate(0.5), rim);
      return;
    }

    // 2) Чернильный волосок-определитель по внешней кромке (контраст на светлом).
    canvas.drawRRect(
      rrect.deflate(0.5),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = AppTheme.glassStroke,
    );

    // 3) 45° edge-light: ярко в углах TL/BR, прозрачно по центрам граней —
    //    это градиентная кромка из CSS-референса (white → transparent → white).
    canvas.drawRRect(
      rrect.deflate(0.6),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xF2FFFFFF),
            Color(0x14FFFFFF),
            Color(0x66FFFFFF),
            Color(0xF2FFFFFF),
          ],
          stops: [0.0, 0.42, 0.6, 1.0],
        ).createShader(rect),
    );

    // 4) Specular-фаска (inset-bevel): яркий блик на верхней внутренней кромке,
    //    мягкий возврат снизу. Лёгкий blur даёт «жидкость», а не резкую линию.
    final inner = rect.deflate(1.3);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          inner, Radius.circular(math.max(0, radius - 1.3))),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.8)
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppTheme.glassHighlight,
            Colors.white.withValues(alpha: 0.04),
            Colors.white.withValues(alpha: 0.42),
          ],
          stops: const [0.0, 0.55, 1.0],
        ).createShader(inner),
    );
  }

  @override
  bool shouldRepaint(covariant _LiquidGlassPainter old) =>
      old.radius != radius || old.dark != dark;
}

/// Верхняя панель из light liquid glass: матирует контент под собой, отделяется
/// чернильным волоском и тонкой белой specular-линией. Свап-совместима со
/// стандартным AppBar (title-строкой).
class GlassAppBar extends StatelessWidget implements PreferredSizeWidget {
  const GlassAppBar(
      {super.key, required this.title, this.actions, this.leading});

  final String title;
  final List<Widget>? actions;
  final Widget? leading;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title),
      actions: actions,
      leading: leading,
      backgroundColor: Colors.transparent,
      flexibleSpace: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: const BoxDecoration(
              color: AppTheme.glassFill,
              border: Border(bottom: BorderSide(color: AppTheme.glassStroke)),
            ),
            // Тонкая specular-линия по нижней кромке — блик матового стекла.
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                height: 1,
                color: Colors.white.withValues(alpha: 0.55),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Глобальная амбиентная подложка: тёплая «костяная» база + мягкие световые
/// пятна (белое + тёплый камень), медленно дрейфующие. Даёт light liquid glass
/// динамичную яркость для матирования. При «уменьшенном движении» — статичны.
class AmbientBackground extends StatefulWidget {
  const AmbientBackground({super.key, required this.child});
  final Widget child;

  @override
  State<AmbientBackground> createState() => _AmbientBackgroundState();
}

class _AmbientBackgroundState extends State<AmbientBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(seconds: 28))
        ..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduced = AppMotion.reduced(context);
    return Container(
      color: AppTheme.bg,
      child: Stack(
        children: [
          if (reduced)
            const _Glows(t: 0.5)
          else
            AnimatedBuilder(
              animation: _c,
              builder: (_, __) => _Glows(t: _c.value),
            ),
          Positioned.fill(child: widget.child),
        ],
      ),
    );
  }
}

/// Два световых пятна, чуть смещающихся во времени [t] (0..1): светлое сверху-
/// слева, тёплый камень снизу-справа. Низкая непрозрачность — свет, не цвет.
class _Glows extends StatelessWidget {
  const _Glows({required this.t});
  final double t;

  @override
  Widget build(BuildContext context) {
    final phase = t * 2 * math.pi;
    final dx = 0.16 * math.cos(phase);
    final dy = 0.12 * math.sin(phase);
    return Positioned.fill(
      child: IgnorePointer(
        child: Stack(
          children: [
            _blob(
              Alignment(-0.85 + dx, -0.95 + dy),
              Colors.white,
              alpha: 0.55,
              size: 620,
            ),
            _blob(
              Alignment(0.95 - dx, 0.9 - dy),
              AppTheme.accent2,
              alpha: 0.30,
              size: 520,
            ),
          ],
        ),
      ),
    );
  }

  Widget _blob(Alignment align, Color color,
      {required double alpha, required double size}) {
    return Align(
      alignment: align,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color.withValues(alpha: alpha),
              color.withValues(alpha: 0)
            ],
          ),
        ),
      ),
    );
  }
}
