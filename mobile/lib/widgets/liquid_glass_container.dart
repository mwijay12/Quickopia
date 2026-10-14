import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Reusable Liquid Glass (Glassmorphic) Container.
/// Applies a frosted backdrop blur, specular gradient highlights, and a crisp border.
class LiquidGlassContainer extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final double blur;
  final Color? baseColor;
  final Color? borderColor;
  final double borderWidth;
  final List<BoxShadow>? shadows;
  final Gradient? gradient;

  const LiquidGlassContainer({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.borderRadius = AppTheme.radiusMd,
    this.blur = 14.0,
    this.baseColor,
    this.borderColor,
    this.borderWidth = 1.2,
    this.shadows,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveBorderColor =
        borderColor ?? Colors.white.withValues(alpha: 0.28);
    final effectiveGradient = gradient ??
        LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            baseColor?.withValues(alpha: 0.22) ?? Colors.white.withValues(alpha: 0.18),
            baseColor?.withValues(alpha: 0.08) ?? Colors.white.withValues(alpha: 0.06),
          ],
        );

    Widget content = Container(
      width: width,
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        gradient: effectiveGradient,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: effectiveBorderColor,
          width: borderWidth,
        ),
        boxShadow: shadows ??
            [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
      ),
      child: child,
    );

    // Apply BackdropFilter blur if blur > 0
    if (blur > 0) {
      content = ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: content,
        ),
      );
    }

    if (margin != null) {
      content = Padding(padding: margin!, child: content);
    }

    return content;
  }
}

/// A tappable Liquid Glass Card with smooth ripple and depth
class LiquidGlassCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final Color? baseColor;
  final Color? borderColor;
  final double blur;

  const LiquidGlassCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.borderRadius = AppTheme.radiusMd,
    this.baseColor,
    this.borderColor,
    this.blur = 14.0,
  });

  @override
  Widget build(BuildContext context) {
    final widget = LiquidGlassContainer(
      borderRadius: borderRadius,
      blur: blur,
      baseColor: baseColor,
      borderColor: borderColor,
      margin: margin,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(borderRadius),
          onTap: onTap,
          child: Padding(
            padding: padding,
            child: child,
          ),
        ),
      ),
    );

    return widget;
  }
}

/// A compact Liquid Glass pill badge
class LiquidGlassBadge extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final Color? borderColor;

  const LiquidGlassBadge({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    this.color,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return LiquidGlassContainer(
      borderRadius: 30,
      blur: 8,
      padding: padding,
      baseColor: color ?? AppTheme.accentAmber,
      borderColor: borderColor ?? (color ?? AppTheme.accentAmber).withValues(alpha: 0.4),
      borderWidth: 1.0,
      child: child,
    );
  }
}
