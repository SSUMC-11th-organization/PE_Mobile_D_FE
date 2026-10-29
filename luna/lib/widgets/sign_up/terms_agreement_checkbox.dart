import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// 필수 약관 동의 Checkbox. 체크 상태는 부모(State)가 관리한다.
class TermsAgreementCheckbox extends StatelessWidget {
  const TermsAgreementCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      // 문구를 눌러도 체크 상태가 바뀌도록 Row 전체를 누를 수 있게 함
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(8),
      child: Row(
        children: [
          Checkbox(
            value: value,
            onChanged: (checked) => onChanged(checked ?? false),
            activeColor: AppColors.primary500,
            side: const BorderSide(color: AppColors.secondary300, width: 1.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          Text('필수 약관에 동의합니다', style: Theme.of(context).textTheme.bodyLarge),
        ],
      ),
    );
  }
}
