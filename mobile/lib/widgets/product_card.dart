import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/product_model.dart';
import '../providers/cart_provider.dart';
import '../providers/favorites_provider.dart';
import '../theme/app_theme.dart';
import '../utils/currency_formatter.dart';
import 'product_detail_sheet.dart';
import 'quantity_stepper.dart';
import 'skeleton_loading.dart';

class ProductCard extends StatelessWidget {
  final Product product;

  const ProductCard({super.key, required this.product});

  void _openDetails(BuildContext context) {
    ProductDetailSheet.show(context, product);
  }

  @override
  Widget build(BuildContext context) {
    final favorites = Provider.of<FavoritesProvider?>(context);
    final isFav = favorites?.isFavorite(product.id) ?? false;

    return Card(
      elevation: 1,
      shadowColor: Colors.black.withValues(alpha: 0.06),
      color: AppTheme.cardSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openDetails(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Stack with Badges & Action Overlays (Furniking style)
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 1.15,
                  child: product.imageUrl != null && product.imageUrl!.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: product.imageUrl!,
                          fit: BoxFit.cover,
                          memCacheWidth: 400,
                          fadeInDuration: const Duration(milliseconds: 200),
                          placeholder: (context, url) => const ShimmerSkeleton(borderRadius: 0),
                          errorWidget: (_, __, ___) => _placeholderImage(),
                        )
                      : _placeholderImage(),
                ),

                // Top-Left: Rating Badge or Urgency Pill
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.68),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star_rounded, color: Colors.amber, size: 13),
                        const SizedBox(width: 2),
                        Text(
                          product.displayRating.toStringAsFixed(1),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Top-Right: Favorite / Love Icon
                Positioned(
                  top: 6,
                  right: 6,
                  child: Material(
                    color: Colors.white.withValues(alpha: 0.9),
                    shape: const CircleBorder(),
                    elevation: 1,
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () {
                        HapticFeedback.lightImpact();
                        favorites?.toggleFavorite(product.id);
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(5),
                        child: Icon(
                          isFav ? Icons.favorite : Icons.favorite_border,
                          size: 17,
                          color: isFav ? Colors.red : Colors.grey.shade700,
                        ),
                      ),
                    ),
                  ),
                ),

                // Bottom-Right of Image: Eye Icon (Quick View Preview)
                Positioned(
                  bottom: 6,
                  right: 6,
                  child: Material(
                    color: Colors.white.withValues(alpha: 0.9),
                    shape: const CircleBorder(),
                    elevation: 1,
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => _openDetails(context),
                      child: const Padding(
                        padding: EdgeInsets.all(5),
                        child: Icon(
                          Icons.visibility_outlined,
                          size: 16,
                          color: AppTheme.primaryNavy,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Product Details
            Padding(
              padding: const EdgeInsets.fromLTRB(9, 8, 9, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 12.5,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  if (product.unit != null && product.unit!.isNotEmpty)
                    Text(
                      product.unit!,
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 10.5),
                    ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          CurrencyFormatter.formatTzs(product.priceTzs),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12.5,
                            color: AppTheme.primaryNavy,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      _cartControl(context),
                    ],
                  ),
                  if (!product.isInStock)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'Out of stock',
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    )
                  else if (product.stockQuantity <= 5)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'Only ${product.stockQuantity} left!',
                        style: TextStyle(
                          color: Colors.orange.shade800,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholderImage() => Container(
        color: Colors.grey.shade100,
        child: Center(
          child: Icon(
            Icons.shopping_bag_outlined,
            size: 36,
            color: Colors.grey.shade400,
          ),
        ),
      );

  Widget _cartControl(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final quantity = cart.quantityOf(product.id);

    if (!product.isInStock) {
      return Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(Icons.add, size: 16, color: Colors.grey.shade500),
      );
    }

    if (quantity == 0) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.read<CartProvider>().addItem(product),
          customBorder: const CircleBorder(),
          child: Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(Icons.add, size: 16, color: Colors.white),
          ),
        ),
      );
    }

    return QuantityStepper(
      quantity: quantity,
      maxQuantity: product.stockQuantity,
      canIncrement: quantity < product.stockQuantity,
      onCustomQuantitySet: (val) {
        final actual = context.read<CartProvider>().setQuantity(product.id, val);
        if (val > product.stockQuantity) {
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.orange.shade800,
              content: Text(
                'Kiasi kimepunguzwa hadi $actual (kikomo cha stoo: ${product.stockQuantity})',
              ),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      },
      onIncrement: () {
        if (quantity < product.stockQuantity) {
          context.read<CartProvider>().increment(product.id);
        } else {
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.orange.shade800,
              content: Text(
                'Zimebaki units ${product.stockQuantity} tu! (Max stock limit reached)',
              ),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      },
      onDecrement: () => context.read<CartProvider>().decrement(product.id),
    );
  }
}
