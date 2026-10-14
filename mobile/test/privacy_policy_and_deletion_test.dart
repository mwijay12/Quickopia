import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:quickopia/models/profile_model.dart';
import 'package:quickopia/providers/auth_provider.dart';
import 'package:quickopia/providers/cart_provider.dart';
import 'package:quickopia/providers/order_history_provider.dart';
import 'package:quickopia/screens/auth/signup_screen.dart';
import 'package:quickopia/screens/customer/account_screen.dart';
import 'package:quickopia/screens/customer/privacy_policy_screen.dart';

class MockAuthProviderForPrivacy extends ChangeNotifier implements AuthProvider {
  @override
  AuthStatus status;
  @override
  Profile? profile;
  @override
  String? errorMessage;

  MockAuthProviderForPrivacy({
    this.status = AuthStatus.authenticated,
    this.profile,
  });

  @override
  bool get isAuthenticated => status == AuthStatus.authenticated && profile != null;

  @override
  Future<String?> signIn({required String email, required String password}) async => null;

  @override
  Future<Map<String, dynamic>> signUp({
    required String email,
    required String password,
    required String fullName,
    String? phone,
  }) async => {'success': true, 'requiresEmailConfirmation': false, 'error': null};

  @override
  Future<void> signOut() async {
    status = AuthStatus.unauthenticated;
    profile = null;
    notifyListeners();
  }

  @override
  Future<void> reloadProfile() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PrivacyPolicyScreen Tests', () {
    testWidgets('PrivacyPolicyScreen renders hero card, clauses, and language toggle', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: PrivacyPolicyScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // English initial view
      expect(find.text('Privacy Policy'), findsOneWidget);
      expect(find.text('Data Privacy & Protection'), findsOneWidget);
      expect(find.text('Your Data Subject Rights'), findsOneWidget);
      expect(find.text('1. Information We Collect'), findsOneWidget);
      expect(find.text('2. Location & GPS Data'), findsOneWidget);
      expect(find.text('3. Microphone & Voice Assistant Access'), findsOneWidget);
      expect(find.text('4. Financial & Payment Data'), findsOneWidget);
      expect(find.text('5. Third-Party Infrastructure & Security'), findsOneWidget);
      expect(find.text('6. Data Retention & Account Deletion'), findsOneWidget);
      expect(find.text('I Understand & Agree'), findsOneWidget);

      // Toggle to Kiswahili
      await tester.tap(find.text('Kiswahili'));
      await tester.pumpAndSettle();

      expect(find.text('Sera ya Faragha'), findsOneWidget);
      expect(find.text('Ulinzi wa Taarifa Binafsi (PDPA)'), findsOneWidget);
      expect(find.text('Haki Zako Kama Mtumiaji'), findsOneWidget);
      expect(find.text('1. Taarifa Tunazokusanya'), findsOneWidget);
      expect(find.text('2. Taarifa za Eneo na GPS'), findsOneWidget);
      expect(find.text('3. Matumizi ya Kipaza Sauti (Microphone)'), findsOneWidget);
      expect(find.text('Nimeelewa na Kukubaliana'), findsOneWidget);
    });
  });

  group('AccountScreen Privacy and Deletion Tests', () {
    testWidgets('AccountScreen includes Privacy Policy tile and Delete Account action', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final mockAuth = MockAuthProviderForPrivacy(
        status: AuthStatus.authenticated,
        profile: Profile(
          id: 'user-privacy-123',
          fullName: 'Amani Mwijage',
          role: 'customer',
          phone: '+255712345678',
        ),
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>.value(value: mockAuth),
            ChangeNotifierProvider<CartProvider>(create: (_) => CartProvider()),
            ChangeNotifierProvider<OrderHistoryProvider>(create: (_) => OrderHistoryProvider()),
          ],
          child: const MaterialApp(
            home: AccountScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Find Privacy Policy tile
      expect(find.text('Privacy Policy / Sera ya Faragha'), findsOneWidget);
      expect(find.text('Data protection, PDPA rights & safety protocols'), findsOneWidget);

      // Find Delete Account button
      final deleteBtn = find.text('Delete Account / Futa Akaunti');
      expect(deleteBtn, findsOneWidget);

      // Tap Delete Account to open confirmation dialog
      await tester.ensureVisible(deleteBtn);
      await tester.tap(deleteBtn);
      await tester.pumpAndSettle();

      // Verify confirmation dialog renders with warning and cancel action
      expect(find.text('Delete Account / Futa Akaunti'), findsWidgets);
      expect(find.text('Cancel / Ghairi'), findsOneWidget);
      expect(find.text('Delete Account / Futa'), findsOneWidget);

      // Tap Cancel to dismiss
      await tester.tap(find.text('Cancel / Ghairi'));
      await tester.pumpAndSettle();
      expect(find.text('Cancel / Ghairi'), findsNothing);
    });
  });

  group('SignUpScreen Legal Disclaimers Test', () {
    testWidgets('SignUpScreen links both Terms & Conditions and Privacy Policy', (tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>(create: (_) => MockAuthProviderForPrivacy(status: AuthStatus.unauthenticated)),
          ],
          child: const MaterialApp(
            home: SignUpScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Terms & Conditions'), findsOneWidget);
      expect(find.text('Privacy Policy / Sera ya Faragha'), findsOneWidget);
    });
  });
}
