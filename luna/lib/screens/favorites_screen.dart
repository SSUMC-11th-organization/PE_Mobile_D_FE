import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/models/favorite_list_item.dart';
import '../theme/app_colors.dart';
import '../view_models/favorites_view_model.dart';
import '../view_models/load_phase.dart';
import '../widgets/common/movie_log_app_bar.dart';
import '../widgets/common/movie_log_button.dart';
import '../widgets/movie/movie_tile_card.dart';

/// 마이페이지 위에 열리는 '내 즐겨찾기' 화면. root Navigator 위라 하단 NavigationBar가 없다.
/// 목록 · 빈 목록 · 조회 오류 · 영화 정보 한 건 실패를 서로 다른 화면으로 보여준다.
class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key, required this.onOpenMovie});

  /// 카드를 눌러 상세로 이동한다. 상세가 닫힐 때 완료되는 Future를 돌려준다
  final Future<void> Function(int movieId) onOpenMovie;

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  @override
  void initState() {
    super.initState();
    // refresh()는 첫 줄에서 알림을 보내므로 첫 build 이후에 호출한다
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<FavoritesViewModel>().refresh();
    });
  }

  Future<void> _open(FavoritesViewModel vm, int movieId) async {
    await widget.onOpenMovie(movieId);
    if (!mounted) return;
    // 상세에서 해제하고 돌아왔을 수 있으므로 목록을 다시 조회한다.
    // ViewModel도 같은 현재 세션인지 다시 확인한다
    await vm.refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const MovieLogAppBar(
        title: '내 즐겨찾기',
        showBackButton: true,
        centerTitle: true,
        fallbackLocation: '/my',
      ),
      body: SafeArea(
        child: Consumer<FavoritesViewModel>(
          builder: (context, vm, _) => switch (vm.phase) {
            LoadPhase.idle || LoadPhase.loading => const Center(
              child: CircularProgressIndicator(semanticsLabel: '즐겨찾기를 불러오는 중'),
            ),
            LoadPhase.empty => RefreshIndicator(
              onRefresh: vm.refresh,
              child: const CustomScrollView(
                physics: AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: FavoritesEmpty(),
                  ),
                ],
              ),
            ),
            LoadPhase.error => FavoritesError(
              message: vm.errorMessage ?? '즐겨찾기를 불러오지 못했습니다.',
              onRetry: vm.refresh,
            ),
            LoadPhase.ready => RefreshIndicator(
              onRefresh: vm.refresh,
              child: ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
                itemCount: vm.items.length,
                separatorBuilder: (_, _) => const SizedBox(height: 16),
                itemBuilder: (context, index) => _FavoriteCard(
                  item: vm.items[index],
                  isRetrying: vm.isRetrying(vm.items[index].favorite.movieId),
                  onTap: () => _open(vm, vm.items[index].favorite.movieId),
                  onRetry: () =>
                      vm.retryMovie(vm.items[index].favorite.movieId),
                ),
              ),
            ),
          },
        ),
      ),
    );
  }
}

class _FavoriteCard extends StatelessWidget {
  const _FavoriteCard({
    required this.item,
    required this.isRetrying,
    required this.onTap,
    required this.onRetry,
  });

  final FavoriteListItem item;
  final bool isRetrying;
  final VoidCallback onTap;
  final VoidCallback onRetry;

  // createdAt은 UTC로 오므로 기기 시간대로 바꿔 'yyyy.MM.dd'로 표시
  static String _formatDate(DateTime dateTime) {
    final local = dateTime.toLocal();
    String twoDigits(int value) => value.toString().padLeft(2, '0');
    return '${local.year}.${twoDigits(local.month)}.${twoDigits(local.day)}';
  }

  @override
  Widget build(BuildContext context) {
    final movie = item.movie;
    final label = '${_formatDate(item.favorite.createdAt)} 즐겨찾기';

    if (movie == null) {
      // 영화 정보 한 건만 실패: placeholder와 그 카드만 다시 조회하는 버튼
      return MovieTileCard(
        title: '영화 #${item.favorite.movieId}',
        showPoster: false,
        subtitle: item.errorMessage ?? FavoritesViewModel.movieErrorMessage,
        label: label,
        onTap: onTap,
        action: Align(
          alignment: Alignment.centerLeft,
          child: isRetrying
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : TextButton(
                  onPressed: onRetry,
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    foregroundColor: AppColors.primary500,
                    textStyle: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  child: const Text('정보 다시 불러오기'),
                ),
        ),
      );
    }

    final subtitle = [
      ?movie.releaseYear?.toString(),
      ...movie.genres.take(2).map((genre) => genre.name),
    ].join(' · ');

    return MovieTileCard(
      title: movie.title,
      posterPath: movie.posterPath,
      subtitle: subtitle,
      label: label,
      onTap: onTap,
    );
  }
}

/// 즐겨찾기가 하나도 없을 때.
class FavoritesEmpty extends StatelessWidget {
  const FavoritesEmpty({super.key});

  static const message = '아직 즐겨찾기한 영화가 없습니다.';

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.bookmark_border,
              size: 48,
              color: AppColors.primary500,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: textTheme.bodyLarge?.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              '영화 상세에서 북마크를 눌러보세요.',
              style: textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// 즐겨찾기 목록 조회 전체가 실패했을 때.
class FavoritesError extends StatelessWidget {
  const FavoritesError({
    super.key,
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              style: Theme.of(context).textTheme.bodyLarge
                  ?.copyWith(fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            MovieLogButton(
              label: '다시 시도',
              width: 200,
              height: 52,
              onPressed: onRetry,
            ),
          ],
        ),
      ),
    );
  }
}
