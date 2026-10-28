import 'package:flutter/material.dart';

import 'app_svg_icon.dart';

/// 모든 화면에서 공통으로 쓰는 AppBar.
/// 색, 글꼴, 정렬은 AppTheme의 AppBarTheme을 따른다.
class MovieLogAppBar extends StatelessWidget implements PreferredSizeWidget {
  const MovieLogAppBar({
    super.key,
    required this.title,
    this.showBackButton = false,
    this.actions,
  });

  final String title;
  final bool showBackButton; // true면 왼쪽에 뒤로가기 버튼을 표시
  final List<Widget>? actions;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      leading: showBackButton
          ? IconButton(
              onPressed: () => Navigator.of(context).maybePop(),
              icon: const AppSvgIcon(
                'assets/icons/arrow_back.svg',
                semanticsLabel: '뒤로가기',
              ),
            )
          : null,
      title: Text(title),
      actions: actions,
    );
  }
}
