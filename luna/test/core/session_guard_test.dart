import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/core/session/auth_session_bridge.dart';
import 'package:movielog/core/session/session_guard.dart';
import 'package:movielog/core/utils/map_bounded.dart';

/// AuthViewModel 대신 version·email만 바꿔 알림을 보내는 신호.
class _AuthSignals extends ChangeNotifier {
  int version = 0;
  String? email;

  void emit({int? version, String? email, bool clearEmail = false}) {
    if (version != null) this.version = version;
    if (email != null) this.email = email;
    if (clearEmail) this.email = null;
    notifyListeners();
  }
}

void main() {
  group('SessionGuard', () {
    test('새 세션을 시작하면 이전 generation의 응답은 현재가 아니다', () {
      final guard = SessionGuard();
      final first = guard.startSession('a@example.com');
      expect(guard.isCurrent(first, 'a@example.com'), isTrue);

      final second = guard.startSession('a@example.com'); // 같은 계정 재로그인
      expect(guard.isCurrent(first, 'a@example.com'), isFalse);
      expect(guard.isCurrent(second, 'a@example.com'), isTrue);
      expect(guard.isCurrent(second, 'b@example.com'), isFalse);
    });

    test('invalidate하면 계정이 비고 어떤 응답도 현재가 아니다', () {
      final guard = SessionGuard();
      final generation = guard.startSession('a@example.com');
      guard.invalidate();

      expect(guard.accountId, isNull);
      expect(guard.isCurrent(generation, 'a@example.com'), isFalse);
    });
  });

  group('AuthSessionBridge', () {
    late _AuthSignals signals;
    late AuthSessionBridge bridge;

    setUp(() {
      signals = _AuthSignals();
      bridge = AuthSessionBridge(
        authSignals: signals,
        sessionVersion: () => signals.version,
        verifiedEmail: () => signals.email,
      );
    });

    tearDown(() => bridge.dispose());

    test('email이 처음 확인되면 그 계정으로 세션을 시작한다', () {
      expect(bridge.guard.accountId, isNull);

      signals.emit(version: 1, email: 'a@example.com');

      expect(bridge.guard.accountId, 'a@example.com');
    });

    test('닉네임 수정처럼 version·email이 같은 알림은 세션을 바꾸지 않는다', () {
      signals.emit(version: 1, email: 'a@example.com');
      final generation = bridge.guard.generation;

      signals.emit(); // 같은 값으로 다시 알림

      expect(bridge.guard.generation, generation);
    });

    test('같은 이메일로 다시 로그인해도 sessionVersion이 바뀌면 새 세션이다', () {
      signals.emit(version: 1, email: 'a@example.com');
      final before = bridge.guard.generation;

      signals.emit(version: 2);

      expect(bridge.guard.generation, greaterThan(before));
      expect(bridge.guard.isCurrent(before, 'a@example.com'), isFalse);
      expect(bridge.guard.accountId, 'a@example.com');
    });

    test('로그아웃(email 없음)이면 계정을 비우고, 다른 계정 로그인은 새 계정으로 시작한다', () {
      signals.emit(version: 1, email: 'a@example.com');
      signals.emit(version: 2, clearEmail: true);
      expect(bridge.guard.accountId, isNull);

      signals.emit(version: 3, email: 'b@example.com');
      expect(bridge.guard.accountId, 'b@example.com');
    });
  });

  group('mapBounded', () {
    test('입력 순서대로 결과를 돌려주고 동시 실행 수를 제한한다', () async {
      var inFlight = 0;
      var maxInFlight = 0;

      final result = await mapBounded<int, int>(
        List.generate(12, (i) => i),
        5,
        (value) async {
          inFlight++;
          if (inFlight > maxInFlight) maxInFlight = inFlight;
          // 뒤 항목이 먼저 끝나도 결과 순서는 입력 순서를 따른다
          await Future<void>.delayed(Duration(milliseconds: 12 - value));
          inFlight--;
          return value * 10;
        },
      );

      expect(result, List.generate(12, (i) => i * 10));
      expect(maxInFlight, 5);
    });

    test('빈 입력은 바로 빈 목록, 0 이하 동시 수는 오류다', () async {
      expect(await mapBounded<int, int>([], 5, (v) async => v), isEmpty);
      expect(
        () => mapBounded<int, int>([1], 0, (v) async => v),
        throwsArgumentError,
      );
    });
  });
}
