import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/hero_banner_model.dart';
import '../../models/order_model.dart';
import '../../models/product_model.dart';
import '../../providers/admin_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/currency_formatter.dart';
import '../../widgets/liquid_glass_container.dart';
import '../../widgets/order_receipt_sheet.dart';
import '../../widgets/order_status_badge.dart';

class AdminInAppScreen extends StatefulWidget {
  const AdminInAppScreen({super.key});

  @override
  State<AdminInAppScreen> createState() => _AdminInAppScreenState();
}

class _AdminInAppScreenState extends State<AdminInAppScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().loadData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: AppTheme.brandOrangeGradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Supermarket Admin Console',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 18,
                color: Colors.white,
                letterSpacing: -0.3,
              ),
            ),
            Text(
              'Manage Store Catalog, Live Pricing & Orders',
              style: TextStyle(
                fontSize: 11,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            tooltip: 'Refresh Data',
            onPressed: () => context.read<AdminProvider>().loadData(),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [
            Tab(icon: Icon(Icons.dashboard_rounded, size: 18), text: 'Orders & KPI'),
            Tab(icon: Icon(Icons.inventory_2_rounded, size: 18), text: 'Inventory & Pricing'),
            Tab(icon: Icon(Icons.view_carousel_rounded, size: 18), text: 'Hero Banners'),
          ],
        ),
      ),
      body: admin.status == AdminStatus.loading && admin.orders.isEmpty
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryOrange),
              ),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOrdersTab(context, admin),
                _buildInventoryTab(context, admin),
                _buildHeroBannersTab(context, admin),
              ],
            ),
    );
  }

  // TAB 1: ORDERS & KPI DASHBOARD
  Widget _buildOrdersTab(BuildContext context, AdminProvider admin) {
    final stats = admin.stats;

    return RefreshIndicator(
      onRefresh: () => admin.loadData(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 4 KPI Metric Cards in 2x2 Grid
          Row(
            children: [
              Expanded(
                child: _buildKpiCard(
                  title: "Today's Sales",
                  value: CurrencyFormatter.formatTzs(stats.totalRevenueTzs),
                  icon: Icons.payments_rounded,
                  color: Colors.green.shade700,
                  badge: 'Revenue',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildKpiCard(
                  title: 'Total Orders',
                  value: '${stats.totalOrders} Orders',
                  icon: Icons.shopping_basket_rounded,
                  color: AppTheme.primaryNavy,
                  badge: 'All Orders',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildKpiCard(
                  title: 'Out for Delivery',
                  value: '${stats.outForDeliveryCount} En Route',
                  icon: Icons.delivery_dining_rounded,
                  color: Colors.teal.shade700,
                  badge: 'With Drivers',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildKpiCard(
                  title: 'Low Stock Alert',
                  value: '${stats.lowStockCount} Product${stats.lowStockCount == 1 ? '' : 's'}',
                  icon: Icons.warning_amber_rounded,
                  color: stats.lowStockCount > 0 ? Colors.red.shade700 : Colors.grey,
                  badge: 'Stock (<10)',
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _filterChip(admin, 'all', 'All (${admin.orders.length})'),
                _filterChip(admin, 'placed', 'Placed (${stats.placedCount})'),
                _filterChip(admin, 'packing', 'Packing (${stats.packingCount})'),
                _filterChip(admin, 'ready', 'Ready (${stats.readyCount})'),
                _filterChip(admin, 'out_for_delivery', 'En Route (${stats.outForDeliveryCount})'),
                _filterChip(admin, 'delivered', 'Delivered (${stats.deliveredCount})'),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Orders List
          if (admin.filteredOrders.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 40),
              alignment: Alignment.center,
              child: const Column(
                children: [
                  Icon(Icons.inbox_outlined, size: 48, color: Colors.grey),
                  SizedBox(height: 8),
                  Text('No orders found in this stage.', style: TextStyle(color: Colors.grey)),
                ],
              ),
            )
          else
            ...admin.filteredOrders.map((o) => _buildOrderAdminTile(context, o)),
        ],
      ),
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required String badge,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  badge,
                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey.shade700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: AppTheme.primaryNavy,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(AdminProvider admin, String statusKey, String label) {
    final isSelected = admin.selectedStatusFilter == statusKey;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => admin.filterOrders(statusKey),
        selectedColor: AppTheme.primaryNavy,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : AppTheme.primaryNavy,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          fontSize: 12,
        ),
        backgroundColor: Colors.white,
        side: BorderSide(
          color: isSelected ? AppTheme.primaryNavy : Colors.grey.shade300,
        ),
      ),
    );
  }

  Widget _buildOrderAdminTile(BuildContext context, Order order) {
    final date = DateFormat('d MMM, HH:mm').format(order.createdAt.toLocal());
    final itemsSummary = order.items.map((i) => '${i.title} x${i.quantity}').join(', ');

    return Card(
      elevation: 0.5,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      '#${order.orderNumber}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                        color: AppTheme.primaryNavy,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: order.fulfillmentType == 'pickup'
                            ? Colors.teal.shade50
                            : Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        order.fulfillmentType == 'pickup' ? 'Store Pickup' : 'Doorstep Delivery',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: order.fulfillmentType == 'pickup'
                              ? Colors.teal.shade800
                              : Colors.blue.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
                OrderStatusBadge(status: order.status),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              itemsSummary,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$date · Simu: ${order.customerPhone}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                Text(
                  CurrencyFormatter.formatTzs(order.totalAmountTzs),
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                    color: AppTheme.primaryNavy,
                  ),
                ),
              ],
            ),
            const Divider(height: 18),

            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  icon: const Icon(Icons.receipt_long_outlined, size: 15),
                  label: const Text('Receipt', style: TextStyle(fontSize: 11)),
                  style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    side: BorderSide(color: Colors.grey.shade400),
                  ),
                  onPressed: () => OrderReceiptSheet.show(context, order),
                ),
                const SizedBox(width: 8),
                if (order.status == 'placed')
                  ElevatedButton.icon(
                    icon: const Icon(Icons.inventory_rounded, size: 15, color: Colors.black),
                    label: const Text('Start Packing ➔', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentAmber,
                      foregroundColor: Colors.black,
                      visualDensity: VisualDensity.compact,
                    ),
                    onPressed: () => _updateStatus(context, order.id, 'packing'),
                  )
                else if (order.status == 'packing')
                  ElevatedButton.icon(
                    icon: const Icon(Icons.check_circle_outline, size: 15, color: Colors.white),
                    label: const Text('Ready for Driver ➔', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal.shade700,
                      foregroundColor: Colors.white,
                      visualDensity: VisualDensity.compact,
                    ),
                    onPressed: () => _updateStatus(context, order.id, 'ready'),
                  )
                else if (order.status == 'ready')
                  ElevatedButton.icon(
                    icon: const Icon(Icons.electric_bolt, size: 15, color: Colors.white),
                    label: const Text('Dispatch to Driver ➔', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryOrange,
                      foregroundColor: Colors.white,
                      visualDensity: VisualDensity.compact,
                    ),
                    onPressed: () => _updateStatus(context, order.id, 'out_for_delivery'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateStatus(BuildContext context, String orderId, String newStatus) async {
    final success = await context.read<AdminProvider>().updateOrderStatus(orderId, newStatus);
    if (context.mounted && success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Order status updated to: $newStatus'),
          backgroundColor: Colors.green.shade700,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  // TAB 2: INVENTORY & PRICES
  Widget _buildInventoryTab(BuildContext context, AdminProvider admin) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search products by title to adjust prices or stock...',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onChanged: (q) => admin.searchProducts(q),
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: admin.filteredProducts.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final product = admin.filteredProducts[index];
              final isLow = product.stockQuantity < 10;

              return Card(
                elevation: 0.5,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  side: BorderSide(
                    color: isLow ? Colors.red.shade300 : Colors.grey.shade200,
                  ),
                ),
                child: ListTile(
                  title: Text(
                    product.title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  subtitle: Text(
                    'Price: ${CurrencyFormatter.formatTzs(product.priceTzs)} · Stock: ${product.stockQuantity} units',
                    style: TextStyle(
                      color: isLow ? Colors.red.shade700 : Colors.grey.shade700,
                      fontWeight: isLow ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  trailing: ElevatedButton.icon(
                    icon: const Icon(Icons.edit, size: 14, color: Colors.white),
                    label: const Text('Edit', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryOrange,
                      foregroundColor: Colors.white,
                      visualDensity: VisualDensity.compact,
                    ),
                    onPressed: () => _showEditProductDialog(context, product),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showEditProductDialog(BuildContext context, Product product) {
    final priceController = TextEditingController(text: product.priceTzs.toInt().toString());
    final stockController = TextEditingController(text: product.stockQuantity.toString());
    bool isAvailable = product.isAvailable;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Edit: ${product.title}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: priceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'New Price (TZS)',
                  prefixText: 'TZS ',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: stockController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Stock Quantity (Units)',
                  suffixText: 'units',
                ),
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                title: const Text('Available in Store'),
                value: isAvailable,
                onChanged: (val) => setDialogState(() => isAvailable = val),
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryOrange,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                final newPrice = double.tryParse(priceController.text) ?? product.priceTzs;
                final newStock = int.tryParse(stockController.text) ?? product.stockQuantity;

                final success = await context.read<AdminProvider>().updateProductPriceAndStock(
                      productId: product.id,
                      newPriceTzs: newPrice,
                      newStockQuantity: newStock,
                      isAvailable: isAvailable,
                    );

                if (ctx.mounted) Navigator.pop(ctx);
                if (context.mounted && success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Product "${product.title}" updated successfully!'),
                      backgroundColor: Colors.green.shade700,
                    ),
                  );
                }
              },
              child: const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }

  // TAB 3: HERO BANNERS & GRAPHICS
  Widget _buildHeroBannersTab(BuildContext context, AdminProvider admin) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const LiquidGlassContainer(
          borderRadius: 16,
          blur: 14,
          gradient: LinearGradient(
            colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.view_carousel_rounded, color: AppTheme.primaryOrange, size: 22),
                  SizedBox(width: 8),
                  Text(
                    'Parallax Hero Cards & Graphics',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 6),
              Text(
                'Customize background pictures behind the customer storefront parallax cards. Changes persist and render in real time for all shoppers.',
                style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.3),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        const Text(
          'Active Hero Banner Slides & Backgrounds:',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryNavy,
          ),
        ),
        const SizedBox(height: 12),

        ...List.generate(admin.heroBannerSlides.length, (index) {
          final slide = admin.heroBannerSlides[index];
          return _buildBannerSlideManagerCard(context, admin, index, slide);
        }),
      ],
    );
  }

  Widget _buildBannerSlideManagerCard(
    BuildContext context,
    AdminProvider admin,
    int index,
    HeroBannerSlide slide,
  ) {
    final hasBg = slide.imageUrl != null && slide.imageUrl!.trim().isNotEmpty;

    return Card(
      elevation: 0.5,
      margin: const EdgeInsets.only(bottom: 14),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner Preview Container
          Container(
            height: 110,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: slide.gradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Stack(
              children: [
                if (hasBg)
                  Positioned.fill(
                    child: Image.network(
                      slide.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    ),
                  ),
                if (hasBg)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.black.withValues(alpha: 0.85),
                            Colors.black.withValues(alpha: 0.40),
                          ],
                        ),
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: slide.badgeColor.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: slide.badgeColor, width: 0.8),
                        ),
                        child: Text(
                          slide.tag,
                          style: TextStyle(
                            color: slide.badgeColor,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        slide.title.replaceAll('\n', ' '),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        slide.subtitle,
                        style: const TextStyle(color: Colors.white70, fontSize: 11),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Action Controls
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      hasBg ? Icons.image_outlined : Icons.image_not_supported_outlined,
                      size: 16,
                      color: hasBg ? Colors.green.shade700 : Colors.grey,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      hasBg ? 'Custom Background Active' : 'Default Gradient (No Image)',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: hasBg ? Colors.green.shade700 : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.add_photo_alternate_rounded, size: 14, color: Colors.white),
                  label: Text(
                    hasBg ? 'Change Pic' : 'Add BG Pic',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryOrange,
                    foregroundColor: Colors.white,
                    visualDensity: VisualDensity.compact,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () => _showEditBannerBgDialog(context, admin, index, slide),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showEditBannerBgDialog(
    BuildContext context,
    AdminProvider admin,
    int index,
    HeroBannerSlide slide,
  ) {
    final urlCtrl = TextEditingController(text: slide.imageUrl ?? '');
    String previewUrl = slide.imageUrl ?? '';

    final presets = [
      {'name': 'Supermarket Aisles', 'url': 'https://images.unsplash.com/photo-1578916171728-46686eac8d58?w=800&q=80'},
      {'name': 'Fresh Organic Produce', 'url': 'https://images.unsplash.com/photo-1542838132-92c53300491e?w=800&q=80'},
      {'name': 'Bakery & Fresh Bread', 'url': 'https://images.unsplash.com/photo-1509440159596-0249088772ff?w=800&q=80'},
      {'name': 'Kitchen Staples & Pantry', 'url': 'https://images.unsplash.com/photo-1608686207856-001b95cf60ca?w=800&q=80'},
      {'name': 'Tropical Fresh Fruits', 'url': 'https://images.unsplash.com/photo-1619566636858-adf3ef46400b?w=800&q=80'},
      {'name': 'Beverages & Soft Drinks', 'url': 'https://images.unsplash.com/photo-1527661591475-527312dd65f5?w=800&q=80'},
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        'Background Pic: ${slide.tag}',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.neutralDark,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Live Preview
                if (previewUrl.isNotEmpty) ...[
                  Container(
                    height: 110,
                    width: double.infinity,
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: Image.network(
                            previewUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Center(
                              child: Text('Invalid image URL', style: TextStyle(color: Colors.red)),
                            ),
                          ),
                        ),
                        Positioned.fill(
                          child: Container(
                            color: Colors.black.withValues(alpha: 0.35),
                          ),
                        ),
                        const Center(
                          child: Text(
                            'Live Background Preview',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // Custom URL Input
                TextField(
                  controller: urlCtrl,
                  decoration: InputDecoration(
                    labelText: 'Custom Image URL',
                    hintText: 'https://example.com/banner-graphic.jpg',
                    prefixIcon: const Icon(Icons.link_rounded),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.check_circle, color: AppTheme.primaryOrange),
                      onPressed: () {
                        setSheetState(() => previewUrl = urlCtrl.text.trim());
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    ),
                  ),
                  onChanged: (val) => setSheetState(() => previewUrl = val.trim()),
                ),
                const SizedBox(height: 14),

                const Text(
                  'Or Choose a High-Res Grocery Preset:',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.neutralDark),
                ),
                const SizedBox(height: 8),

                SizedBox(
                  height: 38,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: presets.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, i) {
                      final p = presets[i];
                      final isSelected = previewUrl == p['url'];
                      return ActionChip(
                        avatar: Icon(
                          isSelected ? Icons.check_circle : Icons.photo,
                          size: 16,
                          color: isSelected ? Colors.white : AppTheme.primaryOrange,
                        ),
                        label: Text(
                          p['name']!,
                          style: TextStyle(
                            color: isSelected ? Colors.white : AppTheme.neutralDark,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        backgroundColor: isSelected ? AppTheme.primaryOrange : Colors.grey.shade100,
                        onPressed: () {
                          urlCtrl.text = p['url']!;
                          setSheetState(() => previewUrl = p['url']!);
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 18),

                Row(
                  children: [
                    if (slide.imageUrl != null && slide.imageUrl!.isNotEmpty)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            await admin.updateSlideBgImage(index, null);
                            if (ctx.mounted) Navigator.pop(ctx);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Background picture removed.')),
                              );
                            }
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text('Remove Picture'),
                        ),
                      ),
                    if (slide.imageUrl != null && slide.imageUrl!.isNotEmpty)
                      const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: () async {
                          final newUrl = urlCtrl.text.trim();
                          await admin.updateSlideBgImage(index, newUrl.isNotEmpty ? newUrl : null);
                          if (ctx.mounted) Navigator.pop(ctx);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Hero card background picture updated!'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryOrange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('Save Picture', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
