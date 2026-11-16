import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../view_models/auth_view_model.dart';
import '../widgets/common/movie_log_app_bar.dart';
import '../widgets/common/movie_log_button.dart';
import '../widgets/common/movie_log_text_form_field.dart';

/// 로그인 화면. AuthViewModel.login()만 호출하고 직접 /home으로 이동하지 않는다.
/// 성공해서 status가 signedIn이 되면 Router의 redirect가 홈으로 보낸다.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordFocusNode = FocusNode();
  late final TapGestureRecognizer _signUpRecognizer;

  @override
  void initState() {
    super.initState();
    _signUpRecognizer = TapGestureRecognizer()..onTap = _goToSignUp;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _passwordFocusNode.dispose();
    _signUpRecognizer.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) =>
      (value?.trim().isEmpty ?? true) ? '이메일을 입력해 주세요.' : null;

  String? _validatePassword(String? value) =>
      (value?.isEmpty ?? true) ? '비밀번호를 입력해 주세요.' : null;

  bool get _canInteract {
    final auth = context.read<AuthViewModel>();
    return auth.status != AuthStatus.authenticating &&
        !auth.storageCleanupInProgress;
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    // 비밀번호는 요청에만 쓰고 저장하거나 로그로 남기지 않는다
    context.read<AuthViewModel>().login(
      _emailController.text.trim(),
      _passwordController.text,
    );
  }

  void _goToSignUp() {
    if (!_canInteract) return;
    context.push('/sign-up');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = context.watch<AuthViewModel>();
    final loading = auth.status == AuthStatus.authenticating;
    final enabled = !loading && !auth.storageCleanupInProgress;

    return Scaffold(
      appBar: const MovieLogAppBar(title: '로그인', centerTitle: true),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 48, 24, 32),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: SvgPicture.asset(
                    'assets/logos/movielog_logo.svg',
                    width: 84,
                    height: 84,
                    semanticsLabel: 'MovieLog 로고',
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'MovieLog에 로그인',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                MovieLogTextFormField(
                  label: '이메일',
                  controller: _emailController,
                  enabled: enabled,
                  hintText: '이메일 주소를 입력해주세요',
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  validator: _validateEmail,
                  isConfirmed: false, // 로그인은 형식 통과 ✓ 표시를 하지 않는다
                  onChanged: (_) => auth.clearLoginError(),
                  onFieldSubmitted: (_) => _passwordFocusNode.requestFocus(),
                ),
                const SizedBox(height: 16),
                MovieLogTextFormField(
                  label: '비밀번호',
                  controller: _passwordController,
                  focusNode: _passwordFocusNode,
                  enabled: enabled,
                  hintText: '비밀번호를 입력해주세요',
                  isPassword: true,
                  textInputAction: TextInputAction.done,
                  validator: _validatePassword,
                  isConfirmed: false,
                  // AUTH401_1(이메일·비밀번호 불일치)은 입력칸 오류로 표시한다
                  errorText: auth.loginFieldError,
                  onChanged: (_) => auth.clearLoginError(),
                  onFieldSubmitted: (_) {
                    if (enabled) _submit();
                  },
                ),
                // 네트워크·저장 실패 등 입력과 무관한 오류는 입력칸과 분리해 표시한다
                if (auth.message != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    auth.message!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                ],
                const SizedBox(height: 48),
                MovieLogButton(
                  label: '로그인',
                  width: double.infinity,
                  height: 56,
                  isLoading: loading,
                  onPressed: enabled ? _submit : null,
                ),
                const SizedBox(height: 24),
                Text.rich(
                  TextSpan(
                    text: '계정이 없나요?  ',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    children: [
                      TextSpan(
                        text: '회원가입',
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                        recognizer: _signUpRecognizer,
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
