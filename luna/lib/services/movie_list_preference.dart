import 'package:shared_preferences/shared_preferences.dart';

import '../models/movie_sort_order.dart';

/// 영화 목록에서 마지막으로 선택한 장르와 정렬 방식을 기기에 저장한다.
/// shared_preferences는 보안 저장소가 아니므로 이런 단순한 설정값만 저장한다.
class MovieListPreference {
  MovieListPreference({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  // 읽기와 쓰기가 반드시 같은 Key를 쓰도록 한곳에 둔다
  // 여러 TMDB 장르 ID를 저장한다. 이전 버전의 값(장르 이름·단일 ID)과 섞이지 않도록 Key를 새로 둔다
  static const _selectedGenreKey = 'selected_genre_ids';
  static const _sortOrderKey = 'movie_sort_order';

  final SharedPreferencesAsync _preferences;

  /// 마지막으로 선택한 TMDB 장르 ID 목록. 저장된 값이 없으면 null("전체").
  /// shared_preferences는 int 목록을 저장하지 못하므로 문자열 목록으로 저장하고 읽을 때 되돌린다.
  Future<List<int>?> readGenreIds() async {
    final saved = await _preferences.getStringList(_selectedGenreKey);
    final ids = saved?.map(int.tryParse).nonNulls.toList();
    return (ids == null || ids.isEmpty) ? null : ids;
  }

  /// null 또는 빈 목록("전체")이면 저장된 값을 지운다.
  Future<void> saveGenreIds(List<int>? genreIds) async {
    if (genreIds == null || genreIds.isEmpty) {
      await _preferences.remove(_selectedGenreKey);
    } else {
      await _preferences.setStringList(
        _selectedGenreKey,
        genreIds.map((id) => '$id').toList(),
      );
    }
  }

  /// enum은 바로 저장할 수 없으므로 name(String)으로 저장하고 읽을 때 되돌린다.
  /// 저장된 값이 없거나 알 수 없는 값이면 기본순.
  Future<MovieSortOrder> readSortOrder() async {
    final name = await _preferences.getString(_sortOrderKey);
    return MovieSortOrder.values.asNameMap()[name] ?? MovieSortOrder.basic;
  }

  Future<void> saveSortOrder(MovieSortOrder order) async {
    await _preferences.setString(_sortOrderKey, order.name);
  }

  Future<void> clear() async {
    await _preferences.remove(_selectedGenreKey);
    await _preferences.remove(_sortOrderKey);
  }
}
