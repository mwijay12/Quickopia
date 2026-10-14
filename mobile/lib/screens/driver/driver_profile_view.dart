import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/driver_orders_provider.dart';
import '../../services/branch_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/currency_formatter.dart';
import '../customer/terms_and_conditions_screen.dart';

class DriverProfileView extends StatefulWidget {
  final VoidCallback onSignOut;

  const DriverProfileView({
    super.key,
    required this.onSignOut,
  });

  @override
  State<DriverProfileView> createState() => _DriverProfileViewState();
}

class _DriverProfileViewState extends State<DriverProfileView> {
  String _branchName = 'Quickopia Pilot Branch';
  bool _loadingBranch = true;

  @override
  void initState() {
    super.initState();
    _loadBranch();
  }

  Future<void> _loadBranch() async {
    try {
      final branch = await BranchService().fetchPrimaryBranch();
      if (mounted) {
        setState(() {
          _branchName = branch.name;
          _loadingBranch = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _loadingBranch = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final driverOrders = context.watch<DriverOrdersProvider>();
    final profile = auth.profile;

    final name = profile?.fullName ?? 'Quickopia Driver';
    final phone = profile?.phone ?? 'No phone added';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'D';

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Driver Identity Card
        Card(
          elevation: 0.5,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: AppTheme.primaryNavy,
                  child: Text(
                    initial,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              name,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryNavy,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.green.shade200),
                            ),
                            child: const Text(
                              'ACTIVE',
                              style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.green),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        phone,
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.two_wheeler, size: 16, color: AppTheme.accentAmber),
                          const SizedBox(width: 4),
                          Text(
                            'Quickopia Delivery Partner',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey.shade800,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Lifetime Stats Card
        Card(
          elevation: 0.5,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Matokeo Yako ya Kazi (Performance)',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryNavy,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Safari Zilizokamilika',
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${driverOrders.totalCompletedCount}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryNavy,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Jumla ya Mapato',
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            CurrencyFormatter.formatTzs(driverOrders.totalEarningsTzs),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Operation Details & Branch
        Card(
          elevation: 0.5,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.storefront_outlined, color: AppTheme.primaryNavy),
                title: const Text('Supermarket Branch'),
                subtitle: Text(_loadingBranch ? 'Inapakia tawi...' : _branchName),
              ),
              const Divider(height: 1),
              const ListTile(
                leading: Icon(Icons.verified_user_outlined, color: AppTheme.primaryNavy),
                title: Text('Hali ya Usalama (Verification)'),
                subtitle: Text('Akaunti imethibitishwa kwa uwasilishaji'),
                trailing: Icon(Icons.check_circle, color: Colors.green, size: 20),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.help_outline, color: AppTheme.primaryNavy),
                title: const Text('Msaada wa Dereva (Dispatch Support)'),
                subtitle: const Text('Wasiliana na meneja wa duka kwa msaada'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Tafadhali wasiliana na kaunta ya supermarket kwa maswali ya safari.')),
                  );
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.gavel_outlined, color: AppTheme.primaryNavy),
                title: const Text('Driver Code & Guidelines / Kanuni'),
                subtitle: const Text('Usalama barabarani, usafi & msimbo wa OTP'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  TermsAndConditionsScreen.show(context, initialTabIndex: 1);
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Sign Out Button
        OutlinedButton.icon(
          onPressed: widget.onSignOut,
          icon: const Icon(Icons.logout, color: Colors.red),
          label: const Text(
            'Toka Kwenye Akaunti / Sign Out',
            style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
          ),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            side: BorderSide(color: Colors.red.shade300),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
          ),
        ),
        const SizedBox(height: 24),

        Center(
          child: Text(
            'Quickopia Driver v1.0 • Dar es Salaam, Tanzania',
            style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
          ),
        ),
      ],
    );
  }
}
