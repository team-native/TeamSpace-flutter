import 'package:flutter/material.dart';
import 'app/router.dart';
import 'core/network/api_client.dart';
import 'data/repositories/auth_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 토큰이 완전히 만료(갱신도 실패)되면 로그인 화면으로 보내면서
  // "로그인이 만료됐어요" 팝업을 띄워요 (LoginScreen의 isExpired = true)
  ApiClient.onUnauthorized =
      () => appRouter.go(AppRoutes.login, extra: true);

  // "로그인 유지"로 저장된 토큰이 있으면 로그인 화면을 건너뛰고 홈으로 가요.
  // 토큰이 오래돼서 만료됐더라도 홈에서 API를 부를 때 자동 갱신을 시도하고,
  // 그것도 실패하면 위의 onUnauthorized로 로그인 화면에 돌아가요.
  if (await AuthRepository.instance.hasSession()) {
    appRouter.go(AppRoutes.home);
  }

  runApp(const NativeTeamSpaceApp());
}

class NativeTeamSpaceApp extends StatelessWidget {
  const NativeTeamSpaceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'NativeTeamSpace',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Pretendard', // 프로젝트 기본 폰트
        scaffoldBackgroundColor: const Color(0xFFF6F7F9),
      ),
      routerConfig: appRouter,

      // 웹 실행 시 스마트폰(390px~430px) 중앙 비율 프레임으로 가두는 설정
      // 웹 실행 시 스마트폰(390px~430px) 중앙 비율 프레임으로 가두는 설정
      builder: (context, child) {
        return Container(
          color: const Color(0xFF18181B), // 웹 데스크톱 배경색 (다크 그레이)
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 430, // 아이폰 Pro/Pro Max 모바일 해상도 너비 제한
              ),
              child: ClipRect(
                // 💡 키보드가 켜져 있을 때 빈 곳을 탭하면 키보드가 내려가도록 전역 처리
                // (FocusScope.of(context) 대신 FocusManager.instance를 직접 써서
                //  BuildContext에 대한 InheritedWidget 구독을 만들지 않아요 —
                //  이게 다이얼로그를 닫는 탭과 겹칠 때 생기던 크래시의 원인이었어요)
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
                  child: child,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}