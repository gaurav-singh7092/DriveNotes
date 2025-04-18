import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:note_sync/features/auth/providers/auth_provider.dart';
import 'package:note_sync/presentation/screens/auth_screen.dart';
import 'package:note_sync/presentation/screens/notes_list_screen.dart';
import 'package:note_sync/presentation/screens/note_detail_screen.dart';
import 'package:note_sync/presentation/screens/splash_screen.dart';

final goRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authNotifierProvider);

  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final location = state.matchedLocation;
      final isLoggedIn = authState.state == AuthState.authenticated;

      if (location == '/splash') {
        return null;
      }

      if (!isLoggedIn && location != '/auth') {
        return '/auth';
      }

      if (isLoggedIn && location == '/auth') {
        return '/notes';
      }

      return null;
    },
    refreshListenable: RouterNotifier(ref),
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/auth',
        builder: (context, state) => const AuthScreen(),
      ),
      GoRoute(
        path: '/notes',
        builder: (context, state) => const NotesListScreen(),
        routes: [
          GoRoute(
            path: 'detail/:noteId',
            builder: (context, state) {
              final noteId = state.pathParameters['noteId']!;
              return NoteDetailScreen(noteId: noteId);
            },
          ),
          GoRoute(
            path: 'new',
            builder: (context, state) =>
                const NoteDetailScreen(isNewNote: true),
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('Not Found')),
      body: Center(
        child: Text('Page not found: ${state.matchedLocation}'),
      ),
    ),
  );
});

class RouterNotifier extends ChangeNotifier {
  final Ref _ref;

  RouterNotifier(this._ref) {
    _ref.listen(authNotifierProvider, (previous, next) {
      if (previous?.state != next.state) {
        notifyListeners();
      }
    });
  }
}
