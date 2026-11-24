import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart' as kakao;
import 'package:muntum/constants/kakao_config.dart';
import 'package:muntum/models/auth_models.dart';
import 'package:muntum/services/kakao_auth_service.dart';

void main() {
  tearDown(dotenv.clean);

  test('missing client configuration fails before calling the SDK', () async {
    dotenv.clean();
    expect(KakaoConfig.isConfigured, isFalse);
    await expectLater(
      KakaoAuthService().authorize(),
      throwsA(
        isA<KakaoLoginException>().having(
          (error) => error.code,
          'code',
          'KAKAO_NOT_CONFIGURED',
        ),
      ),
    );
  });

  test(
    'reads the client key from the environment and rejects invalid values',
    () {
      dotenv.loadFromString(
        envString: 'KAKAO_NATIVE_APP_KEY=00000000000000000000000000000000',
      );
      expect(KakaoConfig.isConfigured, isTrue);
      expect(KakaoConfig.nativeAppKey, '00000000000000000000000000000000');
      dotenv.loadFromString(envString: 'KAKAO_NATIVE_APP_KEY=invalid');
      expect(KakaoConfig.isConfigured, isFalse);
    },
  );

  test(
    'prefers installed KakaoTalk and returns only its access token',
    () async {
      final client = _Client();
      final request = await KakaoAuthService(client: client).authorize();
      expect(client.calls, ['installed', 'talk']);
      expect(request.provider, SocialAuthProvider.kakao);
      expect(request.toJson(), {
        'provider': 'KAKAO',
        'token': 'talk-access-token',
      });
    },
  );

  test('uses account login when KakaoTalk is not installed', () async {
    final client = _Client()..installed = false;
    final request = await KakaoAuthService(client: client).authorize();
    expect(client.calls, ['installed', 'account']);
    expect(request.token, 'account-access-token');
  });

  test('falls back to account login when Talk cannot authorize', () async {
    final client = _Client()
      ..talkError = PlatformException(code: 'OPEN_URL_ERROR');
    final request = await KakaoAuthService(client: client).authorize();
    expect(client.calls, ['installed', 'talk', 'account']);
    expect(request.token, 'account-access-token');
  });

  final cancellations = <String, Exception>{
    'native cancel': PlatformException(code: 'CANCELED'),
    'client cancel': kakao.KakaoClientException(
      kakao.ClientErrorCause.cancelled,
      'cancelled',
    ),
    'consent declined': kakao.KakaoAuthException(
      kakao.AuthErrorCause.accessDenied,
      'declined',
    ),
  };
  for (final cancellation in cancellations.entries) {
    test('${cancellation.key} never opens account login after Talk', () async {
      final client = _Client()..talkError = cancellation.value;
      await expectLater(
        KakaoAuthService(client: client).authorize(),
        throwsA(isA<KakaoLoginCanceledException>()),
      );
      expect(client.calls, ['installed', 'talk']);
    });
  }

  test('account cancellation is also a quiet cancellation', () async {
    final client = _Client()
      ..installed = false
      ..accountError = PlatformException(code: 'CANCELED');
    await expectLater(
      KakaoAuthService(client: client).authorize(),
      throwsA(isA<KakaoLoginCanceledException>()),
    );
    expect(client.calls, ['installed', 'account']);
  });

  test('does not pass an empty SDK token to the backend', () async {
    final client = _Client()..talkToken = ' ';
    await expectLater(
      KakaoAuthService(client: client).authorize(),
      throwsA(
        isA<KakaoLoginException>().having(
          (error) => error.code,
          'code',
          'KAKAO_TOKEN_MISSING',
        ),
      ),
    );
  });

  test('does not expose raw SDK error bodies', () async {
    final client = _Client()
      ..installed = false
      ..accountError = PlatformException(
        code: 'NETWORK_ERROR',
        message: 'access_token=private-token',
      );
    await expectLater(
      KakaoAuthService(client: client).authorize(),
      throwsA(
        isA<KakaoLoginException>()
            .having((error) => error.code, 'code', 'NETWORK_ERROR')
            .having(
              (error) => error.message,
              'message',
              isNot(contains('private-token')),
            ),
      ),
    );
  });

  test('Android and iOS callbacks use local build settings', () {
    final manifest = File(
      'android/app/src/main/AndroidManifest.xml',
    ).readAsStringSync();
    final plist = File('ios/Runner/Info.plist').readAsStringSync();
    expect(manifest, contains(r'android:scheme="${kakaoLoginScheme}"'));
    expect(manifest, contains('android:host="oauth"'));
    expect(
      manifest,
      contains('com.kakao.sdk.flutter.auth.AuthCodeHandlerActivity'),
    );
    expect(plist, contains(r'<string>$(KAKAO_LOGIN_SCHEME)</string>'));
    expect(plist, contains('<string>kakaokompassauth</string>'));
    for (final name in ['Debug', 'Release']) {
      expect(
        File('ios/Flutter/$name.xcconfig').readAsStringSync(),
        contains('#include "Kakao.xcconfig"'),
      );
    }
  });

  test('iOS generator handles missing, quoted and invalid client keys', () async {
    final directory = await Directory.systemTemp.createTemp(
      'muntum-kakao-test-',
    );
    addTearDown(() => directory.delete(recursive: true));
    final script = File('tool/configure_kakao.rb').absolute.path;
    Future<ProcessResult> generate() => Process.run('ruby', [
      '-r',
      script,
      '-e',
      'configure_kakao(ARGV.fetch(0))',
      directory.path,
    ]);
    final output = File('${directory.path}/ios/Flutter/Kakao.local.xcconfig');
    expect((await generate()).exitCode, 0);
    expect(await output.readAsString(), contains('kakaounconfigured'));
    final environment = File('${directory.path}/.env');
    await environment.writeAsString(
      'KAKAO_NATIVE_APP_KEY="00000000000000000000000000000000"\nOTHER_SECRET=not-for-native\n',
    );
    expect((await generate()).exitCode, 0);
    expect(
      await output.readAsString(),
      contains('kakao00000000000000000000000000000000'),
    );
    expect(await output.readAsString(), isNot(contains('not-for-native')));
    await environment.writeAsString(
      'KAKAO_NATIVE_APP_KEY=invalid-private-value',
    );
    final result = await generate();
    expect(result.exitCode, isNot(0));
    expect(result.stderr.toString(), isNot(contains('invalid-private-value')));
  });
}

class _Client extends KakaoAuthClient {
  final calls = <String>[];
  bool installed = true;
  Exception? talkError;
  Exception? accountError;
  String talkToken = 'talk-access-token';

  @override
  Future<bool> isTalkInstalled() async {
    calls.add('installed');
    return installed;
  }

  @override
  Future<String> loginWithTalk() async {
    calls.add('talk');
    if (talkError != null) throw talkError!;
    return talkToken;
  }

  @override
  Future<String> loginWithAccount() async {
    calls.add('account');
    if (accountError != null) throw accountError!;
    return 'account-access-token';
  }
}
