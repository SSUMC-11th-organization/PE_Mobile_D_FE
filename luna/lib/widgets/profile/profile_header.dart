import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

class ProfileHeader extends StatelessWidget {
  const ProfileHeader({
    super.key,
    this.imagePath, // null이면 기본 Icon을 표시
    required this.name,
    required this.email,
    this.joinedAt,
  });

  /// 가입일을 "2026.10.10 가입" 형식으로 바꾼다. 서버의 UTC 시각을 기기 날짜로 표시한다.
  static String formatJoinedAt(DateTime createdAt) {
    final local = createdAt.toLocal();
    String two(int value) => value.toString().padLeft(2, '0');
    return '${local.year}.${two(local.month)}.${two(local.day)} 가입';
  }

  final String? imagePath;
  final String name;
  final String email; // GET me로 받은 이메일
  final DateTime? joinedAt; // GET me의 createdAt. null이면 표시하지 않는다

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final path = imagePath;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center, // 교차축(가로) 가운데 정렬
      children: [
        Container(
          width: 128,
          height: 128,
          margin: const EdgeInsets.only(bottom: 16), // 바깥 여백: 사진과 이름 사이
          padding: const EdgeInsets.all(2), // 안쪽 여백: 테두리와 사진 사이
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            border: Border.fromBorderSide(
              BorderSide(color: AppColors.primary300, width: 2),
            ),
          ),
          child: ClipOval(
            child: path == null
                ? const _DefaultAvatar()
                : Image.asset(
                    path,
                    fit: BoxFit.cover,
                    // 이미지 파일을 못 불러올 때도 기본 Icon으로 대체
                    errorBuilder: (_, _, _) => const _DefaultAvatar(),
                  ),
          ),
        ),
        Text(
          name,
          style: textTheme.headlineMedium,
          textAlign: TextAlign.center,
        ),
        if (joinedAt case final joinedAt?) ...[
          const SizedBox(height: 4),
          Text(
            formatJoinedAt(joinedAt),
            style: textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
        const SizedBox(height: 4),
        Text(
          email,
          style: textTheme.bodyLarge?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

/// 프로필 이미지가 없을 때 보여주는 기본 Icon
class _DefaultAvatar extends StatelessWidget {
  const _DefaultAvatar();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ColoredBox(
      color: colorScheme.primaryContainer,
      child: Center(
        child: Icon(Icons.person, size: 64, color: colorScheme.primary),
      ),
    );
  }
}
