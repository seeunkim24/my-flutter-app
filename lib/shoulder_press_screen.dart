import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:google_mlkit_commons/google_mlkit_commons.dart';
import 'package:first_app/models.dart';
import 'package:first_app/utils.dart';
import 'package:first_app/pose_painter.dart';
import 'package:first_app/workout_completion_screen.dart';
import 'package:collection/collection.dart';
import 'package:first_app/main.dart'; // <--- 이 줄을 추가하여 main.dart의 cameras 전역 변수에 접근

late PoseDetector _poseDetector;
bool _isProcessing = false;

class ShoulderPressScreen extends StatefulWidget {
  final CameraDescription camera;
  final Exercise exercise;
  final int targetReps;

  const ShoulderPressScreen({
    super.key,
    required this.camera,
    required this.exercise,
    required this.targetReps,
  });

  @override
  State<ShoulderPressScreen> createState() => _ShoulderPressScreenState();
}

class _ShoulderPressScreenState extends State<ShoulderPressScreen> {
  late CameraController _cameraController;
  List<Pose> _poses = [];
  String _feedbackMessage = "운동을 시작하세요!";
  int _completedReps = 0;
  RepetitionState _repState = RepetitionState.initial;
  List<FeedbackEntry> _feedbackLog = [];
  DateTime? _sessionStartTime;
  List<PostureRule> _violatedRules = [];
  double _lastElbowAngle = 0.0;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    _cameraController = CameraController(
      widget.camera,
      ResolutionPreset.medium,
      enableAudio: false,
    );
    await _cameraController.initialize();
    debugPrint('카메라 초기화 완료: ${_cameraController.value.isInitialized}');

    final options = PoseDetectorOptions(
      mode: PoseDetectionMode.stream,
      model: PoseDetectionModel.base,
    );
    _poseDetector = PoseDetector(options: options);
    debugPrint('PoseDetector 초기화 완료');

    _cameraController.startImageStream((CameraImage image) {
      if (!_isProcessing) {
        _isProcessing = true;
        _detectPose(image).then((_) {
          _isProcessing = false;
        }).catchError((e) {
          debugPrint('포즈 감지 중 오류 발생: $e');
          _isProcessing = false;
        });
      }
    });

    _sessionStartTime = DateTime.now();

    if (mounted) setState(() {});
  }

  Future<void> _detectPose(CameraImage image) async {
    debugPrint('이미지 스트림에서 _detectPose 호출됨');

    final inputImage = InputImage.fromPlatform(image);
    debugPrint('InputImage 생성 완료 (fromPlatform)');

    try {
      final poses = await _poseDetector.processImage(inputImage);
      debugPrint('감지된 포즈 수: ${poses.length}');

      if (mounted) {
        setState(() {
          _poses = poses;
          if (_poses.isNotEmpty) {
            _analyzeCurrentPosture(_poses.first);
          } else {
            _feedbackMessage = "사람을 인식할 수 없습니다. 화면에 몸을 맞춰주세요.";
            _violatedRules = [];
          }
        });
      }
    } catch (e) {
      debugPrint('PoseDetector.processImage 오류: $e');
      if (mounted) {
        setState(() {
          _feedbackMessage = "자세 분석 중 오류 발생: ${e.toString()}";
          _violatedRules = [];
        });
      }
    }
  }

  void _analyzeCurrentPosture(Pose pose) {
    final result = analyzeShoulderPressPosture(
      pose: pose,
      currentRepState: _repState,
      lastElbowAngle: _lastElbowAngle,
    );

    final bool repCounted = result.item1;
    final String newFeedbackMessage = result.item2;
    final List<PostureRule> newViolatedRules = result.item3;
    final RepetitionState newRepState = result.item4;

    if (repCounted) {
      _completedReps++;
      _feedbackLog.add(FeedbackEntry(
        timestamp: DateTime.now(),
        message: "횟수 ${_completedReps}회 카운트!",
        violatedRules: newViolatedRules,
      ));
      if (_completedReps >= widget.targetReps) {
        _endWorkoutSession();
        return;
      }
    }

    setState(() {
      _feedbackMessage = newFeedbackMessage;
      _violatedRules = newViolatedRules;
      _repState = newRepState;
    });

    final leftElbow = pose.landmarks[PoseLandmarkType.leftElbow]?.toOffset();
    final rightElbow = pose.landmarks[PoseLandmarkType.rightElbow]?.toOffset();
    if (leftElbow != null && rightElbow != null) {
      final leftWrist = pose.landmarks[PoseLandmarkType.leftWrist]?.toOffset();
      final rightWrist = pose.landmarks[PoseLandmarkType.rightWrist]?.toOffset();
      final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder]?.toOffset();
      final rightShoulder = pose.landmarks[PoseLandmarkType.rightShoulder]?.toOffset();

      if (leftWrist != null && rightWrist != null && leftShoulder != null && rightShoulder != null) {
        final double leftArmAngle = calculateAngle3P(leftShoulder, leftElbow, leftWrist);
        final double rightArmAngle = calculateAngle3P(rightShoulder, rightElbow, rightWrist);
        _lastElbowAngle = (leftArmAngle + rightArmAngle) / 2;
      }
    }
  }

  void _endWorkoutSession() {
    _cameraController.stopImageStream();
    _poseDetector.close();

    final session = WorkoutSession(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      exerciseType: widget.exercise.type,
      targetReps: widget.targetReps,
      completedReps: _completedReps,
      startTime: _sessionStartTime ?? DateTime.now(),
      endTime: DateTime.now(),
      feedbackLog: _feedbackLog,
    );

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => WorkoutCompletionScreen(
          session: session,
          cameras: cameras, // main.dart의 전역 cameras 변수를 전달
        ),
      ),
    );
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
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.exercise.name),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: AspectRatio(
              aspectRatio: _cameraController.value.aspectRatio,
              child: CameraPreview(_cameraController),
            ),
          ),
          Positioned.fill(
            child: _poses.isNotEmpty
                ? CustomPaint(
              painter: PoseLandmarkPainter(
                _poses.first,
                imageSize: _cameraController.value.previewSize!,
                violatedRules: _violatedRules,
              ),
            )
                : Container(),
          ),
          Positioned(
            top: 20,
            left: 20,
            right: 20,
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      '${_completedReps} / ${widget.targetReps} 회',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    LinearProgressIndicator(
                      value: _completedReps / widget.targetReps,
                      backgroundColor: Colors.grey[300],
                      color: Colors.blueAccent,
                      minHeight: 10,
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              color: Colors.white.withOpacity(0.9),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  _feedbackMessage,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: _violatedRules.isNotEmpty ? Colors.red : Colors.green,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
