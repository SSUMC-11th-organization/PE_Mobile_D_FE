import 'package:flutter/material.dart';

import '../../data/models/rating_request.dart';
import '../common/movie_log_button.dart';
import '../movie/movie_rating_input.dart';

/// onSubmit이 던지면 입력을 유지하지 않고 Dialog를 닫는다.
/// 다시 시도해도 같은 결과인 오류(이미 평점·이미 즐겨찾기·회원 없음)에 쓰며,
/// 안내는 Dialog를 연 화면이 Snackbar로 보여준다.
class RatingDialogClose implements Exception {
  const RatingDialogClose();
}

/// 별점과 코멘트를 입력받아 onSubmit으로 저장하는 커스텀 Dialog.
/// 저장에 성공하면 true, 취소하거나 RatingDialogClose로 닫히면 false를 돌려준다.
/// onSubmit이 그 밖의 오류로 실패하면 Dialog를 유지해 입력을 보존하고 다시 시도할 수 있게 한다.
class RatingDialog extends StatefulWidget {
  const RatingDialog({
    super.key,
    this.initialScore = 0,
    this.initialComment,
    this.showAddToFavorite = false,
    required this.onSubmit,
  });

  final int initialScore;
  final String? initialComment;

  /// "즐겨찾기에도 추가" 체크박스 표시 여부. 평점 수정에서도 같은 Dialog를 쓰므로 기본은 숨긴다.
  /// 상세 화면의 "평점 남기기"에서 아직 즐겨찾기하지 않은 영화일 때만 true
  final bool showAddToFavorite;

  /// 체크박스가 보이지 않으면 addToFavorites는 항상 false
  final Future<void> Function(int score, String? comment, bool addToFavorites)
  onSubmit;

  @override
  State<RatingDialog> createState() => _RatingDialogState();
}

class _RatingDialogState extends State<RatingDialog> {
  static const _maxCommentLength = 500;
  static const _pillRadius = 999.0;

  late int _score = widget.initialScore;
  // build에서 만들면 별점을 고를 때마다 입력 중인 코멘트가 사라진다
  late final _commentController = TextEditingController(
    text: widget.initialComment ?? '',
  );
  bool _isSubmitting = false;
  bool _addToFavorites = false;
  String? _errorText;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _onConfirm() async {
    final trimmed = _commentController.text.trim();
    if (trimmed.length > _maxCommentLength) {
      setState(() => _errorText = '코멘트는 500자 이하로 입력해 주세요.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorText = null;
    });

    try {
      await widget.onSubmit(
        _score,
        trimmed.isEmpty ? null : trimmed,
        widget.showAddToFavorite && _addToFavorites,
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } on RatingDialogClose {
      if (!mounted) return;
      Navigator.pop(context, false);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        // 호출부가 StateError에 담아 준 서버 문구가 있으면 그대로 보여준다
        _errorText = error is StateError
            ? error.message
            : '저장하지 못했습니다. 잠시 후 다시 시도해 주세요.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // 시스템 뒤로가기는 PopScope가, 바깥 탭은 showDialog의 barrierDismissible이 막는다
    return PopScope(
      canPop: !_isSubmitting,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '평점을 남겨주세요',
                style: theme.textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Center(
                child: MovieRatingInput(
                  rating: _score.toDouble(),
                  enabled: !_isSubmitting,
                  onChanged: (value) =>
                      setState(() => _score = validateServerScore(value)),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                '코멘트 (선택, 최대 500자)',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _commentController,
                enabled: !_isSubmitting,
                maxLines: 3,
                maxLength: _maxCommentLength,
                decoration: const InputDecoration(
                  hintText: '이 영화의 인상적인 장면은...',
                ),
              ),
              if (widget.showAddToFavorite)
                CheckboxListTile(
                  value: _addToFavorites,
                  onChanged: _isSubmitting
                      ? null
                      : (value) =>
                            setState(() => _addToFavorites = value ?? false),
                  title: const Text('즐겨찾기에도 추가'),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
              if (_errorText != null) ...[
                const SizedBox(height: 8),
                Text(
                  _errorText!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: MovieLogButton(
                      label: '취소',
                      width: double.infinity,
                      isSecondary: true,
                      borderRadius: _pillRadius,
                      onPressed: _isSubmitting
                          ? null
                          : () => Navigator.pop(context, false),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: MovieLogButton(
                      label: '확인',
                      width: double.infinity,
                      borderRadius: _pillRadius,
                      isLoading: _isSubmitting,
                      // 별점을 고르기 전에는 코멘트만으로 확인할 수 없다
                      onPressed: _score > 0 ? _onConfirm : null,
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
