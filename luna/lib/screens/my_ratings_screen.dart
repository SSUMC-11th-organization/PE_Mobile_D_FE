import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../view_models/my_ratings_view_model.dart';
import '../widgets/common/movie_log_app_bar.dart';
import '../widgets/my_ratings/my_ratings_states.dart';
import '../widgets/my_ratings/rating_card.dart';

/// 마이페이지 위에 열리는 '내가 등록한 평점' 화면.
/// 로그인 기능이 없으므로 학습용 memberId의 공개 평점을 조회한다(수정 기능 없음).
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
                message: viewModel.message ?? '평점을 불러오지 못했습니다.',
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
          RatingCard(entry: entry),
        ],
      ],
    );
  }
}
