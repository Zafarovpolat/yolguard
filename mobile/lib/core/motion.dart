import 'package:flutter/material.dart';

/// Токены и виджеты движения. Принцип: анимируем только opacity+transform,
/// уважаем «уменьшенное движение» ОС (доступность) — тогда только opacity.
class AppMotion {
  AppMotion._();

  static const Duration instant = Duration(milliseconds: 90);
  static const Duration fast = Duration(milliseconds: 180);
  static const Duration normal = Duration(milliseconds: 320);
  static const Duration slow = Duration(milliseconds: 560);

  static const Curve standard = Cubic(0.22, 1, 0.36, 1); // мягкое замедление
  static const Curve sharp = Cubic(0.4, 0, 0.2, 1);

  /// Шаг каскада для списков/сеток.
  static Duration stagger(int index,
          {Duration step = const Duration(milliseconds: 55)}) =>
      step * index;

  /// Пользователь просит меньше движения (ОС/доступность).
  static bool reduced(BuildContext context) {
    final mq = MediaQuery.maybeOf(context);
    return mq?.disableAnimations == true || mq?.accessibleNavigation == true;
  }
}

/// Появление: лёгкий подъём + прозрачность. При reduced — сразу показываем.
class FadeSlideIn extends StatefulWidget {
  const FadeSlideIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.offset = 14,
  });
  final Widget child;
  final Duration delay;
  final double offset;

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: AppMotion.normal);

  @override
  void initState() {
    super.initState();
    Future.delayed(widget.delay, () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (AppMotion.reduced(context)) return widget.child;
    final a = CurvedAnimation(parent: _c, curve: AppMotion.standard);
    return AnimatedBuilder(
      animation: a,
      builder: (_, child) => Opacity(
        opacity: a.value.clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(0, widget.offset * (1 - a.value)),
          child: child,
        ),
      ),
      child: widget.child,
    );
  }
}

/// Тактильное нажатие: лёгкий масштаб. Гарантирует зону нажатия ≥44px.
class Pressable extends StatefulWidget {
  const Pressable(
      {super.key, required this.child, this.onTap, this.scale = 0.97});
  final Widget child;
  final VoidCallback? onTap;
  final double scale;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final reduced = AppMotion.reduced(context);
    final enabled = widget.onTap != null;
    return GestureDetector(
      onTapDown: enabled ? (_) => setState(() => _down = true) : null,
      onTapUp: enabled ? (_) => setState(() => _down = false) : null,
      onTapCancel: enabled ? () => setState(() => _down = false) : null,
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: (_down && !reduced) ? widget.scale : 1,
        duration: AppMotion.fast,
        curve: AppMotion.standard,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
          child: widget.child,
        ),
      ),
    );
  }
}

/// Переход между экранами в духе iOS: плавное проявление + микромасштаб.
/// При «уменьшенном движении» — только opacity, без трансформаций.
class SpringPageTransitionsBuilder extends PageTransitionsBuilder {
  const SpringPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: AppMotion.standard,
      reverseCurve: AppMotion.standard.flipped,
    );
    if (AppMotion.reduced(context)) {
      return FadeTransition(opacity: curved, child: child);
    }
    return FadeTransition(
      opacity: curved,
      child: ScaleTransition(
        scale: Tween<double>(begin: 0.985, end: 1.0).animate(curved),
        child: child,
      ),
    );
  }
}
