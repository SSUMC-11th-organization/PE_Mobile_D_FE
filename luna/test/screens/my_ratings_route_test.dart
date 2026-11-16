import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:movielog/data/models/rating_dto.dart';
import 'package:movielog/data/models/tmdb_movie_detail_dto.dart';
import 'package:movielog/data/models/tmdb_movie_page.dart';
import 'package:movielog/data/services/rating_api_service.dart';
import 'package:movielog/data/services/tmdb_movie_service.dart';
import 'package:movielog/router/app_router.dart';
import 'package:movielog/screens/my_ratings_screen.dart';
import 'package:movielog/screens/profile_screen.dart';
import 'package:movielog/theme/app_theme.dart';
import 'package:movielog/view_models/auth_view_model.dart';
import 'package:movielog/view_models/learning_member_session.dart';
import 'package:provider/provider.dart';

import '../helpers/fake_auth.dart';

class _FakeRatingApiService extends RatingApiService {
  _FakeRatingApiService() : super(Dio(), Dio());

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

  // 로그인 상태로 시작하면 redirect가 /home으로 보내 인기 영화를 요청한다
  @override
  Future<TmdbMoviePageDto> fetchPopular({int page = 1}) async =>
      TmdbMoviePageDto.fromJson({
        'page': 1,
        'results': <Object>[],
        'total_pages': 1,
        'total_results': 0,
      });
}

/// 로그인된 세션으로 앱 Router를 띄운다.
Future<GoRouter> _pumpApp(
  WidgetTester tester, {
  required RatingApiService ratingService,
  required LearningMemberSession session,
}) async {
  final auth = signedInAuth();
  final router = AppRouter.createRouter(auth);
  addTearDown(router.dispose);
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<LearningMemberSession>.value(value: session),
        ChangeNotifierProvider<AuthViewModel>.value(value: auth),
        Provider<TmdbMovieService>.value(value: _FakeTmdbMovieService()),
        Provider<RatingApiService>.value(value: ratingService),
      ],
      child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
    ),
  );
  return router;
}

void main() {
  testWidgets('마이페이지 → 내가 등록한 평점은 하단 탭 없이 열리고, 뒤로가면 마이페이지로 돌아온다', (
    tester,
  ) async {
    final ratingService = _FakeRatingApiService();
    final router = await _pumpApp(
      tester,
      ratingService: ratingService,
      session: LearningMemberSession()..setMemberId(1),
    );
    router.go('/my');
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

  testWidgets('학습용 회원 ID가 없으면 평점을 조회하지 않고 회원가입을 안내한다', (tester) async {
    final ratingService = _FakeRatingApiService();
    final router = await _pumpApp(
      tester,
      ratingService: ratingService,
      session: LearningMemberSession(),
    );
    router.go('/my/ratings');
    await tester.pumpAndSettle();

    expect(find.text('학습용 회원가입이 필요합니다.'), findsOneWidget);
    expect(find.byType(MyRatingsScreen), findsNothing);
    expect(ratingService.requestedIds, isEmpty);
  });
}
