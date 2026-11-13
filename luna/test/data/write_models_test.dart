import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/data/models/common_response.dart';
import 'package:movielog/data/models/create_member_request.dart';
import 'package:movielog/data/models/rating_request.dart';
import 'package:movielog/data/models/sign_up_models.dart';

void main() {
  test('회원가입 요청은 이메일·닉네임만 trim하고 비밀번호는 그대로 보낸다', () {
    const request = CreateMemberRequest(
      email: ' a@umc.com ',
      password: ' Pass1! ',
      nickname: ' 루나 ',
    );

    expect(request.toJson(), {
      'email': 'a@umc.com',
      'password': ' Pass1! ',
      'nickname': '루나',
    });
  });

  test('회원가입 공통 응답의 result에서 memberId를 읽는다', () {
    final response = CommonResponse<SignUpResult>.fromJson({
      'isSuccess': true,
      'code': 'COMMON201',
      'message': '성공',
      'result': {'memberId': 7, 'email': 'a@umc.com', 'nickname': '루나'},
    }, (value) => SignUpResult.fromJson(value as Map<String, dynamic>));

    expect(response.result?.memberId, 7);
  });

  test('공통 형식이 아닌 오류 body는 message를 null로 돌려준다', () {
    expect(
      readCommonErrorMessage({
        'isSuccess': false,
        'code': 'COMMON409',
        'message': '이미 사용 중인 이메일입니다.',
      }),
      '이미 사용 중인 이메일입니다.',
    );
    expect(readCommonErrorMessage({'error': 'Bad Gateway'}), isNull);
    expect(readCommonErrorMessage('<html></html>'), isNull);
  });

  test('평점 요청은 빈 코멘트를 생략하고 코멘트를 trim한다', () {
    expect(
      const CreateRatingRequest(movieId: 550, score: 4, comment: '  ').toJson(),
      {'movieId': 550, 'score': 4},
    );
    expect(
      const CreateRatingRequest(
        movieId: 550,
        score: 4,
        comment: ' 좋아요 ',
      ).toJson(),
      {'movieId': 550, 'score': 4, 'comment': '좋아요'},
    );
  });

  test('서버 평점은 1~5 정수만 통과한다', () {
    expect(validateServerScore(3), 3);
    expect(() => validateServerScore(0), throwsArgumentError);
    expect(() => validateServerScore(3.5), throwsArgumentError);
    expect(() => validateServerScore(6), throwsArgumentError);
  });
}
