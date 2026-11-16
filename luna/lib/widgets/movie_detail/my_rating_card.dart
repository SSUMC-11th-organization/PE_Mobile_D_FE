import 'package:flutter/material.dart';

import '../../data/models/rating_dto.dart';
import '../../theme/app_colors.dart';

/// 영화 상세에서 이번 세션에 등록한 내 평점을 보여주는 카드.
/// 등록 응답 result(Rating 객체)를 그대로 그리므로 목록을 다시 조회하지 않는다.
class MyRatingCard extends StatelessWidget {
  const MyRatingCard({super.key, required this.rating});

  final RatingDto rating;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final comment = rating.comment;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary100,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '내가 남긴 평점',
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              for (var i = 1; i <= 5; i++)
                Icon(
                  i <= rating.score ? Icons.star : Icons.star_border,
                  size: 20,
                  color: AppColors.tertiary300,
                ),
              const SizedBox(width: 8),
              Text('${rating.score}점', style: theme.textTheme.bodyMedium),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            comment == null || comment.isEmpty ? '코멘트 없이 별점만 남겼어요.' : comment,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: comment == null || comment.isEmpty
                  ? theme.colorScheme.onSurfaceVariant
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}
