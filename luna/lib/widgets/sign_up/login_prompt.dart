import 'package:flutter/material.dart';

/// 화면 하단의 "이미 계정이 있나요? 로그인" 안내 문구.
class LoginPrompt extends StatelessWidget {
  const LoginPrompt({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Text.rich(
      TextSpan(
        text: '이미 계정이 있나요? ',
        children: [
          TextSpan(
            text: '로그인',
            style: TextStyle(color: theme.colorScheme.primary),
          ),
        ],
      ),
      style: theme.textTheme.bodyLarge,
      textAlign: TextAlign.center,
    );
  }
}
