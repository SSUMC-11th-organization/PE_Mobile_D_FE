import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// 화면 하단의 "이미 계정이 있나요? 로그인" 안내 문구.
/// onTap이 null이면 눌러도 동작하지 않는다(예: 제출 중).
class LoginPrompt extends StatefulWidget {
  const LoginPrompt({super.key, this.onTap});

  final VoidCallback? onTap;

  @override
  State<LoginPrompt> createState() => _LoginPromptState();
}

class _LoginPromptState extends State<LoginPrompt> {
  // TextSpan의 탭 인식기는 직접 dispose해야 하므로 State에서 관리한다
  late final _recognizer = TapGestureRecognizer()
    ..onTap = () => widget.onTap?.call();

  @override
  void dispose() {
    _recognizer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Text.rich(
      TextSpan(
        text: '이미 계정이 있나요? ',
        children: [
          TextSpan(
            text: '로그인',
            style: TextStyle(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w700,
            ),
            recognizer: _recognizer,
          ),
        ],
      ),
      style: theme.textTheme.bodyLarge,
      textAlign: TextAlign.center,
    );
  }
}
