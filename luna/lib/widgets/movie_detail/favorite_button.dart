import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../theme/app_colors.dart';
import '../../view_models/favorite_detail_view_model.dart';

/// 영화 상세의 제목·정보 텍스트 오른쪽에 두는 북마크 버튼.
/// 첫 여부 조회·등록·해제 중에는 북마크 자리에만 CircularProgressIndicator를 보여준다.
class FavoriteButton extends StatelessWidget {
  const FavoriteButton({super.key, required this.onResult});

  /// 등록·해제 요청이 끝난 뒤 결과 문구를 받아 Snackbar로 안내한다
  final ValueChanged<String> onResult;

  static const _boxWidth = 62.0;
  static const _boxHeight = 64.0;

  Future<void> _toggle(BuildContext context, FavoriteDetailViewModel vm) async {
    final requested = await vm.toggle();
    // 세션이 바뀌어 결과를 버린 경우(isSaving이 남음)에는 안내하지 않는다
    if (!context.mounted || !requested || vm.isDisposed || vm.isSaving) return;
    onResult(
      vm.errorMessage ?? (vm.isFavorite ? '즐겨찾기에 추가했습니다.' : '즐겨찾기에서 삭제했습니다.'),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Consumer<FavoriteDetailViewModel>(
      builder: (context, vm, _) {
        final busy = vm.isLoading || vm.isSaving || vm.isWaitingForSession;
        final loadFailed = !vm.hasLoadedStatus && !busy;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: _boxWidth,
              height: _boxHeight,
              decoration: BoxDecoration(
                color: AppColors.surfaceLowest,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.secondary300),
              ),
              child: busy
                  ? const Center(
                      child: SizedBox.square(
                        dimension: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primary500,
                          semanticsLabel: '즐겨찾기 요청 중',
                        ),
                      ),
                    )
                  : IconButton(
                      color: AppColors.primary500,
                      iconSize: 32,
                      tooltip: loadFailed
                          ? '즐겨찾기 여부 다시 확인'
                          : (vm.isFavorite ? '즐겨찾기 해제' : '즐겨찾기 추가'),
                      // 첫 여부 조회에 실패했으면 같은 자리에서 다시 조회한다
                      onPressed: loadFailed
                          ? vm.load
                          : () => _toggle(context, vm),
                      icon: Icon(
                        loadFailed
                            ? Icons.refresh
                            : (vm.isFavorite
                                  ? Icons.bookmark
                                  : Icons.bookmark_border),
                      ),
                    ),
            ),
            const SizedBox(height: 6),
            Text(
              '즐겨찾기',
              style: theme.textTheme.labelMedium?.copyWith(
                color: AppColors.primary500,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        );
      },
    );
  }
}
