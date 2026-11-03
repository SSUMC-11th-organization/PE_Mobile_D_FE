import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/models/rating_with_movie.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../view_models/my_ratings_view_model.dart';
import '../widgets/movie_list_states.dart';
import '../widgets/tmdb_poster_image.dart';
import 'profile_screen.dart' show CommonAppBar;

class MyRatingsScreen extends StatelessWidget {
  const MyRatingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBar(
        title: '내가 등록한 평점',
        centerTitle: true,
        onBack: () => context.pop(),
      ),
      body: Consumer<MyRatingsViewModel>(
        builder: (context, viewModel, child) {
          switch (viewModel.status) {
            case MyRatingsLoadStatus.idle:
            case MyRatingsLoadStatus.loading:
              return const MovieListLoading();
            case MyRatingsLoadStatus.empty:
              return const Center(child: Text('등록된 평점이 없습니다.'));
            case MyRatingsLoadStatus.error:
              return MovieListError(
                message: viewModel.message,
                onRetry: viewModel.load,
              );
            case MyRatingsLoadStatus.success:
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (viewModel.message != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        viewModel.message!,
                        style: AppTextStyles.bodySmall,
                      ),
                    ),
                  for (final entry in viewModel.ratings)
                    _RatingCard(entry: entry),
                ],
              );
          }
        },
      ),
    );
  }
}

class _RatingCard extends StatelessWidget {
  const _RatingCard({required this.entry});

  final RatingWithMovie entry;

  @override
  Widget build(BuildContext context) {
    final rating = entry.rating;
    final date = rating.createdAt.toLocal().toString().substring(0, 10);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.lightViolet),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: TmdbPosterImage(
              posterPath: entry.movie?.posterPath,
              width: 64,
              height: 96,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.movie?.title ?? '영화 #${rating.movieId}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '별점 ${rating.score} / 5',
                  style: const TextStyle(
                    color: AppColors.violet,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (rating.comment != null) ...[
                  const SizedBox(height: 4),
                  Text(rating.comment!, style: AppTextStyles.bodySmall),
                ],
                const SizedBox(height: 4),
                Text(date, style: AppTextStyles.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
