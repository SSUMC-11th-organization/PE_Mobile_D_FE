import 'package:flutter/material.dart';

/// 영화 목록 상단의 장르 선택 Chip 목록. 가로로 스크롤되며 하나만 선택된다.
/// 첫 번째 Chip은 allLabel("전체")이다.
class GenreChipBar extends StatelessWidget {
  const GenreChipBar({
    super.key,
    required this.genres,
    required this.allLabel,
    required this.selectedGenre,
    required this.onSelected,
  });

  final List<String> genres;
  final String allLabel;
  final String selectedGenre;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final options = [allLabel, ...genres];

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: options.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final genre = options[index];
          return _GenreChip(
            label: genre,
            selected: genre == selectedGenre,
            onTap: () => onSelected(genre),
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
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
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
