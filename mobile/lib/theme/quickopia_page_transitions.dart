import 'package:flutter/material.dart';
import 'app_motion.dart';

/// Quickopia's custom page transition:
/// - 240 ms combined fade + upward slide (rise).
/// - Content is legible at 60 % of the timeline (fade completes early).
/// - Wired through [PageTransitionsTheme] so all 31 existing
///   [MaterialPageRoute] call-sites adopt the new transition with zero edits.
///
/// Design rationale: a shopper navigates catalog → product → cart → checkout
/// dozens of times per session. Material's default zoom transition feels
/// heavy on a path that frequent. A compact rise-and-fade keeps
/// the app feeling snappy without sacrificing visual continuity.
class QuickopiaPageTransitionsBuilder extends PageTransitionsBuilder {
  const QuickopiaPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return QuickopiaReveal(
      animation: animation,
      child: child,
    );
  }
}

/// The actual transition widget: fades in while rising ~14 px.
/// Fade completes at 60 % of [AppMotion.pageTransition] so text is legible
/// long before the slide finishes.
class QuickopiaReveal extends StatelessWidget {
  const QuickopiaReveal({
    super.key,
    required this.animation,
    required this.child,
  });

  final Animation<double> animation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final fade = CurvedAnimation(
      parent: animation,
      // Fade completes at 60 % of the parent timeline.
      curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
    );

    final slide = CurvedAnimation(
      parent: animation,
      curve: AppMotion.standard, // easeOutCubic full duration
    );

    return FadeTransition(
      opacity: fade,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.0, 0.04), // 4 % of screen height (≈ 36 px)
          end: Offset.zero,
        ).animate(slide),
        child: child,
      ),
    );
  }
}

/// A sliver-compatible widget that staggers [children] into view.
/// Only the first [maxStaggered] items receive a delay; items beyond
/// that threshold reveal immediately so scroll performance is not affected.
///
/// Using a maximum of 6 staggered cards prevents the "card #40 always
/// waits its full delay" problem that occurs when staggering by absolute
/// list index on a lazily-built [SliverGrid].
class StaggeredReveal extends StatelessWidget {
  const StaggeredReveal({
    super.key,
    required this.index,
    required this.child,
    this.maxStaggered = 6,
  });

  final int index;
  final Widget child;

  /// Items at or beyond this index use [Duration.zero] delay.
  final int maxStaggered;

  @override
  Widget build(BuildContext context) {
    final delay = index < maxStaggered
        ? AppMotion.staggerStep * index
        : Duration.zero;

    return _DelayedReveal(delay: delay, child: child);
  }
}

class _DelayedReveal extends StatefulWidget {
  const _DelayedReveal({required this.delay, required this.child});

  final Duration delay;
  final Widget child;

  @override
  State<_DelayedReveal> createState() => _DelayedRevealState();
}

class _DelayedRevealState extends State<_DelayedReveal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppMotion.slow, // 320 ms for card reveal
    );

    _opacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.7, curve: Curves.easeIn),
    );

    _slide = Tween<Offset>(
      begin: const Offset(0.0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: AppMotion.standard,
    ));

    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      Future.delayed(widget.delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}
