import 'package:flutter/material.dart';

import '../core/glass.dart';
import '../core/motion.dart';
import '../core/theme.dart';

/// Единый горизонтальный/вертикальный отступ страниц.
const EdgeInsets kPagePadding =
    EdgeInsets.symmetric(horizontal: 20, vertical: 16);

/// Мелкий заголовок-секция (капсом, спокойный, с трекингом).
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          color: AppTheme.muted,
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

/// Карточка из «жидкого стекла»: матовая полупрозрачная поверхность,
/// волосок-граница, верхний блик и мягкая тень; тактильное нажатие при onTap.
class AppCard extends StatelessWidget {
  const AppCard({super.key, required this.child, this.onTap, this.padding});
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    final box = GlassSurface(
      radius: AppTheme.rCard,
      blur: 14,
      padding: padding ?? const EdgeInsets.all(18),
      child: child,
    );
    if (onTap == null) return box;
    return Pressable(onTap: onTap, scale: 0.98, child: box);
  }
}

/// Таблетка статуса: цветная точка + подпись на мягкой тонированной подложке.
class StatusPill extends StatelessWidget {
  const StatusPill(this.label, {super.key, this.color});
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppTheme.muted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(
                  color: c, fontSize: 12, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

/// Строка «подпись — значение».
class InfoRow extends StatelessWidget {
  const InfoRow(this.label, this.value, {super.key});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(label,
                style: const TextStyle(color: AppTheme.muted, fontSize: 13)),
          ),
          Expanded(
            child: Text(value,
                style:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

/// Прокрутка с вертикальным центрированием: контент не «прилипает» к верху,
/// пустое место снизу не остаётся. На маленьком экране остаётся скроллящейся.
class CenteredScroll extends StatelessWidget {
  const CenteredScroll({
    super.key,
    required this.child,
    this.padding = kPagePadding,
    this.maxWidth = 460,
  });
  final Widget child;
  final EdgeInsets padding;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: padding,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight - padding.vertical,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: child,
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Скелет-плейсхолдер с мягким шиммером. Анимируем только цвет (opacity),
/// при «уменьшенном движении» — статичная подложка.
class Skeleton extends StatefulWidget {
  const Skeleton({
    super.key,
    this.width,
    this.height = 16,
    this.radius = 8,
  });
  final double? width;
  final double height;
  final double radius;

  @override
  State<Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<Skeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1150))
    ..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shape = BorderRadius.circular(widget.radius);
    if (AppMotion.reduced(context)) {
      return Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(color: AppTheme.bgTint, borderRadius: shape),
      );
    }
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) {
        final t = 0.45 + 0.55 * _c.value; // 0.45..1.0
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: Color.lerp(AppTheme.bgTint, AppTheme.line, t),
            borderRadius: shape,
          ),
        );
      },
    );
  }
}

/// Индикатор загрузки: НЕ скроллится (кладётся внутрь внешнего списка).
/// Несколько скелет-карточек, имитирующих будущий контент.
class LoadingView extends StatelessWidget {
  const LoadingView({super.key, this.rows = 3});
  final int rows;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(rows, (i) {
        return Padding(
          padding: EdgeInsets.only(bottom: i == rows - 1 ? 0 : 12),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(AppTheme.rCard),
              border: Border.all(color: AppTheme.line),
            ),
            child: Row(
              children: [
                const Skeleton(width: 42, height: 42, radius: 12),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Skeleton(width: 140, height: 14),
                      SizedBox(height: 10),
                      Skeleton(height: 12),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}

/// Пустое состояние: иконка в тонированном круге + заголовок + подпись +
/// опциональное действие. По центру — чтобы не оставалось пустоты снизу.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
    this.tint,
  });
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    final c = tint ?? AppTheme.accent;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
              color: c.withValues(alpha: 0.10), shape: BoxShape.circle),
          child: Icon(icon, color: c, size: 32),
        ),
        const SizedBox(height: 18),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
              fontSize: 17, fontWeight: FontWeight.w800, letterSpacing: -0.2),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 8),
          Text(
            subtitle!,
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 14, color: AppTheme.muted, height: 1.4),
          ),
        ],
        if (action != null) ...[
          const SizedBox(height: 22),
          action!,
        ],
      ],
    );
  }
}

/// Ошибка: мягкий красный круг, сообщение и кнопка повтора.
class ErrorView extends StatelessWidget {
  const ErrorView(this.message, {super.key, this.onRetry});
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.error_outline_rounded,
      tint: AppTheme.red,
      title: 'Что-то пошло не так',
      subtitle: message,
      action: onRetry == null
          ? null
          : OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 20),
              label: const Text('Повторить'),
            ),
    );
  }
}

/// Плавающий снек в едином стиле (обычный / ошибка).
void showSnack(BuildContext context, String message, {bool error = false}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? AppTheme.red : AppTheme.ink,
      ),
    );
}

/// Латинский логотип-вордмарк «Yo'lGuard» редакторским serif'ом: курсивный
/// «Yo'l» + прямой «Guard». Только латиница — у Instrument Serif нет кириллицы.
class AppWordmark extends StatelessWidget {
  const AppWordmark({super.key, this.size = 34, this.color});
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(children: [
        TextSpan(text: "Yo'l", style: AppTheme.serif(size: size, color: color)),
        TextSpan(
          text: 'Guard',
          style:
              AppTheme.serif(size: size, color: color, style: FontStyle.normal),
        ),
      ]),
    );
  }
}
