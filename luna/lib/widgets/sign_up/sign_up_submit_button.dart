import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// 가입하기 버튼. onPressed가 null이면 연보라색 비활성화 상태로 표시된다.
class SignUpSubmitButton extends StatelessWidget {
  const SignUpSubmitButton({super.key, required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primary500,
        disabledBackgroundColor: AppColors.secondary300,
        disabledForegroundColor: AppColors.neutral100,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: const Text('가입하기'),
    );
  }
}
