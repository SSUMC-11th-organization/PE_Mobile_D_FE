import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/tmdb_movie_dto.dart';
import '../../theme/app_colors.dart';
import '../common/app_svg_icon.dart';
import '../common/tmdb_poster_image.dart';

/// 홈 상단의 추천 영화 카드. 인기 영화 1위의 포스터 위에 제목·정보·상세보기 버튼을 겹쳐 표시한다.
/// movie가 null이면(불러오는 중·실패) 같은 크기의 빈 카드만 보여준다.
class HomeHeroCard extends StatelessWidget {
  const HomeHeroCard({super.key, required this.movie});

  final TmdbMovieDto? movie;

  static const _aspectRatio = 0.68;
  static const _radius = 24.0;

  @override
  Widget build(BuildContext context) {
    final movie = this.movie;
    if (movie == null) {
      return AspectRatio(
        aspectRatio: _aspectRatio,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(_radius),
          ),
        ),
      );
    }

    final textTheme = Theme.of(context).textTheme;
    // 개봉 연도는 알 수 없으면 생략하고 평점은 항상 표시
    final subtitle = [
      ?movie.releaseYear?.toString(),
      '★ ${movie.voteAverage.toStringAsFixed(1)}',
    ].join(' · ');

    return AspectRatio(
      aspectRatio: _aspectRatio,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(_radius),
        child: Stack(
          fit: StackFit.expand,
          children: [
            TmdbPosterImage(posterPath: movie.posterPath),
            // 아래쪽 글자가 잘 보이도록 포스터 하단을 어둡게 처리
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black87],
                  stops: [0.4, 1],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary600,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.primary400),
                    ),
                    child: Text(
                      '오늘의 인기 1위',
                      style: textTheme.labelLarge?.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    movie.title,
                    style: textTheme.headlineLarge?.copyWith(
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: textTheme.bodyLarge?.copyWith(color: Colors.white70),
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: () => context.push('/home/movies/${movie.id}'),
                    icon: const AppSvgIcon(
                      'assets/icons/info.svg',
                      size: 20,
                      color: Colors.white,
                    ),
                    label: const Text('상세보기'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
