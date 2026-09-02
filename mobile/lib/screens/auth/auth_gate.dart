import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../customer/customer_home_placeholder.dart';
import '../driver/driver_home_placeholder.dart';
import 'login_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    switch (auth.status) {
      case AuthStatus.loading:
        return const Scaffold(
          backgroundColor: AppTheme.neutralLight,
          body: Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accentAmber),
            ),
          ),
        );

      case AuthStatus.unauthenticated:
        return const LoginScreen();

      case AuthStatus.error:
        return Scaffold(
          backgroundColor: AppTheme.neutralLight,
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    auth.errorMessage ?? 'Something went wrong',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16, color: AppTheme.primaryDark),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => auth.signOut(),
                    child: const Text('Sign out and try again'),
                  ),
                ],
              ),
            ),
          ),
        );

      case AuthStatus.authenticated:
        final profile = auth.profile;
        if (profile == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Security gate: Admins must never operate from the mobile app
        if (profile.isAdmin) {
          return Scaffold(
            backgroundColor: AppTheme.primaryNavy,
            body: SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.desktop_windows,
                          color: Colors.white,
                          size: 48,
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Admin Access Required',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Admin accounts must use the Quickopia Admin Portal on the web.\nThe mobile application is reserved for customers and drivers.',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 28),
                      OutlinedButton(
                        onPressed: () => auth.signOut(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white54),
                        ),
                        child: const Text('Sign out'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        // Role-based destination: Driver vs Customer
        return profile.isDriver
            ? const DriverHomePlaceholder()
            : const CustomerHomePlaceholder();
    }
  }
}
