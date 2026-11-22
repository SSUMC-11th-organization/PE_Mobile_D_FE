import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:movielog/core/session/auth_session_bridge.dart';
import 'package:movielog/core/session/session_guard.dart';
import 'package:movielog/data/models/member_info.dart';
import 'package:movielog/data/models/tmdb_movie_page.dart';
import 'package:movielog/data/services/favorite_api_service.dart';
import 'package:movielog/data/services/member_api_service.dart';
import 'package:movielog/data/services/rating_api_service.dart';
import 'package:movielog/data/services/tmdb_movie_service.dart';
import 'package:movielog/router/app_router.dart';
import 'package:movielog/screens/favorites_screen.dart';
import 'package:movielog/screens/movie_detail_screen.dart';
import 'package:movielog/services/saved_email_preference.dart';
import 'package:movielog/theme/app_theme.dart';
import 'package:movielog/view_models/auth_view_model.dart';
import 'package:movielog/view_models/session_rating_store.dart';
import 'package:provider/provider.dart';

import '../helpers/fake_auth.dart';
import '../helpers/fake_favorites.dart';

class _FakeTmdb extends FakeTmdbDetailService {
  // 로그인 상태로 시작하면 redirect가 /home으로 보내 인기 영화를 요청한다
  @override
  Future<TmdbMoviePageDto> fetchPopular({int page = 1}) async =>
      const TmdbMoviePageDto(
        page: 1,
        results: [],
        totalPages: 1,
        totalResults: 0,
      );
}

class _App {
  _App(this.router, this.auth, this.favorites, this.memberApi);

  final GoRouter router;
  final AuthViewModel auth;
  final FakeFavoriteApiService favorites;
  final FakeMemberApiService memberApi;
}

Future<_App> _pumpApp(WidgetTester tester, {Set<int>? favorites}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final memberApi = FakeMemberApiService();
  final auth = signedInAuth(memberApi: memberApi);
  final favoriteApi = FakeFavoriteApiService(favorites: favorites);
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
        Provider<TmdbMovieService>.value(value: _FakeTmdb()),
        Provider<RatingApiService>.value(value: RatingApiService(Dio(), Dio())),
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
      ],
      child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
    ),
  );
  return _App(router, auth, favoriteApi, memberApi);
}

void main() {
  testWidgets('마이페이지의 내 즐겨찾기 행으로 하단 탭 없는 즐겨찾기 목록에 들어간다', (tester) async {
    final app = await _pumpApp(tester, favorites: {550});
    app.router.go('/my');
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('내 즐겨찾기'));
    await tester.tap(find.text('내 즐겨찾기'));
    await tester.pumpAndSettle();

    expect(find.byType(FavoritesScreen), findsOneWidget);
    expect(find.text('영화 550'), findsOneWidget);
    expect(find.byType(NavigationBar).hitTestable(), findsNothing);
  });

  testWidgets('즐겨찾기가 없으면 빈 화면, 조회 오류는 다시 시도 화면을 보여준다', (tester) async {
    final app = await _pumpApp(tester);
    app.router.go('/my/favorites');
    await tester.pumpAndSettle();
    expect(find.text(FavoritesEmpty.message), findsOneWidget);

    app.favorites.listError = DioException(
      requestOptions: RequestOptions(path: '/v8/favorites'),
    );
    app.router.go('/my');
    await tester.pumpAndSettle();
    app.router.push('/my/favorites');
    await tester.pumpAndSettle();
    expect(find.text('즐겨찾기를 불러오지 못했습니다.'), findsOneWidget);

    app.favorites
      ..listError = null
      ..favorites.add(680);
    await tester.tap(find.text('다시 시도'));
    await tester.pumpAndSettle();
    expect(find.text('영화 680'), findsOneWidget);
  });

  testWidgets('상세에서 북마크를 해제하고 뒤로가면 목록에서 사라진다', (tester) async {
    final app = await _pumpApp(tester, favorites: {550, 680});
    app.router.go('/my');
    await tester.pumpAndSettle();
    app.router.push('/my/favorites');
    await tester.pumpAndSettle();

    await tester.tap(find.text('영화 550'));
    await tester.pumpAndSettle();
    expect(find.byType(MovieDetailScreen), findsOneWidget);
    expect(find.byIcon(Icons.bookmark), findsOneWidget); // 서버 여부 반영

    await tester.tap(find.byTooltip('즐겨찾기 해제'));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.bookmark_border), findsOneWidget);
    expect(find.text('즐겨찾기에서 삭제했습니다.'), findsOneWidget);
    expect(app.favorites.calls, contains('DELETE 550'));

    await tester.tap(find.bySemanticsLabel('뒤로가기'));
    await tester.pumpAndSettle();

    expect(find.byType(FavoritesScreen), findsOneWidget);
    expect(find.text('영화 550'), findsNothing);
    expect(find.text('영화 680'), findsOneWidget);
  });

  testWidgets('로그아웃 후 다른 계정으로 로그인하면 이전 계정의 즐겨찾기가 보이지 않는다', (tester) async {
    final app = await _pumpApp(tester, favorites: {550});
    app.router.go('/my');
    await tester.pumpAndSettle();
    app.router.push('/my/favorites');
    await tester.pumpAndSettle();
    expect(find.text('영화 550'), findsOneWidget);

    await app.auth.logout();
    await tester.pumpAndSettle();

    // 서버는 JWT로 사용자를 구분하므로 새 계정의 목록만 돌려준다
    app.favorites.favorites
      ..clear()
      ..add(999);
    app.memberApi.member = MemberInfo(
      email: 'other@example.com',
      nickname: '다른계정',
      createdAt: DateTime.utc(2026, 11, 1),
    );
    await app.auth.login('other@example.com', 'password1!');
    await tester.pumpAndSettle();

    app.router.go('/my');
    await tester.pumpAndSettle();
    app.router.push('/my/favorites');
    await tester.pumpAndSettle();

    expect(find.text('영화 550'), findsNothing);
    expect(find.text('영화 999'), findsOneWidget);
  });
}
