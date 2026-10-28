import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/tmdb_movie_dto.dart';
import '../common/tmdb_poster_image.dart';
import 'poster_badge.dart';

/// 포스터 + 제목 + 연도·장르를 보여주는 공통 영화 카드.
/// 누르면 TMDB 영화 ID를 Path Parameter로 담아 상세 화면을 push한다.
/// 포스터가 남는 세로 공간을 채우므로, 부모가 카드의 높이를 정해줘야 한다.
class MovieCard extends StatelessWidget {
  const MovieCard({super.key, required this.movie, this.genreName});

  final TmdbMovieDto movie;
  final String? genreName; // 장르를 알 수 없으면 null → 표시하지 않음

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    // 개봉 연도·장르 중 있는 값만 표시한다
    final subtitle = [?movie.releaseYear?.toString(), ?genreName].join(' · ');

    return GestureDetector(
      // 포스터 사이 빈 공간을 눌러도 카드 Tap으로 처리
      behavior: HitTestBehavior.opaque,
      onTap: () => context.push('/movies/${movie.id}'),
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
                  right: 8,
                  child: PosterBadge(
                    text: '★ ${movie.voteAverage.toStringAsFixed(1)}',
                  ),
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
          Text(
            subtitle,
            style: textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
