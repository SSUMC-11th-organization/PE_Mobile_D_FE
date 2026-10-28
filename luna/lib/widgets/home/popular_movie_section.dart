import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/tmdb_movie_dto.dart';
import '../../view_models/movie_home_view_model.dart';
import '../movie_list/movie_list_loading.dart';
import 'popular_movie_card.dart';

/// "인기 영화" 제목 + 가로로 스크롤되는 인기 영화 목록.
/// 홈 ViewModel의 상태(Loading·Empty·Error·Success)에 맞는 내용을 목록 자리에 보여준다.
class PopularMovieSection extends StatelessWidget {
  const PopularMovieSection({
    super.key,
    required this.status,
    required this.movies,
    required this.onRetry,
    this.message,
  });

  final MovieHomeLoadStatus status;
  final List<TmdbMovieDto> movies;
  final VoidCallback onRetry;
  final String? message; // Error 상태에서 보여줄 안내 문구

  static const _horizontalPadding = 16.0;
  static const _listHeight = 260.0;
  static const _cardWidth = 140.0;

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
          height: _listHeight,
          child: switch (status) {
            MovieHomeLoadStatus.idle ||
            MovieHomeLoadStatus.loading => _buildLoading(),
            MovieHomeLoadStatus.error => _buildMessage(
              context,
              message ?? '인기 영화를 불러오지 못했어요.',
              showRetry: true,
            ),
            MovieHomeLoadStatus.empty => _buildMessage(
              context,
              '지금은 인기 영화가 없어요.',
            ),
            MovieHomeLoadStatus.success => _buildList(),
          },
        ),
      ],
    );
  }

  Widget _buildList() {
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: _horizontalPadding),
      itemCount: movies.length,
      separatorBuilder: (context, index) => const SizedBox(width: 12),
      itemBuilder: (context, index) {
        return PopularMovieCard(movie: movies[index], rank: index + 1);
      },
    );
  }

  // 영화 카드와 같은 크기의 Skeleton을 인기 영화 수만큼 보여준다
  Widget _buildLoading() {
    return Semantics(
      label: '인기 영화를 불러오는 중',
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: _horizontalPadding),
        itemCount: MovieHomeViewModel.popularCount,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) =>
            const SizedBox(width: _cardWidth, child: MovieCardSkeleton()),
      ),
    );
  }

  Widget _buildMessage(
    BuildContext context,
    String text, {
    bool showRetry = false,
  }) {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            text,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          if (showRetry) ...[
            const SizedBox(height: 12),
            FilledButton(onPressed: onRetry, child: const Text('다시 시도')),
          ],
        ],
      ),
    );
  }
}
