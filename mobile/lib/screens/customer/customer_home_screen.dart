import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/broadcast_notification_model.dart';
import '../../models/supermarket_settings_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/catalog_provider.dart';
import '../../providers/supermarket_provider.dart';
import '../../services/notification_service.dart';
import '../../theme/app_theme.dart';
import '../admin/admin_in_app_screen.dart';
import '../driver/driver_shell.dart';
import '../../widgets/cart_sticky_bar.dart';
import '../../widgets/catalog_search_bar.dart';
import '../../widgets/category_chip_list.dart';
import '../../widgets/parallax_hero_banner.dart';
import '../../widgets/product_card.dart';
import '../../widgets/skeleton_loading.dart';
import 'ai_shopping_assistant_sheet.dart';
import 'notifications_sheet.dart';
import 'support_chat_sheet.dart';

class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _showScrollToTop = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      final show = _scrollController.hasClients && _scrollController.offset > 300;
      if (show != _showScrollToTop) {
        setState(() => _showScrollToTop = show);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final catalog = context.watch<CatalogProvider>();
    final auth = context.watch<AuthProvider>();
    final supermarket =
        Provider.of<SupermarketProvider?>(context)?.settings ??
            const SupermarketSettings();

    return Scaffold(
      floatingActionButton: _showScrollToTop
          ? FloatingActionButton.small(
              onPressed: () {
                _scrollController.animateTo(
                  0,
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeOut,
                );
              },
              backgroundColor: AppTheme.primaryOrange,
              foregroundColor: Colors.white,
              tooltip: 'Scroll to top',
              child: const Icon(Icons.arrow_upward_rounded, size: 18),
            )
          : null,
      body: RefreshIndicator(
        onRefresh: () => catalog.refresh(),
        color: AppTheme.accentAmber,
        child: CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // Pinned Branded App Bar
            SliverAppBar(
              pinned: true,
              floating: false,
              elevation: 0,
              flexibleSpace: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: AppTheme.brandOrangeGradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppTheme.accentAmber, AppTheme.accentOrange],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.accentAmber.withValues(alpha: 0.35),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.shopping_bag_rounded, size: 18, color: Colors.black),
                  ),
                  const SizedBox(width: 9),
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                supermarket.supermarketName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 19,
                                  color: Colors.white,
                                  letterSpacing: -0.4,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppTheme.accentAmber,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'EXPRESS',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 9,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.location_on, size: 11, color: AppTheme.accentAmber),
                              const SizedBox(width: 3),
                              Text(
                                '${supermarket.branchAddress} • ~30 Mins Dispatch',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.white.withValues(alpha: 0.85),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                // Notifications Bell with dynamic count badge
                ValueListenableBuilder<List<BroadcastNotification>>(
                  valueListenable: NotificationService().broadcastsNotifier,
                  builder: (ctx, broadcasts, _) {
                    return Stack(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                          tooltip: 'Broadcasts & Alerts',
                          onPressed: () => NotificationsSheet.show(context),
                        ),
                        if (broadcasts.isNotEmpty)
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: AppTheme.primaryOrange,
                                shape: BoxShape.circle,
                              ),
                              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                              child: Text(
                                broadcasts.length > 9 ? '9+' : '${broadcasts.length}',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),

                // Live Support Messenger Chat (Alibaba style)
                IconButton(
                  icon: const Icon(Icons.chat_bubble_outline_rounded, color: Colors.white),
                  tooltip: 'Live Support Messenger',
                  onPressed: () => SupportChatSheet.show(context),
                ),

                // AI Concierge Shopping Assistant
                Container(
                  margin: const EdgeInsets.only(right: 6),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppTheme.primaryOrange, Color(0xFFE64A19)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryOrange.withValues(alpha: 0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => AiShoppingAssistantSheet.show(context),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.auto_awesome, color: Colors.white, size: 13),
                          SizedBox(width: 4),
                          Text(
                            'AI Assistant',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Admin Hub Shortcut if authenticated user is admin
                if (auth.isAuthenticated && auth.profile?.isAdmin == true)
                  Container(
                    margin: const EdgeInsets.only(right: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.accentAmber.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.accentAmber, width: 1),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AdminInAppScreen()),
                      ),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.admin_panel_settings_rounded, size: 14, color: AppTheme.accentAmber),
                            SizedBox(width: 4),
                            Text(
                              'Admin',
                              style: TextStyle(
                                color: AppTheme.accentAmber,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                // Driver Console Shortcut if authenticated user is driver
                if (auth.isAuthenticated && auth.profile?.isDriver == true)
                  Container(
                    margin: const EdgeInsets.only(right: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00E676).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF00E676), width: 1.2),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const DriverShell()),
                      ),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.two_wheeler_rounded, size: 14, color: Color(0xFF00E676)),
                            SizedBox(width: 4),
                            Text(
                              'Driver Console',
                              style: TextStyle(
                                color: Color(0xFF00E676),
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                const SizedBox(width: 8),
              ],
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(66),
                child: Container(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
                  child: const CatalogSearchBar(),
                ),
              ),
            ),

            // Banner & Categories Section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Driver Fleet Mode Card if signed in as Driver
                    if (auth.isAuthenticated && auth.profile?.isDriver == true) ...[
                      InkWell(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const DriverShell()),
                        ),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF132A13),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF00E676), width: 1.2),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.two_wheeler_rounded, color: Color(0xFF00E676), size: 22),
                              SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Quickopia Driver Fleet Mode Active',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                    Text(
                                      'Tap to switch to live driver delivery console ➔',
                                      style: TextStyle(color: Color(0xFF69F0AE), fontSize: 11),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    if (catalog.status == CatalogStatus.loading && catalog.products.isEmpty) ...[
                      const SkeletonBanner(),
                      const SizedBox(height: 14),
                      const SkeletonCategoryList(),
                      const SizedBox(height: 12),
                    ] else ...[
                      if (catalog.products.length > 2 &&
                          catalog.searchQuery.isEmpty &&
                          catalog.selectedCategoryId == null) ...[
                        ParallaxHeroBanner(
                          onSlideTap: () {
                            if (_scrollController.hasClients) {
                              _scrollController.animateTo(
                                280,
                                duration: const Duration(milliseconds: 350),
                                curve: Curves.easeOut,
                              );
                            }
                          },
                        ),
                        const SizedBox(height: 14),
                      ],
                      const CategoryChipList(),
                      const SizedBox(height: 12),
                    ],
                    _buildSectionHeader(catalog),
                  ],
                ),
              ),
            ),
            ..._buildSliverContent(catalog),
            const SliverToBoxAdapter(
              child: SizedBox(height: 90),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const CartStickyBar(),
    );
  }

  Widget _buildSectionHeader(CatalogProvider catalog) {
    final hasCategoryFilter = catalog.selectedCategoryId != null;
    final selectedCatName = hasCategoryFilter
        ? catalog.categories
            .firstWhere(
              (c) => c.id == catalog.selectedCategoryId,
              orElse: () => catalog.categories.first,
            )
            .name
        : 'Popular Picks';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(
                hasCategoryFilter ? selectedCatName : 'Popular Picks',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.primaryNavy,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.amber.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${catalog.products.length}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber.shade900,
                  ),
                ),
              ),
            ],
          ),
          if (hasCategoryFilter || catalog.searchQuery.isNotEmpty)
            TextButton(
              onPressed: () {
                catalog.selectCategory(null);
                catalog.search('');
              },
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Row(
                children: [
                  Text(
                    'View All',
                    style: TextStyle(
                      color: AppTheme.primaryNavy,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  SizedBox(width: 3),
                  Icon(Icons.arrow_forward_ios_rounded, size: 12, color: AppTheme.primaryNavy),
                ],
              ),
            ),
        ],
      ),
    );
  }

  List<Widget> _buildSliverContent(CatalogProvider catalog) {
    if (catalog.status == CatalogStatus.loading && catalog.products.isEmpty) {
      return [
        const SkeletonProductGrid(count: 6),
      ];
    }

    if (catalog.status == CatalogStatus.error && catalog.products.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.cloud_off, size: 48, color: Colors.grey),
                const SizedBox(height: 12),
                Text(
                  catalog.errorMessage ?? 'Something went wrong',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppTheme.neutralDark, fontSize: 15),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: catalog.refresh,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ];
    }

    if (catalog.products.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.search_off, size: 48, color: Colors.grey.shade400),
                const SizedBox(height: 12),
                const Text(
                  'No products found.',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryNavy,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Try a different search term or category.',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ),
      ];
    }

    return [
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        sliver: SliverGrid(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.64,
          ),
          delegate: SliverChildBuilderDelegate(
            (context, i) => ProductCard(product: catalog.products[i]),
            childCount: catalog.products.length,
          ),
        ),
      ),
    ];
  }
}
