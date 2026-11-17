import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/models/tmdb_movie_dto.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../view_models/movie_home_view_model.dart';
import '../widgets/movie_list_states.dart';
import '../widgets/tmdb_poster_image.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: const Text(
          'MovieLog',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.violet,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.search, color: AppColors.black),
          ),
        ],
      ),
      body: Consumer<MovieHomeViewModel>(
        builder: (context, viewModel, child) {
          return switch (viewModel.status) {
            MovieHomeLoadStatus.idle ||
            MovieHomeLoadStatus.loading => const MovieListLoading(),
            MovieHomeLoadStatus.error => MovieListError(
              message: viewModel.message,
              onRetry: viewModel.loadPopular,
            ),
            MovieHomeLoadStatus.empty => const MovieListEmpty(),
            MovieHomeLoadStatus.success => _HomeContent(
              popular: viewModel.popularMovies,
            ),
          };
        },
      ),
    );
  }
}

class _HomeContent extends StatelessWidget {
  const _HomeContent({required this.popular});

  final List<TmdbMovieDto> popular;

  @override
  Widget build(BuildContext context) {
    final featured = popular.first;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('오늘은 어떤\n영화를 볼까요?', style: AppTextStyles.titleLarge),
          const SizedBox(height: 16),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => context.push('/movies/${featured.id}'),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                children: [
                  AspectRatio(
                    aspectRatio: 3 / 4,
                    child: TmdbPosterImage(
                      posterPath: featured.posterPath,
                      width: double.infinity,
                      height: double.infinity,
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Colors.black87],
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.violet,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              '추천 신작',
                              style: TextStyle(
                                color: AppColors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            featured.title,
                            style: const TextStyle(
                              color: AppColors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () =>
                                  context.push('/movies/${featured.id}'),
                              icon: const Icon(Icons.info_outline, size: 18),
                              label: const Text('상세보기'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.violet,
                                foregroundColor: AppColors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '인기 영화',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: () => context.go('/movies'),
                child: const Text('전체보기 >'),
              ),
            ],
          ),
          SizedBox(
            height: 250,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: popular.length,
              separatorBuilder: (context, index) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final movie = popular[index];
                return SizedBox(
                  width: 130,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => context.push('/movies/${movie.id}'),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: TmdbPosterImage(
                                  posterPath: movie.posterPath,
                                  width: double.infinity,
                                  height: double.infinity,
                                ),
                              ),
                              Positioned(
                                top: 8,
                                left: 8,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black54,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '${index + 1}',
                                    style: const TextStyle(
                                      color: AppColors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          movie.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(
                              Icons.star,
                              size: 14,
                              color: Colors.amber,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              movie.voteAverage.toStringAsFixed(1),
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.gray,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
