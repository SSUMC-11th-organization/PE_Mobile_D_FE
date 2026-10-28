import 'package:flutter/material.dart';

class EditProfileButton extends StatelessWidget {
  const EditProfileButton({super.key});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {}, // 아직 기능 없음 (보이기만 함)
      child: const Text('프로필 수정'),
    );
  }
}
