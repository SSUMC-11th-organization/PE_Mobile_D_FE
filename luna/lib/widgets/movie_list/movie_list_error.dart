import 'package:flutter/material.dart';

/// 영화 목록을 불러오지 못했을 때 보여주는 화면.
/// 내부 예외 대신 사용자가 이해할 수 있는 문구와 다시 시도 버튼을 보여준다.
class MovieListError extends StatelessWidget {
  const MovieListError({
    super.key,
    required this.onRetry,
    this.message = defaultMessage,
  });

  static const defaultMessage = '영화를 불러오지 못했습니다.';

  final VoidCallback onRetry;
  final String message; // 사용자에게 보여줄 안내 문구 (예외 내용 X)

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
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
          FilledButton(onPressed: onRetry, child: const Text('다시 시도')),
        ],
      ),
    );
  }
}
