import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

import '../../data/models/tmdb_movie_detail_dto.dart';

/// 상세 화면의 제목, 연도·상영시간, TMDB 평균 평점, 장르 Chip.
class MovieInfoSection extends StatelessWidget {
  const MovieInfoSection({super.key, required this.movie});

  final TmdbMovieDetailDto movie;

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
    final runtime = movie.runtime;
    // 개봉 연도·상영시간 중 정보가 있는 값만 표시한다 (상영시간은 0으로 오기도 함)
    final subtitle = [
      ?movie.releaseYear?.toString(),
      if (runtime != null && runtime > 0) '$runtime분',
    ].join(' • ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(movie.title, style: textTheme.headlineLarge),
        if (subtitle.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        const SizedBox(height: 12),
        Row(
          children: [
            // 평균 평점은 수정할 수 없으므로 읽기 전용 Indicator로 표시
            // TMDB 평점은 10점 만점이라 별 5개에 맞춰 절반으로 표시
            RatingBarIndicator(
              rating: movie.voteAverage / 2,
              itemCount: 5,
              itemSize: 20,
              itemBuilder: (context, index) {
                return Icon(Icons.star, color: colorScheme.primary);
              },
            ),
            const SizedBox(width: 8),
            Text(
              movie.voteAverage.toStringAsFixed(1),
              style: textTheme.bodyLarge,
            ),
            const SizedBox(width: 4),
            Text(
              '(${_withComma(movie.voteCount)})',
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        if (movie.genres.isNotEmpty) ...[
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: movie.genres
                .map(
                  (genre) => Chip(
                    label: Text(genre.name),
                    backgroundColor: colorScheme.surfaceContainerHighest,
                    labelStyle: textTheme.labelLarge,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                )
                .toList(),
          ),
        ],
      ],
    );
  }
}
