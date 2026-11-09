import 'package:flutter/material.dart';

import '../common/movie_log_button.dart';

/// 평점 삭제 확인 Dialog. 삭제까지 마치면 true, 취소하면 false를 돌려준다.
/// 삭제가 실패하면 Dialog를 유지하고 Snackbar로 안내해 다시 시도할 수 있게 한다.
class DeleteRatingDialog extends StatefulWidget {
  const DeleteRatingDialog({super.key, required this.onConfirm});

  final Future<void> Function() onConfirm;

  @override
  State<DeleteRatingDialog> createState() => _DeleteRatingDialogState();
}

class _DeleteRatingDialogState extends State<DeleteRatingDialog> {
  bool _isDeleting = false;

  Future<void> _onConfirm() async {
    setState(() => _isDeleting = true);
    try {
      await widget.onConfirm();
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _isDeleting = false);
      final message = error is StateError
          ? error.message
          : '삭제하지 못했습니다. 잠시 후 다시 시도해 주세요.';
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    // 시스템 뒤로가기는 PopScope가, 바깥 탭은 showDialog의 barrierDismissible이 막는다
    return PopScope(
      canPop: !_isDeleting,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '평점을 삭제할까요?',
                style: textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                '삭제한 평점은 복구할 수 없습니다.',
                style: textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: MovieLogButton(
                      label: '취소',
                      width: double.infinity,
                      isSecondary: true,
                      onPressed: _isDeleting
                          ? null
                          : () => Navigator.pop(context, false),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: MovieLogButton(
                      label: '삭제',
                      width: double.infinity,
                      isLoading: _isDeleting,
                      onPressed: _onConfirm,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
