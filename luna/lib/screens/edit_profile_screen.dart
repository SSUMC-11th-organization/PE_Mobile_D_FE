import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../theme/app_colors.dart';
import '../view_models/auth_view_model.dart';
import '../view_models/edit_profile_view_model.dart';
import '../widgets/common/movie_log_app_bar.dart';
import '../widgets/common/movie_log_button.dart';

/// 프로필 수정 화면. 이메일은 읽기 전용, 닉네임만 수정한다.
/// 성공하면 AuthViewModel.member가 이미 교체된 상태로 마이페이지에 돌아간다.
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  static const _maxNicknameLength = 12;

  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    final member = context.read<AuthViewModel>().member;
    _controller = TextEditingController(text: member?.nickname ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final viewModel = context.read<EditProfileViewModel>();
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);

    final success = await viewModel.save(_controller.text);
    if (!mounted) return;

    if (success) {
      messenger.showSnackBar(const SnackBar(content: Text('프로필을 수정했어요.')));
      // 마이페이지로 돌아가면 새 닉네임이 이미 반영되어 있다
      if (router.canPop()) {
        router.pop();
      } else {
        router.go('/my');
      }
    } else if (viewModel.message != null) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(viewModel.message!)));
    }
    // 세션 만료(401)는 false를 돌려주고, Router가 로그인 화면으로 보낸다
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final email = context.select<AuthViewModel, String?>(
      (auth) => auth.member?.email,
    );
    final labelStyle = theme.textTheme.bodyLarge?.copyWith(
      fontWeight: FontWeight.w600,
    );

    return Consumer<EditProfileViewModel>(
      builder: (context, viewModel, child) {
        final saving = viewModel.isSaving;
        // 저장 중에는 시스템 뒤로가기(PopScope)와 AppBar 뒤로가기를 함께 막는다
        return PopScope(
          canPop: !saving,
          child: Scaffold(
            appBar: MovieLogAppBar(
              title: '프로필 수정',
              showBackButton: true,
              backEnabled: !saving,
              centerTitle: true,
              fallbackLocation: '/my',
            ),
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 48, 24, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('이메일 (변경할 수 없습니다)', style: labelStyle),
                    const SizedBox(height: 8),
                    TextFormField(
                      initialValue: email,
                      enabled: false, // email은 읽기 전용
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      decoration: const InputDecoration(
                        fillColor: AppColors.secondary100,
                        disabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(8)),
                          borderSide: BorderSide(color: AppColors.secondary300),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text('닉네임', style: labelStyle),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _controller,
                      enabled: !saving,
                      maxLength: _maxNicknameLength,
                      textInputAction: TextInputAction.done,
                      onChanged: (_) => viewModel.onNicknameChanged(),
                      onSubmitted: (_) {
                        if (!saving) _submit();
                      },
                      decoration: InputDecoration(
                        hintText: '닉네임을 입력해주세요',
                        // 길이·중복 오류는 입력칸 아래에 표시하고 입력값은 유지한다
                        errorText: viewModel.nicknameError,
                      ),
                      buildCounter:
                          (
                            context, {
                            required currentLength,
                            required isFocused,
                            required maxLength,
                          }) => Text(
                            '$currentLength / $maxLength',
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontSize: 12,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                    ),
                    const Spacer(),
                    MovieLogButton(
                      label: '저장',
                      width: double.infinity,
                      height: 56,
                      isLoading: saving,
                      onPressed: saving ? null : _submit,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
