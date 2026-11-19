import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/models/tmdb_movie_dto.dart';
import '../view_models/movie_detail_view_model.dart';
import '../view_models/sign_up_view_model.dart';
import '../widgets/rating_dialog.dart';
import '../widgets/tmdb_poster_image.dart';

class MovieDetailScreen extends StatefulWidget {
  const MovieDetailScreen({super.key, required this.movie});

  final TmdbMovieDto? movie;

  @override
  State<MovieDetailScreen> createState() => _MovieDetailScreenState();
}

class _MovieDetailScreenState extends State<MovieDetailScreen> {
  bool isFavorite = false;

  Future<void> _createRating() async {
    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => RatingDialog(
        onSubmit: (score, comment) async {
          final viewModel = context.read<MovieDetailViewModel>();

          await viewModel.createRating(score: score, comment: comment);

          if (viewModel.submitStatus != SubmitStatus.success) {
            throw StateError(viewModel.submitMessage ?? '저장에 실패했습니다.');
          }
        },
      ),
    );

    if (!mounted || saved != true) {
      return;
    }

    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('평점을 등록했습니다.')));
  }

  Future<void> _updateRating() async {
    final viewModel = context.read<MovieDetailViewModel>();

    final rating = viewModel.currentRating;

    if (rating == null) {
      return;
    }

    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => RatingDialog(
        initialScore: rating.score,
        initialComment: rating.comment,
        onSubmit: (score, comment) async {
          await viewModel.updateCurrentRating(score: score, comment: comment);

          if (viewModel.submitStatus != SubmitStatus.success) {
            throw StateError(viewModel.submitMessage ?? '수정에 실패했습니다.');
          }
        },
      ),
    );

    if (!mounted || saved != true) {
      return;
    }

    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('평점을 수정했습니다.')));
  }

  Future<void> _deleteRating() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('평점 삭제'),
          content: const Text('등록한 평점을 삭제할까요?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('삭제'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    final viewModel = context.read<MovieDetailViewModel>();

    await viewModel.deleteCurrentRating();

    if (!mounted) {
      return;
    }

    if (viewModel.submitStatus == SubmitStatus.success) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('평점을 삭제했습니다.')));
    } else if (viewModel.submitMessage != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(viewModel.submitMessage!)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final movie = widget.movie;

    if (movie == null) {
      return const Scaffold(body: Center(child: Text('영화를 찾을 수 없습니다.')));
    }

    final viewModel = context.watch<MovieDetailViewModel>();

    final rating = viewModel.currentRating;

    final year = movie.releaseDate?.split('-').first ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('영화 상세'),
        leading: IconButton(
          onPressed: () {
            context.pop();
          },
          icon: const Icon(Icons.arrow_back),
        ),
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                isFavorite = !isFavorite;
              });

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    isFavorite ? '즐겨찾기에 추가했습니다.' : '즐겨찾기에서 삭제했습니다.',
                  ),
                ),
              );
            },
            icon: Icon(isFavorite ? Icons.bookmark : Icons.bookmark_border),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TmdbPosterImage(
              posterPath: movie.posterPath,
              width: double.infinity,
              height: 400,
            ),

            const SizedBox(height: 24),

            Text(
              movie.title,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 8),

            Text(year),

            const SizedBox(height: 24),

            const Text(
              '평균 평점',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 8),

            Row(
              children: [
                RatingBarIndicator(
                  rating: movie.voteAverage / 2,
                  itemCount: 5,
                  itemSize: 24,
                  itemBuilder: (context, index) {
                    return const Icon(Icons.star, color: Colors.amber);
                  },
                ),
                const SizedBox(width: 8),
                Text((movie.voteAverage / 2).toStringAsFixed(1)),
              ],
            ),

            const SizedBox(height: 32),

            if (rating == null)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _createRating,
                  child: const Text('평점 남기기'),
                ),
              )
            else ...[
              const Text(
                '내 평점',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  const Icon(Icons.star, color: Colors.amber),
                  const SizedBox(width: 6),
                  Text('${rating.score} / 5'),
                ],
              ),

              if (rating.comment != null && rating.comment!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(rating.comment!),
              ],

              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed:
                          viewModel.submitStatus == SubmitStatus.submitting
                          ? null
                          : _updateRating,
                      child: const Text('수정'),
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: ElevatedButton(
                      onPressed:
                          viewModel.submitStatus == SubmitStatus.submitting
                          ? null
                          : _deleteRating,
                      child: const Text('삭제'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
