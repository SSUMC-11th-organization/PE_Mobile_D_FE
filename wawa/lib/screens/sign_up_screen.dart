import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/models/create_member_request.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../view_models/learning_member_session.dart';
import '../view_models/sign_up_view_model.dart';
import '../widgets/movielog_button.dart';
import 'profile_screen.dart' show CommonAppBar;

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

  static final _emailRegExp = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  static final _passwordRegExp = RegExp(
    r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[!@#$%^&*]).{8,}$',
  );

  bool _canSubmit(SignUpViewModel viewModel) =>
      _nicknameController.text.trim().length >= 2 &&
      _nicknameController.text.trim().length <= 12 &&
      _emailRegExp.hasMatch(_emailController.text.trim()) &&
      _passwordRegExp.hasMatch(_passwordController.text) &&
      viewModel.nicknameCheckStatus == CheckStatus.available &&
      viewModel.emailCheckStatus == CheckStatus.available &&
      _agreedToTerms;

  String? _validateNickname(String? value) {
    final nickname = value?.trim() ?? '';
    if (nickname.isEmpty) return null;
    if (nickname.length < 2 || nickname.length > 12) {
      return '닉네임은 2~12자여야 합니다.';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return null;
    if (!_emailRegExp.hasMatch(email)) return '올바른 이메일 형식이 아닙니다.';
    return null;
  }

  String? _validatePassword(String? value) {
    final password = value ?? '';
    if (password.isEmpty) return null;
    if (!_passwordRegExp.hasMatch(password)) {
      return '비밀번호는 대문자/소문자/숫자/특수문자(!@#\$%^&*)를 포함한 8자 이상이어야 합니다.';
    }
    return null;
  }

  bool _isInvalid(String? Function(String?) validate, String text) {
    return text.trim().isNotEmpty && validate(text) != null;
  }

  Widget? _statusIcon(String? Function(String?) validate, String text) {
    if (text.trim().isEmpty) return null;
    final isValid = validate(text) == null;
    return Icon(
      isValid ? Icons.check_circle : Icons.error_outline,
      color: isValid ? AppColors.violet : Colors.red,
    );
  }

  static const _fieldBorderRadius = BorderRadius.all(Radius.circular(12));

  InputDecoration _fieldDecoration({
    required String hint,
    required Widget? suffixIcon,
    required bool isInvalid,
    String? errorText,
  }) {
    return InputDecoration(
      hintText: hint,
      errorText: errorText,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: isInvalid ? Colors.red.shade50 : Colors.grey.shade100,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      enabledBorder: const OutlineInputBorder(
        borderRadius: _fieldBorderRadius,
        borderSide: BorderSide(color: AppColors.gray, width: 1),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: _fieldBorderRadius,
        borderSide: BorderSide(color: AppColors.violet, width: 2),
      ),
      errorBorder: const OutlineInputBorder(
        borderRadius: _fieldBorderRadius,
        borderSide: BorderSide(color: Colors.red),
      ),
      focusedErrorBorder: const OutlineInputBorder(
        borderRadius: _fieldBorderRadius,
        borderSide: BorderSide(color: Colors.red, width: 2),
      ),
    );
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

  Future<void> _submit() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;
    FocusScope.of(context).unfocus();
    final viewModel = context.read<SignUpViewModel>();
    if (!_canSubmit(viewModel)) return;
    await viewModel.submit(
      CreateMemberRequest(
        email: _emailController.text,
        password: _passwordController.text,
        nickname: _nicknameController.text,
      ),
    );
    if (!mounted) return;
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBar(
        title: '회원가입',
        centerTitle: true,
        onBack: () => Navigator.of(context).maybePop(),
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => FocusScope.of(context).unfocus(),
        child: SafeArea(
          top: false,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final maxFormWidth = constraints.maxWidth >= 700
                  ? 560.0
                  : double.infinity;
              return Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxFormWidth),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                    child: Form(
                      key: _formKey,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const _SignUpHeader(),
                          const SizedBox(height: 32),
                          Expanded(
                            child: SingleChildScrollView(
                              keyboardDismissBehavior:
                                  ScrollViewKeyboardDismissBehavior.onDrag,
                              child: Consumer<SignUpViewModel>(
                                builder: (context, viewModel, child) => Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    const Text(
                                      '닉네임',
                                      style: AppTextStyles.bodyMedium,
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: TextFormField(
                                            controller: _nicknameController,
                                            decoration: _fieldDecoration(
                                              hint: '닉네임을 입력해주세요',
                                              suffixIcon: _statusIcon(
                                                _validateNickname,
                                                _nicknameController.text,
                                              ),
                                              isInvalid: _isInvalid(
                                                _validateNickname,
                                                _nicknameController.text,
                                              ),
                                              errorText:
                                                  viewModel.nicknameErrorText,
                                            ),
                                            textInputAction:
                                                TextInputAction.next,
                                            validator: _validateNickname,
                                            onChanged: (value) {
                                              viewModel.onNicknameChanged(
                                                value,
                                              );
                                              setState(() {});
                                            },
                                            onFieldSubmitted: (_) =>
                                                _emailFocusNode.requestFocus(),
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
                                    _CheckMessage(
                                      status: viewModel.nicknameCheckStatus,
                                      subject: '닉네임',
                                    ),
                                    const SizedBox(height: 16),
                                    const Text(
                                      '이메일',
                                      style: AppTextStyles.bodyMedium,
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: TextFormField(
                                            controller: _emailController,
                                            focusNode: _emailFocusNode,
                                            decoration: _fieldDecoration(
                                              hint: '이메일 주소를 입력해주세요',
                                              suffixIcon: _statusIcon(
                                                _validateEmail,
                                                _emailController.text,
                                              ),
                                              isInvalid: _isInvalid(
                                                _validateEmail,
                                                _emailController.text,
                                              ),
                                              errorText:
                                                  viewModel.emailErrorText,
                                            ),
                                            keyboardType:
                                                TextInputType.emailAddress,
                                            textInputAction:
                                                TextInputAction.next,
                                            validator: _validateEmail,
                                            onChanged: (value) {
                                              viewModel.onEmailChanged(value);
                                              setState(() {});
                                            },
                                            onFieldSubmitted: (_) =>
                                                _passwordFocusNode
                                                    .requestFocus(),
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
                                    _CheckMessage(
                                      status: viewModel.emailCheckStatus,
                                      subject: '이메일',
                                    ),
                                    const SizedBox(height: 16),
                                    const Text(
                                      '비밀번호',
                                      style: AppTextStyles.bodyMedium,
                                    ),
                                    const SizedBox(height: 8),
                                    TextFormField(
                                      controller: _passwordController,
                                      focusNode: _passwordFocusNode,
                                      decoration: _fieldDecoration(
                                        hint: '비밀번호를 입력해주세요',
                                        suffixIcon: _statusIcon(
                                          _validatePassword,
                                          _passwordController.text,
                                        ),
                                        isInvalid: _isInvalid(
                                          _validatePassword,
                                          _passwordController.text,
                                        ),
                                        errorText: viewModel.passwordErrorText,
                                      ),
                                      obscureText: true,
                                      textInputAction: TextInputAction.done,
                                      validator: _validatePassword,
                                      onChanged: (_) {
                                        viewModel.onPasswordChanged();
                                        setState(() {});
                                      },
                                      onFieldSubmitted: (_) => _submit(),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          _TermsAgreement(
                            value: _agreedToTerms,
                            onChanged: (value) =>
                                setState(() => _agreedToTerms = value),
                          ),
                          const SizedBox(height: 24),
                          Consumer<SignUpViewModel>(
                            builder: (context, viewModel, child) =>
                                MovieLogButton(
                                  label: '가입하기',
                                  width: double.infinity,
                                  isLoading:
                                      viewModel.submitStatus ==
                                      SubmitStatus.submitting,
                                  onPressed: _canSubmit(viewModel)
                                      ? _submit
                                      : null,
                                ),
                          ),
                          const SizedBox(height: 16),
                          const _LoginPrompt(),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _SignUpHeader extends StatelessWidget {
  const _SignUpHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          '환영합니다!',
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyMedium,
        ),
        const SizedBox(height: 4),
        const Text(
          '간단한 정보만 입력하고 시작해보세요.',
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyMedium,
        ),
      ],
    );
  }
}

class _LoginPrompt extends StatelessWidget {
  const _LoginPrompt();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('이미 계정이 있나요? ', style: AppTextStyles.bodyMedium),
        TextButton(
          onPressed: () {},
          style: TextButton.styleFrom(padding: EdgeInsets.zero),
          child: const Text(
            '로그인',
            style: TextStyle(
              color: AppColors.violet,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _TermsAgreement extends StatelessWidget {
  const _TermsAgreement({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Checkbox(
          value: value,
          onChanged: (checked) => onChanged(checked ?? false),
        ),
        const Text('필수 약관에 동의합니다', style: AppTextStyles.bodyMedium),
      ],
    );
  }
}

// 중복 확인 중 / 사용 가능 문구만 표시한다. 중복·오류는 errorText가 담당한다.
class _CheckMessage extends StatelessWidget {
  const _CheckMessage({required this.status, required this.subject});

  final CheckStatus status;
  final String subject;

  @override
  Widget build(BuildContext context) {
    final (String, Color)? message = switch (status) {
      CheckStatus.checking => ('$subject 사용 가능 여부를 확인 중입니다.', AppColors.info),
      CheckStatus.available => ('사용 가능한 $subject입니다.', AppColors.success),
      _ => null,
    };
    if (message == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 4, left: 4),
      child: Text(
        message.$1,
        style: AppTextStyles.bodySmall.copyWith(
          color: message.$2,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
