import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum AuthStatus { unauthenticated, authenticated, emailUnverified }

class AuthState {
  final User? user;
  final AuthStatus status;

  AuthState({this.user, this.status = AuthStatus.authenticated});
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(AuthState()) {
    restoreSession();
  }

  final _supabase = Supabase.instance.client;

  Future<void> restoreSession() async {
    final session = _supabase.auth.currentSession;
    if (session != null) {
      if (session.user.emailConfirmedAt == null) {
        state =
            AuthState(user: session.user, status: AuthStatus.emailUnverified);
      } else {
        state = AuthState(user: session.user, status: AuthStatus.authenticated);
      }
    }
  }

  Future<void> login({required String email, required String password}) async {
    try {
      final response = await _supabase.auth
          .signInWithPassword(email: email, password: password);

      if (response.user?.emailConfirmedAt == null) {
        state =
            AuthState(user: response.user, status: AuthStatus.emailUnverified);
      } else {
        state =
            AuthState(user: response.user, status: AuthStatus.authenticated);
      }
    } on AuthException catch (e) {
      state = AuthState(status: AuthStatus.unauthenticated);
      
      rethrow;
    }
  }

  Future<void> signup({required String email, required String password}) async {
    try {
      final response =
          await _supabase.auth.signUp(email: email, password: password);

      state =
          AuthState(user: response.user, status: AuthStatus.emailUnverified);
    } on AuthException catch (e) {
      state = AuthState(status: AuthStatus.unauthenticated);
      rethrow;
    }
  }

  Future<void> updateAuthState(Session? session) async {
    if (session != null) {
      state = AuthState(
          user: session.user,
          status: session.user.emailConfirmedAt == null
              ? AuthStatus.emailUnverified
              : AuthStatus.authenticated);
    }
  }

  Future<void> logout() async {
    await _supabase.auth.signOut();
    state = AuthState(status: AuthStatus.unauthenticated);
  }

  Future<void> verifyOtp({required String email, required String token}) async {
    try {
      final response = await _supabase.auth
          .verifyOTP(email: email, token: token, type: OtpType.email);

      if (response.session != null) {
        state = AuthState(
            user: response.session!.user,
            status: response.session!.user.emailConfirmedAt == null
                ? AuthStatus.emailUnverified
                : AuthStatus.authenticated);
      }
    } on AuthException catch (e) {
      state = AuthState(status: AuthStatus.unauthenticated);
      rethrow;
    }
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
