import 'package:flutter/material.dart';
import 'router.dart';
import 'theme.dart';

class NativeTeamSpaceApp extends StatelessWidget {
  const NativeTeamSpaceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'NativeTeamSpace', // 앱 타이틀 반영
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: appRouter,
    );
  }
}