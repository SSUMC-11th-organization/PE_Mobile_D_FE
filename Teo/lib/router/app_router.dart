import 'package:go_router/go_router.dart';

import '../data/mock_movies.dart';
import '../screens/home_screen.dart';
import '../screens/main_screen.dart';
import '../screens/movie_detail_screen.dart';
import '../screens/movie_list_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/sign_up_screen.dart';
import '../screens/start_screen.dart';

class AppRouter {
  AppRouter._();

  static final router = GoRouter(
    initialLocation: '/start',
    routes: [
      GoRoute(path: '/start', builder: (context, state) => const StartScreen()),

      GoRoute(
        path: '/register',
        builder: (context, state) => const SignUpScreen(),
      ),

      ShellRoute(
        builder: (context, state, child) {
          return MainScreen(
            currentIndex: indexFromLocation(state.uri.path),
            child: child,
          );
        },
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => const HomeScreen(),
          ),

          GoRoute(
            path: '/movies',
            builder: (context, state) => const MovieListScreen(),
          ),

          GoRoute(
            path: '/my',
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),

      GoRoute(
        path: '/movies/:movieId',
        builder: (context, state) {
          final movieId = int.tryParse(state.pathParameters['movieId'] ?? '');

          final movie = findMovieById(movieId);

          return MovieDetailScreen(movie: movie);
        },
      ),
    ],
  );

  static int indexFromLocation(String path) {
    if (path.startsWith('/movies')) {
      return 1;
    }

    if (path.startsWith('/my')) {
      return 2;
    }

    return 0;
  }
}
