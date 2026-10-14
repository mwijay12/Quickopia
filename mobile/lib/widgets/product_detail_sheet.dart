import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/product_model.dart';
import '../providers/cart_provider.dart';
import '../providers/catalog_provider.dart';
import '../providers/favorites_provider.dart';
import '../screens/customer/cart_screen.dart';
import '../theme/app_theme.dart';
import '../utils/currency_formatter.dart';
import 'skeleton_loading.dart';

class ProductDetailSheet extends StatefulWidget {
  final Product product;

  const ProductDetailSheet({super.key, required this.product});

  static Future<void> show(BuildContext context, Product product) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ProductDetailSheet(product: product),
    );
  }

  @override
  State<ProductDetailSheet> createState() => _ProductDetailSheetState();
}

class _ProductDetailSheetState extends State<ProductDetailSheet> {
  int _selectedQty = 1;
  int _selectedPhotoIndex = 0;
  int _selectedVariantIndex = 1; // 1kg Standard

  static const List<Map<String, dynamic>> _packagingVariants = [
    {'name': '500g Trial', 'multiplier': 0.55, 'unit': '500g'},
    {'name': '1kg Standard', 'multiplier': 1.0, 'unit': '1kg'},
    {'name': '2kg Family', 'multiplier': 1.9, 'unit': '2kg', 'badge': 'SAVE 5%'},
    {'name': '5kg Value', 'multiplier': 4.6, 'unit': '5kg', 'badge': 'SAVE 8%'},
  ];

  @override
  void initState() {
    super.initState();
    if (!widget.product.isInStock) {
      _selectedQty = 0;
    }
  }

  void _incrementQty() {
    final maxAllowed = widget.product.stockQuantity;
    if (_selectedQty < maxAllowed) {
      setState(() => _selectedQty++);
    } else {
      HapticFeedback.lightImpact();
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.orange.shade800,
          duration: const Duration(seconds: 2),
          content: Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Zimebaki units $maxAllowed tu kwenye stoo! (Max stock limit reached)',
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  void _decrementQty() {
    if (_selectedQty > 1) {
      setState(() => _selectedQty--);
    }
  }

  Future<void> _showCustomQuantityDialog() async {
    final maxAllowed = widget.product.stockQuantity;
    final controller = TextEditingController(text: '$_selectedQty');
    final result = await showDialog<int>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.edit_note_rounded, color: AppTheme.primaryNavy, size: 22),
            SizedBox(width: 8),
            Text(
              'Set Quantity / Weka Idadi',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryNavy,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              autofocus: true,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                labelText: 'Quantity / Idadi',
                hintText: 'e.g. 10',
                suffixText: 'Max: $maxAllowed',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppTheme.primaryNavy, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Stoo iliyopo dukani: $maxAllowed units',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel / Ghairi'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentAmber,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              final val = int.tryParse(controller.text.trim());
              if (val != null) {
                Navigator.pop(dialogCtx, val);
              }
            },
            child: const Text('Confirm / Sawa', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (result != null && mounted) {
      if (result <= 0) {
        setState(() => _selectedQty = 1);
      } else if (result > maxAllowed) {
        setState(() => _selectedQty = maxAllowed);
        HapticFeedback.lightImpact();
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.orange.shade800,
            content: Text(
              'Kiasi kimepunguzwa hadi $maxAllowed (kikomo cha stoo iliyopo).',
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        setState(() => _selectedQty = result);
      }
    }
  }

  void _handleAddToCart() {
    if (!widget.product.isInStock || _selectedQty <= 0) return;

    final cart = context.read<CartProvider>();
    final currentInCart = cart.quantityOf(widget.product.id);
    final maxAvailable = widget.product.stockQuantity;

    if (currentInCart + _selectedQty > maxAvailable) {
      final canAdd = maxAvailable - currentInCart;
      if (canAdd <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red.shade700,
            content: Text(
              'Tayari una units $currentInCart kwenye kikapu (Kikomo cha stoo ni $maxAvailable).',
            ),
          ),
        );
        return;
      }
    }

    final variant = _packagingVariants[_selectedVariantIndex];
    final double mult = variant['multiplier'] as double;
    final double variantPrice = (widget.product.priceTzs * mult).roundToDouble();
    final customProduct = widget.product.copyWith(
      priceTzs: variantPrice,
      unit: variant['unit'] as String,
    );

    final added = cart.addItem(customProduct, quantity: _selectedQty);
    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppTheme.accentGreen,
        duration: const Duration(seconds: 3),
        content: Text(
          'Added $added x ${widget.product.title} (${variant['name']}) to your cart!',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        action: SnackBarAction(
          label: 'VIEW CART',
          textColor: Colors.white,
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const CartScreen()),
            );
          },
        ),
      ),
    );
  }

  void _handleShareProduct() {
    final text = 'Check out ${widget.product.title} at Quickopia Supermarket for ${CurrencyFormatter.formatTzs(widget.product.priceTzs)}!';
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text('Product details copied to clipboard!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final favorites = Provider.of<FavoritesProvider?>(context);
    final isFav = favorites?.isFavorite(product.id) ?? false;
    final catalog = Provider.of<CatalogProvider?>(context);
    final similarProducts = catalog?.products
        .where((p) => p.categoryId == product.categoryId && p.id != product.id)
        .take(6)
        .toList() ?? [];

    final gallery = product.displayGallery;
    final currentImage = gallery.isNotEmpty
        ? gallery[_selectedPhotoIndex.clamp(0, gallery.length - 1)]
        : null;

    final selectedVariant = _packagingVariants[_selectedVariantIndex];
    final double mult = selectedVariant['multiplier'] as double;
    final double effectiveUnitPrice = (product.priceTzs * mult).roundToDouble();
    final lineTotal = effectiveUnitPrice * _selectedQty;

    final topPadding = MediaQuery.of(context).padding.top;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height - topPadding - 12,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        top: true,
        child: Column(
          children: [
            // Pinned Fixed Header obeying status bar
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 10, bottom: 4),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryOrange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'QUICKOPIA EXPRESS',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                        color: AppTheme.primaryOrange,
                      ),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.share_outlined, size: 20, color: Colors.grey),
                    tooltip: 'Share Product',
                    onPressed: _handleShareProduct,
                  ),
                  IconButton(
                    icon: Icon(
                      isFav ? Icons.favorite : Icons.favorite_border,
                      size: 22,
                      color: isFav ? Colors.red : Colors.grey.shade700,
                    ),
                    tooltip: isFav ? 'Remove from favorites' : 'Add to favorites',
                    onPressed: () {
                      favorites?.toggleFavorite(product.id);
                      HapticFeedback.lightImpact();
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 22, color: Colors.grey),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFF1F5F9)),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 8),


              // Hero Image with low stock overlay
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Stack(
                  children: [
                    Container(
                      height: 220,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: currentImage != null && currentImage.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: currentImage,
                              fit: BoxFit.contain,
                              fadeInDuration: const Duration(milliseconds: 200),
                              placeholder: (context, url) => const ShimmerSkeleton(borderRadius: 0),
                              errorWidget: (_, __, ___) => _placeholderImage(),
                            )
                          : _placeholderImage(),
                    ),
                    // Rating overlay pill on image
                    Positioned(
                      top: 10,
                      left: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.75),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star, color: Colors.amber, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              product.displayRating.toStringAsFixed(1),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 3),
                            Text(
                              '(${product.displayReviewCount})',
                              style: TextStyle(
                                color: Colors.grey.shade300,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Stock badge overlay
                    Positioned(
                      bottom: 10,
                      right: 10,
                      child: _stockPill(product),
                    ),
                  ],
                ),
              ),

              // Optional Thumbnails (if multiple images)
              if (gallery.length > 1)
                Padding(
                  padding: const EdgeInsets.only(top: 10, left: 16, right: 16),
                  child: SizedBox(
                    height: 50,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: gallery.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, idx) {
                        final isSelected = idx == _selectedPhotoIndex;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedPhotoIndex = idx),
                          child: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelected ? AppTheme.accentAmber : Colors.grey.shade300,
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: CachedNetworkImage(
                              imageUrl: gallery[idx],
                              fit: BoxFit.cover,
                              memCacheWidth: 100,
                              fadeInDuration: const Duration(milliseconds: 150),
                              placeholder: (context, url) => const ShimmerSkeleton(borderRadius: 0),
                              errorWidget: (_, __, ___) => const Icon(Icons.image, size: 20),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),

              const SizedBox(height: 16),

              // Title, Unit & Price
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryNavy,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (product.unit != null && product.unit!.isNotEmpty)
                      Text(
                        'Unit: ${product.unit}',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                      ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          CurrencyFormatter.formatTzs(effectiveUnitPrice),
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryNavy,
                          ),
                        ),
                        if (product.isInStock)
                          Text(
                            'Available: ${product.stockQuantity} units',
                            style: TextStyle(
                              fontSize: 12,
                              color: product.stockQuantity <= 5
                                  ? Colors.orange.shade800
                                  : Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Packaging & Size Variations Selector
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Packaging & Size Options / Chaguzi za Ufungashaji:',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryNavy,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: List.generate(_packagingVariants.length, (idx) {
                        final v = _packagingVariants[idx];
                        final isSelected = _selectedVariantIndex == idx;
                        final vPrice = (product.priceTzs * (v['multiplier'] as double)).roundToDouble();

                        return InkWell(
                          onTap: () {
                            setState(() => _selectedVariantIndex = idx);
                            HapticFeedback.selectionClick();
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected ? AppTheme.primaryNavy : Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected ? AppTheme.primaryNavy : Colors.grey.shade300,
                                width: isSelected ? 1.5 : 1,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      v['name'] as String,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: isSelected ? Colors.white : AppTheme.primaryNavy,
                                      ),
                                    ),
                                    if (v['badge'] != null) ...[
                                      const SizedBox(width: 4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
                                        decoration: BoxDecoration(
                                          color: isSelected ? AppTheme.accentAmber : Colors.orange.shade100,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          v['badge'] as String,
                                          style: TextStyle(
                                            fontSize: 8,
                                            fontWeight: FontWeight.w900,
                                            color: isSelected ? Colors.black : Colors.orange.shade900,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  CurrencyFormatter.formatTzs(vPrice),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: isSelected ? AppTheme.accentAmber : Colors.grey.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),

              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Divider(),
              ),

              // Description
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Description / Maelezo ya Bidhaa',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryNavy,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      product.description != null && product.description!.trim().isNotEmpty
                          ? product.description!
                          : 'High-quality authentic product sourced directly for Quickopia shoppers. Packaged safely and delivered fresh or ready for fast express pickup at store.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),

              // Similar Products & Alternative Options (Alibaba Style)
              if (similarProducts.isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Divider(),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Similar Products & Options / Bidhaa Zinazofanana',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryNavy,
                        ),
                      ),
                      Text(
                        '${similarProducts.length} items',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 155,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    scrollDirection: Axis.horizontal,
                    itemCount: similarProducts.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (ctx, idx) {
                      final item = similarProducts[idx];
                      return InkWell(
                        onTap: () {
                          Navigator.pop(context);
                          ProductDetailSheet.show(context, item);
                        },
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          width: 120,
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                height: 75,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: item.imageUrl != null && item.imageUrl!.isNotEmpty
                                    ? Image.network(
                                        item.imageUrl!,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => const Icon(Icons.image, size: 24),
                                      )
                                    : const Icon(Icons.image, size: 24),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                item.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryNavy,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                CurrencyFormatter.formatTzs(item.priceTzs),
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.primaryOrange,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],

              const SizedBox(height: 16),

              // Quantity Selector & Add to Cart Action Bar
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  border: Border(top: BorderSide(color: Colors.grey.shade200)),
                ),
                child: Column(
                  children: [
                    if (product.isInStock) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Quantity / Idadi:',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: AppTheme.primaryNavy,
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove, size: 18),
                                  onPressed: _selectedQty > 1 ? _decrementQty : null,
                                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                                  padding: EdgeInsets.zero,
                                ),
                                Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: _showCustomQuantityDialog,
                                    borderRadius: BorderRadius.circular(6),
                                    child: Container(
                                      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                                      alignment: Alignment.center,
                                      padding: const EdgeInsets.symmetric(horizontal: 4),
                                      child: Text(
                                        '$_selectedQty',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.add, size: 18),
                                  onPressed: _selectedQty < product.stockQuantity ? _incrementQty : null,
                                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                                  padding: EdgeInsets.zero,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                    ],

                    // Add to Cart Button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: product.isInStock ? _handleAddToCart : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: product.isInStock ? AppTheme.accentAmber : Colors.grey.shade400,
                          foregroundColor: Colors.black87,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: product.isInStock
                            ? Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.shopping_cart_outlined, size: 18),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      'Add to Cart · ${CurrencyFormatter.formatTzs(lineTotal)}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : const Text(
                                'Out of Stock / Haipatikani Stoo',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ],
  ),
),
);
}

  Widget _stockPill(Product product) {
    if (!product.isInStock) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.red.shade700,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Text(
          'Out of Stock',
          style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
        ),
      );
    }

    if (product.stockQuantity <= 5) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.orange.shade800,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          'Only ${product.stockQuantity} left!',
          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.accentGreen,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        '✓ ${product.stockQuantity} in stock',
        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _placeholderImage() => Container(
        color: Colors.grey.shade100,
        child: Center(
          child: Icon(
            Icons.shopping_bag_outlined,
            size: 54,
            color: Colors.grey.shade400,
          ),
        ),
      );
}
