import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:provider/provider.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../view_models/movie_detail_view_model.dart';
import '../view_models/sign_up_view_model.dart' show SubmitStatus;
import '../widgets/rating_dialog.dart';
import '../widgets/tmdb_poster_image.dart';

const double averageRating = 4.5;

class MovieDetailScreen extends StatefulWidget {
  const MovieDetailScreen({super.key});

  @override
  State<MovieDetailScreen> createState() => _MovieDetailScreenState();
}

class _MovieDetailScreenState extends State<MovieDetailScreen> {
  bool _isFavorite = false;

  void _toggleFavorite() {
    setState(() => _isFavorite = !_isFavorite);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isFavorite ? '즐겨찾기에 추가했습니다.' : '즐겨찾기에서 삭제했습니다.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _openRatingDialog() async {
    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false, // 저장 중 바깥 탭으로 닫히는 것도 막습니다.
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

    if (!mounted || saved != true) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('평점을 등록했습니다. 마이페이지의 "내가 등록한 평점"에서 확인할 수 있습니다.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<MovieDetailViewModel>();
    final movie = viewModel.movie;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 320,
            backgroundColor: AppColors.warmWhite,
            foregroundColor: AppColors.black,
            flexibleSpace: FlexibleSpaceBar(
              background: TmdbPosterImage(
                posterPath: movie.posterPath,
                width: double.infinity,
                height: double.infinity,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(movie.title, style: AppTextStyles.titleLarge),
                  const SizedBox(height: 4),
                  if (movie.releaseDate != null &&
                      movie.releaseDate!.length >= 4)
                    Text(
                      movie.releaseDate!.substring(0, 4),
                      style: const TextStyle(color: AppColors.gray),
                    ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      RatingBarIndicator(
                        rating: averageRating,
                        itemCount: 5,
                        itemSize: 20,
                        itemBuilder: (context, index) =>
                            const Icon(Icons.star, color: Colors.amber),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        averageRating.toStringAsFixed(1),
                        style: AppTextStyles.bodyMedium,
                      ),
                    ],
                  ),
                  if (movie.overview.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    const Text(
                      '시놉시스',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(movie.overview, style: AppTextStyles.bodyMedium),
                  ],
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _toggleFavorite,
                          icon: Icon(
                            _isFavorite
                                ? Icons.bookmark
                                : Icons.bookmark_border,
                            color: AppColors.violet,
                          ),
                          label: Text(_isFavorite ? '즐겨찾기됨' : '즐겨찾기'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.violet,
                            side: const BorderSide(color: AppColors.violet),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: viewModel.memberId == null
                              ? null
                              : _openRatingDialog,
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          label: Text(
                            viewModel.memberId == null
                                ? '회원가입 후 평점 남기기'
                                : '평점 남기기',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.violet,
                            foregroundColor: AppColors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
