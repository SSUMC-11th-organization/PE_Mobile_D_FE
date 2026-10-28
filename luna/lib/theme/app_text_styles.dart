import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Cinematic Archive 타이포그래피. (크기 / 행간 / 자간)
/// 이름은 Figma 기준이고, AppTheme에서 Flutter TextTheme 슬롯에 연결한다.
abstract final class AppTextStyles {
  // TITLE LARGE (HEADLINE LARGE) 28 / 36 / 0
  static const titleLarge = TextStyle(
    fontSize: 28,
    height: 36 / 28,
    letterSpacing: 0,
    fontWeight: FontWeight.w700,
    color: AppColors.neutral900,
  );

  // TITLE MEDIUM (HEADLINE MEDIUM) 24 / 32 / 0
  static const titleMedium = TextStyle(
    fontSize: 24,
    height: 32 / 24,
    letterSpacing: 0,
    fontWeight: FontWeight.w700,
    color: AppColors.neutral900,
  );

  // BODY LARGE 16 / 24 / 0.5
  static const bodyLarge = TextStyle(
    fontSize: 16,
    height: 24 / 16,
    letterSpacing: 0.5,
    fontWeight: FontWeight.w400,
    color: AppColors.neutral900,
  );

  // BODY MEDIUM 14 / 20 / 0.25
  static const bodyMedium = TextStyle(
    fontSize: 14,
    height: 20 / 14,
    letterSpacing: 0.25,
    fontWeight: FontWeight.w400,
    color: AppColors.neutral900,
  );

  // LABEL LARGE (BUTTON LABEL) 14 / 20 / 0.1
  static const labelLarge = TextStyle(
    fontSize: 14,
    height: 20 / 14,
    letterSpacing: 0.1,
    fontWeight: FontWeight.w500,
    color: AppColors.neutral900,
  );

  // 버튼 라벨: LABEL LARGE 크기에 SemiBold
  static const buttonLabel = TextStyle(
    fontSize: 14,
    height: 20 / 14,
    letterSpacing: 0.1,
    fontWeight: FontWeight.w600,
  );

  // LABEL SMALL (METADATA & CAPTIONS) 11 / 16 / 0.5
  static const labelSmall = TextStyle(
    fontSize: 11,
    height: 16 / 11,
    letterSpacing: 0.5,
    fontWeight: FontWeight.w500,
    color: AppColors.neutral900,
  );
}
