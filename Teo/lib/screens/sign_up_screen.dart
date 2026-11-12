import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../view_models/sign_up_view_model.dart';
import '../widgets/common_app_bar.dart';
import '../widgets/movielog_button.dart';
import '../data/models/create_member_request.dart';
import '../view_models/learning_member_session.dart';

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

    if (nickname.length < 2 || nickname.length > 12) {
      return '닉네임은 2~12자여야 합니다.';
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

    final isValid = RegExp(
      r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[!@#$%^&*]).{8,}$',
    ).hasMatch(password);

    if (!isValid) {
      return '비밀번호는 대문자/소문자/숫자/특수문자를 포함한 8자 이상이어야 합니다.';
    }

    return null;
  }

  Future<void> _submit() async {
    final isValid = _formKey.currentState?.validate() ?? false;

    if (!isValid) {
      return;
    }

    final viewModel = context.read<SignUpViewModel>();

    if (viewModel.nicknameCheckStatus != CheckStatus.available ||
        viewModel.emailCheckStatus != CheckStatus.available) {
      return;
    }

    FocusScope.of(context).unfocus();

    await viewModel.submit(
      CreateMemberRequest(
        email: _emailController.text,
        password: _passwordController.text,
        nickname: _nicknameController.text,
      ),
    );

    if (!mounted) {
      return;
    }

    if (viewModel.submitStatus == SubmitStatus.success &&
        viewModel.createdMemberId != null) {
      context.read<LearningMemberSession>().setMemberId(
        viewModel.createdMemberId!,
      );

      context.go('/movies');
      return;
    }

    if (viewModel.snackbarMessage != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(viewModel.snackbarMessage!)));
    }
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
    final viewModel = context.watch<SignUpViewModel>();

    final canSubmit =
        _canSubmit &&
        viewModel.nicknameCheckStatus == CheckStatus.available &&
        viewModel.emailCheckStatus == CheckStatus.available &&
        viewModel.submitStatus != SubmitStatus.submitting;
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

                        Consumer<SignUpViewModel>(
                          builder: (context, viewModel, child) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        controller: _nicknameController,
                                        textInputAction: TextInputAction.next,
                                        autovalidateMode:
                                            AutovalidateMode.onUserInteraction,
                                        decoration: InputDecoration(
                                          hintText: '닉네임을 입력해주세요',
                                          border: const OutlineInputBorder(),
                                          errorText:
                                              viewModel.nicknameErrorText,
                                        ),
                                        validator: _validateNickname,
                                        onChanged: (value) {
                                          viewModel.onNicknameChanged(value);
                                          setState(() {});
                                        },
                                        onFieldSubmitted: (_) {
                                          _emailFocusNode.requestFocus();
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    MovieLogButton(
                                      label: '중복 확인',
                                      isLoading:
                                          viewModel.nicknameCheckStatus ==
                                          CheckStatus.checking,
                                      onPressed: viewModel.canCheckNickname
                                          ? () => viewModel.checkNickname(
                                              _nicknameController.text,
                                            )
                                          : null,
                                    ),
                                  ],
                                ),
                                if (viewModel.nicknameCheckStatus ==
                                    CheckStatus.available)
                                  const Text(
                                    '사용할 수 있는 닉네임입니다.',
                                    style: AppTextStyles.bodySmall,
                                  ),
                              ],
                            );
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

                        Consumer<SignUpViewModel>(
                          builder: (context, viewModel, child) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        controller: _emailController,
                                        focusNode: _emailFocusNode,
                                        keyboardType:
                                            TextInputType.emailAddress,
                                        textInputAction: TextInputAction.next,
                                        autovalidateMode:
                                            AutovalidateMode.onUserInteraction,
                                        decoration: InputDecoration(
                                          hintText: '이메일 주소를 입력해주세요',
                                          border: const OutlineInputBorder(),
                                          errorText: viewModel.emailErrorText,
                                        ),
                                        validator: _validateEmail,
                                        onChanged: (value) {
                                          viewModel.onEmailChanged(value);
                                          setState(() {});
                                        },
                                        onFieldSubmitted: (_) {
                                          _passwordFocusNode.requestFocus();
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    MovieLogButton(
                                      label: '중복 확인',
                                      isLoading:
                                          viewModel.emailCheckStatus ==
                                          CheckStatus.checking,
                                      onPressed: viewModel.canCheckEmail
                                          ? () => viewModel.checkEmail(
                                              _emailController.text,
                                            )
                                          : null,
                                    ),
                                  ],
                                ),
                                if (viewModel.emailCheckStatus ==
                                    CheckStatus.available)
                                  const Text(
                                    '사용할 수 있는 이메일입니다.',
                                    style: AppTextStyles.bodySmall,
                                  ),
                              ],
                            );
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
                          decoration: InputDecoration(
                            hintText: '비밀번호를 입력해주세요',
                            border: const OutlineInputBorder(),
                            errorText: viewModel.passwordErrorText,
                          ),
                          validator: _validatePassword,
                          onChanged: (_) {
                            viewModel.onPasswordChanged();
                            setState(() {});
                          },
                          onFieldSubmitted: (_) {
                            _passwordFocusNode.unfocus();
                          },
                        ),

                        const SizedBox(height: 40),

                        TermsAndSubmit(
                          agreedToTerms: _agreedToTerms,
                          canSubmit: canSubmit,
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

        MovieLogButton(
          label: '가입하기',
          width: double.infinity,
          onPressed: canSubmit ? onSubmit : null,
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
