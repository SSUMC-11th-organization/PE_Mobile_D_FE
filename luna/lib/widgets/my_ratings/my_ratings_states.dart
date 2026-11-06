import 'package:flutter/material.dart';

import '../common/movie_log_button.dart';

/// 평점 목록을 불러오는 동안 보여주는 화면.
class MyRatingsLoading extends StatelessWidget {
  const MyRatingsLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(semanticsLabel: '평점을 불러오는 중'),
    );
  }
}

/// 평점 조회는 성공했지만 등록된 평점이 없을 때 보여주는 화면.
class MyRatingsEmpty extends StatelessWidget {
  const MyRatingsEmpty({super.key});

  static const message = '아직 등록한 평점이 없습니다.';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.star_border,
            size: 48,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 12),
          Text(message, style: theme.textTheme.bodyLarge),
        ],
      ),
    );
  }
}

/// 평점 조회에 실패했을 때 상태 코드별 문구와 다시 시도 버튼을 보여주는 화면.
class MyRatingsError extends StatelessWidget {
  const MyRatingsError({
    super.key,
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
            const SizedBox(height: 12),
            Text(
              message,
              style: theme.textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            // 고정 너비 버튼: 문구 길이와 관계없이 항상 같은 크기
            MovieLogButton(label: '다시 시도', width: 120, onPressed: onRetry),
          ],
        ),
      ),
    );
  }
}
