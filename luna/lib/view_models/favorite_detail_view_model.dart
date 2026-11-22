import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../core/network/api_error.dart';
import '../core/session/session_guard.dart';
import '../core/utils/safe_notify.dart';
import '../data/services/favorite_api_service.dart';

/// 영화 상세의 즐겨찾기(북마크) 상태.
/// isFavorite는 서버에서 확인한 값만 담는다. 결과를 기다리지 않고 먼저 바꾸는
/// optimistic update는 쓰지 않으므로, 실패하면 이전 아이콘 상태가 그대로 남는다.
class FavoriteDetailViewModel extends ChangeNotifier with SafeNotify {
  FavoriteDetailViewModel({
    required this.movieId,
    required this.favoriteApi,
    required this.sessionGuard,
    required this.accountId,
    this.onSessionExpired,
  });

  /// 상세 화면의 TMDB 영화 ID. 즐겨찾기 경로에는 favoriteId가 아니라 이 값을 쓴다
  final int movieId;
  final FavoriteApiService favoriteApi;
  final SessionGuard sessionGuard;

  /// 현재 세션의 계정(GET me의 email). 내 정보를 아직 받지 못했으면 null → 요청하지 않고 기다린다
  final String? accountId;

  /// 토큰 없음·무효·만료(AUTH401_2/3/4)일 때 현재 세션을 정리한다(8주차 expireSession).
  /// 이 ViewModel을 만든 세션 번호로 묶여 있어, 다른 세션은 로그아웃시키지 않는다
  final Future<void> Function()? onSessionExpired;

  /// 세션 만료로 정리를 요청했는지. 화면은 안내 없이 Router의 로그인 이동에 맡긴다
  bool sessionExpired = false;

  bool isFavorite = false;
  bool hasLoadedStatus = false; // 첫 여부 조회가 성공했는지. 실패하면 토글을 막는다
  bool isLoading = false; // 첫 여부 조회 중
  bool isSaving = false; // 등록·해제 중
  String? errorMessage;

  /// 내 정보가 준비되기 전이라 아직 여부를 조회할 수 없는 상태
  bool get isWaitingForSession => accountId == null;

  ({int generation, bool ok}) _snapshot() {
    final generation = sessionGuard.generation;
    final account = accountId;
    return (
      generation: generation,
      ok:
          account != null &&
          sessionGuard.isCurrent(generation, account) &&
          !isDisposed,
    );
  }

  // 요청 이후 화면이 사라졌거나 로그아웃·계정 전환이 일어났으면 결과를 버린다
  bool _isStale(int generation) {
    final account = accountId;
    return isDisposed ||
        account == null ||
        !sessionGuard.isCurrent(generation, account);
  }

  /// 상세 화면 초기화 때 한 번 호출한다. build()에서는 조회하지 않는다.
  Future<void> load() async {
    if (isLoading || isSaving) return;
    final snap = _snapshot();
    if (!snap.ok) return;
    isLoading = true;
    errorMessage = null;
    notifyIfAlive();
    try {
      final result = await favoriteApi.checkFavorite(movieId: movieId);
      if (_isStale(snap.generation)) return;
      isFavorite = result.isFavorite;
      hasLoadedStatus = true;
    } catch (error) {
      if (_isStale(snap.generation)) return;
      if (await _expireIfNeeded(error)) return;
      debugPrint('즐겨찾기 여부 조회 실패: ${error.runtimeType}');
      errorMessage = error is DioException && _isMemberMissing(error)
          ? _memberMissingMessage
          : '즐겨찾기 여부를 확인하지 못했습니다.';
    } finally {
      if (!_isStale(snap.generation)) {
        isLoading = false;
        notifyIfAlive();
      }
    }
  }

  /// 서버 성공을 확인한 뒤에 북마크 상태를 바꾼다. 요청 중에는 중복 탭을 막는다.
  /// timeout 등으로 실패해도 같은 POST를 자동으로 다시 보내지 않는다.
  /// 요청을 보내지 않았으면(중복 탭·세션 준비 전) false를 돌려준다.
  Future<bool> toggle() async {
    if (isSaving || isLoading || !hasLoadedStatus) return false;
    final snap = _snapshot();
    if (!snap.ok) return false;
    final before = isFavorite;
    isSaving = true;
    errorMessage = null;
    notifyIfAlive();
    try {
      if (before) {
        await favoriteApi.deleteFavorite(movieId: movieId);
      } else {
        await favoriteApi.addFavorite(movieId: movieId);
      }
      if (_isStale(snap.generation)) return true;
      isFavorite = !before;
    } on DioException catch (error) {
      if (_isStale(snap.generation)) return true;
      if (await _expireIfNeeded(error)) return true;
      final code = apiErrorCode(error);
      // 이미 등록(409)·이미 해제(404)면 POST/DELETE를 반복하지 않고 서버의 현재 여부로 맞춘다
      if (code == 'FAVORITE409_1' || code == 'FAVORITE404_1') {
        await _syncAfterConflict(snap.generation, before);
      } else {
        // 회원 없음(MEMBER404_1)은 즐겨찾기 없음(FAVORITE404_1)과 구분해 안내한다.
        // 403·네트워크 실패는 로그아웃하지 않고 이전 상태를 유지한다
        isFavorite = before;
        errorMessage = _isMemberMissing(error)
            ? _memberMissingMessage
            : _failureMessage(before);
      }
    } catch (error) {
      if (_isStale(snap.generation)) return true;
      debugPrint('즐겨찾기 변경 응답 처리 실패: ${error.runtimeType}');
      isFavorite = before;
      errorMessage = _failureMessage(before);
    } finally {
      if (!_isStale(snap.generation)) {
        isSaving = false;
        notifyIfAlive();
      }
    }
    return true;
  }

  Future<void> _syncAfterConflict(int generation, bool before) async {
    try {
      final synced = await favoriteApi.checkFavorite(movieId: movieId);
      if (_isStale(generation)) return;
      isFavorite = synced.isFavorite;
      errorMessage = null;
    } catch (_) {
      if (_isStale(generation)) return;
      isFavorite = before;
      errorMessage = '서버 상태를 다시 확인하지 못했습니다.';
    }
  }

  // AUTH401_2/3/4만 세션 만료다. 로그인 오류(AUTH401_1)·403·네트워크 실패는 로그아웃하지 않는다.
  // 이미 현재 세션이 아니면(_isStale) 호출 전에 걸러지므로 이전 계정의 늦은 401은 무시된다
  Future<bool> _expireIfNeeded(Object error) async {
    if (error is! DioException || !isSessionExpiredError(error)) return false;
    sessionExpired = true;
    await onSessionExpired?.call();
    return true;
  }

  static bool _isMemberMissing(DioException error) =>
      apiErrorCode(error) == 'MEMBER404_1';

  static const _memberMissingMessage = '회원 정보를 찾을 수 없어요. 다시 로그인해 주세요.';

  static String _failureMessage(bool wasFavorite) =>
      wasFavorite ? '즐겨찾기 해제에 실패했습니다.' : '즐겨찾기 등록에 실패했습니다.';
}
