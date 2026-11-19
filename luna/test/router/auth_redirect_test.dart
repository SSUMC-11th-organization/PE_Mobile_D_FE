import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/router/app_router.dart';
import 'package:movielog/view_models/auth_view_model.dart';

void main() {
  test('세션 확인 중·확인 실패에는 Splash(/start)에 머문다', () {
    for (final status in [AuthStatus.initializing, AuthStatus.retryRequired]) {
      expect(authRedirect(status, '/start'), isNull);
      expect(authRedirect(status, '/home'), '/start');
      expect(authRedirect(status, '/login'), '/start');
    }
  });

  test('로그아웃 상태에서는 로그인·회원가입만 허용하고 보호 화면은 /login으로 보낸다', () {
    for (final status in [AuthStatus.signedOut, AuthStatus.authenticating]) {
      expect(authRedirect(status, '/login'), isNull);
      expect(authRedirect(status, '/sign-up'), isNull);
      expect(authRedirect(status, '/home'), '/login');
      expect(authRedirect(status, '/my/ratings'), '/login');
      expect(authRedirect(status, '/start'), '/login');
    }
  });

  test('로그인 상태에서는 Splash·로그인·회원가입을 홈으로 보내고 보호 화면은 허용한다', () {
    expect(authRedirect(AuthStatus.signedIn, '/start'), '/home');
    expect(authRedirect(AuthStatus.signedIn, '/login'), '/home');
    expect(authRedirect(AuthStatus.signedIn, '/sign-up'), '/home');
    expect(authRedirect(AuthStatus.signedIn, '/movies/550'), isNull);
    expect(authRedirect(AuthStatus.signedIn, '/my'), isNull);
  });
}
