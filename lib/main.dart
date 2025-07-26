import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:first_app/workout_selection_screen.dart';

late List<CameraDescription> cameras;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    cameras = await availableCameras();
  } on CameraException catch (e) {
    debugPrint('카메라 초기화 오류: ${e.code}\n오류 메시지: ${e.description}');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '덤벨 운동 자세 보조 시스템',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        fontFamily: 'Inter',
      ),
      // WorkoutSelectionScreen에 cameras를 전달합니다.
      home: WorkoutSelectionScreen(cameras: cameras),
    );
  }
}
