import 'package:flutter/material.dart';

import 'screens/start_screen.dart';
import 'theme/app_theme.dart';

class MovieLogApp extends StatelessWidget {
  const MovieLogApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MovieLog', // 앱 이름
      theme: AppTheme.light, // 앱 디자인 테마
      home: const StartScreen(), // 첫 실행 화면 지정
    );
  }
}
