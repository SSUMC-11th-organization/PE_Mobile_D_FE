import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../widgets/common_app_bar.dart';

import 'package:go_router/go_router.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nicknameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();

  bool _agreedToTerms = false;

  bool get _canSubmit {
    return _nicknameController.text.trim().length >= 2 &&
        _emailController.text.contains('@') &&
        _passwordController.text.length >= 8 &&
        _agreedToTerms;
  }

  String? _validateNickname(String? value) {
    final nickname = value?.trim() ?? '';

    if (nickname.isEmpty) {
      return '닉네임을 입력해주세요.';
    }

    if (nickname.length < 2) {
      return '닉네임은 2자 이상이어야 합니다.';
    }

    return null;
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';

    if (email.isEmpty) {
      return '이메일을 입력해주세요.';
    }

    if (!email.contains('@')) {
      return '올바른 이메일 형식이 아닙니다.';
    }

    return null;
  }

  String? _validatePassword(String? value) {
    final password = value ?? '';

    if (password.isEmpty) {
      return '비밀번호를 입력해주세요.';
    }

    if (password.length < 8) {
      return '비밀번호는 8자 이상이어야 합니다.';
    }

    return null;
  }

  void _submit() {
    final isValid = _formKey.currentState?.validate() ?? false;

    if (!isValid) {
      return;
    }

    FocusScope.of(context).unfocus();
    context.go('/home');
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();

    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBar(title: '회원가입', centerTitle: true),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final maxFormWidth = constraints.maxWidth >= 700
                ? 560.0
                : double.infinity;

            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxFormWidth),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SignUpHeader(),

                        const SizedBox(height: 40),

                        const Text(
                          '닉네임',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _nicknameController,
                          textInputAction: TextInputAction.next,
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          decoration: const InputDecoration(
                            hintText: '닉네임을 입력해주세요',
                            border: OutlineInputBorder(),
                          ),
                          validator: _validateNickname,
                          onChanged: (_) {
                            setState(() {});
                          },
                          onFieldSubmitted: (_) {
                            _emailFocusNode.requestFocus();
                          },
                        ),

                        const SizedBox(height: 24),

                        const Text(
                          '이메일',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _emailController,
                          focusNode: _emailFocusNode,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          decoration: const InputDecoration(
                            hintText: '이메일 주소를 입력해주세요',
                            border: OutlineInputBorder(),
                          ),
                          validator: _validateEmail,
                          onChanged: (_) {
                            setState(() {});
                          },
                          onFieldSubmitted: (_) {
                            _passwordFocusNode.requestFocus();
                          },
                        ),

                        const SizedBox(height: 24),

                        const Text(
                          '비밀번호',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _passwordController,
                          focusNode: _passwordFocusNode,
                          obscureText: true,
                          textInputAction: TextInputAction.done,
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          decoration: const InputDecoration(
                            hintText: '비밀번호를 입력해주세요',
                            border: OutlineInputBorder(),
                          ),
                          validator: _validatePassword,
                          onChanged: (_) {
                            setState(() {});
                          },
                          onFieldSubmitted: (_) {
                            _passwordFocusNode.unfocus();
                          },
                        ),

                        const SizedBox(height: 40),

                        TermsAndSubmit(
                          agreedToTerms: _agreedToTerms,
                          canSubmit: _canSubmit,
                          onTermsChanged: (value) {
                            setState(() {
                              _agreedToTerms = value ?? false;
                            });
                          },
                          onSubmit: _submit,
                        ),

                        const SizedBox(height: 24),

                        const LoginGuide(),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class SignUpHeader extends StatelessWidget {
  const SignUpHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        Text(
          '환영합니다!',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),
        SizedBox(height: 8),
        Text(
          '간단한 정보만 입력하고 시작해보세요.',
          style: TextStyle(fontSize: 16, color: AppColors.gray),
        ),
      ],
    );
  }
}

class TermsAndSubmit extends StatelessWidget {
  const TermsAndSubmit({
    super.key,
    required this.agreedToTerms,
    required this.canSubmit,
    required this.onTermsChanged,
    required this.onSubmit,
  });

  final bool agreedToTerms;
  final bool canSubmit;
  final ValueChanged<bool?> onTermsChanged;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Checkbox(value: agreedToTerms, onChanged: onTermsChanged),
            const Text('필수 약관에 동의합니다'),
          ],
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: canSubmit ? onSubmit : null,
          child: const Text('가입하기'),
        ),
      ],
    );
  }
}

class LoginGuide extends StatelessWidget {
  const LoginGuide({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('이미 계정이 있나요?'),
        TextButton(
          onPressed: () {},
          child: const Text('로그인', style: TextStyle(color: AppColors.violet)),
        ),
      ],
    );
  }
}
