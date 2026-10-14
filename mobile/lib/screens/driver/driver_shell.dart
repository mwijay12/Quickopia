import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/order_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/driver_orders_provider.dart';
import '../../services/permission_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/driver_order_card.dart';
import '../../widgets/mark_delivered_sheet.dart';
import '../customer/customer_shell.dart';
import 'driver_available_orders_view.dart';
import 'driver_profile_view.dart';
import 'driver_reports_view.dart';

class DriverShell extends StatefulWidget {
  const DriverShell({super.key});

  @override
  State<DriverShell> createState() => _DriverShellState();
}

class _DriverShellState extends State<DriverShell> with SingleTickerProviderStateMixin {
  int _currentNavIndex = 0;
  late TabController _deliveryTabController;

  @override
  void initState() {
    super.initState();
    _deliveryTabController = TabController(length: 2, vsync: this);
    PermissionService.requestLocationPermission();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final profile = context.read<AuthProvider>().profile;
      if (profile != null) {
        context.read<DriverOrdersProvider>().start(profile.id);
      }
    });
  }

  @override
  void dispose() {
    _deliveryTabController.dispose();
    super.dispose();
  }

  Future<void> _openMarkDelivered(Order order) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => MarkDeliveredSheet(order: order),
    );

    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Delivery completed successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      context.read<DriverOrdersProvider>().refresh();
    }
  }

  Future<void> _signOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out of your driver account?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sign Out', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      context.read<DriverOrdersProvider>().clear();
      await context.read<AuthProvider>().signOut();
    }
  }

  @override
  Widget build(BuildContext context) {
    final driverOrders = context.watch<DriverOrdersProvider>();
    final profile = context.watch<AuthProvider>().profile;

    return Scaffold(
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppTheme.brandOrangeLinearGradient,
          ),
        ),
        foregroundColor: Colors.white,
        title: Row(
          children: [
            const Text('Quickopia Driver', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.circle, color: Color(0xFF00E676), size: 7),
                  SizedBox(width: 4),
                  Text(
                    'ONLINE',
                    style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.storefront_outlined, color: Colors.white),
            tooltip: 'Preview Customer Store / Angalia Duka',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CustomerShell()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: 'Refresh Deliveries',
            onPressed: () => driverOrders.refresh(),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: 'Sign Out',
            onPressed: _signOut,
          ),
        ],
        bottom: _currentNavIndex == 0
            ? TabBar(
                controller: _deliveryTabController,
                indicatorColor: Colors.white,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                indicatorWeight: 3,
                tabs: [
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('My Deliveries (Active)'),
                        if (driverOrders.orders.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          CircleAvatar(
                            radius: 9,
                            backgroundColor: Colors.white,
                            child: Text(
                              '${driverOrders.orders.length}',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryOrange,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Available Orders'),
                        if (driverOrders.availableOrders.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          CircleAvatar(
                            radius: 9,
                            backgroundColor: Colors.white,
                            child: Text(
                              '${driverOrders.availableOrders.length}',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryOrange,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              )
            : null,
      ),
      body: IndexedStack(
        index: _currentNavIndex,
        children: [
          // Screen 0: Deliveries (Active & Available tabs)
          TabBarView(
            controller: _deliveryTabController,
            children: [
              // Tab 1: Active Deliveries assigned to driver
              RefreshIndicator(
                onRefresh: () => driverOrders.refresh(),
                child: _activeDeliveriesBody(driverOrders, profile),
              ),
              // Tab 2: Available orders ready to be claimed
              RefreshIndicator(
                onRefresh: () => driverOrders.refresh(),
                child: DriverAvailableOrdersView(
                  onOrderAccepted: () {
                    // Switch to active deliveries tab when driver accepts an order
                    _deliveryTabController.animateTo(0);
                  },
                ),
              ),
            ],
          ),

          // Screen 1: Reports, Earnings & Payout Status
          const DriverReportsView(),

          // Screen 2: Driver Profile
          DriverProfileView(onSignOut: _signOut),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentNavIndex,
        onDestinationSelected: (idx) {
          setState(() => _currentNavIndex = idx);
        },
        destinations: [
          NavigationDestination(
            icon: Badge(
              isLabelVisible: driverOrders.orders.isNotEmpty,
              label: Text('${driverOrders.orders.length}'),
              child: const Icon(Icons.two_wheeler_outlined),
            ),
            selectedIcon: const Icon(Icons.two_wheeler),
            label: 'Deliveries',
          ),
          const NavigationDestination(
            icon: Icon(Icons.assessment_outlined),
            selectedIcon: Icon(Icons.assessment),
            label: 'Reports & Payout',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _activeDeliveriesBody(DriverOrdersProvider driverOrders, profile) {
    if (driverOrders.status == DriverOrdersStatus.loading && driverOrders.orders.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (driverOrders.status == DriverOrdersStatus.error && driverOrders.orders.isEmpty) {
      return ListView(
        children: [
          const SizedBox(height: 100),
          Center(
            child: Text(
              driverOrders.errorMessage ?? 'Network connection error.',
              style: const TextStyle(color: Colors.grey),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: ElevatedButton(
              onPressed: () => driverOrders.refresh(),
              child: const Text('Retry'),
            ),
          ),
        ],
      );
    }

    if (driverOrders.orders.isEmpty) {
      return ListView(
        children: [
          const SizedBox(height: 80),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              children: [
                const Icon(
                  Icons.moped_outlined,
                  size: 64,
                  color: AppTheme.primaryOrange,
                ),
                const SizedBox(height: 16),
                Text(
                  'Hello ${profile?.fullName ?? "Driver"}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.neutralDark,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'You have no active deliveries right now.\nCheck the "Available Orders" tab above to accept orders.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 13, height: 1.4),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () => _deliveryTabController.animateTo(1),
                  icon: const Icon(Icons.search, size: 18),
                  label: const Text('Browse Available Orders'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryOrange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: driverOrders.orders.length,
      itemBuilder: (context, i) => DriverOrderCard(
        order: driverOrders.orders[i],
        onMarkComplete: () => _openMarkDelivered(driverOrders.orders[i]),
      ),
    );
  }
}
