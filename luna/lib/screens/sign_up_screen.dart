import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../widgets/common/movie_log_app_bar.dart';
import '../widgets/common/movie_log_text_form_field.dart';
import '../widgets/sign_up/login_prompt.dart';
import '../widgets/sign_up/sign_up_submit_button.dart';
import '../widgets/sign_up/sign_up_welcome_text.dart';
import '../widgets/sign_up/terms_agreement_checkbox.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  // Form 전체의 상태(validate 등)에 접근하기 위한 key
  final _formKey = GlobalKey<FormState>();

  // 화면이 살아 있는 동안 유지해야 하므로 build가 아닌 State의 필드로 선언
  final _nicknameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();

  bool _agreedToTerms = false;

  // 이 너비 이상이면 넓은 화면으로 보고 Form 너비를 제한
  static const _wideLayoutBreakpoint = 700.0;
  static const _maxFormWidth = 560.0;
  static const _scrollPadding = EdgeInsets.fromLTRB(24, 24, 24, 32);

  static final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  @override
  void dispose() {
    // 더 이상 쓰지 않는 Controller와 FocusNode 정리
    _nicknameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
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
    if (!_emailPattern.hasMatch(email)) {
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

  // 모든 입력이 유효하고 약관에 동의했을 때만 버튼 활성화
  bool get _canSubmit =>
      _validateNickname(_nicknameController.text) == null &&
      _validateEmail(_emailController.text) == null &&
      _validatePassword(_passwordController.text) == null &&
      _agreedToTerms;

  void _submit() {
    // 버튼 활성화 조건과 별개로, 제출 시 Form 전체를 다시 검증
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;

    FocusScope.of(context).unfocus();
    // ScaffoldMessenger는 앱 전체에서 공유되므로 홈으로 이동한 뒤에도 Snackbar가 보임
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('회원가입이 완료되었습니다.')));
    // 회원가입 화면을 남기지 않고 홈으로 이동 (홈에서 뒤로가기 불가)
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 시작 화면으로 돌아가지 않도록 뒤로가기 버튼을 표시하지 않음
      appBar: const MovieLogAppBar(title: '회원가입', centerTitle: true),
      body: SafeArea(
        // 현재 사용 가능한 너비를 기준으로 Form 배치를 결정
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= _wideLayoutBreakpoint;
            // 휴대폰에서는 Form이 최소한 화면 높이만큼 차지하게 해서
            // 약관·버튼 영역을 화면 아래쪽에 붙임 (키보드가 열리면 스크롤)
            final minFormHeight = isWide
                ? 0.0
                : math.max(
                    0.0,
                    constraints.maxHeight - _scrollPadding.vertical,
                  );

            // 넓은 화면: 가운데 정렬 + 최대 너비 제한 / 휴대폰: 위쪽부터 전체 너비 사용
            return Align(
              alignment: isWide ? Alignment.center : Alignment.topCenter,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: isWide ? _maxFormWidth : double.infinity,
                ),
                // 입력 항목이 화면보다 길어지거나 키보드가 올라와도 스크롤로 접근 가능
                child: SingleChildScrollView(
                  padding: _scrollPadding,
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  child: _buildForm(minHeight: minFormHeight),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // 휴대폰과 넓은 화면 모두 같은 Form(같은 Controller·Validator·상태)을 사용
  Widget _buildForm({required double minHeight}) {
    return Form(
      key: _formKey,
      // 사용자가 입력을 시작한 뒤부터 입력할 때마다 검증
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: minHeight),
        // 남는 세로 공간을 입력 영역과 약관·버튼 영역 사이에 배치
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SignUpWelcomeText(),
                const SizedBox(height: 32),
                MovieLogTextFormField(
                  label: '닉네임',
                  controller: _nicknameController,
                  hintText: '닉네임을 입력해주세요',
                  textInputAction: TextInputAction.next,
                  validator: _validateNickname,
                  // 입력값에 따라 아이콘과 버튼 활성화도 다시 그리기 위해 setState
                  onChanged: (_) => setState(() {}),
                  onFieldSubmitted: (_) => _emailFocusNode.requestFocus(),
                ),
                const SizedBox(height: 16),
                MovieLogTextFormField(
                  label: '이메일',
                  controller: _emailController,
                  focusNode: _emailFocusNode,
                  hintText: '이메일 주소를 입력해주세요',
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  validator: _validateEmail,
                  onChanged: (_) => setState(() {}),
                  onFieldSubmitted: (_) => _passwordFocusNode.requestFocus(),
                ),
                const SizedBox(height: 16),
                MovieLogTextFormField(
                  label: '비밀번호',
                  controller: _passwordController,
                  focusNode: _passwordFocusNode,
                  hintText: '비밀번호를 입력해주세요',
                  isPassword: true,
                  // 마지막 입력창이므로 완료 버튼을 누르면 키보드가 닫힘
                  textInputAction: TextInputAction.done,
                  validator: _validatePassword,
                  onChanged: (_) => setState(() {}),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 화면이 좁아도 입력 영역과 최소 간격 유지
                const SizedBox(height: 48),
                TermsAgreementCheckbox(
                  value: _agreedToTerms,
                  onChanged: (value) => setState(() => _agreedToTerms = value),
                ),
                const SizedBox(height: 16),
                SignUpSubmitButton(onPressed: _canSubmit ? _submit : null),
                const SizedBox(height: 32),
                const LoginPrompt(),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
