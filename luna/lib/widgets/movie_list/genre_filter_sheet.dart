import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// 장르를 여러 개 고르는 BottomSheet 내용.
/// 체크하는 동안에는 이 Sheet 안의 선택 상태만 바뀌고,
/// 확인을 눌렀을 때만 선택한 장르를 Navigator.pop으로 돌려준다.
class GenreFilterSheet extends StatefulWidget {
  const GenreFilterSheet({
    super.key,
    required this.genres,
    required this.initialSelected,
    required this.scrollController,
  });

  final List<String> genres;
  final Set<String> initialSelected; // 현재 영화 목록에 적용된 장르
  // DraggableScrollableSheet가 전달한 controller. 목록 스크롤과 Sheet 드래그를 연결
  final ScrollController scrollController;

  @override
  State<GenreFilterSheet> createState() => _GenreFilterSheetState();
}

class _GenreFilterSheetState extends State<GenreFilterSheet> {
  // 원본 Set을 바꾸지 않도록 복사해서 Sheet 내부 상태로 사용
  late final Set<String> _selected = {...widget.initialSelected};

  void _toggle(String genre, bool? checked) {
    setState(() {
      if (checked ?? false) {
        _selected.add(genre);
      } else {
        _selected.remove(genre);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 드래그 핸들
        Center(
          child: Container(
            margin: const EdgeInsets.only(top: 12, bottom: 20),
            width: 32,
            height: 4,
            decoration: BoxDecoration(
              color: colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('장르 필터', style: textTheme.headlineMedium),
              const SizedBox(height: 4),
              Text(
                '여러 장르를 선택할 수 있어요',
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // 남은 공간에서 장르 목록만 스크롤되고, 아래 확인 버튼은 고정
        Expanded(
          child: ListView.builder(
            controller: widget.scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            itemCount: widget.genres.length,
            itemBuilder: (context, index) {
              final genre = widget.genres[index];
              return CheckboxListTile(
                value: _selected.contains(genre),
                onChanged: (checked) => _toggle(genre, checked),
                title: Text(genre, style: textTheme.bodyLarge),
                // 체크박스를 글자 왼쪽에 표시
                controlAffinity: ListTileControlAffinity.leading,
              );
            },
          ),
        ),
        const Divider(height: 1),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context, _selected),
              // 앱 공통 ElevatedButton(테두리형) 대신 진한 보라 배경으로 표시
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary500,
                foregroundColor: AppColors.neutral100,
                side: BorderSide.none,
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('확인'),
            ),
          ),
        ),
      ],
    );
  }
}
