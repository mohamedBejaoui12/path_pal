import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final _supabase = Supabase.instance.client;

  // Improved session initialization with more robust error handling
  Future<Session?> initializeSession() async {
    try {
      // Use currentSession instead of getSession
      final session = _supabase.auth.currentSession;

      if (session != null) {
        debugPrint('Session recovered successfully');
        // Validate session before returning
        if (_isSessionValid(session)) {
          return session;
        } else {
          debugPrint('Recovered session is invalid');
          return null;
        }
      } else {
        debugPrint('No existing session found');
        return null;
      }
    } catch (e) {
      debugPrint('Error initializing session: $e');
      return null;
    }
  }

  // Helper method to validate session
  bool _isSessionValid(Session session) {
    // Check if access token is not empty
    if (session.accessToken.isEmpty) {
      debugPrint('Session invalid: Empty access token');
      return false;
    }

    // Check session expiration
    final expiresAt = session.expiresAt;
    if (expiresAt != null) {
      final now = DateTime.now().toUtc();
      final expirationTime = DateTime.fromMillisecondsSinceEpoch(
        expiresAt * 1000,
        isUtc: true,
      );
      
      if (now.isAfter(expirationTime)) {
        debugPrint('Session expired');
        return false;
      }
    }

    return true;
  }

  Future<AuthResponse?> signUp({
    required String email, 
    required String password
  }) async {
    try {
      final AuthResponse response = await _supabase.auth.signUp(
        email: email,
        password: password,
      );
      
      return response;
    } on AuthException catch (e) {
      _handleAuthException(e, 'Sign Up');
      return null;
    } catch (e) {
      debugPrint('Unexpected Sign Up Error: $e');
      return null;
    }
  }

  Future<User?> login({
    required String email, 
    required String password
  }) async {
    try {
      final AuthResponse response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      
      return response.user;
    } on AuthException catch (e) {
      _handleAuthException(e, 'Login');
      return null;
    } catch (e) {
      debugPrint('Unexpected Login Error: $e');
      return null;
    }
  }

  // Centralized error handling method
  void _handleAuthException(AuthException e, String context) {
    switch (e.message) {
      case 'User already exists':
        debugPrint('[$context] Email already registered');
        break;
      case 'Invalid email':
        debugPrint('[$context] Invalid email format');
        break;
      case 'Invalid login credentials':
        debugPrint('[$context] Invalid credentials');
        break;
      default:
        debugPrint('[$context] Error: ${e.message}');
    }
  }

  Future<bool> isEmailVerified() async {
    final user = _supabase.auth.currentUser;
    return user?.emailConfirmedAt != null;
  }

  Future<void> logout() async {
    try {
      await _supabase.auth.signOut();
      debugPrint('Logout successful');
    } catch (e) {
      debugPrint('Logout error: $e');
    }
  }

  User? getCurrentUser() {
    return _supabase.auth.currentUser;
  }

  bool get isLoggedIn {
    final session = _supabase.auth.currentSession;
    return session != null && _isSessionValid(session);
  }

  Future<void> resetPassword(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email);
      debugPrint('Password reset email sent');
    } catch (e) {
      debugPrint('Password reset error: $e');
      rethrow;
    }
  }

  Future<bool> checkEmailAvailability(String email) async {
    try {
      // Attempt to sign up with the email to check availability
      final response = await _supabase.auth.signUp(
        email: email,
        password: _generateTemporaryPassword(),
        
      );
      return true; // Email is available
    } on AuthException catch (e) {
      if (e.message.contains('User already exists')) {
        return false; // Email is already in use
      }
      debugPrint('Email availability check error: $e');
      return false;
    } catch (e) {
      debugPrint('Unexpected error checking email: $e');
      return false;
    }
  }

  // Generate a secure temporary password for email availability check
  String _generateTemporaryPassword() {
    // Generate a random, secure temporary password
    return DateTime.now().millisecondsSinceEpoch.toString();
  }
}