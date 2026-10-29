import 'package:flutter/material.dart';

import 'router/app_router.dart';
import 'theme/app_theme.dart';

class MovieLogApp extends StatelessWidget {
  const MovieLogApp({super.key});

  @override
  Widget build(BuildContext context) {
    // 화면 이동과 첫 화면은 AppRouter의 GoRouter가 관리
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'MovieLog', // 앱 이름
      theme: AppTheme.light, // 앱 디자인 테마
      routerConfig: AppRouter.router, // 첫 화면은 GoRouter의 initialLocation
    );
  }
}
