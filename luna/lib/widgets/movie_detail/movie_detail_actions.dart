import 'package:flutter/material.dart';

/// 상세 화면 하단에 고정되는 평점 남기기 버튼.
/// 즐겨찾기는 9주차부터 제목 옆 북마크(FavoriteButton)가 서버 상태로 처리한다.
class MovieDetailActions extends StatelessWidget {
  const MovieDetailActions({
    super.key,
    required this.canRate,
    required this.onRatePressed,
    this.rateLabel = '평점 남기기',
  });

  final bool canRate; // 이번 세션에서 아직 이 영화에 평점을 등록하지 않았을 때만 true
  final String rateLabel;
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
          // 왼쪽 즐겨찾기 버튼이 빠졌으므로 평점 버튼이 전체 너비를 쓴다
          child: FilledButton.icon(
            onPressed: canRate ? onRatePressed : null,
            icon: const Icon(Icons.rate_review_outlined),
            label: Text(rateLabel),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(_buttonHeight),
              shape: const StadiumBorder(),
            ),
          ),
        ),
      ),
    );
  }
}
