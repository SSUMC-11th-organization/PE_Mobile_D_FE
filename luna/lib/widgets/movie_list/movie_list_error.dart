import 'package:flutter/material.dart';

/// 영화 목록을 불러오지 못했을 때 보여주는 화면.
/// 내부 예외 대신 사용자가 이해할 수 있는 문구와 다시 시도 버튼을 보여준다.
class MovieListError extends StatelessWidget {
  const MovieListError({super.key, required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
          const SizedBox(height: 12),
          Text('영화를 불러오지 못했습니다.', style: theme.textTheme.bodyLarge),
          const SizedBox(height: 16),
          FilledButton(onPressed: onRetry, child: const Text('다시 시도')),
        ],
      ),
    );
  }
}
