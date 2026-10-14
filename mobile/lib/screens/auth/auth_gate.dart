import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../customer/customer_shell.dart';
import '../driver/driver_shell.dart';
import '../onboarding/onboarding_screen.dart';

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
        return FutureBuilder<bool>(
          future: OnboardingScreen.hasSeenOnboarding(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Scaffold(
                backgroundColor: AppTheme.neutralLight,
                body: Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accentAmber),
                  ),
                ),
              );
            }
            final hasSeen = snapshot.data ?? false;
            return hasSeen ? const CustomerShell() : const OnboardingScreen();
          },
        );

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

        // Role-based destination: Drivers go to DriverShell,
        // Customers and Admins/Staff enjoy the Customer mobile storefront.
        return profile.isDriver
            ? const DriverShell()
            : const CustomerShell();
    }
  }
}
