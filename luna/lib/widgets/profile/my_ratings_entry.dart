import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// 마이페이지에서 '내가 등록한 평점' 자식 화면으로 이동하는 행.
class MyRatingsEntry extends StatelessWidget {
  const MyRatingsEntry({super.key});

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
          '내가 등록한 평점',
          style: theme.textTheme.bodyLarge?.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        trailing: Icon(Icons.chevron_right, color: colorScheme.primary),
        // push: 뒤로가면 마이페이지로 돌아온다
        onTap: () => context.push('/my/ratings'),
      ),
    );
  }
}
