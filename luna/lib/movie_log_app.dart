import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/network/tmdb_client.dart';
import 'data/services/tmdb_movie_service.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';

class MovieLogApp extends StatelessWidget {
  const MovieLogApp({super.key});

  @override
  Widget build(BuildContext context) {
    // 여러 화면(Route)이 함께 쓰는 Service는 MaterialApp.router 위에 등록해
    // 어느 Route에서든 context.read로 찾을 수 있게 한다
    return MultiProvider(
      providers: [
        Provider<TmdbMovieService>(
          create: (_) => TmdbMovieService(createTmdbClient()),
        ),
      ],
      // 화면 이동과 첫 화면은 AppRouter의 GoRouter가 관리
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        title: 'MovieLog', // 앱 이름
        theme: AppTheme.light, // 앱 디자인 테마
        routerConfig: AppRouter.router, // 첫 화면은 GoRouter의 initialLocation
      ),
    );
  }
}
