import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/data/models/rating_dto.dart';
import 'package:movielog/data/models/tmdb_movie_detail_dto.dart';
import 'package:movielog/data/services/rating_api_service.dart';
import 'package:movielog/data/services/tmdb_movie_service.dart';
import 'package:movielog/router/app_router.dart';
import 'package:movielog/screens/my_ratings_screen.dart';
import 'package:movielog/screens/profile_screen.dart';
import 'package:movielog/theme/app_theme.dart';
import 'package:provider/provider.dart';

class _FakeRatingApiService extends RatingApiService {
  _FakeRatingApiService() : super(Dio());

  final requestedIds = <int>[];

  @override
  Future<List<RatingDto>> fetchMyRatings(int memberId) async {
    requestedIds.add(memberId);
    return const [];
  }
}

class _FakeTmdbMovieService extends TmdbMovieService {
  _FakeTmdbMovieService() : super(Dio());

  @override
  Future<TmdbMovieDetailDto?> findMovieById(int movieId) async => null;
}

void main() {
  testWidgets('마이페이지 → 내가 등록한 평점은 하단 탭 없이 열리고, 뒤로가면 마이페이지로 돌아온다', (
    tester,
  ) async {
    final ratingService = _FakeRatingApiService();
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<TmdbMovieService>.value(value: _FakeTmdbMovieService()),
          Provider<RatingApiService>.value(value: ratingService),
        ],
        child: MaterialApp.router(
          theme: AppTheme.light,
          routerConfig: AppRouter.router,
        ),
      ),
    );
    AppRouter.router.go('/my');
    await tester.pumpAndSettle();
    expect(find.byType(ProfileScreen), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);

    await tester.ensureVisible(find.text('내가 등록한 평점'));
    await tester.tap(find.text('내가 등록한 평점'));
    await tester.pumpAndSettle();

    expect(find.byType(MyRatingsScreen), findsOneWidget);
    expect(ratingService.requestedIds, [1]);
    // root Navigator 위에 쌓여 하단 NavigationBar가 가려진다
    expect(find.byType(NavigationBar).hitTestable(), findsNothing);

    await tester.tap(find.bySemanticsLabel('뒤로가기'));
    await tester.pumpAndSettle();

    expect(find.byType(MyRatingsScreen), findsNothing);
    expect(find.byType(ProfileScreen), findsOneWidget);
    expect(find.byType(NavigationBar).hitTestable(), findsOneWidget);
  });
}
