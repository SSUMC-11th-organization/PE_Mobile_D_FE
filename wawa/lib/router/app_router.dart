import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/services/member_check_service.dart';
import '../data/services/rating_api_service.dart';
import '../data/services/tmdb_movie_service.dart';
import '../screens/my_ratings_screen.dart';
import '../view_models/my_ratings_view_model.dart';
import '../view_models/sign_up_view_model.dart';
import '../screens/home_screen.dart';
import '../screens/main_screen.dart';
import '../screens/movie_detail_screen.dart';
import '../screens/movie_list_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/sign_up_screen.dart';
import '../start_screen.dart';
import '../view_models/movie_home_view_model.dart';
import '../view_models/movie_list_view_model.dart';

class AppRouter {
  AppRouter._(); // 외부에서 객체 생성을 막는 private 생성자

  // root Navigator를 가리키는 키를 클래스에서 한 번만 선언합니다.
  static final rootNavigatorKey = GlobalKey<NavigatorState>();

  static final router = GoRouter(
    initialLocation: '/start', // 앱이 켤 때 처음 보여줄 위치
    navigatorKey: rootNavigatorKey, // GoRouter 전체가 사용할 root Navigator로 등록합니다.
    routes: [
      GoRoute(
        path: '/start',
        builder: (context, state) => const StartScreen(), // 시작 화면
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => ChangeNotifierProvider<SignUpViewModel>(
          create: (context) => SignUpViewModel(
            context.read<MemberCheckService>(),
          ),
          child: const SignUpScreen(), // 회원가입 화면
        ),
      ),
      ShellRoute(
        builder: (context, state, child) {
          return MainScreen(
            currentIndex: _indexFromLocation(state.uri.path),
            child: child,
          );
        },
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => ChangeNotifierProvider<MovieHomeViewModel>(
              create: (context) => MovieHomeViewModel(
                context.read<TmdbMovieService>(),
              )..loadPopular(),
              child: const HomeScreen(),
            ),
          ),
          GoRoute(
            path: '/movies',
            builder: (context, state) => ChangeNotifierProvider<MovieListViewModel>(
              create: (context) => MovieListViewModel(
                context.read<TmdbMovieService>(),
              )..loadInitial(),
              child: const MovieListScreen(),
            ),
          ),
          GoRoute(
            path: '/my',
            builder: (context, state) => const ProfileScreen(),
            routes: [
              GoRoute(
                path: 'ratings', // 최종 경로: /my/ratings
                parentNavigatorKey: rootNavigatorKey, // root Navigator 위에 표시해 하단 NavigationBar를 가립니다.
                builder: (context, state) => ChangeNotifierProvider<MyRatingsViewModel>(
                  create: (context) => MyRatingsViewModel(
                    context.read<RatingApiService>(),
                    context.read<TmdbMovieService>(),
                    sampleMemberId, // 6주차는 학습용 ID 1입니다.
                  )..load(),
                  child: const MyRatingsScreen(),
                ),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/movies/:movieId',
        builder: (context, state) => MovieDetailScreen(
          movieId: int.parse(state.pathParameters['movieId']!),
        ),
      ),
    ],
  );

  static int _indexFromLocation(String path) {
    if (path.startsWith('/movies')) return 1;
    if (path.startsWith('/my')) return 2;
    return 0;
  }
}
