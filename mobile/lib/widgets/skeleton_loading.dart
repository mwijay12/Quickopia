import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Reusable animated shimmer skeleton container.
class ShimmerSkeleton extends StatefulWidget {
  final double? width;
  final double? height;
  final double borderRadius;
  final BoxShape shape;
  final EdgeInsetsGeometry? margin;

  const ShimmerSkeleton({
    super.key,
    this.width,
    this.height,
    this.borderRadius = 8,
    this.shape = BoxShape.rectangle,
    this.margin,
  });

  const ShimmerSkeleton.circular({
    super.key,
    required double size,
    this.margin,
  })  : width = size,
        height = size,
        borderRadius = 0,
        shape = BoxShape.circle;

  @override
  State<ShimmerSkeleton> createState() => _ShimmerSkeletonState();
}

class _ShimmerSkeletonState extends State<ShimmerSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? const Color(0xFF1E242B) : const Color(0xFFE8ECEF);
    final highlightColor =
        isDark ? const Color(0xFF2A323D) : const Color(0xFFF7F9FA);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          margin: widget.margin,
          decoration: BoxDecoration(
            shape: widget.shape,
            borderRadius: widget.shape == BoxShape.rectangle
                ? BorderRadius.circular(widget.borderRadius)
                : null,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              stops: [
                (_controller.value - 0.3).clamp(0.0, 1.0),
                _controller.value.clamp(0.0, 1.0),
                (_controller.value + 0.3).clamp(0.0, 1.0),
              ],
              colors: [
                baseColor,
                highlightColor,
                baseColor,
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Shimmer skeleton for the Parallax Hero Banner carousel.
class SkeletonBanner extends StatelessWidget {
  const SkeletonBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 165,
      margin: const EdgeInsets.symmetric(horizontal: 5),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ShimmerSkeleton(width: 90, height: 16, borderRadius: 6),
          SizedBox(height: 10),
          ShimmerSkeleton(width: 210, height: 22, borderRadius: 6),
          SizedBox(height: 6),
          ShimmerSkeleton(width: 150, height: 18, borderRadius: 6),
          SizedBox(height: 12),
          ShimmerSkeleton(width: 110, height: 26, borderRadius: 20),
        ],
      ),
    );
  }
}

/// Shimmer skeleton for the horizontal category avatar chips.
class SkeletonCategoryList extends StatelessWidget {
  const SkeletonCategoryList({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 86,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 2),
        itemCount: 6,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (context, i) {
          return const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ShimmerSkeleton.circular(size: 52),
              SizedBox(height: 6),
              ShimmerSkeleton(width: 46, height: 10, borderRadius: 4),
            ],
          );
        },
      ),
    );
  }
}

/// Shimmer skeleton for a single product card.
class SkeletonProductCard extends StatelessWidget {
  const SkeletonProductCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0.5,
      color: AppTheme.cardSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      clipBehavior: Clip.antiAlias,
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 1.15,
            child: ShimmerSkeleton(borderRadius: 0),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(9, 8, 9, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerSkeleton(width: double.infinity, height: 13, borderRadius: 4),
                SizedBox(height: 4),
                ShimmerSkeleton(width: 80, height: 13, borderRadius: 4),
                SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ShimmerSkeleton(width: 65, height: 16, borderRadius: 4),
                    ShimmerSkeleton(width: 32, height: 32, borderRadius: 16),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Shimmer skeleton grid for initial storefront product loading.
class SkeletonProductGrid extends StatelessWidget {
  final int count;

  const SkeletonProductGrid({super.key, this.count = 6});

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.64,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, i) => const SkeletonProductCard(),
          childCount: count,
        ),
      ),
    );
  }
}

/// Shimmer skeleton for chat message thread.
class SkeletonChatMessages extends StatelessWidget {
  const SkeletonChatMessages({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Incoming support bubble
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const ShimmerSkeleton.circular(size: 28),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const ShimmerSkeleton(width: 70, height: 10, borderRadius: 4),
                  const SizedBox(height: 6),
                  Container(
                    width: 220,
                    height: 54,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(16),
                        bottomLeft: Radius.circular(16),
                        bottomRight: Radius.circular(16),
                      ),
                    ),
                    padding: const EdgeInsets.all(10),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ShimmerSkeleton(width: 190, height: 10, borderRadius: 4),
                        SizedBox(height: 6),
                        ShimmerSkeleton(width: 120, height: 10, borderRadius: 4),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Outgoing customer bubble
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              width: 180,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              padding: const EdgeInsets.all(10),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ShimmerSkeleton(width: 150, height: 10, borderRadius: 4),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),

          // Incoming reply bubble
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const ShimmerSkeleton.circular(size: 28),
              const SizedBox(width: 8),
              Container(
                width: 240,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                ),
                padding: const EdgeInsets.all(10),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ShimmerSkeleton(width: 210, height: 10, borderRadius: 4),
                    SizedBox(height: 6),
                    ShimmerSkeleton(width: 160, height: 10, borderRadius: 4),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
