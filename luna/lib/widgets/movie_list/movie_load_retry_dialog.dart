import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// 영화 목록 요청이 실패했지만 이전 목록을 유지하고 있을 때 띄우는 재시도 Dialog.
/// 다시 시도를 누르면 true, 취소를 누르면 false를 Navigator.pop으로 돌려준다.
class MovieLoadRetryDialog extends StatelessWidget {
  const MovieLoadRetryDialog({super.key});

  static const title = '영화를 불러오지 못했어요';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;
    final pillShape = const StadiumBorder();

    return Dialog(
      backgroundColor: AppColors.surfaceLowest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: AppColors.primary100,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.replay, size: 32, color: colorScheme.primary),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              '네트워크 상태를 확인하고\n다시 시도해 주세요.',
              style: textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary100,
                      foregroundColor: AppColors.primary500,
                      minimumSize: const Size.fromHeight(52),
                      shape: pillShape,
                    ),
                    child: const Text('취소'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary500,
                      foregroundColor: AppColors.neutral100,
                      minimumSize: const Size.fromHeight(52),
                      shape: pillShape,
                    ),
                    child: const Text('다시 시도'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
