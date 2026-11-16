import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'core/network/movie_log_client.dart';
import 'core/network/tmdb_client.dart';
import 'core/storage/token_storage.dart';
import 'data/services/auth_api_service.dart';
import 'data/services/member_api_service.dart';
import 'data/services/rating_api_service.dart';
import 'data/services/sign_up_service.dart';
import 'data/services/tmdb_movie_service.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';
import 'view_models/auth_view_model.dart';
import 'view_models/learning_member_session.dart';

class MovieLogApp extends StatelessWidget {
  const MovieLogApp({super.key});

  @override
  Widget build(BuildContext context) {
    final tokenStorage = SecureTokenStorage(const FlutterSecureStorage());
    // 워크북 Client는 공개용(Interceptor 없음)과 보호용(AuthInterceptor)으로 나눈다.
    // TMDB Client와는 계속 합치지 않으므로 TMDB 요청에 MovieLog JWT가 실리지 않는다
    final publicClient = createMovieLogClient();
    final authClient = createAuthMovieLogClient(tokenStorage);

    // 여러 화면(Route)이 함께 쓰는 Service는 MaterialApp.router 위에 등록해
    // 어느 Route에서든 context.read로 찾을 수 있게 한다
    return MultiProvider(
      providers: [
        Provider<TokenStorage>.value(value: tokenStorage),
        // 회원가입 결과의 memberId를 마이페이지 평점 조회 Route에서 읽는다
        ChangeNotifierProvider<LearningMemberSession>(
          create: (_) => LearningMemberSession(),
        ),
        Provider<TmdbMovieService>(
          create: (_) => TmdbMovieService(createTmdbClient()),
        ),
        // 공개 Client: 로그인, 회원가입·중복 체크
        Provider<AuthApiService>(create: (_) => AuthApiService(publicClient)),
        Provider<SignUpService>(create: (_) => SignUpService(publicClient)),
        // 보호 Client: 내 정보
        Provider<MemberApiService>(create: (_) => MemberApiService(authClient)),
        // 유저별 평점 조회(공개)와 등록·수정·삭제(보호)를 모두 맡아 두 Client를 받는다
        Provider<RatingApiService>(
          create: (_) => RatingApiService(publicClient, authClient),
        ),
        ChangeNotifierProvider<AuthViewModel>(
          create: (context) => AuthViewModel(
            context.read<AuthApiService>(),
            context.read<MemberApiService>(),
            context.read<TokenStorage>(),
          ),
        ),
      ],
      child: const _MovieLogRouterApp(),
    );
  }
}

/// GoRouter를 앱이 살아 있는 동안 한 번만 만들기 위한 호스트.
/// build에서 만들면 다시 그려질 때마다 Router가 새로 생겨 현재 위치가 초기화된다.
class _MovieLogRouterApp extends StatefulWidget {
  const _MovieLogRouterApp();

  @override
  State<_MovieLogRouterApp> createState() => _MovieLogRouterAppState();
}

class _MovieLogRouterAppState extends State<_MovieLogRouterApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    final authViewModel = context.read<AuthViewModel>();
    _router = AppRouter.createRouter(authViewModel);
    // 첫 build 이후 세션 복원을 시작한다(build 중 notifyListeners 방지)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) authViewModel.restoreSession();
    });
  }

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'MovieLog', // 앱 이름
      theme: AppTheme.light, // 앱 디자인 테마
      routerConfig: _router, // 첫 화면은 Splash(/start)
    );
  }
}
