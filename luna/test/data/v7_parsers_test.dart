import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/data/models/login_models.dart';
import 'package:movielog/data/models/member_info.dart';
import 'package:movielog/data/services/rating_api_service.dart';

void main() {
  test('로그인 result에서 nickname·accessToken을 읽고 memberId는 만들지 않는다', () {
    final result = LoginResult.fromJson({
      'nickname': '영화광',
      'accessToken': 'eyJhbGciOiJIUzI1NiJ9...',
    });

    expect(result.nickname, '영화광');
    expect(result.accessToken, 'eyJhbGciOiJIUzI1NiJ9...');
  });

  test('내 정보 공통 응답에서 email·nickname·createdAt을 읽는다', () {
    final member = parseMemberInfo({
      'isSuccess': true,
      'code': 'COMMON200',
      'message': '회원 정보를 조회했습니다.',
      'result': {
        'email': 'movie@umc.com',
        'nickname': '영화광',
        'createdAt': '2026-09-06T12:14:03.000Z',
      },
    });

    expect(member.email, 'movie@umc.com');
    expect(member.createdAt, DateTime.utc(2026, 9, 6, 12, 14, 3));
  });

  test('평점 등록·수정 result는 Rating 객체다', () {
    final rating = parseRatingResult({
      'isSuccess': true,
      'code': 'COMMON201',
      'message': '평점을 등록했습니다.',
      'result': {
        'ratingId': 12,
        'movieId': 550,
        'score': 5,
        'comment': null,
        'createdAt': '2026-09-06T12:14:03.000Z',
        'updatedAt': '2026-09-07T12:14:03.000Z',
      },
    });

    expect(rating.ratingId, 12);
    expect(rating.comment, isNull);
    expect(rating.updatedAt, DateTime.utc(2026, 9, 7, 12, 14, 3));
  });

  test('result가 없거나 형식이 다르면 성공으로 처리하지 않는다', () {
    expect(
      () => parseRatingResult({
        'isSuccess': true,
        'code': 'COMMON200',
        'message': '',
        'result': null,
      }),
      throwsStateError,
    );
    expect(() => parseMemberInfo('<html>'), throwsStateError);
    expect(() => parseRatingList({'result': []}), throwsStateError);
  });
}
