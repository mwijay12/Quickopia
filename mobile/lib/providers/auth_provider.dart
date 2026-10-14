import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/profile_model.dart';
import '../services/auth_service.dart';

enum AuthStatus { loading, unauthenticated, authenticated, error }

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  StreamSubscription? _authSub;

  AuthStatus status = AuthStatus.loading;
  Profile? profile;
  String? errorMessage;
  bool _isLoadingProfile = false;

  AuthProvider() {
    _init();
  }

  void _init() {
    // React to login/logout/token-refresh events automatically,
    // including restoring a session on app restart.
    try {
      _authSub = _authService.authStateChanges.listen((state) async {
        final session = state.session;
        if (session == null) {
          status = AuthStatus.unauthenticated;
          profile = null;
          errorMessage = null;
          notifyListeners();
        } else {
          await _loadProfile();
        }
      }, onError: (e) {
        status = AuthStatus.unauthenticated;
        notifyListeners();
      });

      // Handle cold-start where a stored session exists before stream emits
      if (_authService.currentSession != null) {
        _loadProfile();
      } else {
        status = AuthStatus.unauthenticated;
      }
    } catch (e) {
      status = AuthStatus.unauthenticated;
    }
  }

  Future<void> _loadProfile() async {
    if (_isLoadingProfile) return;
    _isLoadingProfile = true;

    status = AuthStatus.loading;
    notifyListeners();

    try {
      final fetchedProfile = await _authService.fetchCurrentProfile();
      if (fetchedProfile == null) {
        status = AuthStatus.error;
        errorMessage = 'Could not load your profile. Please try again.';
      } else {
        profile = fetchedProfile;
        status = AuthStatus.authenticated;
        errorMessage = null;
      }
    } catch (e) {
      status = AuthStatus.error;
      errorMessage = 'Something went wrong loading your account.';
    } finally {
      _isLoadingProfile = false;
    }
    notifyListeners();
  }

  bool get isAuthenticated => status == AuthStatus.authenticated && profile != null;

  Future<void> reloadProfile() => _loadProfile();

  Future<Map<String, dynamic>> signUp({
    required String email,
    required String password,
    required String fullName,
    String? phone,
  }) async {
    try {
      final res = await _authService.signUp(
        email: email,
        password: password,
        fullName: fullName,
        phone: phone,
      );
      final bool requiresEmailConfirmation = res.session == null;
      return {
        'success': true,
        'requiresEmailConfirmation': requiresEmailConfirmation,
        'error': null,
      };
    } on Exception catch (e) {
      return {
        'success': false,
        'requiresEmailConfirmation': false,
        'error': _friendlyError(e),
      };
    } catch (e) {
      return {
        'success': false,
        'requiresEmailConfirmation': false,
        'error': 'Unexpected error. Please check your connection and try again.',
      };
    }
  }

  Future<String?> signIn({required String email, required String password}) async {
    try {
      await _authService.signIn(email: email, password: password);
      // Immediately load profile so caller has role and full profile populated
      await _loadProfile();
      return null;
    } on Exception catch (e) {
      return _friendlyError(e);
    } catch (e) {
      return 'Unexpected error. Please try again.';
    }
  }

  Future<void> signOut() async {
    try {
      await _authService.signOut();
    } catch (_) {
      // Force local logout even if network fails
      status = AuthStatus.unauthenticated;
      profile = null;
      notifyListeners();
    }
  }

  String _friendlyError(Exception e) {
    final msg = e.toString().toLowerCase();
    if (msg.contains('invalid login credentials')) {
      return 'Incorrect email or password.';
    } else if (msg.contains('user already registered')) {
      return 'An account with this email already exists.';
    } else if (msg.contains('password should be at least')) {
      return 'Password must be at least 6 characters.';
    } else if (msg.contains('email not confirmed')) {
      return 'Email not confirmed. Please disable "Confirm email" in Supabase Auth settings.';
    } else if (msg.contains('network') || msg.contains('socket') || msg.contains('failed host lookup')) {
      return 'Network error. Please check your connection.';
    }
    return 'Something went wrong. Please try again.';
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }
}
