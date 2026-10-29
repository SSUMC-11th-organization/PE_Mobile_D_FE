import 'package:flutter/material.dart';

/// 상세 화면의 "시놉시스" 제목과 본문. 줄거리가 비어 있으면 안내 문구를 가운데에 보여준다.
class MovieSynopsis extends StatelessWidget {
  const MovieSynopsis({super.key, required this.synopsis});

  final String synopsis;

  static const emptyMessage = '줄거리 정보가 없어요.';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('시놉시스', style: textTheme.headlineMedium),
        const SizedBox(height: 8),
        if (synopsis.trim().isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text(
                emptyMessage,
                style: textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          )
        else
          Text(synopsis, style: textTheme.bodyLarge?.copyWith(height: 1.7)),
      ],
    );
  }
}
