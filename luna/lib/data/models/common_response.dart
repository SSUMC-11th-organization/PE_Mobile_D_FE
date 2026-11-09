/// v6 쓰기 API의 성공 응답과 공통 오류 응답을 감싸는 형식.
/// result는 API마다 담기는 값이 다르므로 제네릭으로 표현하고, 없으면 null이다.
class CommonResponse<T> {
  const CommonResponse({
    required this.isSuccess,
    required this.code,
    required this.message,
    this.result,
  });

  final bool isSuccess;
  final String code;
  final String message;
  final T? result;

  factory CommonResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Object? value) parseResult,
  ) {
    final rawResult = json['result'];
    return CommonResponse<T>(
      isSuccess: json['isSuccess'] as bool,
      code: json['code'] as String,
      message: json['message'] as String,
      result: rawResult == null ? null : parseResult(rawResult),
    );
  }
}

/// 오류 응답 body에서 서버 message를 읽는다.
/// 게이트웨이 오류처럼 공통 형식이 아니면 null을 돌려 호출부의 기본 문구를 쓰게 한다.
String? readCommonErrorMessage(Object? data) {
  if (data is! Map<String, dynamic>) return null;
  try {
    return CommonResponse<Object?>.fromJson(data, (value) => value).message;
  } on TypeError {
    return null;
  }
}
