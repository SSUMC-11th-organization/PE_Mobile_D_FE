import 'package:flutter/material.dart';

/// 상세 화면 하단에 고정되는 즐겨찾기 / 평점 남기기 버튼.
/// 즐겨찾기 여부와 내 평점은 부모(상세 화면)가 상태로 관리한다.
class MovieDetailActions extends StatelessWidget {
  const MovieDetailActions({
    super.key,
    required this.isFavorite,
    required this.myRating,
    required this.onFavoritePressed,
    required this.onRatePressed,
  });

  final bool isFavorite;
  final double? myRating; // 아직 평점을 남기지 않았으면 null
  final VoidCallback onFavoritePressed;
  final VoidCallback onRatePressed;

  static const _buttonHeight = 52.0;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(top: BorderSide(color: colorScheme.outlineVariant)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onFavoritePressed,
                  icon: Icon(
                    isFavorite ? Icons.bookmark : Icons.bookmark_border,
                  ),
                  label: const Text('즐겨찾기'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(_buttonHeight),
                    foregroundColor: colorScheme.primary,
                    side: BorderSide(color: colorScheme.primary),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: onRatePressed,
                  icon: const Icon(Icons.rate_review_outlined),
                  label: Text(myRating == null ? '평점 남기기' : '내 평점 $myRating'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(_buttonHeight),
                    shape: const StadiumBorder(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
