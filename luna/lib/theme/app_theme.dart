import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';
import 'app_text_styles.dart';

abstract final class AppTheme {
  static const _colorScheme = ColorScheme.light(
    primary: AppColors.primary500,
    onPrimary: AppColors.neutral100,
    primaryContainer: AppColors.primary200,
    onPrimaryContainer: AppColors.primary700,
    secondary: AppColors.secondary500,
    onSecondary: AppColors.neutral100,
    secondaryContainer: AppColors.secondary200,
    onSecondaryContainer: AppColors.secondary800,
    tertiary: AppColors.tertiary500,
    onTertiary: AppColors.neutral100,
    tertiaryContainer: AppColors.tertiary100,
    onTertiaryContainer: AppColors.tertiary900,
    surface: AppColors.surfaceBase,
    onSurface: AppColors.neutral900,
    onSurfaceVariant: AppColors.neutral800,
    outline: AppColors.neutral800,
    outlineVariant: AppColors.surfaceHighest,
    surfaceContainerLowest: AppColors.surfaceLowest,
    surfaceContainerLow: AppColors.surfaceLow,
    surfaceContainer: AppColors.surfaceContainer,
    surfaceContainerHigh: AppColors.surfaceHigh,
    surfaceContainerHighest: AppColors.surfaceHighest,
  );

  static const _textTheme = TextTheme(
    headlineLarge: AppTextStyles.titleLarge,
    headlineMedium: AppTextStyles.titleMedium,
    bodyLarge: AppTextStyles.bodyLarge,
    bodyMedium: AppTextStyles.bodyMedium,
    labelLarge: AppTextStyles.labelLarge,
    labelSmall: AppTextStyles.labelSmall,
  );

  static final ThemeData light = ThemeData(
    useMaterial3: true,
    fontFamily: 'Manrope',
    colorScheme: _colorScheme,
    scaffoldBackgroundColor: _colorScheme.surface,
    textTheme: _textTheme,
    appBarTheme: AppBarTheme(
      backgroundColor: _colorScheme.surface,
      foregroundColor: _colorScheme.onSurface,
      centerTitle: false,
      elevation: 0,
      scrolledUnderElevation: 0,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: AppTextStyles.titleMedium.copyWith(
        fontWeight: FontWeight.w600,
        color: _colorScheme.primary,
      ),
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: _colorScheme.surface,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primary600,
        foregroundColor: AppColors.neutral100,
        minimumSize: const Size.fromHeight(56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        textStyle: AppTextStyles.buttonLabel,
      ),
    ),
    // 프로필 수정 버튼: 배경은 표면색, 테두리만 보라색으로 표시
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _colorScheme.surface,
        foregroundColor: AppColors.primary600,
        elevation: 0,
        side: const BorderSide(color: AppColors.primary500),
        minimumSize: const Size(128, 44),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: AppTextStyles.buttonLabel,
      ),
    ),
    // 장르 Chip: 연보라 배경의 알약 모양
    chipTheme: ChipThemeData(
      backgroundColor: _colorScheme.primaryContainer,
      side: BorderSide.none,
      shape: const StadiumBorder(),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6), // 높이 32
      labelStyle: AppTextStyles.labelLarge.copyWith(
        color: _colorScheme.onPrimaryContainer,
      ),
    ),
  );
}
