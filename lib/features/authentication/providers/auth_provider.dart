import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum AuthStatus { 
  initial, 
  authenticated, 
  unauthenticated, 
  emailUnverified,
  loading 
}

class AuthState {
  final AuthStatus status;
  final User? user;
  final String? errorMessage;

  AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.errorMessage,
  });

  AuthState copyWith({
    AuthStatus? status,
    User? user,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final Ref ref;
  final _supabase = Supabase.instance.client;

  AuthNotifier(this.ref) : super(AuthState()) {
    // Initialize auth status on creation
    _initializeAuthStatus();
  }

  Future<void> _initializeAuthStatus() async {
    try {
      final session = _supabase.auth.currentSession;
      final user = _supabase.auth.currentUser;

      // Listen for auth state changes
      _supabase.auth.onAuthStateChange.listen((data) {
        final AuthChangeEvent event = data.event;
        final Session? session = data.session;

        switch (event) {
          case AuthChangeEvent.signedIn:
            if (session != null) {
              _updateAuthStateFromSession(session);
            }
            break;
          case AuthChangeEvent.signedOut:
            state = state.copyWith(
              status: AuthStatus.unauthenticated,
              user: null,
            );
            break;
          case AuthChangeEvent.userUpdated:
            // Handle user profile updates if needed
            break;
          default:
            break;
        }
      });

      // Initial session check
      if (session != null && user != null) {
        _updateAuthStateFromSession(session);
      } else {
        state = state.copyWith(
          status: AuthStatus.unauthenticated,
          user: null,
        );
      }
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: e.toString(),
        user: null,
      );
    }
  }

  void _updateAuthStateFromSession(Session session) {
    final user = session.user;
    if (user.emailConfirmedAt == null) {
      state = state.copyWith(
        status: AuthStatus.emailUnverified,
        user: user,
      );
    } else {
      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: user,
      );
    }
  }

  Future<void> restoreSession() async {
    try {
      final session = _supabase.auth.currentSession;
      if (session != null) {
        _updateAuthStateFromSession(session);
      }
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: 'Session restoration failed: ${e.toString()}',
      );
    }
  }

  Future<void> signUp({
    required String email,
    required String password,
  }) async {
    try {
      state = state.copyWith(status: AuthStatus.loading);

      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
      );

      final user = response.user;
      if (user != null) {
        state = state.copyWith(
          status: AuthStatus.emailUnverified,
          user: user,
        );
        return;
      }

      // Signup failed
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: 'Signup failed',
      );
    } on AuthException catch (e) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: e.message,
      );
    }
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    try {
      state = state.copyWith(status: AuthStatus.loading);

      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      final session = response.session;
      final user = response.user;

      if (session != null && user != null) {
        _updateAuthStateFromSession(session);
      } else {
        state = state.copyWith(
          status: AuthStatus.unauthenticated,
          errorMessage: 'Login failed',
        );
      }
    } on AuthException catch (e) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: e.message,
      );
    }
  }

  Future<void> logout() async {
    try {
      await _supabase.auth.signOut();
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        user: null,
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Logout failed: ${e.toString()}',
      );
    }
  }

  void _logStateTransition(AuthStatus newStatus) {
    debugPrint('Auth State Transition: ${state.status} -> $newStatus');
  }

  void updateAuthStatus(AuthStatus newStatus) {
    _logStateTransition(newStatus);
    state = state.copyWith(status: newStatus);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref);
});