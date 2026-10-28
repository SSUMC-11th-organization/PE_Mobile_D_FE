import 'package:flutter/material.dart';

import '../../models/profile_stat.dart';
import 'stat_item.dart';

class ProfileStats extends StatelessWidget {
  const ProfileStats({super.key, required this.stats});

  final List<ProfileStat> stats;

  @override
  Widget build(BuildContext context) {
    return Row(
      spacing: 8, // 카드 사이 가로 간격
      crossAxisAlignment: CrossAxisAlignment.start, // 교차축(세로) 위쪽 기준
      // map: 데이터(ProfileStat) 하나마다 Widget 하나를 만들어 List로 변환
      // Expanded: 남은 가로 공간을 카드들이 똑같이 나눠 가짐
      children: stats
          .map(
            (stat) => Expanded(
              child: StatItem(
                label: stat.label,
                value: stat.value,
                iconPath: stat.iconPath,
              ),
            ),
          )
          .toList(),
    );
  }
}
