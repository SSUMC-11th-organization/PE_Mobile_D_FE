import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/tmdb_movie_dto.dart';
import '../common/tmdb_poster_image.dart';
import '../movie/poster_badge.dart';

/// 홈 인기 영화 목록의 카드. 순위 배지와 TMDB 평점(10점 만점)을 함께 보여준다.
/// 누르면 TMDB 영화 ID를 Path Parameter로 담아 상세 화면을 push한다.
class PopularMovieCard extends StatelessWidget {
  const PopularMovieCard({super.key, required this.movie, required this.rank});

  final TmdbMovieDto movie;
  final int rank;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => context.push('/home/movies/${movie.id}'),
      child: SizedBox(
        width: 140,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: TmdbPosterImage(posterPath: movie.posterPath),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: PosterBadge(text: '$rank'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              movie.title,
              style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Row(
              children: [
                Icon(Icons.star, size: 16, color: theme.colorScheme.tertiary),
                const SizedBox(width: 4),
                Text(
                  movie.voteAverage.toStringAsFixed(1),
                  style: textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
