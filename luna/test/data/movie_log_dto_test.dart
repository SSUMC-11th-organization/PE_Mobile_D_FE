import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/data/models/check_result.dart';
import 'package:movielog/data/models/rating_dto.dart';

void main() {
  test('CheckResult는 Wrapper 없는 body를 그대로 변환한다', () {
    expect(CheckResult.fromJson({'available': true}).available, isTrue);
    expect(CheckResult.fromJson({'available': false}).available, isFalse);
  });

  test('RatingDto는 평점 항목을 변환하고 comment null을 허용한다', () {
    final withComment = RatingDto.fromJson({
      'ratingId': 1,
      'movieId': 550,
      'score': 5,
      'comment': '최고의 영화!',
      'createdAt': '2026-11-03T19:00:09.148Z',
      'updatedAt': '2026-11-03T19:00:09.148Z',
    });
    final withoutComment = RatingDto.fromJson({
      'ratingId': 3,
      'movieId': 13,
      'score': 3,
      'comment': null,
      'createdAt': '2026-11-03T19:00:09.148Z',
      'updatedAt': '2026-11-03T19:00:09.148Z',
    });

    expect(withComment.movieId, 550);
    expect(withComment.score, 5);
    expect(withComment.comment, '최고의 영화!');
    expect(withComment.createdAt, DateTime.utc(2026, 11, 3, 19, 0, 9, 148));
    expect(withoutComment.comment, isNull);
  });
}
