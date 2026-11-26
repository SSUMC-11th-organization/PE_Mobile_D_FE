import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../common/tmdb_poster_image.dart';

/// 포스터 왼쪽 + 제목·설명·보라색 라벨 오른쪽의 가로형 영화 카드.
/// 내 즐겨찾기·영화 검색 결과가 함께 쓴다.
/// showPoster가 false면(영화 정보를 가져오지 못함) 포스터 자리에 연보라 placeholder를 둔다.
class MovieTileCard extends StatelessWidget {
  const MovieTileCard({
    super.key,
    required this.title,
    this.posterPath,
    this.showPoster = true,
    this.subtitle,
    this.label,
    this.action,
    this.onTap,
  });

  final String title;
  final String? posterPath;
  final bool showPoster;
  final String? subtitle;
  final String? label; // 보라색 강조 문구
  final Widget? action; // 라벨 아래 추가 버튼(정보 다시 불러오기 등)
  final VoidCallback? onTap;

  static const posterWidth = 90.0;
  static const posterHeight = 132.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final borderRadius = BorderRadius.circular(16);

    return Material(
      color: AppColors.surfaceLowest,
      shape: RoundedRectangleBorder(
        borderRadius: borderRadius,
        side: const BorderSide(color: AppColors.secondary300),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: showPoster
                    ? TmdbPosterImage(
                        posterPath: posterPath,
                        width: posterWidth,
                        height: posterHeight,
                      )
                    : Container(
                        width: posterWidth,
                        height: posterHeight,
                        color: AppColors.primary200.withValues(alpha: 0.5),
                      ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodyLarge?.copyWith(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (subtitle != null && subtitle!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        subtitle!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                    if (label != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        label!,
                        style: textTheme.bodyMedium?.copyWith(
                          color: AppColors.primary500,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                    ?action,
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
