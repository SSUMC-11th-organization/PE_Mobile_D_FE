import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../widgets/common/movie_log_button.dart';

/// 앱 시작 시 저장된 토큰을 확인하는 동안 보여주는 Splash.
/// 1주차 시작 화면의 로고·제목·설명 레이아웃을 재사용하고,
/// 하단 '시작하기' 버튼 자리를 확인 중(인디케이터) / 확인 실패(다시 시도)로 대체한다.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key, this.message, this.onRetry});

  final String? message;

  /// null이면 확인 중(initializing), 있으면 확인 실패 후 재시도(retryRequired) 상태
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(32, 32, 32, 56),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'FLUTTER 8주차',
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
              if (onRetry == null)
                const Center(child: CircularProgressIndicator())
              else ...[
                Text(
                  message ?? '로그인 상태를 확인하지 못했어요.',
                  style: textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                MovieLogButton(
                  label: '다시 시도',
                  width: double.infinity,
                  height: 56,
                  onPressed: onRetry,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
