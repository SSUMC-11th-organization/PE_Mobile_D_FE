import 'package:flutter/material.dart';

/// 회원가입 화면 상단의 환영 문구.
class SignUpWelcomeText extends StatelessWidget {
  const SignUpWelcomeText({super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      '환영합니다!\n간단한 정보만 입력하고 시작해보세요.',
      style: Theme.of(context).textTheme.bodyLarge,
      textAlign: TextAlign.center,
    );
  }
}
