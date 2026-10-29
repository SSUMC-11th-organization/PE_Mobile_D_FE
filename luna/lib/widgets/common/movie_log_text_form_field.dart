import 'package:flutter/material.dart';

import 'app_svg_icon.dart';

/// 라벨 + 입력창 + 상태 아이콘을 묶은 공통 입력 위젯.
/// 입력 스타일(배경, 테두리, 오류 색)은 AppTheme의 inputDecorationTheme을 따른다.
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

    return widget.validator(text) != null
        ? AppSvgIcon('assets/icons/error.svg', color: colorScheme.error)
        : AppSvgIcon(
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
        TextFormField(
          controller: widget.controller,
          focusNode: widget.focusNode,
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          obscureText: _obscured,
          decoration: InputDecoration(
            hintText: widget.hintText,
            suffixIcon: _buildSuffix(theme.colorScheme),
          ),
          validator: widget.validator,
          onChanged: widget.onChanged,
          onFieldSubmitted: widget.onFieldSubmitted,
        ),
      ],
    );
  }
}
