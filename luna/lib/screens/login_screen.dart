import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../services/saved_email_preference.dart';
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
  late final AuthViewModel _auth;
  late final SavedEmailPreference _emailPreference;
  bool _rememberEmail = false;

  @override
  void initState() {
    super.initState();
    _signUpRecognizer = TapGestureRecognizer()..onTap = _goToSignUp;
    _auth = context.read<AuthViewModel>();
    _emailPreference = context.read<SavedEmailPreference>();
    _restoreSavedEmail();
    // 화면이 열려 있는 동안 만료되는 경우는 리스너로,
    // 이미 만료된 상태로 화면이 처음 열리는 경우는 첫 프레임 이후 한 번 확인한다
    _auth.addListener(_showSessionExpired);
    WidgetsBinding.instance.addPostFrameCallback((_) => _showSessionExpired());
  }

  /// 토큰 만료·무효로 쫓겨난 경우에만 안내한다.
  /// 직접 로그아웃이나 로그인 실패(AUTH401_1)는 sessionExpired를 켜지 않는다.
  void _showSessionExpired() {
    if (!mounted || !_auth.sessionExpired) return;
    _auth.consumeSessionExpired(); // 먼저 꺼서 같은 Snackbar가 반복되지 않게 한다
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('로그인이 만료됐어요. 다시 로그인해 주세요.')));
  }

  /// 저장해 둔 이메일이 있으면 입력칸을 채우고 '이메일 저장'을 켠 채로 시작한다.
  Future<void> _restoreSavedEmail() async {
    try {
      final email = await _emailPreference.readEmail();
      // 읽는 사이 사용자가 이미 입력을 시작했으면 덮어쓰지 않는다
      if (!mounted || email == null || _emailController.text.isNotEmpty) {
        return;
      }
      setState(() {
        _emailController.text = email;
        _rememberEmail = true;
      });
    } catch (error) {
      debugPrint('저장된 이메일 읽기 실패: ${error.runtimeType}');
    }
  }

  @override
  void dispose() {
    _auth.removeListener(_showSessionExpired);
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

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    final email = _emailController.text.trim();
    final rememberEmail = _rememberEmail;
    final preference = _emailPreference;
    final auth = _auth;

    // 비밀번호는 요청에만 쓰고 저장하거나 로그로 남기지 않는다
    await auth.login(email, _passwordController.text);
    // 성공하면 Router가 이 화면을 닫으므로 mounted와 관계없이 미리 꺼낸 값으로 처리한다
    if (auth.status != AuthStatus.signedIn) return;
    try {
      // 이메일만 저장한다. 체크를 해제하고 로그인하면 이전에 저장한 이메일도 지운다
      if (rememberEmail) {
        await preference.saveEmail(email);
      } else {
        await preference.clear();
      }
    } catch (error) {
      // 이메일 저장 실패는 편의 기능 실패일 뿐이므로 로그인 흐름을 막지 않는다
      debugPrint('이메일 저장 실패: ${error.runtimeType}');
    }
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
                const SizedBox(height: 16),
                // 이메일만 shared_preferences에 저장한다(비밀번호·토큰은 저장하지 않음)
                MergeSemantics(
                  child: InkWell(
                    onTap: enabled
                        ? () => setState(() => _rememberEmail = !_rememberEmail)
                        : null,
                    borderRadius: BorderRadius.circular(8),
                    child: Row(
                      children: [
                        Checkbox(
                          value: _rememberEmail,
                          onChanged: enabled
                              ? (value) =>
                                    setState(() => _rememberEmail = value!)
                              : null,
                        ),
                        Text(
                          '이메일 저장',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
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
