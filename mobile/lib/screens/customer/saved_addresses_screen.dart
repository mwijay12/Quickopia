import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/address_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/address_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/address_form_sheet.dart';

class SavedAddressesScreen extends StatefulWidget {
  const SavedAddressesScreen({super.key});

  @override
  State<SavedAddressesScreen> createState() => _SavedAddressesScreenState();
}

class _SavedAddressesScreenState extends State<SavedAddressesScreen> {
  final _addressService = AddressService();
  List<Address> _addresses = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  Future<void> _loadAddresses() async {
    final profile = context.read<AuthProvider>().profile;
    if (profile == null) {
      setState(() => _loading = false);
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final addresses = await _addressService.fetchSavedAddresses(profile.id);
      if (mounted) {
        setState(() {
          _addresses = addresses;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Could not load saved addresses. Please try again.';
        });
      }
    }
  }

  Future<void> _setDefault(Address address) async {
    final profile = context.read<AuthProvider>().profile;
    if (profile == null) return;

    try {
      await _addressService.setDefaultAddress(
        profileId: profile.id,
        addressId: address.id,
      );
      _loadAddresses();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not set default address: $e')),
        );
      }
    }
  }

  Future<void> _deleteAddress(Address address) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Address?'),
        content: Text('Are you sure you want to remove "${address.label}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _addressService.deleteAddress(address.id);
        _loadAddresses();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not delete address: $e')),
          );
        }
      }
    }
  }

  Future<void> _openAddSheet() async {
    final profile = context.read<AuthProvider>().profile;
    if (profile == null) return;

    final added = await AddressFormSheet.show(context, profileId: profile.id);
    if (added == true) {
      _loadAddresses();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Saved Addresses')),
      body: RefreshIndicator(
        onRefresh: _loadAddresses,
        child: _body(),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddSheet,
        backgroundColor: AppTheme.accentAmber,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add),
        label: const Text('Add Address', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _body() {
    if (_loading && _addresses.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null && _addresses.isEmpty) {
      return ListView(
        children: [
          const SizedBox(height: 120),
          Center(child: Text(_error!)),
          const SizedBox(height: 12),
          Center(
            child: ElevatedButton(
              onPressed: _loadAddresses,
              child: const Text('Retry'),
            ),
          ),
        ],
      );
    }

    if (_addresses.isEmpty) {
      return ListView(
        children: const [
          SizedBox(height: 120),
          Icon(Icons.location_off_outlined, size: 60, color: Colors.grey),
          SizedBox(height: 16),
          Center(
            child: Text(
              'No saved addresses yet.\nSave one to check out faster next time.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ),
        ],
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16).copyWith(bottom: 80),
      itemCount: _addresses.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final a = _addresses[index];
        return Card(
          elevation: 0.5,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            side: BorderSide(
              color: a.isDefault ? AppTheme.accentAmber : Colors.grey.shade200,
              width: a.isDefault ? 1.5 : 1,
            ),
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
                          a.label,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: AppTheme.primaryNavy,
                          ),
                        ),
                        if (a.isDefault) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.accentAmber.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'Default',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    PopupMenuButton<String>(
                      onSelected: (action) {
                        if (action == 'default') _setDefault(a);
                        if (action == 'delete') _deleteAddress(a);
                      },
                      itemBuilder: (ctx) => [
                        if (!a.isDefault)
                          const PopupMenuItem(
                            value: 'default',
                            child: Text('Set as Default'),
                          ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Text('Delete', style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '${a.neighborhood}, ${a.city}',
                  style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                ),
                Text(
                  'Landmark: ${a.landmark}',
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                ),
                if (a.houseDetails != null && a.houseDetails!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Details: ${a.houseDetails!}',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                ],
                if (a.phone != null && a.phone!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.phone_android_rounded, size: 14, color: AppTheme.primaryOrange),
                      const SizedBox(width: 4),
                      Text(
                        a.phone!,
                        style: const TextStyle(
                          color: AppTheme.neutralDark,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
                if (a.latitude != null && a.longitude != null) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.pin_drop, size: 14, color: AppTheme.accentOrange),
                      const SizedBox(width: 4),
                      Text(
                        'Map pin attached',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
