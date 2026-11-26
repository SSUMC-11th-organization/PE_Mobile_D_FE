import 'dart:async';

import 'package:dio/dio.dart';
import 'package:movielog/core/storage/token_storage.dart';
import 'package:movielog/data/models/login_models.dart';
import 'package:movielog/data/models/member_info.dart';
import 'package:movielog/data/services/auth_api_service.dart';
import 'package:movielog/data/services/member_api_service.dart';
import 'package:movielog/services/saved_email_preference.dart';
import 'package:movielog/view_models/auth_view_model.dart';

/// 메모리에만 토큰을 두는 테스트용 저장소.
class FakeTokenStorage implements TokenStorage {
  FakeTokenStorage({this.token});

  String? token;
  Object? readError;
  Object? writeError;
  int deleteCount = 0;

  @override
  Future<String?> readAccessToken() async {
    if (readError != null) throw readError!;
    return token;
  }

  @override
  Future<void> saveAccessToken(String token) async {
    if (writeError != null) throw writeError!;
    this.token = token;
  }

  @override
  Future<void> deleteAccessToken() async {
    deleteCount++;
    token = null;
  }
}

class FakeAuthApiService extends AuthApiService {
  FakeAuthApiService() : super(Dio());

  Object? error;
  String accessToken = 'test-token';
  Completer<void>? gate;
  final requests = <LoginRequest>[];

  @override
  Future<LoginResult> login(LoginRequest request) async {
    requests.add(request);
    await gate?.future;
    if (error != null) throw error!;
    return LoginResult(nickname: '무비러버', accessToken: accessToken);
  }
}

class FakeMemberApiService extends MemberApiService {
  FakeMemberApiService() : super(Dio());

  Object? error;
  Completer<void>? gate;
  int fetchCount = 0;
  MemberInfo member = testMember;

  @override
  Future<MemberInfo> fetchMe() async {
    fetchCount++;
    await gate?.future;
    if (error != null) throw error!;
    return member;
  }
}

final testMember = MemberInfo(
  email: 'movie@example.com',
  nickname: '무비러버',
  createdAt: DateTime.utc(2026, 10, 10),
);

/// 서버 공통 오류 형식의 DioException.
DioException apiError(int statusCode, String code, {String path = '/v8'}) {
  final options = RequestOptions(path: path);
  return DioException.badResponse(
    statusCode: statusCode,
    requestOptions: options,
    response: Response(
      requestOptions: options,
      statusCode: statusCode,
      data: {
        'isSuccess': false,
        'code': code,
        'message': '$code 메시지',
        'result': null,
      },
    ),
  );
}

/// 이미 로그인(signedIn)과 내 정보 확인이 끝난 AuthViewModel.
AuthViewModel signedInAuth({
  FakeTokenStorage? storage,
  FakeMemberApiService? memberApi,
}) {
  return AuthViewModel(
      FakeAuthApiService(),
      memberApi ?? FakeMemberApiService(),
      storage ?? FakeTokenStorage(token: 'test-token'),
    )
    ..status = AuthStatus.signedIn
    ..member = testMember
    ..memberStatus = MemberLoadStatus.success;
}

/// 메모리에만 이메일을 두는 '이메일 저장' 설정.
class FakeSavedEmailPreference implements SavedEmailPreference {
  FakeSavedEmailPreference({this.email});

  String? email;
  int clearCount = 0;

  @override
  Future<String?> readEmail() async => email;

  @override
  Future<void> saveEmail(String email) async => this.email = email.trim();

  @override
  Future<void> clear() async {
    clearCount++;
    email = null;
  }
}
