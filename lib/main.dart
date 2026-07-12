import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:muntum/gates/auth_gate.dart';

Future<void> main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  await dotenv.load(fileName: ".env");
  final clientId = dotenv.env['NAVER_MAP_CLIENT_ID'] ?? '';

  await FlutterNaverMap().init(
    clientId: clientId,
    onAuthFailed: (ex) {
      switch (ex) {
        case NQuotaExceededException(:final message):
          print("사용량 초과 (message: $message)");
          break;
        case NUnauthorizedClientException() ||
            NClientUnspecifiedException() ||
            NAnotherAuthFailedException():
          print("인증 실패: $ex");
          break;
      }
    },
  );
  FlutterNativeSplash.remove();
  runApp(const MuntumApp());
}

class MuntumApp extends StatelessWidget {
  const MuntumApp({super.key});

  // This widget is the root of the application.
  @override
  Widget build(BuildContext context) {
    return ScreenUtilPlusInit(
      minTextAdapt: true,
      splitScreenMode: true,
      // 390x844 UI
      designSize: const Size(390, 844),
      builder: (context, child) => MaterialApp(
        title: 'Mumtum',
        home: child,
        debugShowCheckedModeBanner: false,
      ),
      child: const AuthGate(),
    );
  }
}
