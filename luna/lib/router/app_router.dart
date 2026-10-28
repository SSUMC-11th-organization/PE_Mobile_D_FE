import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/services/tmdb_movie_service.dart';
import '../screens/home_screen.dart';
import '../screens/main_screen.dart';
import '../screens/movie_detail_screen.dart';
import '../screens/movie_list_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/sign_up_screen.dart';
import '../screens/start_screen.dart';
import '../view_models/movie_detail_view_model.dart';
import '../view_models/movie_home_view_model.dart';
import '../view_models/movie_list_view_model.dart';

/// 앱 전체에서 사용하는 Route를 한곳에서 관리한다.
/// 새 화면이 생기면 MaterialApp이 아니라 여기 routes에 GoRoute를 추가한다.
class AppRouter {
  AppRouter._(); // 외부에서 객체를 만들지 못하도록 막는 private 생성자

  // 앱 전체에서 라우터 하나만 쓰도록 static final로 선언
  static final router = GoRouter(
    initialLocation: '/start',
    routes: [
      GoRoute(path: '/start', builder: (context, state) => const StartScreen()),
      GoRoute(
        path: '/sign-up',
        builder: (context, state) => const SignUpScreen(),
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
                // 영화 목록 ViewModel도 Route에서 만들고, 생성 직후 장르·영화 목록을 한 번 불러온다
                builder: (context, state) =>
                    ChangeNotifierProvider<MovieListViewModel>(
                      create: (context) =>
                          MovieListViewModel(context.read<TmdbMovieService>())
                            ..loadInitial(),
                      child: const MovieListScreen(),
                    ),
                // 영화 탭에서 연 상세는 영화 탭 안에 쌓임: /movies/:movieId
                routes: [_movieDetailRoute(':movieId')],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/my',
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );

  // 같은 상세 화면을 홈·영화 탭에서 각각 사용하기 위한 Route 생성 함수.
  // Path Parameter의 TMDB 영화 ID로 상세 ViewModel을 만들고 바로 조회한다.
  static GoRoute _movieDetailRoute(String path) {
    return GoRoute(
      path: path,
      builder: (context, state) => ChangeNotifierProvider<MovieDetailViewModel>(
        create: (context) => MovieDetailViewModel(
          context.read<TmdbMovieService>(),
          // Path Parameter는 문자열이므로 숫자로 변환. 숫자가 아니면 null
          movieId: int.tryParse(state.pathParameters['movieId']!),
        )..load(),
        child: const MovieDetailScreen(),
      ),
    );
  }
}
