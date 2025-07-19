// lib/workout_selection_screen.dart

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'shoulder_press_screen.dart'; // 새로 만든 파일을 import 합니다.

class WorkoutSelectionScreen extends StatelessWidget {
  // 사용 가능한 카메라 목록을 받습니다.
  final List<CameraDescription> cameras;

  const WorkoutSelectionScreen({super.key, required this.cameras});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('운동 선택')),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            // 카메라가 준비되었는지 확인
            if (cameras.isNotEmpty) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => ShoulderPressScreen(camera: cameras.first),
                ),
              );
            } else {
              // 카메라를 찾을 수 없을 때 오류 메시지
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('카메라를 찾을 수 없습니다.')),
              );
            }
          },
          child: const Text('숄더 프레스'),
        ),
      ),
    );
  }
}