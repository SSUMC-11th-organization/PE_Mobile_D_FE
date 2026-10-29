import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
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

  bool get _canSubmit =>
      _nicknameController.text.trim().length >= 2 &&
      _emailRegExp.hasMatch(_emailController.text.trim()) &&
      _passwordController.text.length >= 8 &&
      _agreedToTerms;

  String? _validateNickname(String? value) {
    final nickname = value?.trim() ?? '';
    if (nickname.isEmpty) return null;
    if (nickname.length < 2) return '닉네임은 2자 이상이어야 합니다.';
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
    if (password.length < 8) return '비밀번호는 8자 이상이어야 합니다.';
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
  }) {
    return InputDecoration(
      hintText: hint,
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

  void _submit() {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;
    FocusScope.of(context).unfocus();
    // go()로 이동하여 회원가입 화면이 Back Stack에 남지 않도록 한다.
    context.go('/home');
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
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  const Text(
                                    '닉네임',
                                    style: AppTextStyles.bodyMedium,
                                  ),
                                  const SizedBox(height: 8),
                                  TextFormField(
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
                                    ),
                                    textInputAction: TextInputAction.next,
                                    validator: _validateNickname,
                                    onChanged: (_) => setState(() {}),
                                    onFieldSubmitted: (_) =>
                                        _emailFocusNode.requestFocus(),
                                  ),
                                  const SizedBox(height: 16),
                                  const Text(
                                    '이메일',
                                    style: AppTextStyles.bodyMedium,
                                  ),
                                  const SizedBox(height: 8),
                                  TextFormField(
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
                                    ),
                                    keyboardType: TextInputType.emailAddress,
                                    textInputAction: TextInputAction.next,
                                    validator: _validateEmail,
                                    onChanged: (_) => setState(() {}),
                                    onFieldSubmitted: (_) =>
                                        _passwordFocusNode.requestFocus(),
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
                                    ),
                                    obscureText: true,
                                    textInputAction: TextInputAction.done,
                                    validator: _validatePassword,
                                    onChanged: (_) => setState(() {}),
                                    onFieldSubmitted: (_) => _submit(),
                                  ),
                                ],
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
                          ElevatedButton(
                            onPressed: _canSubmit ? _submit : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.violet,
                              foregroundColor: AppColors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('가입하기'),
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
