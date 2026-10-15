import 'package:flutter/animation.dart';

/// Named motion tokens for Quickopia.
/// All durations and curves should be drawn from here rather than
/// declared inline. This keeps motion consistent and makes app-wide
/// timing changes a one-file edit.
class AppMotion {
  AppMotion._();

  // ── Duration tokens ────────────────────────────────────────────────
  /// 0 ms. For state that should snap instantly.
  static const Duration instant = Duration.zero;

  /// 90 ms. Micro-interaction: checkbox ticks, icon swaps.
  static const Duration fast = Duration(milliseconds: 90);

  /// 200 ms. Standard UI response: button feedback, chip selects.
  static const Duration normal = Duration(milliseconds: 200);

  /// 240 ms. Page transitions, card reveals.
  static const Duration pageTransition = Duration(milliseconds: 240);

  /// 320 ms. Sheet entrance, dialogs.
  static const Duration slow = Duration(milliseconds: 320);

  /// 500 ms. Hero animations, banners.
  static const Duration deliberate = Duration(milliseconds: 500);

  /// 1 200 ms. Looping/continuous animations (shimmer, pulse).
  static const Duration looping = Duration(milliseconds: 1200);

  // ── Stagger ────────────────────────────────────────────────────────
  /// 45 ms per-item stagger step for list/grid reveals.
  static const Duration staggerStep = Duration(milliseconds: 45);

  // ── Curve tokens ───────────────────────────────────────────────────
  /// Default easing for most transitions.
  static const Curve standard = Curves.easeOutCubic;

  /// Decelerate-only: for elements arriving on screen.
  static const Curve decelerate = Curves.decelerate;

  /// Accelerate-only: for elements leaving screen.
  static const Curve accelerate = Curves.easeIn;

  /// Spring-like overshoot for playful surfaces (cart badge, etc.)
  static const Curve spring = Curves.elasticOut;

  /// Fade curve — used for opacity-only transitions.
  static const Curve fade = Curves.easeInOut;
}
