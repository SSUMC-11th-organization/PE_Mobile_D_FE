import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/models/tmdb_movie_dto.dart';
import '../data/services/rating_api_service.dart';
import '../data/services/sign_up_service.dart';
import '../data/services/tmdb_movie_service.dart';
import '../screens/home_screen.dart';
import '../screens/login_screen.dart';
import '../screens/main_screen.dart';
import '../screens/movie_detail_loader.dart';
import '../screens/movie_list_screen.dart';
import '../screens/my_ratings_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/sign_up_screen.dart';
import '../screens/start_screen.dart';
import '../view_models/auth_view_model.dart';
import '../view_models/learning_member_session.dart';
import '../view_models/movie_home_view_model.dart';
import '../view_models/my_ratings_view_model.dart';
import '../view_models/sign_up_view_model.dart';

import '../data/services/member_api_service.dart';
import '../screens/edit_profile_screen.dart';
import '../view_models/edit_profile_view_model.dart';

import '../core/session/session_guard.dart';
import '../data/services/favorite_api_service.dart';
import '../view_models/favorite_detail_view_model.dart';
import '../screens/favorites_screen.dart';
import '../view_models/favorites_view_model.dart';
import '../view_models/paged_movies_view_model.dart';
import '../screens/movie_search_screen.dart';

String? authRedirect(AuthStatus status, String location) {
  const publicPaths = {'/login', '/register'};

  final atStart = location == '/start';
  final atPublic = publicPaths.contains(location);

  return switch (status) {
    AuthStatus.initializing ||
    AuthStatus.retryRequired => atStart ? null : '/start',

    AuthStatus.signedOut ||
    AuthStatus.authenticating => atPublic ? null : '/login',

    AuthStatus.signedIn => (atStart || atPublic) ? '/home' : null,
  };
}

class AppRouter {
  AppRouter._();

  static final rootNavigatorKey = GlobalKey<NavigatorState>();

  static GoRouter createRouter(AuthViewModel authViewModel) {
    return GoRouter(
      initialLocation: '/start',
      navigatorKey: rootNavigatorKey,

      refreshListenable: authViewModel,

      redirect: (context, state) {
        return authRedirect(authViewModel.status, state.uri.path);
      },

      routes: [
        GoRoute(path: '/', redirect: (context, state) => '/start'),

        GoRoute(
          path: '/start',
          builder: (context, state) {
            final auth = context.watch<AuthViewModel>();

            return SplashScreen(
              message: auth.message,
              onRetry: auth.status == AuthStatus.retryRequired
                  ? auth.restoreSession
                  : null,
            );
          },
        ),

        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),

        GoRoute(
          path: '/register',
          builder: (context, state) => ChangeNotifierProvider<SignUpViewModel>(
            create: (context) => SignUpViewModel(context.read<SignUpService>()),
            child: const SignUpScreen(),
          ),
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
              builder: (context, state) =>
                  ChangeNotifierProvider<MovieHomeViewModel>(
                    create: (context) =>
                        MovieHomeViewModel(context.read<TmdbMovieService>())
                          ..loadPopular(),
                    child: const HomeScreen(),
                  ),
            ),

            GoRoute(
              path: '/movies',
              builder: (context, state) =>
                  ChangeNotifierProvider<PagedMoviesViewModel>(
                    create: (context) => PagedMoviesViewModel(
                      tmdbApi: context.read<TmdbMovieService>(),
                    )..initialize(),
                    child: const MovieListScreen(),
                  ),
              routes: [
                GoRoute(
                  path: 'search',
                  parentNavigatorKey: rootNavigatorKey,
                  builder: (context, state) =>
                      ChangeNotifierProvider<PagedMoviesViewModel>(
                        create: (_) => PagedMoviesViewModel(
                          tmdbApi: context.read<TmdbMovieService>(),
                        ),
                        child: MovieSearchScreen(
                          onOpenMovie: (movie) async {
                            await context.push(
                              '/movies/${movie.id}',
                              extra: movie,
                            );
                          },
                        ),
                      ),
                ),
              ],
            ),

            GoRoute(
              path: '/my',
              builder: (context, state) => const ProfileScreen(),
              routes: [
                GoRoute(
                  path: 'ratings',
                  parentNavigatorKey: rootNavigatorKey,
                  builder: (context, state) {
                    final id = context.read<LearningMemberSession>().memberId;

                    if (id == null) {
                      return Scaffold(
                        appBar: AppBar(
                          centerTitle: true,
                          title: const Text('내가 등록한 평점'),
                        ),
                        body: const Center(child: Text('학습용 회원가입이 필요합니다.')),
                      );
                    }

                    return ChangeNotifierProvider<MyRatingsViewModel>(
                      create: (context) => MyRatingsViewModel(
                        context.read<RatingApiService>(),
                        context.read<TmdbMovieService>(),
                        id,
                      )..load(),
                      child: const MyRatingsScreen(),
                    );
                  },
                ),

                GoRoute(
                  path: 'favorites',
                  parentNavigatorKey: rootNavigatorKey,
                  builder: (context, state) {
                    final auth = context.watch<AuthViewModel>();
                    final member = auth.member;
                    final guard = context.read<SessionGuard>();

                    if (member == null || guard.accountId != member.email) {
                      return const Scaffold(
                        body: Center(child: CircularProgressIndicator()),
                      );
                    }

                    return ChangeNotifierProvider<FavoritesViewModel>(
                      key: ValueKey('${member.email}:${guard.generation}'),
                      create: (context) => FavoritesViewModel(
                        favoriteApi: context.read<FavoriteApiService>(),
                        tmdbApi: context.read<TmdbMovieService>(),
                        sessionGuard: guard,
                        accountId: member.email,
                      ),
                      child: FavoritesScreen(
                        onOpenMovie: (movie) async {
                          await context.push(
                            '/movies/${movie.id}',
                            extra: movie,
                          );
                        },
                      ),
                    );
                  },
                ),

                GoRoute(
                  path: 'profile/edit',
                  parentNavigatorKey: rootNavigatorKey,
                  builder: (context, state) {
                    final auth = context.watch<AuthViewModel>();

                    if (auth.member == null) {
                      return Scaffold(
                        appBar: AppBar(
                          centerTitle: true,
                          title: const Text('프로필 수정'),
                        ),
                        body: Center(
                          child: auth.memberStatus == MemberLoadStatus.error
                              ? TextButton(
                                  onPressed: () {
                                    auth.loadMember(force: true);
                                  },
                                  child: const Text('다시 시도'),
                                )
                              : const CircularProgressIndicator(),
                        ),
                      );
                    }

                    return ChangeNotifierProvider<EditProfileViewModel>(
                      create: (context) => EditProfileViewModel(
                        context.read<MemberApiService>(),
                        auth,
                      ),
                      child: const EditProfileScreen(),
                    );
                  },
                ),
              ],
            ),
          ],
        ),

        GoRoute(
          path: '/movies/:movieId',
          builder: (context, state) {
            final id = int.tryParse(state.pathParameters['movieId'] ?? '');

            if (id == null || id < 1) {
              return const Scaffold(
                body: Center(child: Text('영화 ID가 올바르지 않습니다.')),
              );
            }

            final auth = context.watch<AuthViewModel>();
            final member = auth.member;
            final guard = context.read<SessionGuard>();

            if (member == null || guard.accountId != member.email) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            final extra = state.extra;

            return ChangeNotifierProvider<FavoriteDetailViewModel>(
              key: ValueKey('${member.email}:${guard.generation}'),
              create: (_) => FavoriteDetailViewModel(
                movieId: id,
                favoriteApi: context.read<FavoriteApiService>(),
                sessionGuard: guard,
                accountId: member.email,
                onSessionExpired: auth.expireSession,
              ),
              child: MovieDetailLoader(
                movieId: id,
                initialMovie: extra is TmdbMovieDto && extra.id == id
                    ? extra
                    : null,
              ),
            );
          },
        ),
      ],
    );
  }

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
