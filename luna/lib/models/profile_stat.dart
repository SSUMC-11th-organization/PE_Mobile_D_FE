/// 프로필 통계 카드 하나에 들어가는 데이터.
class ProfileStat {
  const ProfileStat({
    required this.label,
    required this.value,
    required this.iconPath,
  });

  final String label;
  final String value;
  final String iconPath; // assets/icons/ 아래의 단색 SVG
}
