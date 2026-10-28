import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// 단색 SVG 아이콘을 테마 색상으로 칠해서 보여주는 공용 위젯.
/// SVG 원본은 색이 지정돼 있지 않아 검정으로 나오므로, colorFilter로 색을 입힌다.
class AppSvgIcon extends StatelessWidget {
  const AppSvgIcon(
    this.assetPath, {
    super.key,
    this.size = 24,
    this.color,
    this.semanticsLabel,
  });

  final String assetPath;
  final double size;
  final Color? color; // 지정하지 않으면 테마의 onSurface 색을 사용
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      assetPath,
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(
        color ?? Theme.of(context).colorScheme.onSurface,
        BlendMode.srcIn, // 원본 도형 모양은 유지하고 색만 덮어씀
      ),
      semanticsLabel: semanticsLabel,
    );
  }
}
