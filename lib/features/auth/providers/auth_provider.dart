import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:note_sync/features/auth/services/auth_service.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

enum AuthState {
  initial,
  authenticated,
  unauthenticated,
  loading,
  error,
}

class AuthStateData {
  final AuthState state;
  final String? error;
  final AccessCredentials? credentials;

  AuthStateData({
    required this.state,
    this.error,
    this.credentials,
  });

  AuthStateData copyWith({
    AuthState? state,
    String? error,
    AccessCredentials? credentials,
  }) {
    return AuthStateData(
      state: state ?? this.state,
      error: error ?? this.error,
      credentials: credentials ?? this.credentials,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthStateData> {
  final AuthService _authService;

  AuthNotifier(this._authService)
      : super(AuthStateData(state: AuthState.initial));

  Future<void> checkAuth() async {
    state = state.copyWith(state: AuthState.loading);

    try {
      final isSignedIn = await _authService.isSignedIn();

      if (isSignedIn) {
        final credentials = await _authService.refreshCredentialsIfNeeded();

        if (credentials != null) {
          state = AuthStateData(
            state: AuthState.authenticated,
            credentials: credentials,
          );
          return;
        }
      }

      state = AuthStateData(state: AuthState.unauthenticated);
    } catch (e) {
      state = AuthStateData(
        state: AuthState.error,
        error: e.toString(),
      );
    }
  }

  Future<void> signIn() async {
    state = state.copyWith(state: AuthState.loading);

    try {
      final credentials = await _authService.signIn();

      if (credentials != null) {
        state = AuthStateData(
          state: AuthState.authenticated,
          credentials: credentials,
        );
      } else {
        state = AuthStateData(
          state: AuthState.unauthenticated,
          error: "Authentication failed",
        );
      }
    } catch (e) {
      state = AuthStateData(
        state: AuthState.unauthenticated,
        error: e.toString(),
      );
    }
  }

  Future<void> signOut() async {
    state = state.copyWith(state: AuthState.loading);

    try {
      await _authService.signOut();
      state = AuthStateData(state: AuthState.unauthenticated);
    } catch (e) {
      state = AuthStateData(
        state: AuthState.error,
        error: e.toString(),
      );
    }
  }

  Future<AccessCredentials?> getCredentials() async {
    if (state.state == AuthState.authenticated && state.credentials != null) {
      return await _authService.refreshCredentialsIfNeeded();
    }
    return null;
  }
}

final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AuthStateData>((ref) {
  final authService = ref.watch(authServiceProvider);
  return AuthNotifier(authService);
});
