import 'package:flutter/material.dart';
import 'app/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // TODO: SecureStorage, Dio 등 전역 서비스 초기화 위치

  runApp(const NativeTeamSpaceApp());
}