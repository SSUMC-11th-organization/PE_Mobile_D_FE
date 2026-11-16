import 'package:flutter/foundation.dart';

import '../data/models/rating_dto.dart';
import 'auth_view_model.dart';

/// 이번 로그인 세션에서 등록한 평점(등록·수정 응답의 Rating 객체)을 보관한다.
///
/// v7에는 토큰 기반 '내 평점 목록 GET'이 없고, 로그인·내 정보 응답에도 memberId가 없다.
/// 그래서 서버의 기존 평점 전체를 복원하지 않고, 현재 세션에서 만든 Rating만 수정·삭제한다.
/// 로그아웃·만료·재로그인으로 sessionVersion이 바뀌면 이전 세션의 평점을 비운다.
class SessionRatingStore extends ChangeNotifier {
  SessionRatingStore(this._auth) : _version = _auth.sessionVersion {
    _auth.addListener(_onAuthChanged);
  }

  final AuthViewModel _auth;
  int _version;

  // 최근에 등록한 평점이 앞에 오도록 유지한다
  final List<RatingDto> _ratings = [];

  List<RatingDto> get ratings => List.unmodifiable(_ratings);

  RatingDto? ratingForMovie(int movieId) {
    for (final rating in _ratings) {
      if (rating.movieId == movieId) return rating;
    }
    return null;
  }

  /// 등록 응답의 Rating을 추가한다. 요청 이후 세션이 바뀌었으면 무시한다.
  void add(RatingDto rating, {required int sessionVersion}) {
    if (!_isCurrent(sessionVersion)) return;
    _ratings
      ..removeWhere((item) => item.ratingId == rating.ratingId)
      ..insert(0, rating);
    notifyListeners();
  }

  /// 수정 응답의 Rating으로 기존 항목을 교체한다(PATCH는 전체 교체).
  void replace(RatingDto rating, {required int sessionVersion}) {
    if (!_isCurrent(sessionVersion)) return;
    final index = _ratings.indexWhere(
      (item) => item.ratingId == rating.ratingId,
    );
    if (index < 0) return;
    _ratings[index] = rating;
    notifyListeners();
  }

  /// 삭제 성공 또는 서버에 이미 없는 평점(RATING404_1)을 목록에서 뺀다.
  void remove(int ratingId, {required int sessionVersion}) {
    if (!_isCurrent(sessionVersion)) return;
    final before = _ratings.length;
    _ratings.removeWhere((item) => item.ratingId == ratingId);
    if (_ratings.length != before) notifyListeners();
  }

  bool _isCurrent(int sessionVersion) =>
      sessionVersion == _version && sessionVersion == _auth.sessionVersion;

  void _onAuthChanged() {
    if (_auth.sessionVersion == _version) return;
    _version = _auth.sessionVersion;
    if (_ratings.isEmpty) return;
    _ratings.clear(); // 이전 세션의 평점이 다음 회원에게 보이지 않게 한다
    notifyListeners();
  }

  @override
  void dispose() {
    _auth.removeListener(_onAuthChanged);
    super.dispose();
  }
}
