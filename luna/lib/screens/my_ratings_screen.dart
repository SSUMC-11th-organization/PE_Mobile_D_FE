import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/models/rating_dto.dart';
import '../view_models/my_ratings_view_model.dart';
import '../widgets/common/movie_log_app_bar.dart';
import '../widgets/movie_detail/rating_dialog.dart';
import '../widgets/my_ratings/delete_rating_dialog.dart';
import '../widgets/my_ratings/my_ratings_states.dart';
import '../widgets/my_ratings/rating_card.dart';

/// 마이페이지 위에 열리는 '내가 등록한 평점' 화면.
/// 로그인 기능이 없으므로 학습용 memberId의 평점을 조회·수정·삭제한다.
/// root Navigator 위에 표시되므로 하단 NavigationBar가 없다.
class MyRatingsScreen extends StatelessWidget {
  const MyRatingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const MovieLogAppBar(
        title: '내가 등록한 평점',
        showBackButton: true,
        centerTitle: true,
        fallbackLocation: '/my',
      ),
      body: SafeArea(
        child: Consumer<MyRatingsViewModel>(
          builder: (context, viewModel, child) {
            return switch (viewModel.status) {
              MyRatingsLoadStatus.idle ||
              MyRatingsLoadStatus.loading => const MyRatingsLoading(),
              MyRatingsLoadStatus.empty => const MyRatingsEmpty(),
              MyRatingsLoadStatus.error => MyRatingsError(
                // 쓰기 성공 뒤 재조회만 실패했다면 저장 완료 사실을 함께 안내한다
                message:
                    viewModel.refreshWarning ??
                    viewModel.message ??
                    '평점을 불러오지 못했습니다.',
                onRetry: viewModel.load,
              ),
              MyRatingsLoadStatus.success => _RatingList(viewModel: viewModel),
            };
          },
        ),
      ),
    );
  }
}

class _RatingList extends StatelessWidget {
  const _RatingList({required this.viewModel});

  final MyRatingsViewModel viewModel;

  // 재조회 중에는 이 목록이 Loading으로 바뀌어 context가 사라지므로
  // Dialog의 콜백은 context 대신 viewModel을 직접 사용한다
  Future<void> _onEditPressed(BuildContext context, RatingDto rating) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false, // 저장 중 바깥 탭으로 닫히는 것도 막는다
      builder: (_) => RatingDialog(
        initialScore: rating.score,
        initialComment: rating.comment, // null이면 빈 칸으로 시작
        onSubmit: (score, comment) => viewModel.updateRating(
          ratingId: rating.ratingId,
          score: score,
          comment: comment,
        ),
      ),
    );
  }

  Future<void> _onDeletePressed(BuildContext context, RatingDto rating) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false, // 삭제 중 바깥 탭으로 닫히는 것도 막는다
      builder: (_) => DeleteRatingDialog(
        onConfirm: () => viewModel.deleteRating(rating.ratingId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final notice = viewModel.message; // 일부 영화 정보 누락 안내
    final ratings = viewModel.ratings;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
      children: [
        if (notice != null) ...[
          Text(
            notice,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
        ],
        for (final (index, entry) in ratings.indexed) ...[
          if (index > 0) const SizedBox(height: 24),
          RatingCard(
            entry: entry,
            onEdit: () => _onEditPressed(context, entry.rating),
            onDelete: () => _onDeletePressed(context, entry.rating),
          ),
        ],
      ],
    );
  }
}
