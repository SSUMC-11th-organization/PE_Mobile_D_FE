import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

/// 여러 화면이 함께 쓰는 공용 버튼. 기본 · 통신 중 · 비활성 세 상태를 표시만 하고,
/// 상태를 바꾸는 결정은 화면(ViewModel)이 isLoading·onPressed로 전달한다.
///
/// width: null이면 label 길이에 맞는 크기, double.infinity면 부모가 허용하는 최대 너비,
/// 고정 값이면 항상 그 크기를 사용한다.
class MovieLogButton extends StatelessWidget {
  const MovieLogButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.width,
    this.height = 48,
  });

  final String label;
  final VoidCallback? onPressed; // null이면 조건이 충족되지 않은 비활성 상태
  final bool isLoading; // true면 onPressed와 관계없이 비활성 + 인디케이터 표시
  final double? width;
  final double height; // 기본값은 입력창 높이(48)와 맞춤

  bool get _disabled => isLoading || onPressed == null;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: ElevatedButton(
        onPressed: _disabled ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary500,
          foregroundColor: AppColors.neutral100,
          // 통신 중은 회색, 조건 미충족은 연보라로 구분
          disabledBackgroundColor: isLoading
              ? AppColors.neutral800
              : AppColors.secondary300,
          disabledForegroundColor: AppColors.neutral100,
          // elevatedButtonTheme(프로필 수정 버튼)의 테두리·최소 너비 128을 끊어야
          // width: null일 때 내용 크기만 차지한다
          side: BorderSide.none,
          minimumSize: Size.zero,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          textStyle: AppTextStyles.buttonLabel,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: isLoading ? _buildIndicator() : Text(label),
      ),
    );
  }

  // 인디케이터만 그리되, 보이지 않는 label 자리를 유지해
  // 통신 중에 버튼 너비가 줄어들지 않게 한다 (label은 그리지 않음)
  Widget _buildIndicator() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Visibility(
          visible: false,
          maintainSize: true,
          maintainAnimation: true,
          maintainState: true,
          child: Text(label),
        ),
        const SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.neutral100,
          ),
        ),
      ],
    );
  }
}
