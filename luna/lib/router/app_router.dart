import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/models/tmdb_movie_dto.dart';
import '../data/services/rating_api_service.dart';
import '../data/services/sign_up_service.dart';
import '../data/services/tmdb_movie_service.dart';
import '../screens/home_screen.dart';
import '../screens/main_screen.dart';
import '../screens/movie_detail_screen.dart';
import '../screens/movie_list_screen.dart';
import '../screens/my_ratings_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/sign_up_screen.dart';
import '../screens/start_screen.dart';
import '../view_models/learning_member_session.dart';
import '../view_models/movie_detail_view_model.dart';
import '../view_models/movie_home_view_model.dart';
import '../view_models/movie_list_view_model.dart';
import '../view_models/my_ratings_view_model.dart';
import '../view_models/sign_up_view_model.dart';
import '../widgets/common/movie_log_app_bar.dart';

/// 앱 전체에서 사용하는 Route를 한곳에서 관리한다.
/// 새 화면이 생기면 MaterialApp이 아니라 여기 routes에 GoRoute를 추가한다.
class AppRouter {
  AppRouter._(); // 외부에서 객체를 만들지 못하도록 막는 private 생성자

  // 하단 NavigationBar 바깥의 root Navigator를 가리키는 키
  static final rootNavigatorKey = GlobalKey<NavigatorState>();

  // 앱 전체에서 라우터 하나만 쓰도록 static final로 선언
  static final router = GoRouter(
    initialLocation: '/start',
    navigatorKey: rootNavigatorKey,
    routes: [
      GoRoute(path: '/start', builder: (context, state) => const StartScreen()),
      GoRoute(
        path: '/sign-up',
        // 중복 확인 상태는 회원가입 화면에서만 쓰므로 이 Route에서 ViewModel을 만든다
        builder: (context, state) => ChangeNotifierProvider<SignUpViewModel>(
          create: (context) =>
              SignUpViewModel(context.read<SignUpService>()),
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
                routes: [
                  GoRoute(
                    path: 'ratings', // 최종 경로: /my/ratings
                    // 탭 Navigator가 아닌 root Navigator 위에 표시해 하단 NavigationBar를 가린다
                    parentNavigatorKey: rootNavigatorKey,
                    builder: (context, state) {
                      final id = context.read<LearningMemberSession>().memberId;
                      if (id == null) {
                        return const Scaffold(
                          appBar: MovieLogAppBar(
                            title: '내가 등록한 평점',
                            showBackButton: true,
                            centerTitle: true,
                            fallbackLocation: '/my',
                          ),
                          body: Center(child: Text('학습용 회원가입이 필요합니다.')),
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
                ],
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
      builder: (context, state) {
        // Path Parameter는 문자열이므로 숫자로 변환. 숫자가 아니면 null
        final id = int.tryParse(state.pathParameters['movieId']!);
        // extra는 Deep Link로 들어오면 없으므로 URL의 ID와 일치할 때만 사용한다
        final extra = state.extra;
        return ChangeNotifierProvider<MovieDetailViewModel>(
          create: (context) => MovieDetailViewModel(
            context.read<TmdbMovieService>(),
            context.read<RatingApiService>(),
            movieId: id,
            memberId: context.read<LearningMemberSession>().memberId,
            initialMovie: extra is TmdbMovieDto && extra.id == id
                ? extra
                : null,
          )..load(),
          child: const MovieDetailScreen(),
        );
      },
    );
  }
}
