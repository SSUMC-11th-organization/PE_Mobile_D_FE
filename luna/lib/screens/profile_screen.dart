import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/models/member_info.dart';
import '../models/profile_stat.dart';
import '../view_models/auth_view_model.dart';
import '../widgets/common/movie_log_app_bar.dart';
import '../widgets/common/movie_log_button.dart';
import '../widgets/profile/edit_profile_button.dart';
import '../widgets/profile/favorite_genres.dart';
import '../widgets/profile/my_ratings_entry.dart';
import '../widgets/profile/profile_header.dart';
import '../widgets/profile/profile_stats.dart';

/// 마이페이지. MainScreen이 시작한 내 정보 로딩(memberStatus)과
/// AuthViewModel.member(GET me)를 구독한다.
/// 사진·통계·장르는 기존 디자인 예시 데이터이며 v7 GET me 응답에는 없다.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // read가 아니라 watch로 구독해야 로딩 완료·프로필 수정 후 다시 그려진다
    final auth = context.watch<AuthViewModel>();
    final member = auth.member;

    if (member != null) return _ProfileContent(member: member, auth: auth);

    // 내 정보를 받기 전에는 화면 전체를 로딩 또는 실패·재시도로 대체한다
    final failed = auth.memberStatus == MemberLoadStatus.error;
    return Scaffold(
      appBar: const MovieLogAppBar(title: '내 프로필', centerTitle: true),
      body: Center(
        child: failed
            ? Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '내 정보를 불러오지 못했어요.',
                      style: Theme.of(context).textTheme.bodyLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    MovieLogButton(
                      label: '다시 시도',
                      width: 200,
                      height: 56,
                      onPressed: () => auth.loadMember(force: true),
                    ),
                  ],
                ),
              )
            : const CircularProgressIndicator(semanticsLabel: '내 정보를 불러오는 중'),
      ),
    );
  }
}

class _ProfileContent extends StatelessWidget {
  const _ProfileContent({required this.member, required this.auth});

  final MemberInfo member;
  final AuthViewModel auth;

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
      appBar: MovieLogAppBar(
        title: '내 프로필',
        actions: [
          TextButton(
            // 토큰과 member를 지우면 상태가 signedOut이 되고 Router가 /login으로 보낸다
            onPressed: auth.storageCleanupInProgress ? null : auth.logout,
            child: const Text('로그아웃'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
          child: Column(
            // 자식들을 가로 전체 너비로 늘려서 각 위젯 안에서 가운데 정렬이 되도록 함
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ProfileHeader(
                imagePath: 'assets/images/profile/profile_movielog.jpg',
                name: member.nickname,
                email: member.email,
                joinedAt: member.createdAt,
              ),
              const SizedBox(height: 24),
              Center(
                child: EditProfileButton(
                  onPressed: () => context.push('/my/profile/edit'),
                ),
              ),
              const SizedBox(height: 24),
              const ProfileStats(stats: _stats),
              const SizedBox(height: 24),
              const MyRatingsEntry(),
              const SizedBox(height: 32),
              const FavoriteGenres(genres: _genres),
            ],
          ),
        ),
      ),
    );
  }
}
