import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/cart_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/floating_pill_bottom_bar.dart';
import 'account_screen.dart';
import 'cart_screen.dart';
import 'customer_home_screen.dart';
import 'order_history_screen.dart';

class CustomerShell extends StatefulWidget {
  final int initialIndex;

  const CustomerShell({super.key, this.initialIndex = 0});

  static CustomerShellState? of(BuildContext context) {
    return context.findAncestorStateOfType<CustomerShellState>();
  }

  @override
  State<CustomerShell> createState() => CustomerShellState();
}

class CustomerShellState extends State<CustomerShell> {
  late int _index = widget.initialIndex;

  void setTab(int index) {
    if (index >= 0 && index < 4) {
      setState(() => _index = index);
    }
  }

  late final List<Widget> _screens = [
    const CustomerHomeScreen(),
    CartScreen(onStartShopping: () => setState(() => _index = 0)),
    OrderHistoryScreen(onStartShopping: () => setState(() => _index = 0)),
    const AccountScreen(),
  ];

  Future<void> _handlePop(bool didPop) async {
    if (didPop) return;

    // If on a sub-tab (Cart, Orders, Account), first return to Home tab
    if (_index != 0) {
      setState(() => _index = 0);
      return;
    }

    // On Home tab, prompt exit confirmation
    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        ),
        title: const Row(
          children: [
            Icon(Icons.exit_to_app_rounded, color: AppTheme.primaryOrange),
            SizedBox(width: 8),
            Text(
              'Exit Quickopia?',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        content: const Text(
          'Are you sure you want to exit the application?\nJe, una uhakika unataka kutoka kwenye application?',
          style: TextStyle(fontSize: 14, color: AppTheme.neutralDark),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: const Text('Stay / Baki', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
            ),
            child: const Text('Exit / Toka', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (shouldExit == true) {
      await SystemNavigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) => _handlePop(didPop),
      child: Scaffold(
        extendBody: false,
        body: IndexedStack(
          index: _index,
          children: _screens,
        ),
        bottomNavigationBar: FloatingPillBottomBar(
          currentIndex: _index,
          cartBadgeCount: cart.itemCount,
          onTap: (i) => setState(() => _index = i),
        ),
      ),
    );
  }
}
