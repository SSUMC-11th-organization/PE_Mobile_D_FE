/// 영화 목록의 정렬 방식. name을 shared_preferences에 저장한다.
enum MovieSortOrder {
  basic('기본순'),
  rating('평점순'),
  latest('최신순'),
  title('제목순');

  const MovieSortOrder(this.label);

  final String label; // 정렬 메뉴에 표시할 이름
}
