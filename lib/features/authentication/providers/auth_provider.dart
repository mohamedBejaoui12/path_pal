import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/auth_service.dart';

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
  final _authService = AuthService();

  AuthNotifier(this.ref) : super(AuthState()) {
    // Initialize auth status on creation
    _initializeAuthStatus();
  }

  Future<void> _initializeAuthStatus() async {
    try {
      final session = _supabase.auth.currentSession;
      final user = _supabase.auth.currentUser;

      if (session != null && user != null) {
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
      } else {
        state = state.copyWith(status: AuthStatus.unauthenticated);
      }
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> signUp({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(status: AuthStatus.loading);

    try {
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
      }
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
    state = state.copyWith(status: AuthStatus.loading);

    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      final user = response.user;
      if (user != null) {
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
      state = state.copyWith(status: AuthStatus.unauthenticated);
    } catch (e) {
      debugPrint('Logout error: $e');
    }
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref);
});