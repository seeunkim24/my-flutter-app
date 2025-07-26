// lib/shoulder_press_screen.dart

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:google_mlkit_commons/google_mlkit_commons.dart'; // 누락된 패키지 추가

// 포즈 감지에 사용할 변수들을 클래스 밖에서 선언
late PoseDetector _poseDetector;
bool _isProcessing = false;

class ShoulderPressScreen extends StatefulWidget {
  final CameraDescription camera;

  const ShoulderPressScreen({super.key, required this.camera});

  @override
  State<ShoulderPressScreen> createState() => _ShoulderPressScreenState();
}

class _ShoulderPressScreenState extends State<ShoulderPressScreen> {
  late CameraController _cameraController;
  List<Pose> _poses = [];

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    // 1. 카메라 컨트롤러 초기화
    _cameraController = CameraController(
      widget.camera,
      ResolutionPreset.medium,
      enableAudio: false,
    );
    await _cameraController.initialize();

    // 2. PoseDetector 초기화
    final options = PoseDetectorOptions(
      mode: PoseDetectionMode.stream,
      model: PoseDetectionModel.base, // 또는 .accurate
    );
    _poseDetector = PoseDetector(options: options);

    // 3. 이미지 스트림 시작 및 포즈 감지
    _cameraController.startImageStream((CameraImage image) {
      if (!_isProcessing) {
        _isProcessing = true;
        _detectPose(image).then((_) {
          _isProcessing = false;
        });
      }
    });

    if (mounted) setState(() {});
  }

  Future<void> _detectPose(CameraImage image) async {
    // 카메라 이미지의 회전 정보를 가져옵니다.
    // 기기 방향에 따라 적절한 회전 값을 설정해야 합니다.
    final InputImageRotation rotation = _cameraRotation(widget.camera.sensorOrientation);

    final inputImage = InputImage.fromBytes(
      bytes: image.planes[0].bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation, // 회전 정보 적용
        format: InputImageFormat.yuv420, // YUV420_888 형식으로 가정
        bytesPerRow: image.planes[0].bytesPerRow,
      ),
    );

    final poses = await _poseDetector.processImage(inputImage);
    if (mounted) {
      setState(() {
        _poses = poses;
      });
    }
  }

  // 카메라 센서 방향에 따른 InputImageRotation 변환 함수
  InputImageRotation _cameraRotation(int sensorOrientation) {
    switch (sensorOrientation) {
      case 0:
        return InputImageRotation.rotation0deg;
      case 90:
        return InputImageRotation.rotation90deg;
      case 180:
        return InputImageRotation.rotation180deg;
      case 270:
        return InputImageRotation.rotation270deg;
      default:
        return InputImageRotation.rotation0deg;
    }
  }

  @override
  void dispose() {
    _cameraController.dispose();
    _poseDetector.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_cameraController.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }
    return Scaffold(
      appBar: AppBar(title: const Text('숄더 프레스 모션캡처')),
      body: Stack(
        children: [
          // 카메라 미리보기 화면
          CameraPreview(_cameraController),
          // 포즈 랜드마크와 연결선을 그리는 커스텀 오버레이
          _poses.isNotEmpty
              ? CustomPaint(
            size: MediaQuery.of(context).size, // 화면 전체 크기에 맞춤
            painter: PoseLandmarkPainter(_poses.first),
          )
              : const SizedBox.shrink(),
        ],
      ),
    );
  }
}

// Mediapipe 결과를 화면에 그리는 커스텀 페인터
class PoseLandmarkPainter extends CustomPainter {
  final Pose pose;
  final Paint _pointPaint = Paint()
    ..color = Colors.green // 관절 점 색상
    ..strokeWidth = 5.0
    ..style = PaintingStyle.fill; // 점을 채워서 그림

  final Paint _linePaint = Paint()
    ..color = Colors.blue // 연결선 색상
    ..strokeWidth = 3.0
    ..style = PaintingStyle.stroke; // 선으로 그림

  PoseLandmarkPainter(this.pose);

  @override
  void paint(Canvas canvas, Size size) {
    // 랜드마크 그리기 (점)
    for (var landmark in pose.landmarks.values) {
      // 랜드마크 좌표는 0~1 사이의 비율이므로, 실제 화면 크기에 맞춰 변환
      final Offset position = Offset(landmark.x * size.width, landmark.y * size.height);
      canvas.drawCircle(position, 4.0, _pointPaint); // 점 크기 4.0
    }

    // 랜드마크 연결선 그리기 (골격)
    // 상반신 주요 관절 연결
    _drawLine(canvas, size, PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder); // 어깨
    _drawLine(canvas, size, PoseLandmarkType.leftShoulder, PoseLandmarkType.leftElbow);     // 왼팔 상단
    _drawLine(canvas, size, PoseLandmarkType.leftElbow, PoseLandmarkType.leftWrist);       // 왼팔 하단
    _drawLine(canvas, size, PoseLandmarkType.rightShoulder, PoseLandmarkType.rightElbow);   // 오른팔 상단
    _drawLine(canvas, size, PoseLandmarkType.rightElbow, PoseLandmarkType.rightWrist);     // 오른팔 하단

    _drawLine(canvas, size, PoseLandmarkType.leftShoulder, PoseLandmarkType.leftHip);       // 왼쪽 몸통
    _drawLine(canvas, size, PoseLandmarkType.rightShoulder, PoseLandmarkType.rightHip);     // 오른쪽 몸통
    _drawLine(canvas, size, PoseLandmarkType.leftHip, PoseLandmarkType.rightHip);         // 골반

    // 얼굴 부분 (선택 사항)
    _drawLine(canvas, size, PoseLandmarkType.nose, PoseLandmarkType.leftEyeInner);
    _drawLine(canvas, size, PoseLandmarkType.leftEyeInner, PoseLandmarkType.leftEye);
    _drawLine(canvas, size, PoseLandmarkType.leftEye, PoseLandmarkType.leftEyeOuter);
    _drawLine(canvas, size, PoseLandmarkType.leftEyeOuter, PoseLandmarkType.leftEar);
    _drawLine(canvas, size, PoseLandmarkType.nose, PoseLandmarkType.rightEyeInner);
    _drawLine(canvas, size, PoseLandmarkType.rightEyeInner, PoseLandmarkType.rightEye);
    _drawLine(canvas, size, PoseLandmarkType.rightEye, PoseLandmarkType.rightEyeOuter);
    _drawLine(canvas, size, PoseLandmarkType.rightEyeOuter, PoseLandmarkType.rightEar);
    _drawLine(canvas, size, PoseLandmarkType.leftMouth, PoseLandmarkType.rightMouth);
  }

  // 두 랜드마크를 연결하는 헬퍼 함수
  void _drawLine(Canvas canvas, Size size, PoseLandmarkType startType, PoseLandmarkType endType) {
    final start = pose.landmarks[startType];
    final end = pose.landmarks[endType];

    if (start != null && end != null) {
      final Offset startPoint = Offset(start.x * size.width, start.y * size.height);
      final Offset endPoint = Offset(end.x * size.width, end.y * size.height);
      canvas.drawLine(startPoint, endPoint, _linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant PoseLandmarkPainter oldDelegate) {
    // 이전 포즈와 현재 포즈가 다르면 다시 그립니다.
    return oldDelegate.pose != pose;
  }
}
