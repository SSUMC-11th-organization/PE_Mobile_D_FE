import 'package:flutter/material.dart';

import '../../data/models/tmdb_genre_dto.dart';

/// 영화 목록 상단의 장르 선택 Chip 목록. 가로로 스크롤되며 하나만 선택된다.
/// 첫 번째 Chip은 allLabel("전체")이고, 누르면 장르 ID 대신 null을 전달한다.
class GenreChipBar extends StatelessWidget {
  const GenreChipBar({
    super.key,
    required this.genres,
    required this.selectedGenreId,
    required this.onSelected,
    this.enabled = true,
    this.allLabel = '전체',
  });

  final List<TmdbGenreDto> genres; // Genre API로 받은 id/name
  final int? selectedGenreId; // null이면 "전체"
  final ValueChanged<int?> onSelected;
  final bool enabled; // false면 모든 Chip을 누를 수 없음 (요청 중)
  final String allLabel;

  @override
  Widget build(BuildContext context) {
    // "전체"는 id가 없으므로 null로 표현한다
    final options = <(int?, String)>[
      (null, allLabel),
      for (final genre in genres) (genre.id, genre.name),
    ];

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: options.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final (id, name) = options[index];
          return _GenreChip(
            label: name,
            selected: id == selectedGenreId,
            onTap: enabled ? () => onSelected(id) : null,
          );
        },
      ),
    );
  }
}

class _GenreChip extends StatelessWidget {
  const _GenreChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap; // null이면 비활성화

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ChoiceChip(
      label: Text(label),
      selected: selected,
      // onSelected가 null이면 ChoiceChip이 비활성화 모양으로 그려지고 눌리지 않는다
      onSelected: onTap == null ? null : (_) => onTap!(),
      showCheckmark: false,
      // 선택된 Chip만 진한 보라 배경 + 흰 글자
      selectedColor: colorScheme.primary,
      labelStyle: TextStyle(
        color: selected
            ? colorScheme.onPrimary
            : colorScheme.onPrimaryContainer,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}
