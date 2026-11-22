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
  });

  /// 상세 화면의 TMDB 영화 ID. 즐겨찾기 경로에는 favoriteId가 아니라 이 값을 쓴다
  final int movieId;
  final FavoriteApiService favoriteApi;
  final SessionGuard sessionGuard;

  /// 현재 세션의 계정(GET me의 email). 내 정보를 아직 받지 못했으면 null → 요청하지 않고 기다린다
  final String? accountId;

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
      debugPrint('즐겨찾기 여부 조회 실패: ${error.runtimeType}');
      errorMessage = '즐겨찾기 여부를 확인하지 못했습니다.';
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
      final code = apiErrorCode(error);
      // 이미 등록(409)·이미 해제(404)면 POST/DELETE를 반복하지 않고 서버의 현재 여부로 맞춘다
      if (code == 'FAVORITE409_1' || code == 'FAVORITE404_1') {
        await _syncAfterConflict(snap.generation, before);
      } else {
        isFavorite = before;
        errorMessage = _failureMessage(before);
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

  static String _failureMessage(bool wasFavorite) =>
      wasFavorite ? '즐겨찾기 해제에 실패했습니다.' : '즐겨찾기 등록에 실패했습니다.';
}
