import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// 마이페이지에서 자식 화면으로 이동하는 행('내가 등록한 평점', '내 즐겨찾기').
class ProfileMenuEntry extends StatelessWidget {
  const ProfileMenuEntry({
    super.key,
    required this.title,
    required this.location,
  });

  final String title;
  final String location; // push할 경로. 뒤로가면 마이페이지로 돌아온다

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final borderRadius = BorderRadius.circular(16);

    return Material(
      color: colorScheme.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: borderRadius,
        side: BorderSide(color: colorScheme.primaryContainer, width: 2),
      ),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        title: Text(
          title,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        trailing: Icon(Icons.chevron_right, color: colorScheme.primary),
        onTap: () => context.push(location),
      ),
    );
  }
}
