import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

// 운동 종류를 정의하는 열거형
enum ExerciseType {
  shoulderPress,
  // 다른 운동 종류를 여기에 추가할 수 있습니다.
  unknown,
}

// 운동 정보를 담는 클래스
class Exercise {
  final ExerciseType type; // 운동 종류
  final String name; // 운동 이름 (예: 숄더 프레스)
  final String description; // 운동 설명
  final String imageUrl; // 운동 아이콘 또는 이미지 URL (현재는 사용 안 함)

  const Exercise({
    required this.type,
    required this.name,
    this.description = '',
    this.imageUrl = '',
  });
}

// 운동 세션의 기록을 담는 클래스
class WorkoutSession {
  final String id; // 세션 고유 ID
  final ExerciseType exerciseType; // 운동 종류
  final int targetReps; // 목표 횟수
  final int completedReps; // 완료 횟수
  final DateTime startTime; // 운동 시작 시간
  final DateTime endTime; // 운동 종료 시간
  final List<FeedbackEntry> feedbackLog; // 자세 피드백 기록
  // final String videoPath; // 운동 영상 경로 (현재는 구현 안 함)

  WorkoutSession({
    required this.id,
    required this.exerciseType,
    required this.targetReps,
    required this.completedReps,
    required this.startTime,
    required this.endTime,
    this.feedbackLog = const [],
    // this.videoPath = '',
  });

  // WorkoutSession 객체를 Map으로 변환 (저장용)
  Map<String, dynamic> toJson() => {
    'id': id,
    'exerciseType': exerciseType.name,
    'targetReps': targetReps,
    'completedReps': completedReps,
    'startTime': startTime.toIso8601String(),
    'endTime': endTime.toIso8601String(),
    'feedbackLog': feedbackLog.map((e) => e.toJson()).toList(),
    // 'videoPath': videoPath,
  };

  // Map을 WorkoutSession 객체로 변환 (불러오기용)
  factory WorkoutSession.fromJson(Map<String, dynamic> json) => WorkoutSession(
    id: json['id'],
    exerciseType: ExerciseType.values.firstWhere(
            (e) => e.name == json['exerciseType'],
        orElse: () => ExerciseType.unknown),
    targetReps: json['targetReps'],
    completedReps: json['completedReps'],
    startTime: DateTime.parse(json['startTime']),
    endTime: DateTime.parse(json['endTime']),
    feedbackLog: (json['feedbackLog'] as List)
        .map((e) => FeedbackEntry.fromJson(e))
        .toList(),
    // videoPath: json['videoPath'],
  );
}

// 특정 시점의 자세 피드백을 담는 클래스
class FeedbackEntry {
  final DateTime timestamp; // 피드백 발생 시간
  final String message; // 피드백 메시지
  final List<PostureRule> violatedRules; // 위반한 자세 규칙 목록

  FeedbackEntry({
    required this.timestamp,
    required this.message,
    this.violatedRules = const [],
  });

  // FeedbackEntry 객체를 Map으로 변환 (저장용)
  Map<String, dynamic> toJson() => {
    'timestamp': timestamp.toIso8601String(),
    'message': message,
    'violatedRules': violatedRules.map((e) => e.name).toList(),
  };

  // Map을 FeedbackEntry 객체로 변환 (불러오기용)
  factory FeedbackEntry.fromJson(Map<String, dynamic> json) => FeedbackEntry(
    timestamp: DateTime.parse(json['timestamp']),
    message: json['message'],
    violatedRules: (json['violatedRules'] as List)
        .map((e) => PostureRule.values.firstWhere((rule) => rule.name == e))
        .toList(),
  );
}

// 자세 분석 규칙을 정의하는 열거형
enum PostureRule {
  armNotFullyExtended, // 팔이 완전히 펴지지 않음
  torsoTooLeaned, // 상체가 너무 기울어짐
  elbowTooFarBack, // 팔꿈치가 너무 뒤로 빠짐
  dumbbellHeightUneven, // 양쪽 덤벨 높이 불균형
  dumbbellNotHorizontal, // 덤벨이 지면과 수평이 아님 (BLE 데이터 필요, 현재는 시뮬레이션)
  // 추가적인 규칙을 여기에 정의할 수 있습니다.
}

// 운동 횟수 카운팅 상태
enum RepetitionState {
  down, // 시작 자세 (팔이 내려간 상태)
  up, // 끝 자세 (팔이 올라간 상태)
  transition, // 전환 중
  initial, // 초기 상태
}
