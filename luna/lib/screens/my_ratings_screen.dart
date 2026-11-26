import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/models/rating_dto.dart';
import '../view_models/my_ratings_view_model.dart';
import '../widgets/common/loading_overlay.dart';
import '../widgets/common/movie_log_app_bar.dart';
import '../widgets/common/movie_log_button.dart';
import '../widgets/movie_detail/rating_dialog.dart';
import '../widgets/my_ratings/delete_rating_dialog.dart';
import '../widgets/my_ratings/my_ratings_states.dart';
import '../widgets/my_ratings/rating_card.dart';

/// 마이페이지 위에 열리는 '내가 등록한 평점' 화면.
/// 토큰 기반 '내 평점 목록 GET'이 없으므로 이번 로그인 세션에서 등록한 평점만 수정·삭제한다.
/// root Navigator 위에 표시되므로 하단 NavigationBar가 없다.
class MyRatingsScreen extends StatelessWidget {
  const MyRatingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<MyRatingsViewModel>(
      builder: (context, viewModel, child) {
        // AppBar의 뒤로가기까지 덮도록 Scaffold 전체 위에 오버레이를 올린다
        return PopScope(
          canPop: !viewModel.isDeletingSelected,
          child: LoadingOverlay(
            isLoading: viewModel.isDeletingSelected,
            child: Scaffold(
              appBar: const MovieLogAppBar(
                title: '내가 등록한 평점',
                showBackButton: true,
                centerTitle: true,
                fallbackLocation: '/my',
              ),
              body: SafeArea(child: _buildBody(viewModel)),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBody(MyRatingsViewModel viewModel) {
    // 다중 삭제 뒤 재조회 중에도 오버레이 아래의 목록을 그대로 유지한다
    if (viewModel.isDeletingSelected) return _RatingList(viewModel: viewModel);

    return switch (viewModel.status) {
      MyRatingsLoadStatus.idle ||
      MyRatingsLoadStatus.loading => const MyRatingsLoading(),
      MyRatingsLoadStatus.empty => const MyRatingsEmpty(),
      MyRatingsLoadStatus.success => _RatingList(viewModel: viewModel),
    };
  }
}

class _RatingList extends StatelessWidget {
  const _RatingList({required this.viewModel});

  final MyRatingsViewModel viewModel;

  // 삭제로 목록이 비면 이 위젯이 Empty로 바뀌어 context가 사라지므로
  // Dialog의 콜백은 context 대신 viewModel을 직접 사용한다
  Future<void> _onEditPressed(BuildContext context, RatingDto rating) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false, // 저장 중 바깥 탭으로 닫히는 것도 막는다
      builder: (_) => RatingDialog(
        initialScore: rating.score,
        initialComment: rating.comment, // null이면 빈 칸으로 시작
        // 수정에서는 체크박스를 보이지 않으므로 세 번째 값(addToFavorites)은 쓰지 않는다
        onSubmit: (score, comment, _) => viewModel.updateRating(
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

  Future<void> _onDeleteSelectedPressed(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    // 단일 삭제와 달리 Dialog는 묻기만 하고 닫히며, 진행 상태는 화면의 오버레이가 보여준다
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => const DeleteRatingDialog(title: '선택한 평점을 삭제할까요?'),
    );
    if (confirmed != true) return;

    final failed = await viewModel.deleteSelectedRatings();
    if (failed > 0) {
      messenger.showSnackBar(
        SnackBar(content: Text('$failed개 항목을 삭제하지 못했습니다. 선택된 항목을 다시 확인해 주세요.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final notice = viewModel.message; // 일부 영화 정보 누락 안내
    final ratings = viewModel.ratings;
    final isSelectionMode = viewModel.isSelectionMode;
    final selectedCount = viewModel.selectedRatingIds.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SelectionHeader(viewModel: viewModel),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              const SessionScopeNotice(),
              const SizedBox(height: 16),
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
                if (isSelectionMode)
                  SelectableRatingCard(
                    entry: entry,
                    isSelected: viewModel.selectedRatingIds.contains(
                      entry.rating.ratingId,
                    ),
                    onToggle: () =>
                        viewModel.toggleSelection(entry.rating.ratingId),
                  )
                else
                  RatingCard(
                    entry: entry,
                    onEdit: () => _onEditPressed(context, entry.rating),
                    onDelete: () => _onDeletePressed(context, entry.rating),
                  ),
              ],
            ],
          ),
        ),
        if (isSelectionMode)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: MovieLogButton(
              label: '선택한 $selectedCount개 삭제',
              width: double.infinity,
              height: 56,
              borderRadius: 999,
              onPressed: selectedCount > 0
                  ? () => _onDeleteSelectedPressed(context)
                  : null,
            ),
          ),
      ],
    );
  }
}

/// 목록 위의 "편집" 버튼 줄. 다중 선택 중에는 선택 수와 "취소"를 보여준다.
class _SelectionHeader extends StatelessWidget {
  const _SelectionHeader({required this.viewModel});

  final MyRatingsViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSelectionMode = viewModel.isSelectionMode;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
      child: Row(
        children: [
          if (isSelectionMode)
            Text(
              '${viewModel.selectedRatingIds.length}개 선택됨',
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          const Spacer(),
          TextButton(
            onPressed: isSelectionMode
                ? viewModel.cancelSelection
                : viewModel.enterSelectionMode,
            child: Text(isSelectionMode ? '취소' : '편집'),
          ),
        ],
      ),
    );
  }
}
