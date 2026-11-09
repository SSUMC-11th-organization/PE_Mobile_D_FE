import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// child 위에 어두운 배경과 흰색 인디케이터를 올려 입력을 막는 오버레이.
class LoadingOverlay extends StatelessWidget {
  const LoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
  });

  final bool isLoading;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          const ModalBarrier(dismissible: false, color: Colors.black45),
        if (isLoading)
          const Center(
            child: CircularProgressIndicator(color: AppColors.neutral100),
          ),
      ],
    );
  }
}
