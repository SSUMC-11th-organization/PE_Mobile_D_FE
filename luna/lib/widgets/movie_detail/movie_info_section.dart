import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

import '../../models/movie.dart';

/// 상세 화면의 제목, 연도·장르·상영시간, 평균 평점, 키워드 Chip.
class MovieInfoSection extends StatelessWidget {
  const MovieInfoSection({super.key, required this.movie});

  final Movie movie;

  // 1245 → "1,245"
  static String _withComma(int value) => value.toString().replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => ',',
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(movie.title, style: textTheme.headlineLarge),
        const SizedBox(height: 4),
        Text(
          '${movie.year} • ${movie.genre} • ${movie.runtime}분',
          style: textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            // 평균 평점은 수정할 수 없으므로 읽기 전용 Indicator로 표시
            RatingBarIndicator(
              rating: movie.rating,
              itemCount: 5,
              itemSize: 20,
              itemBuilder: (context, index) {
                return Icon(Icons.star, color: colorScheme.primary);
              },
            ),
            const SizedBox(width: 8),
            Text('${movie.rating}', style: textTheme.bodyLarge),
            const SizedBox(width: 4),
            Text(
              '(${_withComma(movie.ratingCount)})',
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: movie.tags
              .map(
                (tag) => Chip(
                  label: Text(tag),
                  backgroundColor: colorScheme.surfaceContainerHighest,
                  labelStyle: textTheme.labelLarge,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}
