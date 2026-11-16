import 'package:flutter/material.dart';

/// 마이페이지의 '프로필 수정' 버튼. 내 정보를 받기 전에는 onPressed가 null이라 비활성이다.
class EditProfileButton extends StatelessWidget {
  const EditProfileButton({super.key, required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(onPressed: onPressed, child: const Text('프로필 수정'));
  }
}
