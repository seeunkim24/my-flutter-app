import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'workout_selection_screen.dart'; // 이전에 만든 운동 선택 화면 파일

// 앱 시작 전, 사용 가능한 카메라를 찾습니다.
late List<CameraDescription> cameras;

Future<void> main() async {
  // 카메라 초기화 전에 Flutter 프레임워크가 준비되었는지 확인합니다.
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // 기기에서 사용 가능한 카메라 목록을 가져옵니다.
    cameras = await availableCameras();
  } on CameraException catch (e) {
    // 카메라 초기화 실패 시 오류 처리
    debugPrint('Error: $e.code\nError Message: $e.description');
  }

  // 카메라 목록을 workout_selection_screen으로 전달하며 앱을 시작합니다.
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dumbbell Tracker',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      // 시작 화면에 카메라 목록을 전달합니다.
      home: WorkoutSelectionScreen(cameras: cameras),
    );
  }
}

class ExerciseSelectionScreen extends StatelessWidget {
  const ExerciseSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('운동 종류 선택'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton(
            onPressed: () {
              // 여기에 '숄더 프레스' 운동을 시작하는 로직을 추가할 수 있습니다.
              // 예를 들어, 다음 화면으로 이동하는 코드를 넣을 수 있습니다.
              print('숄더 프레스 선택');
            },
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 60), // 버튼 크기
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12), // 모서리 둥글게
              ),
            ),
            child: const Text(
              '숄더 프레스',
              style: TextStyle(fontSize: 20),
            ),
          ),
        ),
      ),
    );
  }
}
