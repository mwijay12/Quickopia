import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/supabase_config.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/order_history_provider.dart';
import '../../services/branch_service.dart';
import '../../services/profile_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/validators.dart';
import 'saved_addresses_screen.dart';
import '../admin/admin_in_app_screen.dart';
import '../auth/login_screen.dart';
import '../driver/driver_shell.dart';
import '../onboarding/onboarding_screen.dart';
import 'privacy_policy_screen.dart';
import 'terms_and_conditions_screen.dart';
import '../../widgets/liquid_glass_container.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final _profileService = ProfileService();

  Future<void> _openProfilePictureDialog(dynamic profileObj) async {
    final profile = profileObj;
    String currentAvatar = profile.avatarUrl ?? '';
    final urlCtrl = TextEditingController(text: currentAvatar);
    String previewUrl = currentAvatar;
    bool saving = false;

    final avatarPresets = [
      'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=200',
      'https://images.unsplash.com/photo-1580489944761-15a19d654956?w=200',
      'https://images.unsplash.com/photo-1570295999919-56ceb5ecca61?w=200',
      'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200',
      'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=200',
      'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=200',
      'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=200',
      'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=200',
      'https://images.unsplash.com/photo-1522075469751-3a6694fb2f61?w=200',
      'https://api.dicebear.com/7.x/bottts/png?seed=QuickShopper',
      'https://api.dicebear.com/7.x/micah/png?seed=QuickVIP',
    ];

    await showModalBottomSheet(
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
                    const Text(
                      'Update Profile Picture',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.neutralDark,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Large Avatar Live Preview
                Center(
                  child: Stack(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppTheme.primaryOrange, width: 2.5),
                        ),
                        child: CircleAvatar(
                          radius: 46,
                          backgroundColor: AppTheme.primaryOrange,
                          backgroundImage: previewUrl.isNotEmpty ? NetworkImage(previewUrl) : null,
                          child: previewUrl.isEmpty
                              ? const Icon(Icons.person, size: 50, color: Colors.white)
                              : null,
                        ),
                      ),
                      if (previewUrl.isNotEmpty)
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: InkWell(
                            onTap: () {
                              setSheetState(() {
                                previewUrl = '';
                                urlCtrl.clear();
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close, size: 14, color: Colors.white),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Custom Picture Link input
                TextField(
                  controller: urlCtrl,
                  decoration: InputDecoration(
                    labelText: 'Custom Photo Link / Image URL',
                    hintText: 'https://example.com/my-photo.jpg',
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
                const SizedBox(height: 16),

                const Text(
                  'Or Choose an Avatar Style:',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.neutralDark),
                ),
                const SizedBox(height: 10),

                SizedBox(
                  height: 64,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: avatarPresets.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (context, i) {
                      final url = avatarPresets[i];
                      final isSelected = previewUrl == url;
                      return InkWell(
                        onTap: () {
                          urlCtrl.text = url;
                          setSheetState(() => previewUrl = url);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? AppTheme.primaryOrange : Colors.grey.shade300,
                              width: isSelected ? 3 : 1,
                            ),
                          ),
                          child: CircleAvatar(
                            radius: 28,
                            backgroundImage: NetworkImage(url),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          setSheetState(() {
                            previewUrl = '';
                            urlCtrl.clear();
                          });
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.grey.shade800,
                          side: BorderSide(color: Colors.grey.shade400),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('Use Initials'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: saving
                            ? null
                            : () async {
                                setSheetState(() => saving = true);
                                try {
                                  await _profileService.updateBasicInfo(
                                    profileId: profile.id,
                                    fullName: profile.fullName,
                                    phone: profile.phone ?? '',
                                    avatarUrl: previewUrl.isNotEmpty ? previewUrl : null,
                                  );
                                  if (ctx.mounted) Navigator.pop(ctx);
                                  if (!mounted) return;
                                  await context.read<AuthProvider>().reloadProfile();
                                  if (!mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Profile picture updated successfully!'),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                } catch (e) {
                                  setSheetState(() => saving = false);
                                  if (!mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Could not update avatar: $e')),
                                  );
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryOrange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: saving
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Text('Save Picture', style: TextStyle(fontWeight: FontWeight.bold)),
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

  Future<void> _openEditProfile(dynamic profileObj) async {
    final profile = profileObj;
    final nameCtrl = TextEditingController(text: profile.fullName ?? '');
    final phoneCtrl = TextEditingController(text: profile.phone ?? '');
    final vehicleCtrl = TextEditingController(text: profile.vehicleInfo ?? profile.bio ?? '');
    String selectedAvatar = profile.avatarUrl ?? '';
    final formKey = GlobalKey<FormState>();
    bool saving = false;

    final avatarPresets = [
      'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=150',
      'https://images.unsplash.com/photo-1580489944761-15a19d654956?w=150',
      'https://images.unsplash.com/photo-1570295999919-56ceb5ecca61?w=150',
      'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150',
      'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150',
      'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=150',
      'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=150',
    ];

    await showModalBottomSheet(
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
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Edit Profile',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.neutralDark,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Avatar Selection Row
                  const Text(
                    'Profile Picture',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.neutralDark),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 60,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: avatarPresets.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemBuilder: (context, i) {
                        final url = avatarPresets[i];
                        final isSelected = selectedAvatar == url;
                        return InkWell(
                          onTap: () => setSheetState(() => selectedAvatar = url),
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected ? AppTheme.primaryOrange : Colors.grey.shade300,
                                width: isSelected ? 3 : 1,
                              ),
                            ),
                            child: CircleAvatar(
                              radius: 26,
                              backgroundImage: NetworkImage(url),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 14),

                  TextFormField(
                    controller: nameCtrl,
                    decoration: InputDecoration(
                      labelText: 'Full Name',
                      prefixIcon: const Icon(Icons.person_outline),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      ),
                    ),
                    validator: (v) => Validators.requiredField(v, label: 'Full Name'),
                  ),
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: phoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: 'Phone Number',
                      hintText: '0712345678 or +255712345678',
                      prefixIcon: const Icon(Icons.phone_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      ),
                    ),
                    validator: (v) => (v == null || !Validators.isValidTzPhone(v))
                        ? 'Enter a valid Tanzanian phone number'
                        : null,
                  ),
                  const SizedBox(height: 12),

                  if (profile.isDriver == true) ...[
                    TextFormField(
                      controller: vehicleCtrl,
                      decoration: InputDecoration(
                        labelText: 'Vehicle Information',
                        hintText: 'e.g. Boxer BM 150 • T 412 DFG',
                        prefixIcon: const Icon(Icons.two_wheeler),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ] else if (profile.isAdmin == true) ...[
                    TextFormField(
                      controller: vehicleCtrl,
                      decoration: InputDecoration(
                        labelText: 'Admin Role / Branch',
                        hintText: 'e.g. Store Supervisor • Mikocheni',
                        prefixIcon: const Icon(Icons.admin_panel_settings_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  ElevatedButton(
                    onPressed: saving
                        ? null
                        : () async {
                            if (!formKey.currentState!.validate()) return;
                            final authProvider = context.read<AuthProvider>();
                            final messenger = ScaffoldMessenger.of(context);
                            final navigator = Navigator.of(ctx);
                            setSheetState(() => saving = true);
                            try {
                              final normalized = Validators.normalizeTzPhone(phoneCtrl.text.trim());
                              await _profileService.updateBasicInfo(
                                profileId: profile.id,
                                fullName: nameCtrl.text.trim(),
                                phone: normalized,
                                avatarUrl: selectedAvatar.isNotEmpty ? selectedAvatar : null,
                                vehicleInfo: vehicleCtrl.text.trim().isNotEmpty ? vehicleCtrl.text.trim() : null,
                              );
                              if (mounted) {
                                await authProvider.reloadProfile();
                                navigator.pop();
                                messenger.showSnackBar(
                                  const SnackBar(content: Text('Profile updated successfully')),
                                );
                              }
                            } catch (e) {
                              setSheetState(() => saving = false);
                              if (mounted) {
                                messenger.showSnackBar(
                                  SnackBar(content: Text('Could not update profile: $e')),
                                );
                              }
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryOrange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: saving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text(
                            'Save Changes',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _contactStore() async {
    try {
      final branch = await BranchService().fetchPrimaryBranch();
      if (branch.phone != null && branch.phone!.isNotEmpty) {
        final uri = Uri.parse('tel:${branch.phone}');
        if (await canLaunchUrl(uri)) await launchUrl(uri);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Store phone number is not available')),
          );
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not reach store right now')),
        );
      }
    }
  }

  Future<void> _confirmSignOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out of Quickopia?'),
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
      context.read<OrderHistoryProvider>().clear();
      context.read<CartProvider>().clearCart();
      await context.read<AuthProvider>().signOut();
    }
  }

  Future<void> _confirmDeleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Delete Account / Futa Akaunti',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: const Text(
          'Are you sure you want to permanently delete your Quickopia account? All personal data, saved delivery addresses, and active credentials will be permanently erased in accordance with the Tanzania Personal Data Protection Act.\n\n'
          'Una uhakika unataka kufuta kabisa akaunti yako? Taarifa zako zote zitafutwa na hatua hii haiwezi kurudishwa.',
          style: TextStyle(fontSize: 13, height: 1.45),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel / Ghairi'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete Account / Futa'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final messenger = ScaffoldMessenger.of(context);
      final auth = context.read<AuthProvider>();
      try {
        if (auth.profile != null) {
          try {
            await SupabaseConfig.client
                .from('profiles')
                .update({'full_name': 'Deleted User', 'phone': null})
                .eq('id', auth.profile!.id);
          } catch (_) {}
        }
        if (mounted) {
          context.read<OrderHistoryProvider>().clear();
          context.read<CartProvider>().clearCart();
          await auth.signOut();
          messenger.showSnackBar(
            const SnackBar(
              content: Text('Akaunti imefutwa kikamilifu. / Account deleted successfully.'),
              backgroundColor: Colors.black87,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          messenger.showSnackBar(
            SnackBar(content: Text('Error deleting account: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final profile = auth.profile;
    final email = _profileService.currentEmail ?? 'No email on file';
    final name = profile?.fullName ?? 'Quickopia Shopper';
    final phone = profile?.phone ?? 'No phone added';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'Q';

    return Scaffold(
      appBar: AppBar(title: const Text('My Account')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header Profile Card
          Card(
            elevation: 0.5,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: auth.isAuthenticated
                  ? Row(
                      children: [
                        Stack(
                          children: [
                            GestureDetector(
                              onTap: () {
                                if (profile != null) _openProfilePictureDialog(profile);
                              },
                              child: CircleAvatar(
                                radius: 34,
                                backgroundColor: AppTheme.primaryOrange,
                                backgroundImage: (profile?.avatarUrl != null && profile!.avatarUrl!.isNotEmpty)
                                    ? NetworkImage(profile.avatarUrl!)
                                    : null,
                                child: (profile?.avatarUrl == null || profile!.avatarUrl!.isEmpty)
                                    ? Text(
                                        initial,
                                        style: const TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      )
                                    : null,
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: InkWell(
                                onTap: () {
                                  if (profile != null) _openProfilePictureDialog(profile);
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(5),
                                  decoration: const BoxDecoration(
                                    color: AppTheme.primaryOrange,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
                                    ],
                                  ),
                                  child: const Icon(Icons.camera_alt_rounded, size: 13, color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryNavy,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                email,
                                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                phone,
                                style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                              ),
                              const SizedBox(height: 5),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: profile?.isAdmin == true
                                      ? Colors.amber.shade100
                                      : (profile?.isDriver == true
                                          ? Colors.green.shade100
                                          : Colors.blue.shade100),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  profile?.isAdmin == true
                                      ? 'STORE ADMIN'
                                      : (profile?.isDriver == true
                                          ? 'DELIVERY PARTNER • ${profile?.vehicleInfo ?? "Active"}'
                                          : 'VALUED CUSTOMER'),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: profile?.isAdmin == true
                                      ? Colors.amber.shade900
                                      : (profile?.isDriver == true
                                          ? Colors.green.shade900
                                          : Colors.blue.shade900),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, color: AppTheme.primaryNavy),
                          tooltip: 'Edit Profile',
                          onPressed: () => _openEditProfile(profile!),
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: AppTheme.accentAmber.withValues(alpha: 0.3),
                          child: const Icon(
                            Icons.person_outline,
                            size: 32,
                            color: AppTheme.primaryNavy,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Guest Shopper',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryNavy,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Sign in to access your orders & addresses',
                                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const LoginScreen()),
                          ),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                          child: const Text('Sign In'),
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 16),

          // Supermarket / Admin Portal Banner for Store Admins
          if (profile?.isAdmin == true) ...[
            LiquidGlassContainer(
              borderRadius: AppTheme.radiusLg,
              blur: 16,
              borderWidth: 1.2,
              borderColor: AppTheme.primaryOrange.withValues(alpha: 0.5),
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF1E2024).withValues(alpha: 0.95),
                  const Color(0xFF141518).withValues(alpha: 0.92),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryOrange,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryOrange.withValues(alpha: 0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.admin_panel_settings_rounded, color: Colors.white, size: 22),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Supermarket Admin Console',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                                letterSpacing: -0.3,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Manage Store Catalog, Pricing, Inventory & Live Orders',
                              style: TextStyle(color: AppTheme.primaryOrangeLight, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'As a Store Admin / Manager, you can adjust product prices, update stock levels, verify live orders, and manage hero banner promotions directly in the app.',
                    style: TextStyle(color: Colors.white, fontSize: 12, height: 1.4),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.dashboard_customize_rounded, size: 18, color: Colors.white),
                      label: const Text(
                        'Open Admin Console ➔',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryOrange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                        ),
                      ),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AdminInAppScreen()),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.sync_rounded, size: 14, color: Colors.white70),
                        SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Synchronized directly with Supabase Realtime & Web Admin',
                            style: TextStyle(color: Colors.white70, fontSize: 10),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Driver Delivery Console Banner for Drivers
          if (profile?.isDriver == true) ...[
            LiquidGlassContainer(
              borderRadius: AppTheme.radiusLg,
              blur: 16,
              borderWidth: 1.2,
              borderColor: const Color(0xFF00E676).withValues(alpha: 0.6),
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF132A13).withValues(alpha: 0.95),
                  const Color(0xFF0D1B0D).withValues(alpha: 0.92),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00E676),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF00E676).withValues(alpha: 0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.two_wheeler_rounded, color: Colors.black, size: 22),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Quickopia Driver Fleet Console',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                                letterSpacing: -0.3,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Live Deliveries, Available Orders, OTP Proof & Earnings',
                              style: TextStyle(color: Color(0xFF69F0AE), fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00E676),
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.dashboard_rounded, size: 18),
                      label: const Text(
                        'Open Driver Dashboard / Fungua Dashibodi',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const DriverShell()),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.check_circle_outline, size: 14, color: Color(0xFF69F0AE)),
                        SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Active Driver Account — GPS tracking & live order dispatch enabled',
                            style: TextStyle(color: Color(0xFFE2E8F0), fontSize: 10),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Referral Program Card
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryOrange.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.card_giftcard, color: AppTheme.primaryOrange, size: 20),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'Refer a Friend',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: AppTheme.neutralDark,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryOrange.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${profile?.referralCount ?? 0} Referred',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryOrange,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Share your code with friends and family. When they place their first order, you both get recognized for supermarket shopping loyalty rewards!',
                    style: TextStyle(fontSize: 12, color: Colors.black87),
                  ),
                  const SizedBox(height: 12),
                  Builder(
                    builder: (context) {
                      final myReferralCode = (profile?.referralCode != null && profile!.referralCode!.isNotEmpty)
                          ? profile.referralCode!
                          : ((profile != null && profile.id.length >= 5)
                              ? 'QK-${profile.id.substring(0, 5).toUpperCase()}'
                              : 'QK-REWARDS');

                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'YOUR CODE',
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey),
                                ),
                                Text(
                                  myReferralCode,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.2,
                                    color: AppTheme.primaryOrange,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.copy, size: 20, color: AppTheme.primaryOrange),
                                  tooltip: 'Copy Code',
                                  onPressed: () {
                                    Clipboard.setData(ClipboardData(text: myReferralCode));
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Referral code $myReferralCode copied to clipboard!')),
                                    );
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.share, size: 20, color: Color(0xFF25D366)),
                                  tooltip: 'Share on WhatsApp',
                                  onPressed: () => _shareReferralCode(myReferralCode),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  if (profile?.referredBy != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      'Referred by: ${profile!.referredBy}',
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontStyle: FontStyle.italic),
                    ),
                  ] else ...[
                    const SizedBox(height: 10),
                    TextButton.icon(
                      onPressed: _openEnterReferralCodeDialog,
                      icon: const Icon(Icons.loyalty_outlined, size: 16),
                      label: const Text('Have a friend\'s referral code? Redeem here'),
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        foregroundColor: AppTheme.primaryOrange,
                        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Menu Options
          Card(
            elevation: 0.5,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.location_on_outlined, color: AppTheme.primaryOrange),
                  title: const Text('Saved Addresses'),
                  subtitle: const Text('Manage your delivery landmarks & map pins'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    if (!auth.isAuthenticated) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      );
                      return;
                    }
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SavedAddressesScreen()),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.support_agent_outlined, color: AppTheme.primaryOrange),
                  title: const Text('Help / Contact Store'),
                  subtitle: const Text('Call the supermarket branch directly'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _contactStore,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.auto_awesome_outlined, color: Color(0xFFFF5200)),
                  title: const Text('App Welcome & Onboarding'),
                  subtitle: const Text('View intro guides and highlights'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const OnboardingScreen()),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.gavel_outlined, color: AppTheme.primaryOrange),
                  title: const Text('Terms & Conditions / Vigezo na Masharti'),
                  subtitle: const Text('Service agreement, delivery terms & return policies'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => TermsAndConditionsScreen.show(context),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.privacy_tip_outlined, color: AppTheme.primaryOrange),
                  title: const Text('Privacy Policy / Sera ya Faragha'),
                  subtitle: const Text('Data protection, PDPA rights & safety protocols'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => PrivacyPolicyScreen.show(context),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Sign Out or Sign In Button
          if (auth.isAuthenticated) ...[
            OutlinedButton.icon(
              onPressed: _confirmSignOut,
              icon: const Icon(Icons.logout, color: Colors.red),
              label: const Text(
                'Sign Out',
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
            const SizedBox(height: 14),
            TextButton.icon(
              onPressed: _confirmDeleteAccount,
              icon: Icon(Icons.delete_forever_outlined, color: Colors.grey.shade600, size: 18),
              label: Text(
                'Delete Account / Futa Akaunti',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ] else
            ElevatedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              ),
              icon: const Icon(Icons.login),
              label: const Text(
                'Sign In or Register',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),

          const SizedBox(height: 32),

          // Footer
          Center(
            child: Text(
              'Quickopia v1.0 (MVP)',
              style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _shareReferralCode(String code) async {
    final msg =
        '🛒 Shop with Quickopia Supermarket! Use my referral code *$code* on your first order for doorstep delivery or fast pickup in Dar es Salaam!\n\nDownload Quickopia app: https://quickopia.app';
    final url = Uri.parse('https://wa.me/?text=${Uri.encodeComponent(msg)}');
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(url);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open WhatsApp.')),
        );
      }
    }
  }

  Future<void> _openEnterReferralCodeDialog() async {
    final codeCtrl = TextEditingController();
    bool submitting = false;
    String? dialogError;

    await showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Enter Referral Code'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Enter the referral code given by your friend. You will both be recognized for loyalty rewards.',
                style: TextStyle(fontSize: 13, color: Colors.black87),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: codeCtrl,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  labelText: 'Referral Code (e.g. QK-7X9B2)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  errorText: dialogError,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: submitting
                  ? null
                  : () async {
                      final input = codeCtrl.text.trim();
                      if (input.isEmpty) {
                        setDialogState(() => dialogError = 'Please enter a code');
                        return;
                      }

                      setDialogState(() {
                        submitting = true;
                        dialogError = null;
                      });

                      final messenger = ScaffoldMessenger.of(context);
                      final authProvider = context.read<AuthProvider>();
                      try {
                        final res = await SupabaseConfig.client
                            .rpc('apply_referral_code', params: {'p_code': input});

                        final map = res as Map<String, dynamic>;
                        if (map['success'] == true) {
                          if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                          if (mounted) {
                            await authProvider.reloadProfile();
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text('Referral code applied successfully!'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        } else {
                          setDialogState(() {
                            dialogError =
                                map['error'] as String? ?? 'Failed to apply code';
                            submitting = false;
                          });
                        }
                      } catch (e) {
                        setDialogState(() {
                          dialogError = 'Network error. Please try again.';
                          submitting = false;
                        });
                      }
                    },
              child: Text(submitting ? 'Applying...' : 'Apply Code'),
            ),
          ],
        ),
      ),
    );
  }
}

