import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'profile_screen.dart';

class StartScreen extends StatelessWidget {
  const StartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Scaffold(
      body: SafeArea( // 화면의 안전 영역을 고려하여 UI를 배치
        child: Padding(
          padding: const EdgeInsets.fromLTRB(32, 32, 32, 56),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [ // UI 요소들을 세로로 배치
              Text(
                'FLUTTER 1주차',
                style: textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 72),
              Center(
                child: SvgPicture.asset(
                  'assets/logos/movielog_logo.svg',
                  width: 72,
                  height: 72,
                  semanticsLabel: 'MovieLog 로고',
                ),
              ),
              const SizedBox(height: 72),
              Text(
                '영화의 순간을\n기록하세요',
                style: textTheme.headlineLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                '보고 싶은 영화부터 나만의 평점까지\n한곳에서 관리해요',
                style: textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              FilledButton(
                onPressed: () {
                  Navigator.of(context).push( // 프로필 화면으로 이동
                    MaterialPageRoute<void>(
                      builder: (_) => const ProfileScreen(),
                    ),
                  );
                },
                child: const Text('시작하기'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
