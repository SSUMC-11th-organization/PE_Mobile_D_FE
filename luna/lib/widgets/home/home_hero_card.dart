import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/movie.dart';
import '../../theme/app_colors.dart';
import '../common/app_svg_icon.dart';

/// 홈 상단의 추천 영화 카드. 포스터 위에 제목·정보·상세보기 버튼을 겹쳐 표시한다.
class HomeHeroCard extends StatelessWidget {
  const HomeHeroCard({super.key, required this.movie});

  final Movie movie;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return AspectRatio(
      aspectRatio: 0.68,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(movie.posterAsset, fit: BoxFit.cover),
            // 아래쪽 글자가 잘 보이도록 포스터 하단을 어둡게 처리
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black87],
                  stops: [0.4, 1],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary600,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.primary400),
                    ),
                    child: Text(
                      '추천 신작',
                      style: textTheme.labelLarge?.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    movie.title,
                    style: textTheme.headlineLarge?.copyWith(
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${movie.tags.take(2).join(' · ')} · ${movie.runtime}분',
                    style: textTheme.bodyLarge?.copyWith(color: Colors.white70),
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: () => context.push('/home/movies/${movie.id}'),
                    icon: const AppSvgIcon(
                      'assets/icons/info.svg',
                      size: 20,
                      color: Colors.white,
                    ),
                    label: const Text('상세보기'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
