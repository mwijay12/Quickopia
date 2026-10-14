import 'dart:async';
import 'dart:math' as math;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/hero_banner_model.dart';
import '../providers/admin_provider.dart';
import '../providers/catalog_provider.dart';
import '../theme/app_theme.dart';

class ParallaxHeroBanner extends StatefulWidget {
  final VoidCallback? onSlideTap;

  const ParallaxHeroBanner({super.key, this.onSlideTap});

  @override
  State<ParallaxHeroBanner> createState() => _ParallaxHeroBannerState();
}

class _ParallaxHeroBannerState extends State<ParallaxHeroBanner> {
  late final PageController _pageController;
  int _currentPage = 0;
  Timer? _autoScrollTimer;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.92);
    _startTimer();
  }

  void _startTimer() {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!mounted) return;
      final admin = context.read<AdminProvider?>();
      final count = admin?.heroBannerSlides.length ?? HeroBannerSlide.defaultSlides.length;
      if (_pageController.hasClients && count > 0) {
        final nextPage = (_currentPage + 1) % count;
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _handleSlideTap(HeroBannerSlide slide) {
    HapticFeedback.lightImpact();
    final catalog = context.read<CatalogProvider?>();
    if (catalog == null) return;

    // Determine target category
    String? target = slide.targetCategory?.trim();
    if (target == null || target.isEmpty) {
      final combined =
          '${slide.title} ${slide.subtitle} ${slide.tag} ${slide.actionLabel}'
              .toLowerCase();
      if (combined.contains('veggie') ||
          combined.contains('vegetable') ||
          combined.contains('mboga') ||
          combined.contains('produce')) {
        target = 'Fresh Produce';
      } else if (combined.contains('bakery') ||
          combined.contains('bread') ||
          combined.contains('mkate')) {
        target = 'Bakery';
      } else if (combined.contains('dairy') ||
          combined.contains('milk') ||
          combined.contains('maziwa') ||
          combined.contains('egg')) {
        target = 'Dairy & Eggs';
      } else if (combined.contains('beverage') ||
          combined.contains('drink') ||
          combined.contains('juice') ||
          combined.contains('vinywaji')) {
        target = 'Beverages';
      }
    }

    if (target != null && target.isNotEmpty) {
      final targetLower = target.toLowerCase();
      final matchedCat = catalog.categories.cast<dynamic>().firstWhere(
        (c) =>
            c.id == target ||
            c.name.toLowerCase() == targetLower ||
            c.name.toLowerCase().contains(targetLower) ||
            targetLower.contains(c.name.toLowerCase()) ||
            (c.nameSw != null &&
                (c.nameSw!.toLowerCase().contains(targetLower) ||
                    targetLower.contains(c.nameSw!.toLowerCase()))),
        orElse: () => null,
      );

      if (matchedCat != null) {
        catalog.selectCategory(matchedCat.id);
      } else {
        catalog.search(target);
      }
    }

    widget.onSlideTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider?>();
    final slides = (admin != null && admin.heroBannerSlides.isNotEmpty)
        ? admin.heroBannerSlides
        : HeroBannerSlide.defaultSlides;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 165,
          child: PageView.builder(
            controller: _pageController,
            clipBehavior: Clip.none,
            itemCount: slides.length,
            onPageChanged: (idx) => setState(() => _currentPage = idx),
            itemBuilder: (context, index) {
              final slide = slides[index];

              return AnimatedBuilder(
                animation: _pageController,
                builder: (context, child) {
                  double pageOffset = 0;
                  if (_pageController.position.haveDimensions &&
                      _pageController.page != null) {
                    pageOffset = _pageController.page! - index;
                  }

                  // Mathematical Gauss curve parallax shift
                  final double gauss =
                      math.exp(-(math.pow((pageOffset.abs() - 0.5), 2) / 0.1));
                  final double translationOffset =
                      -20 * gauss * pageOffset.sign;

                  return Transform.translate(
                    offset: Offset(translationOffset, 0),
                    child: child,
                  );
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 5),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: slide.gradient,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: slide.gradient.first.withValues(alpha: 0.35),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _handleSlideTap(slide),
                      child: Stack(
                        children: [
                          // Background picture with optical parallax translation & cached network image
                          if (slide.imageUrl != null &&
                              slide.imageUrl!.trim().isNotEmpty) ...[
                            Positioned.fill(
                              child: AnimatedBuilder(
                                animation: _pageController,
                                builder: (context, _) {
                                  double pageOffset = 0;
                                  if (_pageController.position.haveDimensions &&
                                      _pageController.page != null) {
                                    pageOffset = _pageController.page! - index;
                                  }
                                  return Transform.translate(
                                    offset: Offset(pageOffset * -30, 0),
                                    child: Transform.scale(
                                      scale: 1.25,
                                      child: CachedNetworkImage(
                                        imageUrl: slide.imageUrl!,
                                        fit: BoxFit.cover,
                                        memCacheWidth: 800,
                                        fadeInDuration:
                                            const Duration(milliseconds: 250),
                                        errorWidget: (_, __, ___) =>
                                            const SizedBox.shrink(),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            // Dark gradient overlay scrim for sharp typography contrast
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                    colors: [
                                      Colors.black.withValues(alpha: 0.88),
                                      Colors.black.withValues(alpha: 0.65),
                                      Colors.black.withValues(alpha: 0.35),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],

                          // Decorative background circles
                          Positioned(
                            right: -24,
                            bottom: -24,
                            child: Container(
                              width: 140,
                              height: 140,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withValues(alpha: 0.05),
                              ),
                            ),
                          ),

                          // Parallax shifted Icon emblem
                          Positioned(
                            right: 14,
                            top: 20,
                            child: AnimatedBuilder(
                              animation: _pageController,
                              builder: (context, _) {
                                double pageOffset = 0;
                                if (_pageController.position.haveDimensions &&
                                    _pageController.page != null) {
                                  pageOffset = _pageController.page! - index;
                                }
                                return Transform.translate(
                                  offset: Offset(pageOffset * 30, 0),
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      slide.icon,
                                      size: 42,
                                      color: slide.badgeColor
                                          .withValues(alpha: 0.85),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),

                          // Text Content
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Tag Badge
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: slide.badgeColor
                                        .withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: slide.badgeColor
                                          .withValues(alpha: 0.5),
                                      width: 0.8,
                                    ),
                                  ),
                                  child: Text(
                                    slide.tag,
                                    style: TextStyle(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.8,
                                      color: slide.badgeColor,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 6),

                                // Display Title
                                Text(
                                  slide.title,
                                  style: const TextStyle(
                                    fontSize: 16.5,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    height: 1.15,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                                const SizedBox(height: 4),

                                // Subtitle
                                Text(
                                  slide.subtitle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.white.withValues(alpha: 0.75),
                                  ),
                                ),
                                const SizedBox(height: 10),

                                // Action Chip
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.15),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        slide.actionLabel,
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.6,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),

        // Animated Dot Indicators
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(slides.length, (idx) {
            final isActive = idx == _currentPage;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: isActive ? 20 : 6,
              height: 5,
              decoration: BoxDecoration(
                color: isActive ? AppTheme.primaryOrange : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(3),
              ),
            );
          }),
        ),
      ],
    );
  }
}
