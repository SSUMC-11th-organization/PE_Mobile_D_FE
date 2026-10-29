// PR을 위한 주석 추가
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// [Mission 2] 1. Movie Class를 작성한다.
class Movie {
  const Movie({required this.id, required this.title});

  final int id;
  final String title;
}

class StartScreen extends StatelessWidget {
  const StartScreen({super.key});

  // [Mission 2] 4. nullable 닉네임을 안전한 기본값으로 변환한다.
  String getDisplayName(String? nickname) {
    return nickname?.trim().isNotEmpty == true ? nickname! : '무비러버';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 시안에 맞는 따뜻한 베이지색 배경 적용
      backgroundColor: const Color(0xFFFAF9F5),
      body: SafeArea(
        child: Padding(
          // 좌우 여백 24px 적용
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              const SizedBox(height: 40),
              // 상단 작은 텍스트
              const Text(
                'FLUTTER 0주차',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2.0,
                  color: Color(0xFF79747E),
                ),
              ),
              // Spacer를 사용해 화면 세로 중앙으로 내용물 밀어내기
              const Spacer(),
              // 보라색 아이콘
              const Icon(
                Icons.movie_outlined,
                size: 80,
                color: Color(0xFF6750A4),
              ),
              const SizedBox(height: 24),
              // 메인 타이틀
              const Text(
                '영화의 순간을\n기록하세요',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  height: 1.3,
                  color: Color(0xFF1C1B1F),
                ),
              ),
              const SizedBox(height: 16),
              // 서브 타이틀
              const Text(
                '보고 싶은 영화부터 나만의 평점까지\n한곳에서 관리해요',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  height: 1.5,
                  color: Color(0xFF79747E),
                ),
              ),
              const Spacer(),
              // 꽉 차는 너비의 시작하기 버튼
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    // [Mission 2] 2. 영화 3개를 List<Movie>에 넣는다.
                    final movies = <Movie>[
                      const Movie(id: 1, title: '스파이더맨'),
                      const Movie(id: 2, title: '코코'),
                      const Movie(id: 3, title: '오디세이'),
                    ];

                    // [Mission 2] 3. for 또는 map을 사용해 영화 제목을 출력한다.
                    debugPrint('--- 내 영화 목록 ---');
                    for (var movie in movies) {
                      debugPrint('영화 제목: ${movie.title}');
                    }

                    // [Mission 2] 4. nullable 변환 테스트 출력
                    String? myNickname;
                    debugPrint('환영합니다, ${getDisplayName(myNickname)}님!');

                    // go()로 이동하여 시작 화면이 Back Stack에 남지 않도록 한다.
                    context.go('/register');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6750A4), // 버튼 보라색
                    foregroundColor: Colors.white, // 글자 흰색
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0, // 그림자 제거
                  ),
                  child: const Text(
                    '시작하기',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
