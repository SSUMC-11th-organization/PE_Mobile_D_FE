import 'package:flutter/material.dart';

/// 상세 화면의 "시놉시스" 제목과 본문.
class MovieSynopsis extends StatelessWidget {
  const MovieSynopsis({super.key, required this.synopsis});

  final String synopsis;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('시놉시스', style: textTheme.headlineMedium),
        const SizedBox(height: 8),
        Text(synopsis, style: textTheme.bodyLarge?.copyWith(height: 1.7)),
      ],
    );
  }
}
