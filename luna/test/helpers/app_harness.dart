import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:movielog/core/session/auth_session_bridge.dart';
import 'package:movielog/core/session/session_guard.dart';
import 'package:movielog/data/models/tmdb_genre_dto.dart';
import 'package:movielog/data/models/tmdb_movie_dto.dart';
import 'package:movielog/data/models/tmdb_movie_page.dart';
import 'package:movielog/data/services/favorite_api_service.dart';
import 'package:movielog/data/services/member_api_service.dart';
import 'package:movielog/data/services/rating_api_service.dart';
import 'package:movielog/data/services/tmdb_movie_service.dart';
import 'package:movielog/models/movie_sort_order.dart';
import 'package:movielog/router/app_router.dart';
import 'package:movielog/services/movie_list_preference.dart';
import 'package:movielog/services/saved_email_preference.dart';
import 'package:movielog/theme/app_theme.dart';
import 'package:movielog/view_models/auth_view_model.dart';
import 'package:movielog/view_models/session_rating_store.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import 'fake_auth.dart';
import 'fake_favorites.dart';

/// 앱 Router 전체를 띄우는 테스트용 TMDB Service.
/// 상세는 FakeTmdbDetailService, 목록·검색은 정해 둔 결과를 돌려준다.
class FakeAppTmdbService extends FakeTmdbDetailService {
  final searchQueries = <String>[];
  Object? searchError;
  List<TmdbMovieDto> searchResults = [testMovie(550, '별빛 아래 우리')];

  @override
  Future<TmdbMoviePageDto> fetchPopular({int page = 1}) async =>
      const TmdbMoviePageDto(
        page: 1,
        results: [],
        totalPages: 1,
        totalResults: 0,
      );

  @override
  Future<List<TmdbGenreDto>> fetchGenres() async => const [
    TmdbGenreDto(id: 18, name: '드라마'),
  ];

  @override
  Future<TmdbMoviePageDto> discoverMovies({
    required int page,
    List<int>? genreIds,
  }) async => TmdbMoviePageDto(
    page: page,
    results: [testMovie(page * 10, '목록 영화 $page')],
    totalPages: 1,
    totalResults: 1,
  );

  @override
  Future<TmdbMoviePageDto> searchMovies({
    required int page,
    required String query,
  }) async {
    searchQueries.add(query);
    if (searchError != null) throw searchError!;
    return TmdbMoviePageDto(
      page: page,
      results: searchResults,
      totalPages: 1,
      totalResults: searchResults.length,
    );
  }
}

/// 기기 저장소 대신 메모리에 두는 영화 목록 설정.
class MemoryMovieListPreference implements MovieListPreference {
  List<int>? genreIds;
  MovieSortOrder sortOrder = MovieSortOrder.basic;

  @override
  Future<List<int>?> readGenreIds() async => genreIds;
  @override
  Future<void> saveGenreIds(List<int>? genreIds) async =>
      this.genreIds = genreIds;
  @override
  Future<MovieSortOrder> readSortOrder() async => sortOrder;
  @override
  Future<void> saveSortOrder(MovieSortOrder order) async => sortOrder = order;
  @override
  Future<void> clear() async {}
}

TmdbMovieDto testMovie(int id, String title) => TmdbMovieDto(
  id: id,
  title: title,
  overview: '',
  posterPath: null,
  backdropPath: null,
  releaseDate: '2025-01-01',
  genreIds: const [18],
  voteAverage: 8,
  popularity: 0,
);

class TestApp {
  TestApp(this.router, this.auth, this.favorites, this.memberApi, this.tmdb);

  final GoRouter router;
  final AuthViewModel auth;
  final FakeFavoriteApiService favorites;
  final FakeMemberApiService memberApi;
  final FakeAppTmdbService tmdb;
}

/// 로그인된 세션으로 앱 Router와 9주차 Provider(세션 가드·즐겨찾기)를 띄운다.
Future<TestApp> pumpRouterApp(
  WidgetTester tester, {
  Set<int>? favorites,
  RatingApiService? ratingApi,
  List<SingleChildWidget> extraProviders = const [],
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final memberApi = FakeMemberApiService();
  final auth = signedInAuth(memberApi: memberApi);
  final favoriteApi = FakeFavoriteApiService(favorites: favorites);
  final tmdb = FakeAppTmdbService();
  final router = AppRouter.createRouter(auth);
  addTearDown(router.dispose);

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthViewModel>.value(value: auth),
        ChangeNotifierProvider<SessionRatingStore>(
          create: (_) => SessionRatingStore(auth),
        ),
        Provider<MemberApiService>.value(value: memberApi),
        Provider<SavedEmailPreference>.value(value: FakeSavedEmailPreference()),
        Provider<MovieListPreference>.value(value: MemoryMovieListPreference()),
        Provider<TmdbMovieService>.value(value: tmdb),
        Provider<RatingApiService>.value(
          value: ratingApi ?? RatingApiService(Dio(), Dio()),
        ),
        Provider<FavoriteApiService>.value(value: favoriteApi),
        Provider<AuthSessionBridge>(
          lazy: false,
          create: (_) => AuthSessionBridge(
            authSignals: auth,
            sessionVersion: () => auth.sessionVersion,
            verifiedEmail: () =>
                auth.status == AuthStatus.signedIn ? auth.member?.email : null,
          ),
          dispose: (_, bridge) => bridge.dispose(),
        ),
        Provider<SessionGuard>(
          create: (context) => context.read<AuthSessionBridge>().guard,
        ),
        ...extraProviders,
      ],
      child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
    ),
  );
  return TestApp(router, auth, favoriteApi, memberApi, tmdb);
}
