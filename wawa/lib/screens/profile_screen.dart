import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

// 1. 공용 AppBar 위젯
class CommonAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback? onBack;
  final List<Widget>? actions;
  final bool centerTitle;
  final TextStyle? titleStyle;

  const CommonAppBar({
    super.key,
    required this.title,
    this.onBack,
    this.actions,
    this.centerTitle = false,
    this.titleStyle,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(
        title,
        style:
            titleStyle ??
            AppTextStyles.titleLarge.copyWith(color: AppColors.violet),
      ),
      centerTitle: centerTitle,
      leading: onBack == null
          ? null
          : IconButton(icon: const Icon(Icons.arrow_back), onPressed: onBack),
      actions: actions,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

// 2. 재사용 가능한 통계 항목 위젯 (본 영화, 평점 등)

// 2. 재사용 가능한 통계 항목 위젯 (수정됨)
class StatItem extends StatelessWidget {
  final String label;
  final String value;

  const StatItem({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.lightGray,
        border: Border.all(color: AppColors.lightViolet),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // 1. 라벨(본 영화, 평점 등)을 위로 배치
          Text(label, style: AppTextStyles.bodyMedium),
          const SizedBox(height: 4),
          // 2. 숫자(342, 4.2 등)를 아래로 배치하고 보라색 적용
          Text(
            value,
            style: AppTextStyles.titleLarge.copyWith(color: AppColors.violet),
          ),
        ],
      ),
    );
  }
}

// 3. 메인 프로필 화면
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CommonAppBar(title: '내 프로필'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(margin: const EdgeInsets.only(bottom: 16)),
            const CircleAvatar(
              radius: 46,
              backgroundColor: AppColors.violet,
              child: CircleAvatar(
                radius: 44,
                backgroundImage: AssetImage(
                  'assets/images/profile/profile_movielog.jpg',
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text('무비러버', style: AppTextStyles.titleLarge),
            const SizedBox(height: 8),
            const Text(
              '좋아하는 영화를 기록하고 있어요',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium,
            ),
            const SizedBox(height: 16),

            // 프로필 수정 버튼 (미션 조건에 맞춘 ElevatedButton)
            ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.person_outline, size: 18),
              label: const Text('프로필 수정'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.white,
                foregroundColor: AppColors.violet,
                elevation: 0,
                side: const BorderSide(color: AppColors.violet),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 통계 영역 (Row를 사용해 3개의 StatItem을 가로로 배치)
            const Row(
              children: [
                Expanded(
                  child: StatItem(label: '본 영화', value: '342'),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: StatItem(label: '평점', value: '4.2'),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: StatItem(label: '즐겨찾기', value: '58'),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // 선호하는 장르 영역
            Align(
              alignment: Alignment.centerLeft,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SvgPicture.asset(
                    'assets/icons/movie.svg',
                    width: 18,
                    height: 18,
                    colorFilter: const ColorFilter.mode(
                      AppColors.violet,
                      BlendMode.srcIn,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    '선호하는 장르',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Chip(
                  label: const Text('드라마'),
                  backgroundColor: AppColors.lightViolet,
                  side: const BorderSide(color: AppColors.lightViolet),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                const SizedBox(width: 8), // Chip 사이의 간격
                Chip(
                  label: const Text('SF'),
                  backgroundColor: AppColors.lightViolet,
                  side: const BorderSide(color: AppColors.lightViolet),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                const SizedBox(width: 8),
                Chip(
                  label: const Text('애니메이션'),
                  backgroundColor: AppColors.lightViolet,
                  side: const BorderSide(color: AppColors.lightViolet),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
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
