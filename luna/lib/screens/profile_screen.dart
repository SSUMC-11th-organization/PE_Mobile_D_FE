import 'package:flutter/material.dart';

import '../models/profile_stat.dart';
import '../widgets/common/movie_log_app_bar.dart';
import '../widgets/profile/edit_profile_button.dart';
import '../widgets/profile/favorite_genres.dart';
import '../widgets/profile/profile_header.dart';
import '../widgets/profile/profile_stats.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  // 화면에 표시할 데이터. 항목을 추가하면 Widget도 자동으로 늘어남
  static const _stats = [
    ProfileStat(
      label: '본 영화',
      value: '342',
      iconPath: 'assets/icons/movie.svg',
    ),
    ProfileStat(label: '평점', value: '4.2', iconPath: 'assets/icons/star.svg'),
    ProfileStat(
      label: '즐겨찾기',
      value: '58',
      iconPath: 'assets/icons/bookmark.svg',
    ),
  ];
  static const _genres = ['드라마', 'SF', '애니메이션'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const MovieLogAppBar(title: '내 프로필'),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
          child: Column(
            // 자식들을 가로 전체 너비로 늘려서 각 위젯 안에서 가운데 정렬이 되도록 함
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: const [
              ProfileHeader(
                imagePath: 'assets/images/profile/profile_movielog.jpg',
                name: '무비러버',
                bio: '매주 주말엔 영화관으로 출근하는 프로 관람객. 좋은 영화를 보고 기록하는 것을 좋아합니다.',
              ),
              SizedBox(height: 24),
              Center(child: EditProfileButton()),
              SizedBox(height: 24),
              ProfileStats(stats: _stats),
              SizedBox(height: 24),
              FavoriteGenres(genres: _genres),
            ],
          ),
        ),
      ),
    );
  }
}
