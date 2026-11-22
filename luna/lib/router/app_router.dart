import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/session/session_guard.dart';
import '../data/models/tmdb_movie_dto.dart';
import '../data/services/favorite_api_service.dart';
import '../data/services/member_api_service.dart';
import '../data/services/rating_api_service.dart';
import '../data/services/sign_up_service.dart';
import '../data/services/tmdb_movie_service.dart';
import '../screens/edit_profile_screen.dart';
import '../screens/favorites_screen.dart';
import '../screens/home_screen.dart';
import '../screens/login_screen.dart';
import '../screens/main_screen.dart';
import '../screens/movie_detail_screen.dart';
import '../screens/movie_list_screen.dart';
import '../screens/movie_search_screen.dart';
import '../screens/my_ratings_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/sign_up_screen.dart';
import '../screens/splash_screen.dart';
import '../services/movie_list_preference.dart';
import '../view_models/auth_view_model.dart';
import '../view_models/edit_profile_view_model.dart';
import '../view_models/favorite_detail_view_model.dart';
import '../view_models/favorites_view_model.dart';
import '../view_models/movie_detail_view_model.dart';
import '../view_models/movie_home_view_model.dart';
import '../view_models/movie_list_view_model.dart';
import '../view_models/my_ratings_view_model.dart';
import '../view_models/paged_movies_view_model.dart';
import '../view_models/session_rating_store.dart';
import '../view_models/sign_up_view_model.dart';
import '../widgets/common/movie_log_app_bar.dart';
import '../widgets/common/movie_log_button.dart';

/// 인증 상태에 맞는 경로를 정한다. redirect 안에서는 상태만 읽고 API를 호출하지 않는다.
String? authRedirect(AuthStatus status, String location) {
  const publicPaths = {'/login', '/sign-up'};
  final atStart = location == '/start';
  final atPublic = publicPaths.contains(location);

  return switch (status) {
    // 토큰 확인 중 또는 확인 실패(재시도 버튼): Splash 유지
    AuthStatus.initializing ||
    AuthStatus.retryRequired => atStart ? null : '/start',
    // 로그아웃 또는 로그인 요청 중: 로그인·회원가입 화면만 허용
    AuthStatus.signedOut ||
    AuthStatus.authenticating => atPublic ? null : '/login',
    // 로그인됨: Splash와 로그인·회원가입 화면은 홈으로 보냄
    AuthStatus.signedIn => (atStart || atPublic) ? '/home' : null,
  };
}

/// 앱 전체에서 사용하는 Route를 한곳에서 관리한다.
/// 새 화면이 생기면 MaterialApp이 아니라 여기 routes에 GoRoute를 추가한다.
class AppRouter {
  AppRouter._(); // 외부에서 객체를 만들지 못하도록 막는 private 생성자

  // 하단 NavigationBar 바깥의 root Navigator를 가리키는 키
  static final rootNavigatorKey = GlobalKey<NavigatorState>();

  // redirect가 AuthViewModel을 읽어야 하므로 인스턴스를 받아 만든다.
  // 앱이 살아 있는 동안 한 번만 만들어야 한다(_MovieLogRouterApp의 initState).
  static GoRouter createRouter(AuthViewModel authViewModel) {
    return GoRouter(
      initialLocation: '/start',
      navigatorKey: rootNavigatorKey,
      // 인증 상태(status)가 바뀌면 사용자가 이동하지 않아도 redirect를 다시 실행한다
      refreshListenable: authViewModel.statusListenable,
      redirect: (context, state) =>
          authRedirect(authViewModel.status, state.uri.path),
      routes: [
        GoRoute(
          path: '/start', // Splash: 토큰 확인 중 / 확인 실패 시 재시도
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
          path: '/sign-up',
          // 중복 확인 상태는 회원가입 화면에서만 쓰므로 이 Route에서 ViewModel을 만든다
          builder: (context, state) => ChangeNotifierProvider<SignUpViewModel>(
            create: (context) => SignUpViewModel(context.read<SignUpService>()),
            child: const SignUpScreen(),
          ),
        ),
        // 탭마다 독립된 Navigator(Branch)를 두고 IndexedStack으로 모두 유지
        // → 탭을 바꿔도 각 탭의 화면 Stack·스크롤·필터 상태가 남음
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) {
            return MainScreen(navigationShell: navigationShell);
          },
          branches: [
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/home',
                  // 홈 ViewModel은 이 Route에서 만들고, 생성 직후 한 번만 인기 영화를 요청한다.
                  // (build마다 요청이 반복되지 않음. indexedStack이라 탭을 바꿔도 유지됨)
                  builder: (context, state) =>
                      ChangeNotifierProvider<MovieHomeViewModel>(
                        create: (context) =>
                            MovieHomeViewModel(context.read<TmdbMovieService>())
                              ..loadPopular(),
                        child: const HomeScreen(),
                      ),
                  // 홈에서 연 상세는 홈 탭 안에 쌓임: /home/movies/:movieId
                  routes: [_movieDetailRoute('movies/:movieId')],
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/movies',
                  // 영화 목록 ViewModel도 Route에서 만들고, 생성 직후 장르·첫 page를 한 번 불러온다
                  builder: (context, state) =>
                      ChangeNotifierProvider<MovieListViewModel>(
                        create: (context) => MovieListViewModel(
                          context.read<TmdbMovieService>(),
                          preference: context.read<MovieListPreference>(),
                        )..initialize(),
                        child: const MovieListScreen(),
                      ),
                  routes: [
                    // 정적인 search를 동적인 :movieId보다 먼저 등록한다.
                    // 순서가 바뀌면 'search'가 영화 ID로 해석된다
                    GoRoute(
                      path: 'search', // 최종 경로: /movies/search
                      parentNavigatorKey: rootNavigatorKey,
                      // 영화 목록과 별도의 PagedMoviesViewModel 인스턴스를 쓴다
                      builder: (context, state) =>
                          ChangeNotifierProvider<PagedMoviesViewModel>(
                            create: (context) => PagedMoviesViewModel(
                              tmdbApi: context.read<TmdbMovieService>(),
                            ),
                            child: MovieSearchScreen(
                              onOpenMovie: (movie) => context.push(
                                '/movies/search/${movie.id}',
                                extra: movie,
                              ),
                            ),
                          ),
                      // 검색 결과에서 연 상세: /movies/search/:movieId
                      routes: [
                        _movieDetailRoute(
                          ':movieId',
                          parentNavigatorKey: rootNavigatorKey,
                        ),
                      ],
                    ),
                    // 영화 탭에서 연 상세는 영화 탭 안에 쌓임: /movies/:movieId
                    _movieDetailRoute(':movieId'),
                  ],
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/my',
                  builder: (context, state) => const ProfileScreen(),
                  routes: [
                    GoRoute(
                      path: 'ratings', // 최종 경로: /my/ratings
                      // 탭 Navigator가 아닌 root Navigator 위에 표시해 하단 NavigationBar를 가린다
                      parentNavigatorKey: rootNavigatorKey,
                      // 7주차의 memberId 대신 토큰 기반 Service와 이번 세션의 평점 목록을 쓴다
                      builder: (context, state) =>
                          ChangeNotifierProvider<MyRatingsViewModel>(
                            create: (context) => MyRatingsViewModel(
                              context.read<RatingApiService>(),
                              context.read<TmdbMovieService>(),
                              context.read<SessionRatingStore>(),
                              context.read<AuthViewModel>(),
                            )..load(),
                            child: const MyRatingsScreen(),
                          ),
                    ),
                    GoRoute(
                      path: 'favorites', // 최종 경로: /my/favorites
                      parentNavigatorKey: rootNavigatorKey,
                      builder: (context, state) => const _FavoritesRoute(),
                      // 즐겨찾기에서 연 상세도 root Navigator 위에 쌓는다: /my/favorites/:movieId
                      routes: [
                        _movieDetailRoute(
                          ':movieId',
                          parentNavigatorKey: rootNavigatorKey,
                        ),
                      ],
                    ),
                    GoRoute(
                      path: 'profile/edit', // 최종 경로: /my/profile/edit
                      parentNavigatorKey: rootNavigatorKey,
                      builder: (context, state) {
                        final auth = context.watch<AuthViewModel>();
                        // 내 정보를 아직 못 받았으면 수정할 값이 없으므로 로딩·재시도만 보여준다
                        if (auth.member == null) {
                          return Scaffold(
                            appBar: const MovieLogAppBar(
                              title: '프로필 수정',
                              showBackButton: true,
                              centerTitle: true,
                              fallbackLocation: '/my',
                            ),
                            body: Center(
                              child: auth.memberStatus == MemberLoadStatus.error
                                  ? MovieLogButton(
                                      label: '다시 시도',
                                      width: 120,
                                      onPressed: () =>
                                          auth.loadMember(force: true),
                                    )
                                  : const CircularProgressIndicator(),
                            ),
                          );
                        }
                        // 프로필 수정 화면에서만 쓰는 ViewModel이므로 Route에서 만든다
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
          ],
        ),
      ],
    );
  }

  // 같은 상세 화면을 홈·영화 탭·내 즐겨찾기에서 각각 사용하기 위한 Route 생성 함수.
  // Path Parameter의 TMDB 영화 ID로 상세 ViewModel을 만들고 바로 조회한다.
  // parentNavigatorKey를 주면 하단 NavigationBar 바깥(root)에 표시한다.
  static GoRoute _movieDetailRoute(
    String path, {
    GlobalKey<NavigatorState>? parentNavigatorKey,
  }) {
    return GoRoute(
      path: path,
      parentNavigatorKey: parentNavigatorKey,
      builder: (context, state) {
        // Path Parameter는 문자열이므로 숫자로 변환. 숫자가 아니면 null
        final id = int.tryParse(state.pathParameters['movieId']!);
        // extra는 Deep Link로 들어오면 없으므로 URL의 ID와 일치할 때만 사용한다
        final extra = state.extra;
        return ChangeNotifierProvider<MovieDetailViewModel>(
          create: (context) => MovieDetailViewModel(
            context.read<TmdbMovieService>(),
            context.read<RatingApiService>(),
            context.read<AuthViewModel>(),
            context.read<SessionRatingStore>(),
            movieId: id,
            initialMovie: extra is TmdbMovieDto && extra.id == id
                ? extra
                : null,
          )..load(),
          // 즐겨찾기 상태는 계정·세션마다 새로 만든다. 영화 정보 ViewModel은 그대로 둔다
          child: _FavoriteDetailScope(
            movieId: id ?? 0,
            child: const MovieDetailScreen(),
          ),
        );
      },
    );
  }
}

/// 상세 화면에 현재 세션의 FavoriteDetailViewModel을 제공한다.
/// ValueKey(email:generation)가 바뀌면(로그아웃·계정 전환·재로그인) 이전 계정의 ViewModel을
/// 버리고 새로 만든다. 닉네임 수정이나 build 재실행으로는 key가 바뀌지 않는다.
class _FavoriteDetailScope extends StatelessWidget {
  const _FavoriteDetailScope({required this.movieId, required this.child});

  final int movieId;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    final member = auth.member;
    final guard = context.read<SessionGuard>();
    // 내 정보가 준비되고 현재 세션과 일치할 때만 계정을 넘긴다.
    // 그전에는 영화 정보는 보여주고 북마크 자리만 로딩으로 둔다
    final accountId = member != null && guard.accountId == member.email
        ? member.email
        : null;

    return ChangeNotifierProvider<FavoriteDetailViewModel>(
      key: ValueKey(
        accountId == null ? 'pending' : '$accountId:${guard.generation}',
      ),
      create: (context) {
        // 이 ViewModel이 속한 세션 번호. 다른 세션이면 expireSession이 무시한다
        final sessionVersion = auth.sessionVersion;
        return FavoriteDetailViewModel(
          movieId: movieId,
          favoriteApi: context.read<FavoriteApiService>(),
          sessionGuard: guard,
          accountId: accountId,
          onSessionExpired: () =>
              auth.expireSession(requestVersion: sessionVersion),
        );
      },
      child: child,
    );
  }
}

/// /my/favorites. 내 정보(member)가 준비되면 현재 세션의 FavoritesViewModel을 만든다.
/// 즐겨찾기 API에는 memberId를 보내지 않고 JWT로 사용자를 구분하며,
/// email은 화면 쪽 세션 구분(ValueKey·SessionGuard)에만 쓴다.
class _FavoritesRoute extends StatelessWidget {
  const _FavoritesRoute();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    final member = auth.member;
    final guard = context.read<SessionGuard>();

    if (member == null || guard.accountId != member.email) {
      return Scaffold(
        appBar: const MovieLogAppBar(
          title: '내 즐겨찾기',
          showBackButton: true,
          centerTitle: true,
          fallbackLocation: '/my',
        ),
        body: Center(
          // 내 정보 로딩이 실패했으면 인디케이터만 계속 보여주지 않고 재시도를 연다
          child: auth.memberStatus == MemberLoadStatus.error
              ? MovieLogButton(
                  label: '내 정보 다시 조회',
                  width: 180,
                  onPressed: () => auth.loadMember(force: true),
                )
              : const CircularProgressIndicator(),
        ),
      );
    }

    return ChangeNotifierProvider<FavoritesViewModel>(
      // 계정이나 세션이 바뀌면 이전 사용자의 목록을 버리고 새 ViewModel을 만든다
      key: ValueKey('${member.email}:${guard.generation}'),
      create: (context) {
        final sessionVersion = auth.sessionVersion;
        return FavoritesViewModel(
          favoriteApi: context.read<FavoriteApiService>(),
          tmdbApi: context.read<TmdbMovieService>(),
          sessionGuard: guard,
          accountId: member.email,
          onSessionExpired: () =>
              auth.expireSession(requestVersion: sessionVersion),
        );
      },
      child: FavoritesScreen(
        onOpenMovie: (movieId) => context.push('/my/favorites/$movieId'),
      ),
    );
  }
}
