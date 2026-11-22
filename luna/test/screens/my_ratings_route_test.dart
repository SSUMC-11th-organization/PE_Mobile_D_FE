import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:movielog/data/models/member_info.dart';
import 'package:movielog/data/models/rating_dto.dart';
import 'package:movielog/data/models/tmdb_movie_detail_dto.dart';
import 'package:movielog/data/models/tmdb_movie_page.dart';
import 'package:movielog/data/services/member_api_service.dart';
import 'package:movielog/data/services/rating_api_service.dart';
import 'package:movielog/data/services/tmdb_movie_service.dart';
import 'package:movielog/router/app_router.dart';
import 'package:movielog/screens/edit_profile_screen.dart';
import 'package:movielog/screens/login_screen.dart';
import 'package:movielog/screens/my_ratings_screen.dart';
import 'package:movielog/screens/profile_screen.dart';
import 'package:movielog/services/saved_email_preference.dart';
import 'package:movielog/theme/app_theme.dart';
import 'package:movielog/view_models/auth_view_model.dart';
import 'package:movielog/view_models/session_rating_store.dart';
import 'package:movielog/widgets/profile/discard_changes_dialog.dart';
import 'package:movielog/widgets/profile/profile_header.dart';
import 'package:provider/provider.dart';

import '../helpers/fake_auth.dart';

class _FakeRatingApiService extends RatingApiService {
  _FakeRatingApiService() : super(Dio(), Dio());
}

class _FakeMemberApiService extends FakeMemberApiService {
  Object? updateError;
  final updatedNicknames = <String>[];

  @override
  Future<MemberInfo> updateNickname(String nickname) async {
    updatedNicknames.add(nickname);
    if (updateError != null) throw updateError!;
    return MemberInfo(
      email: testMember.email,
      nickname: nickname,
      createdAt: testMember.createdAt,
    );
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

class _App {
  _App(this.router, this.auth, this.store, this.memberApi, this.storage);

  final GoRouter router;
  final AuthViewModel auth;
  final SessionRatingStore store;
  final _FakeMemberApiService memberApi;
  final FakeTokenStorage storage;
}

/// 로그인된 세션으로 앱 Router를 띄운다.
Future<_App> _pumpApp(WidgetTester tester) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final storage = FakeTokenStorage(token: 'test-token');
  final memberApi = _FakeMemberApiService();
  final auth = signedInAuth(storage: storage, memberApi: memberApi);
  final store = SessionRatingStore(auth);
  final router = AppRouter.createRouter(auth);
  addTearDown(router.dispose);
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthViewModel>.value(value: auth),
        ChangeNotifierProvider<SessionRatingStore>.value(value: store),
        Provider<MemberApiService>.value(value: memberApi),
        Provider<SavedEmailPreference>.value(value: FakeSavedEmailPreference()),
        Provider<TmdbMovieService>.value(value: _FakeTmdbMovieService()),
        Provider<RatingApiService>.value(value: _FakeRatingApiService()),
      ],
      child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
    ),
  );
  return _App(router, auth, store, memberApi, storage);
}

void main() {
  testWidgets('마이페이지는 GET me의 닉네임·이메일을 보여준다', (tester) async {
    final app = await _pumpApp(tester);
    app.router.go('/my');
    await tester.pumpAndSettle();

    expect(find.byType(ProfileScreen), findsOneWidget);
    expect(find.text('무비러버'), findsOneWidget);
    expect(find.text('movie@example.com'), findsOneWidget);
    expect(find.text('로그아웃'), findsOneWidget);
  });

  testWidgets('내가 등록한 평점은 하단 탭 없이 이번 세션의 평점을 보여주고, 뒤로가면 마이페이지로 돌아온다', (
    tester,
  ) async {
    final app = await _pumpApp(tester);
    app.store.add(
      RatingDto(
        ratingId: 1,
        movieId: 550,
        score: 5,
        comment: '최고의 영화!',
        createdAt: DateTime.utc(2026, 11, 16),
      ),
      sessionVersion: app.auth.sessionVersion,
    );
    app.router.go('/my');
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('내가 등록한 평점'));
    await tester.tap(find.text('내가 등록한 평점'));
    await tester.pumpAndSettle();

    expect(find.byType(MyRatingsScreen), findsOneWidget);
    expect(find.text('최고의 영화!'), findsOneWidget);
    // root Navigator 위에 쌓여 하단 NavigationBar가 가려진다
    expect(find.byType(NavigationBar).hitTestable(), findsNothing);

    await tester.tap(find.bySemanticsLabel('뒤로가기'));
    await tester.pumpAndSettle();

    expect(find.byType(ProfileScreen), findsOneWidget);
    expect(find.byType(NavigationBar).hitTestable(), findsOneWidget);
  });

  testWidgets('프로필 수정에 성공하면 마이페이지로 돌아가고 새 닉네임이 바로 보인다', (tester) async {
    final app = await _pumpApp(tester);
    app.router.go('/my');
    await tester.pumpAndSettle();

    await tester.tap(find.text('프로필 수정'));
    await tester.pumpAndSettle();
    expect(find.byType(EditProfileScreen), findsOneWidget);
    expect(find.byType(NavigationBar).hitTestable(), findsNothing);

    await tester.enterText(find.byType(TextField).last, '시네필');
    await tester.tap(find.text('저장'));
    await tester.pumpAndSettle();

    expect(app.memberApi.updatedNicknames, ['시네필']);
    expect(find.byType(EditProfileScreen), findsNothing);
    expect(find.text('시네필'), findsOneWidget);
    expect(find.text('프로필을 수정했어요.'), findsOneWidget);
    expect(app.memberApi.fetchCount, 0); // GET me를 다시 부르지 않는다
  });

  testWidgets('MEMBER409_1이면 화면에 남아 입력값을 유지하고 필드 아래에 안내한다', (tester) async {
    final app = await _pumpApp(tester);
    app.memberApi.updateError = apiError(409, 'MEMBER409_1');
    app.router.go('/my/profile/edit');
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).last, '영화광');
    await tester.tap(find.text('저장'));
    await tester.pumpAndSettle();

    expect(find.byType(EditProfileScreen), findsOneWidget);
    expect(find.text('이미 사용 중인 닉네임이에요.'), findsOneWidget);
    expect(find.widgetWithText(TextField, '영화광'), findsOneWidget);
    expect(app.auth.status, AuthStatus.signedIn);
  });

  testWidgets('네트워크 실패는 로그아웃하지 않고 Snackbar로 재시도를 안내한다', (tester) async {
    final app = await _pumpApp(tester);
    app.memberApi.updateError = DioException.connectionError(
      requestOptions: RequestOptions(path: '/v8/members/me'),
      reason: 'offline',
    );
    app.router.go('/my/profile/edit');
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).last, '시네필');
    await tester.tap(find.text('저장'));
    await tester.pumpAndSettle();

    expect(find.text('네트워크 상태를 확인하고 다시 시도해 주세요.'), findsOneWidget);
    expect(find.byType(EditProfileScreen), findsOneWidget);
    expect(app.auth.status, AuthStatus.signedIn);
  });

  testWidgets('닉네임이 2자 미만이면 요청하지 않는다', (tester) async {
    final app = await _pumpApp(tester);
    app.router.go('/my/profile/edit');
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).last, '영');
    await tester.tap(find.text('저장'));
    await tester.pumpAndSettle();

    expect(find.text('닉네임은 2~12자로 입력해 주세요.'), findsOneWidget);
    expect(app.memberApi.updatedNicknames, isEmpty);
  });

  testWidgets('프로필 수정 중 세션이 만료되면 로그인 화면에서 만료 Snackbar를 한 번 보여준다', (
    tester,
  ) async {
    final app = await _pumpApp(tester);
    app.memberApi.updateError = apiError(401, 'AUTH401_4');
    app.router.go('/my/profile/edit');
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).last, '시네필');
    await tester.tap(find.text('저장'));
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.text('로그인이 만료됐어요. 다시 로그인해 주세요.'), findsOneWidget);
    expect(app.auth.sessionExpired, isFalse); // 표시 후 꺼서 반복하지 않는다
    expect(app.storage.token, isNull);
  });

  testWidgets('로그아웃하면 토큰과 내 정보를 지우고 만료 안내 없이 로그인 화면으로 간다', (tester) async {
    final app = await _pumpApp(tester);
    app.router.go('/my');
    await tester.pumpAndSettle();

    await tester.tap(find.text('로그아웃'));
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.text('로그인이 만료됐어요. 다시 로그인해 주세요.'), findsNothing);
    expect(app.storage.token, isNull);
    expect(app.auth.member, isNull);

    // 로그아웃 후 보호 화면으로 직접 가도 로그인 화면으로 막힌다
    app.router.go('/my/ratings');
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.byType(MyRatingsScreen), findsNothing);
  });

  group('Challenge', () {
    test('가입일은 "2026.10.10 가입" 형식으로 표시한다', () {
      expect(
        ProfileHeader.formatJoinedAt(DateTime(2026, 10, 10)),
        '2026.10.10 가입',
      );
      expect(
        ProfileHeader.formatJoinedAt(DateTime(2026, 1, 5)),
        '2026.01.05 가입',
      );
    });

    testWidgets('마이페이지 닉네임 아래에 가입일을 보여준다', (tester) async {
      final app = await _pumpApp(tester);
      app.router.go('/my');
      await tester.pumpAndSettle();

      expect(
        find.text(ProfileHeader.formatJoinedAt(testMember.createdAt)),
        findsOneWidget,
      );
    });

    testWidgets('내 정보 로딩 중에는 전체 로딩, 실패하면 다시 시도로 불러온다', (tester) async {
      final app = await _pumpApp(tester);
      app.auth
        ..member = null
        ..memberStatus = MemberLoadStatus.loading;
      app.router.go('/my');
      // 로딩 인디케이터는 계속 움직이므로 pumpAndSettle 대신 몇 프레임만 진행한다
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('로그아웃'), findsNothing);

      // 로딩 실패 → 재시도 버튼
      app.memberApi.error = DioException.connectionError(
        requestOptions: RequestOptions(path: '/v8/members/me'),
        reason: 'offline',
      );
      app.auth.memberStatus = MemberLoadStatus.idle;
      await app.auth.loadMember();
      await tester.pumpAndSettle();
      expect(find.text('내 정보를 불러오지 못했어요.'), findsOneWidget);
      expect(app.auth.status, AuthStatus.signedIn); // 실패해도 로그아웃하지 않음

      app.memberApi.error = null;
      await tester.tap(find.text('다시 시도'));
      await tester.pumpAndSettle();
      expect(find.text('무비러버'), findsOneWidget);
      expect(find.text('로그아웃'), findsOneWidget);
    });

    testWidgets('변경 내용이 없으면 확인 없이 마이페이지로 돌아간다', (tester) async {
      final app = await _pumpApp(tester);
      app.router.go('/my');
      await tester.pumpAndSettle();
      await tester.tap(find.text('프로필 수정'));
      await tester.pumpAndSettle();

      await tester.tap(find.bySemanticsLabel('뒤로가기'));
      await tester.pumpAndSettle();

      expect(find.byType(DiscardChangesDialog), findsNothing);
      expect(find.byType(ProfileScreen), findsOneWidget);
    });

    testWidgets('변경 내용이 있으면 확인 Dialog를 띄우고, 계속 수정은 머물고 나가기는 돌아간다', (
      tester,
    ) async {
      final app = await _pumpApp(tester);
      app.router.go('/my');
      await tester.pumpAndSettle();
      await tester.tap(find.text('프로필 수정'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).last, '시네필');
      await tester.pump();

      await tester.tap(find.bySemanticsLabel('뒤로가기'));
      await tester.pumpAndSettle();
      expect(find.text('변경 내용을 버릴까요?'), findsOneWidget);
      expect(find.text('저장하지 않은 내용은 사라집니다.'), findsOneWidget);

      await tester.tap(find.text('계속 수정'));
      await tester.pumpAndSettle();
      expect(find.byType(EditProfileScreen), findsOneWidget);
      expect(find.widgetWithText(TextField, '시네필'), findsOneWidget);

      // 시스템 뒤로가기도 같은 확인을 거친다
      final popped = await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(popped, isTrue);
      expect(find.text('변경 내용을 버릴까요?'), findsOneWidget);

      await tester.tap(find.text('나가기'));
      await tester.pumpAndSettle();
      expect(find.byType(EditProfileScreen), findsNothing);
      expect(find.byType(ProfileScreen), findsOneWidget);
      expect(find.text('무비러버'), findsOneWidget); // 저장하지 않았으므로 그대로
      expect(app.memberApi.updatedNicknames, isEmpty);
    });
  });
}
