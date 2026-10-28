import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../common/app_svg_icon.dart';

class StatItem extends StatelessWidget {
  const StatItem({
    super.key,
    required this.label,
    required this.value,
    required this.iconPath,
  });

  final String label;
  final String value;
  final String iconPath;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        border: Border.all(color: colorScheme.primaryContainer),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppSvgIcon(iconPath, size: 14, color: colorScheme.primary),
              const SizedBox(width: 4),
              Text(label, style: textTheme.labelSmall),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: textTheme.headlineMedium?.copyWith(
              color: AppColors.primary600,
            ),
          ),
        ],
      ),
    );
  }
}
