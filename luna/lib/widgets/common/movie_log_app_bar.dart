import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'app_svg_icon.dart';

/// 모든 화면에서 공통으로 쓰는 AppBar.
/// 색, 글꼴, 정렬은 AppTheme의 AppBarTheme을 따른다.
class MovieLogAppBar extends StatelessWidget implements PreferredSizeWidget {
  const MovieLogAppBar({
    super.key,
    required this.title,
    this.showBackButton = false,
    this.centerTitle,
    this.actions,
  });

  final String title;
  final bool showBackButton; // true면 왼쪽에 뒤로가기 버튼을 표시
  final bool? centerTitle; // 지정하지 않으면 AppBarTheme 설정(왼쪽 정렬)을 따름
  final List<Widget>? actions;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  // 이전 화면이 쌓여 있으면 pop으로 돌아가고,
  // 없으면(URL로 바로 들어온 경우 등) 홈으로 이동해 버튼이 동작하지 않는 상황을 막음
  void _goBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      leading: showBackButton
          ? IconButton(
              onPressed: () => _goBack(context),
              icon: const AppSvgIcon(
                'assets/icons/arrow_back.svg',
                semanticsLabel: '뒤로가기',
              ),
            )
          : null,
      title: Text(title),
      centerTitle: centerTitle,
      actions: actions,
    );
  }
}
