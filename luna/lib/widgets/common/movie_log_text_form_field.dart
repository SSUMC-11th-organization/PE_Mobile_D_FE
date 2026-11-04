import 'package:flutter/material.dart';

import '../../theme/app_text_styles.dart';
import 'app_svg_icon.dart';

/// 라벨 + 입력창 + 상태 아이콘을 묶은 공통 입력 위젯.
/// 입력 스타일(배경, 테두리, 오류 색)은 AppTheme의 inputDecorationTheme을 따른다.
/// 서버 중복 확인처럼 validator 밖에서 정한 결과는 errorText·message·isConfirmed로 받는다.
class MovieLogTextFormField extends StatefulWidget {
  const MovieLogTextFormField({
    super.key,
    required this.label,
    required this.controller,
    required this.validator,
    this.hintText,
    this.focusNode,
    this.keyboardType,
    this.textInputAction,
    this.isPassword = false,
    this.onChanged,
    this.onFieldSubmitted,
    this.errorText,
    this.message,
    this.messageColor,
    this.isConfirmed,
    this.trailing,
  });

  final String label;
  final TextEditingController controller;
  final FormFieldValidator<String> validator;
  final String? hintText;
  final FocusNode? focusNode;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool isPassword; // true면 입력값을 가리고 표시·숨김 버튼을 보여줌
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onFieldSubmitted;
  // validator를 통과해도 이 값이 있으면 에러 상태로 표시 (예: 이미 사용 중인 닉네임)
  final String? errorText;
  // 에러가 없을 때 입력창 아래에 보여줄 안내 문구와 색 (예: 사용 가능, 확인 중)
  final String? message;
  final Color? messageColor;
  // null이면 validator만으로 ✓ 표시, 값이 있으면 true일 때만 ✓ 표시 (예: 중복 확인 통과)
  final bool? isConfirmed;
  // 입력창 오른쪽에 나란히 둘 Widget (예: 중복 확인 버튼). 입력창 바깥에 배치
  final Widget? trailing;

  @override
  State<MovieLogTextFormField> createState() => _MovieLogTextFormFieldState();
}

class _MovieLogTextFormFieldState extends State<MovieLogTextFormField> {
  // 비밀번호 가림 여부는 이 입력창 안에서만 쓰이므로 여기서 관리
  late bool _obscured = widget.isPassword;

  // 입력값이 있을 때만 오류(!) 또는 완료(✓) 아이콘 표시
  Widget? _buildStatusIcon(ColorScheme colorScheme) {
    final text = widget.controller.text;
    if (text.isEmpty) return null;

    if (widget.errorText != null || widget.validator(text) != null) {
      return AppSvgIcon('assets/icons/error.svg', color: colorScheme.error);
    }
    if (widget.isConfirmed == false) return null;
    return AppSvgIcon(
      'assets/icons/check_circle.svg',
      color: colorScheme.primary,
    );
  }

  Widget _buildVisibilityButton(ColorScheme colorScheme) {
    return IconButton(
      onPressed: () => setState(() => _obscured = !_obscured),
      tooltip: _obscured ? '비밀번호 표시' : '비밀번호 숨기기',
      icon: AppSvgIcon(
        _obscured
            ? 'assets/icons/visibility_off.svg'
            : 'assets/icons/visibility.svg',
        color: colorScheme.onSurfaceVariant,
      ),
    );
  }

  Widget? _buildSuffix(ColorScheme colorScheme) {
    final statusIcon = _buildStatusIcon(colorScheme);
    if (!widget.isPassword && statusIcon == null) return null;

    return Padding(
      padding: EdgeInsets.only(right: widget.isPassword ? 4 : 12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ?statusIcon, // null이면 목록에 넣지 않음
          if (widget.isPassword) _buildVisibilityButton(colorScheme),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          widget.label,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        _buildFieldRow(theme),
      ],
    );
  }

  Widget _buildFieldRow(ThemeData theme) {
    final field = TextFormField(
      controller: widget.controller,
      focusNode: widget.focusNode,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      obscureText: _obscured,
      decoration: InputDecoration(
        hintText: widget.hintText,
        suffixIcon: _buildSuffix(theme.colorScheme),
        // validator 에러가 있으면 그 문구가, 없으면 이 errorText가 표시된다
        errorText: widget.errorText,
        // 에러가 표시되는 동안에는 helperText가 자동으로 숨겨진다
        helperText: widget.message,
        helperStyle: AppTextStyles.labelSmall.copyWith(
          fontSize: 12,
          color: widget.messageColor,
        ),
      ),
      validator: widget.validator,
      onChanged: widget.onChanged,
      onFieldSubmitted: widget.onFieldSubmitted,
    );

    final trailing = widget.trailing;
    if (trailing == null) return field;

    // 버튼은 입력창과 별도 형제로 두고, 아래 안내 문구가 생겨도 입력창 높이에 맞춰 위쪽 정렬
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: field),
        const SizedBox(width: 8),
        trailing,
      ],
    );
  }
}
