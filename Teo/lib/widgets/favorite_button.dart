import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../view_models/favorite_detail_view_model.dart';

class FavoriteButton extends StatelessWidget {
  const FavoriteButton({super.key});

  Future<void> _toggle(BuildContext context, FavoriteDetailViewModel vm) async {
    await vm.toggle();

    if (!context.mounted) return;

    final message =
        vm.errorMessage ?? (vm.isFavorite ? '즐겨찾기에 추가했습니다.' : '즐겨찾기에서 삭제했습니다.');

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FavoriteDetailViewModel>(
      builder: (context, vm, _) {
        if (vm.isLoading || vm.isSaving) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: SizedBox.square(
              dimension: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        }

        if (!vm.hasLoadedStatus) {
          return IconButton(
            tooltip: '즐겨찾기 상태 다시 확인',
            onPressed: vm.load,
            icon: const Icon(Icons.refresh),
          );
        }

        return IconButton(
          tooltip: '즐겨찾기',
          onPressed: () => _toggle(context, vm),
          icon: Icon(vm.isFavorite ? Icons.bookmark : Icons.bookmark_border),
        );
      },
    );
  }
}
