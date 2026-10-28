import 'package:flutter/material.dart';

import '../../data/models/tmdb_genre_dto.dart';
import '../../theme/app_colors.dart';

/// 장르를 여러 개 고르는 BottomSheet 내용.
/// 체크하는 동안에는 이 Sheet 안의 선택 상태만 바뀌고,
/// 확인을 눌렀을 때만 선택한 장르 ID를 Navigator.pop으로 돌려준다.
/// 아무것도 고르지 않고 확인하면 빈 Set("전체")을 돌려준다.
class GenreFilterSheet extends StatefulWidget {
  const GenreFilterSheet({
    super.key,
    required this.genres,
    required this.initialSelected,
    required this.scrollController,
  });

  final List<TmdbGenreDto> genres; // Genre API로 받은 id/name
  final Set<int> initialSelected; // 현재 영화 목록에 적용된 장르 ID
  // DraggableScrollableSheet가 전달한 controller. 목록 스크롤과 Sheet 드래그를 연결
  final ScrollController scrollController;

  @override
  State<GenreFilterSheet> createState() => _GenreFilterSheetState();
}

class _GenreFilterSheetState extends State<GenreFilterSheet> {
  // 원본 Set을 바꾸지 않도록 복사해서 Sheet 내부 상태로 사용
  late final Set<int> _selected = {...widget.initialSelected};

  void _toggle(int genreId, bool? checked) {
    setState(() {
      if (checked ?? false) {
        _selected.add(genreId);
      } else {
        _selected.remove(genreId);
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
                value: _selected.contains(genre.id),
                onChanged: (checked) => _toggle(genre.id, checked),
                title: Text(genre.name, style: textTheme.bodyLarge),
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

/// 장르 필터 BottomSheet를 띄우고, 확인을 누르면 선택한 장르 ID를 돌려준다.
/// 확인 없이 닫으면 null → 기존 필터를 유지한다.
Future<Set<int>?> showGenreFilterSheet(
  BuildContext context, {
  required List<TmdbGenreDto> genres,
  required Set<int> initialSelected,
}) {
  return showModalBottomSheet<Set<int>>(
    context: context,
    // Sheet가 화면 절반 이상으로 커질 수 있도록 허용
    isScrollControlled: true,
    useSafeArea: true,
    builder: (sheetContext) {
      // 위아래로 드래그해 높이를 조절할 수 있는 Sheet
      return DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.55, // 처음엔 화면의 절반 정도
        minChildSize: 0.3,
        maxChildSize: 0.9, // 위로 드래그하면 거의 전체 화면
        builder: (context, scrollController) => GenreFilterSheet(
          genres: genres,
          initialSelected: initialSelected,
          scrollController: scrollController,
        ),
      );
    },
  );
}
