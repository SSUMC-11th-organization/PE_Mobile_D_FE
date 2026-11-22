import 'package:flutter/material.dart';

import '../../view_models/load_phase.dart';
import '../../view_models/paged_movies_view_model.dart';
import '../common/movie_log_button.dart';

/// 목록 아래 footer: 더 보기 · 추가 로딩 · 다음 page 실패(같은 page 재시도) · 마지막 page.
class MoviePageFooter extends StatelessWidget {
  const MoviePageFooter({
    super.key,
    required this.vm,
    this.moreLabel = '더 보기',
    this.endMessage = '모든 영화를 확인했습니다.',
  });

  final PagedMoviesViewModel vm;
  final String moreLabel;
  final String endMessage;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final loadMoreError = vm.loadMoreError;

    // 마지막 page(또는 TMDB 최대 500 page)까지 봤으면 더 보기를 숨기고 끝 상태를 보여준다
    if (!vm.hasMore && !vm.isLoadingMore && loadMoreError == null) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
        child: Text(
          endMessage,
          style: textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      child: Column(
        children: [
          if (loadMoreError != null) ...[
            Text(
              loadMoreError,
              style: textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
          ],
          // 요청 중에는 기존 카드를 그대로 두고 버튼만 회색 + 인디케이터로 바꾼다
          MovieLogButton(
            width: double.infinity,
            height: 52,
            label: loadMoreError == null ? moreLabel : '다음 페이지 다시 시도',
            isLoading: vm.isLoadingMore,
            onPressed: vm.phase == LoadPhase.ready && !vm.isRefreshing
                ? vm.loadNextPage
                : null,
          ),
        ],
      ),
    );
  }
}
