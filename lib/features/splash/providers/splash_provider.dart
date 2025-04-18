import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:note_sync/features/auth/providers/auth_provider.dart';

final splashInitializationProvider = FutureProvider<bool>((ref) async {
  await Future.delayed(const Duration(seconds: 2));

  await ref.read(authNotifierProvider.notifier).checkAuth();

  final authState = ref.read(authNotifierProvider);

  return authState.state == AuthState.authenticated;
});

class SplashController {
  final Ref _ref;

  SplashController(this._ref);

  Future<void> initializeAndNavigate(GoRouter router) async {
    try {
      final isAuthenticated =
          await _ref.read(splashInitializationProvider.future);

      if (isAuthenticated) {
        router.go('/notes');
      } else {
        router.go('/auth');
      }
    } catch (e) {
      router.go('/auth');
    }
  }
}

final splashControllerProvider = Provider<SplashController>((ref) {
  return SplashController(ref);
});
