import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../core/network/api_error.dart';
import '../core/session/session_guard.dart';
import '../core/utils/safe_notify.dart';
import '../data/services/favorite_api_service.dart';

class FavoriteDetailViewModel extends ChangeNotifier with SafeNotify {
  FavoriteDetailViewModel({
    required this.movieId,
    required this.favoriteApi,
    required this.sessionGuard,
    required this.accountId,
    required this.onSessionExpired,
  });

  final int movieId;
  final FavoriteApiService favoriteApi;
  final SessionGuard sessionGuard;
  final String accountId;
  final Future<void> Function() onSessionExpired;

  bool isFavorite = false;
  bool hasLoadedStatus = false;
  bool isLoading = false;
  bool isSaving = false;
  String? errorMessage;

  ({int generation, bool ok}) _snapshot() {
    final generation = sessionGuard.generation;

    return (
      generation: generation,
      ok: sessionGuard.isCurrent(generation, accountId) && !isDisposed,
    );
  }

  Future<void> load() async {
    if (isLoading || isSaving) return;

    final snap = _snapshot();
    if (!snap.ok) return;

    isLoading = true;
    errorMessage = null;
    notifyIfAlive();

    try {
      final result = await favoriteApi.checkFavorite(movieId: movieId);

      if (!sessionGuard.isCurrent(snap.generation, accountId) || isDisposed) {
        return;
      }

      isFavorite = result.isFavorite;
      hasLoadedStatus = true;
    } on DioException catch (error) {
      if (!sessionGuard.isCurrent(snap.generation, accountId) || isDisposed) {
        return;
      }

      final code = apiErrorCode(error);

      if (code == 'AUTH401_2' || code == 'AUTH401_3' || code == 'AUTH401_4') {
        await onSessionExpired();
        return;
      }

      errorMessage = '즐겨찾기 여부를 확인하지 못했습니다.';
    } catch (_) {
      if (!sessionGuard.isCurrent(snap.generation, accountId) || isDisposed) {
        return;
      }

      errorMessage = '즐겨찾기 여부를 확인하지 못했습니다.';
    } finally {
      if (sessionGuard.isCurrent(snap.generation, accountId) && !isDisposed) {
        isLoading = false;
        notifyIfAlive();
      }
    }
  }

  Future<void> toggle() async {
    if (isSaving || isLoading || !hasLoadedStatus) return;

    final snap = _snapshot();
    if (!snap.ok) return;

    final before = isFavorite;

    isSaving = true;
    errorMessage = null;
    notifyIfAlive();

    try {
      if (before) {
        await favoriteApi.deleteFavorite(movieId: movieId);

        if (!sessionGuard.isCurrent(snap.generation, accountId) || isDisposed) {
          return;
        }

        isFavorite = false;
      } else {
        await favoriteApi.addFavorite(movieId: movieId);

        if (!sessionGuard.isCurrent(snap.generation, accountId) || isDisposed) {
          return;
        }

        isFavorite = true;
      }
    } on DioException catch (error) {
      if (!sessionGuard.isCurrent(snap.generation, accountId) || isDisposed) {
        return;
      }

      final code = apiErrorCode(error);

      if (code == 'AUTH401_2' || code == 'AUTH401_3' || code == 'AUTH401_4') {
        await onSessionExpired();
        return;
      }

      if (code == 'FAVORITE409_1' || code == 'FAVORITE404_1') {
        try {
          final synced = await favoriteApi.checkFavorite(movieId: movieId);

          if (!sessionGuard.isCurrent(snap.generation, accountId) ||
              isDisposed) {
            return;
          }

          isFavorite = synced.isFavorite;
          errorMessage = null;
        } catch (_) {
          if (!sessionGuard.isCurrent(snap.generation, accountId) ||
              isDisposed) {
            return;
          }

          isFavorite = before;
          errorMessage = '서버 상태를 다시 확인하지 못했습니다.';
        }
      } else {
        isFavorite = before;
        errorMessage = before ? '즐겨찾기 해제에 실패했습니다.' : '즐겨찾기 등록에 실패했습니다.';
      }
    } catch (_) {
      if (!sessionGuard.isCurrent(snap.generation, accountId) || isDisposed) {
        return;
      }

      isFavorite = before;
      errorMessage = before ? '즐겨찾기 해제에 실패했습니다.' : '즐겨찾기 등록에 실패했습니다.';
    } finally {
      if (sessionGuard.isCurrent(snap.generation, accountId) && !isDisposed) {
        isSaving = false;
        notifyIfAlive();
      }
    }
  }
}
