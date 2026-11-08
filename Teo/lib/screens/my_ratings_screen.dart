import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/models/rating_with_movie.dart';
import '../view_models/my_ratings_view_model.dart';
import '../widgets/common_app_bar.dart';
import '../widgets/tmdb_poster_image.dart';

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
              return const Center(child: CircularProgressIndicator());

            case MyRatingsLoadStatus.empty:
              return const Center(child: Text('등록한 평점이 없습니다.'));

            case MyRatingsLoadStatus.error:
              return _ErrorView(
                message: viewModel.message ?? '평점을 불러오지 못했습니다.',
                onRetry: viewModel.load,
              );

            case MyRatingsLoadStatus.success:
              return _RatingsList(
                ratings: viewModel.ratings,
                message: viewModel.message,
              );
          }
        },
      ),
    );
  }
}

class _RatingsList extends StatelessWidget {
  const _RatingsList({required this.ratings, required this.message});

  final List<RatingWithMovie> ratings;
  final String? message;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (message != null) ...[
          Text(message!, style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 12),
        ],

        ...ratings.map(
          (entry) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _RatingCard(entry: entry),
          ),
        ),
      ],
    );
  }
}

class _RatingCard extends StatelessWidget {
  const _RatingCard({required this.entry});

  final RatingWithMovie entry;

  @override
  Widget build(BuildContext context) {
    final rating = entry.rating;
    final movie = entry.movie;

    final createdDate =
        '${rating.createdAt.year}.'
        '${rating.createdAt.month.toString().padLeft(2, '0')}.'
        '${rating.createdAt.day.toString().padLeft(2, '0')}';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TmdbPosterImage(
              posterPath: movie?.posterPath,
              width: 90,
              height: 130,
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    movie?.title ?? '영화 정보 없음',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    'movieId: ${rating.movieId}',
                    style: const TextStyle(color: Colors.grey),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    '평점 ${rating.score}점',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),

                  if (rating.comment != null) ...[
                    const SizedBox(height: 8),
                    Text(rating.comment!),
                  ],

                  const SizedBox(height: 8),

                  Text(
                    createdDate,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
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

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: onRetry, child: const Text('다시 시도')),
          ],
        ),
      ),
    );
  }
}
