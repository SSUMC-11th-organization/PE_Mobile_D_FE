/// values를 convert로 바꾸되, 동시에 진행하는 요청을 concurrency개로 제한한다.
/// 결과는 입력과 같은 순서로 돌려준다. (Future.wait는 모든 요청을 한 번에 보낸다)
///
/// convert 하나가 실패하면 전체가 실패하므로, 카드별 실패는 호출부가 결과 값으로 바꿔 넘긴다.
Future<List<R>> mapBounded<T, R>(
  Iterable<T> values,
  int concurrency,
  Future<R> Function(T value) convert,
) async {
  final input = values.toList(growable: false);
  if (input.isEmpty) return <R>[];
  if (concurrency <= 0) {
    throw ArgumentError.value(concurrency, 'concurrency', 'must be positive');
  }
  final output = List<R?>.filled(input.length, null);
  var next = 0;

  // worker마다 다음 index를 하나씩 가져가 처리한다(Dart는 단일 스레드라 next++가 겹치지 않음)
  Future<void> worker() async {
    while (true) {
      final index = next++;
      if (index >= input.length) return;
      output[index] = await convert(input[index]);
    }
  }

  final workers = List.generate(
    concurrency.clamp(1, input.length),
    (_) => worker(),
  );
  await Future.wait(workers);
  return output.cast<R>();
}
