import 'package:flutter/material.dart';

/// 평점 목록을 불러오는 동안 보여주는 화면.
class MyRatingsLoading extends StatelessWidget {
  const MyRatingsLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(semanticsLabel: '평점을 불러오는 중'),
    );
  }
}

/// 이번 세션에서 등록한 평점이 없을 때 보여주는 화면.
class MyRatingsEmpty extends StatelessWidget {
  const MyRatingsEmpty({super.key});

  static const message = '이번 로그인에서 등록한 평점이 없습니다.';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.star_border,
            size: 48,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 12),
          Text(message, style: theme.textTheme.bodyLarge),
          const SizedBox(height: 16),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: SessionScopeNotice(),
          ),
        ],
      ),
    );
  }
}

/// 목록 범위의 한계를 알리는 안내.
/// v7에는 토큰 기반 '내 평점 목록 GET'이 없어 재시작 뒤 기존 평점 전체를 복원하지 못한다.
class SessionScopeNotice extends StatelessWidget {
  const SessionScopeNotice({super.key});

  static const message =
      '이번 로그인에서 등록한 평점만 표시돼요. 로그아웃하거나 앱을 다시 시작하면 '
      '이전에 남긴 평점은 이 목록에서 불러오지 않아요.';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            size: 18,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
