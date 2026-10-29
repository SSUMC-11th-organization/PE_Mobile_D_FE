import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/movie.dart';
import 'popular_movie_card.dart';

/// "인기 영화" 제목 + 가로로 스크롤되는 인기 영화 목록.
class PopularMovieSection extends StatelessWidget {
  const PopularMovieSection({super.key, required this.movies});

  final List<Movie> movies;

  static const _horizontalPadding = 16.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: _horizontalPadding),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('인기 영화', style: theme.textTheme.headlineMedium),
              TextButton(
                // 영화 탭으로 전환. go('/movies')와 달리 영화 탭의 필터·상세 상태를 유지
                onPressed: () =>
                    StatefulNavigationShell.of(context).goBranch(1),
                child: const Text('전체보기 ›'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 260,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: _horizontalPadding),
            itemCount: movies.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              return PopularMovieCard(movie: movies[index], rank: index + 1);
            },
          ),
        ),
      ],
    );
  }
}
