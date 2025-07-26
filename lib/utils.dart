import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:first_app/models.dart';

const double pi = 3.1415926535897932;

double calculateAngle3P(Offset a, Offset b, Offset c) {
  double distance(Offset p1, Offset p2) {
    return sqrt(pow(p1.dx - p2.dx, 2) + pow(p1.dy - p2.dy, 2));
  }

  final double ab = distance(a, b);
  final double bc = distance(b, c);
  final double ac = distance(a, c);

  // 코사인 법칙을 사용하여 각도 계산 (라디안)
  // NaN 방지를 위해 acos 인자 범위 제한
  double cosAngle = (ab * ab + bc * bc - ac * ac) / (2 * ab * bc);
  if (cosAngle > 1.0) cosAngle = 1.0;
  if (cosAngle < -1.0) cosAngle = -1.0;

  double angleRad = acos(cosAngle);
  return angleRad * 180 / pi;
}

Offset calculateMidpoint(Offset p1, Offset p2) {
  return Offset((p1.dx + p2.dx) / 2, (p1.dy + p2.dy) / 2);
}

double calculateAngleToHorizontal(Offset p1, Offset p2) {
  final double dx = p2.dx - p1.dx;
  final double dy = p2.dy - p1.dy;
  final double angleRad = atan2(dy, dx);
  double angleDeg = angleRad * 180 / pi;

  if (angleDeg < 0) {
    angleDeg += 360;
  }
  return angleDeg > 180 ? angleDeg - 360 : angleDeg;
}

// 자세 분석 및 횟수 카운팅 로직
// 반환 값: (횟수 카운트 여부, 피드백 메시지, 위반 규칙 목록, 새로운 RepetitionState)
Tuple4<bool, String, List<PostureRule>, RepetitionState> analyzeShoulderPressPosture({
  required Pose pose,
  required RepetitionState currentRepState,
  required double lastElbowAngle, // 이전 프레임의 팔꿈치 각도 (횟수 카운팅용)
}) {
  List<PostureRule> violatedRules = [];
  String feedbackMessage = "자세가 좋습니다.";
  bool repCounted = false;
  RepetitionState nextRepState = currentRepState;

  // 랜드마크 추출 (정규화된 좌표)
  final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder]?.toOffset();
  final rightShoulder = pose.landmarks[PoseLandmarkType.rightShoulder]?.toOffset();
  final leftElbow = pose.landmarks[PoseLandmarkType.leftElbow]?.toOffset();
  final rightElbow = pose.landmarks[PoseLandmarkType.rightElbow]?.toOffset();
  final leftWrist = pose.landmarks[PoseLandmarkType.leftWrist]?.toOffset();
  final rightWrist = pose.landmarks[PoseLandmarkType.rightWrist]?.toOffset();
  final leftHip = pose.landmarks[PoseLandmarkType.leftHip]?.toOffset();
  final rightHip = pose.landmarks[PoseLandmarkType.rightHip]?.toOffset();
  final nose = pose.landmarks[PoseLandmarkType.nose]?.toOffset();

  if (leftShoulder == null || rightShoulder == null ||
      leftElbow == null || rightElbow == null ||
      leftWrist == null || rightWrist == null ||
      leftHip == null || rightHip == null ||
      nose == null) {
    return Tuple4(false, "몸이 카메라에 충분히 잡히지 않았습니다.", violatedRules, currentRepState);
  }

  // 1. 팔꿈치 각도 계산 (어깨-팔꿈치-손목 각도)
  final double leftArmAngle = calculateAngle3P(leftShoulder, leftElbow, leftWrist);
  final double rightArmAngle = calculateAngle3P(rightShoulder, rightElbow, rightWrist);
  final double avgElbowAngle = (leftArmAngle + rightArmAngle) / 2;

  // 횟수 카운팅 로직
  // 시작 자세 및 횟수 카운팅 방법 (PPT 기준)
  // 어깨~팔꿈치~손목이 이루는 각이 90도 이하 = down 상태 (시작 자세)
  // 어깨~팔꿈치~손목이 이루는 각이 160도 이상 = up 상태
  // Up 상태에서 -> down 상태로 변하면 횟수 카운트

  if (currentRepState == RepetitionState.initial) {
    if (avgElbowAngle <= 90) { // 초기 down 자세 감지
      nextRepState = RepetitionState.down;
      feedbackMessage = "운동 시작 준비 (팔 내림)";
    }
  } else if (currentRepState == RepetitionState.down) {
    if (avgElbowAngle >= 160) { // down -> up 전환
      nextRepState = RepetitionState.up;
      feedbackMessage = "팔을 끝까지 밀어올리세요!";
    }
  } else if (currentRepState == RepetitionState.up) {
    if (avgElbowAngle <= 90) { // up -> down 전환 (횟수 카운트)
      repCounted = true;
      nextRepState = RepetitionState.down;
      feedbackMessage = "횟수 카운트!";
    }
  }

  // 1. 팔이 완전히 펴지지 않음 (Up 상태에서 160도 미만)
  if (nextRepState == RepetitionState.up && avgElbowAngle < 160) {
    violatedRules.add(PostureRule.armNotFullyExtended);
    if (!feedbackMessage.contains("팔을 끝까지")) { // 이미 횟수 카운팅 메시지가 아니면 추가
      feedbackMessage = "팔이 완전히 펴지지 않았습니다. 팔을 끝까지 밀어올리세요.";
    }
  }

  // 2. 상체가 적절하게 기울어졌는가 (양쪽 엉덩이 중점과 양쪽 어깨 중점을 이은 선이 지면과 이루는 각)
  final Offset midHip = calculateMidpoint(leftHip, rightHip);
  final Offset midShoulder = calculateMidpoint(leftShoulder, rightShoulder);
  final double torsoAngle = calculateAngleToHorizontal(midHip, midShoulder);

  // 상체가 수직에 가까운지 확인 (예: 80~100도 사이)
  if (torsoAngle < 80 || torsoAngle > 100) {
    violatedRules.add(PostureRule.torsoTooLeaned);
    if (!feedbackMessage.contains("상체")) {
      feedbackMessage = "상체가 너무 기울어졌습니다. 몸을 곧게 세우세요.";
    }
  }

  // 3. 팔꿈치가 뒤로 과도하게 빠지지 않음
  // 어깨와 팔꿈치의 x좌표 비교 (카메라 방향에 따라 달라질 수 있음)
  // 여기서는 카메라가 전면이고, 사람이 정면을 바라본다고 가정합니다.
  // 어깨보다 팔꿈치 x좌표가 작으면 뒤로 빠진 것으로 간주 (화면 좌측이 x=0)
  // 이 로직은 카메라 각도에 따라 조정이 필요할 수 있습니다.
  // 간단하게 어깨와 팔꿈치의 수평 위치를 비교합니다.
  if (leftElbow.dx > leftShoulder.dx + 0.05 || rightElbow.dx < rightShoulder.dx - 0.05) { // 0.05는 임의의 임계값 (정규화된 좌표 기준)
    violatedRules.add(PostureRule.elbowTooFarBack);
    if (!feedbackMessage.contains("팔꿈치")) {
      feedbackMessage = "팔꿈치가 너무 뒤로 빠졌습니다. 팔꿈치를 앞쪽에서 유지하세요.";
    }
  }


  // 4. 양쪽 덤벨의 높이가 같은 상태로 움직임
  // 양쪽 손목의 y좌표 차이가 일정 범위 이내로 유지됨
  final double wristYDiff = (leftWrist.dy - rightWrist.dy).abs();
  if (wristYDiff > 0.05) { // 임의의 임계값 0.05 (정규화된 좌표 기준)
    violatedRules.add(PostureRule.dumbbellHeightUneven);
    if (!feedbackMessage.contains("덤벨 높이")) {
      feedbackMessage = "양쪽 덤벨의 높이를 일치시키세요.";
    }
  }

  // 5. 각 덤벨이 지면과 수평을 유지 (MPU9250 데이터 필요, 현재는 시뮬레이션)
  // 이 부분은 BLE 데이터가 연동되어야 정확한 판단이 가능합니다.
  // 현재는 ML Kit 데이터만 사용하므로, 이 규칙은 시뮬레이션 또는 제외됩니다.
  // if (simulatedDumbbellPitchAngle.abs() > 5) { // 예시: 5도 이상 기울어지면
  //   violatedRules.add(PostureRule.dumbbellNotHorizontal);
  //   feedbackMessage = "덤벨의 수평을 유지시키세요.";
  // }

  // 횟수 카운팅 메시지가 아니라면, 위반 규칙에 따라 일반 피드백 메시지 업데이트
  if (!repCounted && violatedRules.isNotEmpty) {
    if (violatedRules.length >= 2) {
      feedbackMessage = "자세가 불안정합니다. 자세를 교정해주세요!";
    } else {
      // 단일 위반 규칙에 대한 구체적인 피드백 메시지는 이미 위에서 설정됨
      // 만약 위에서 설정되지 않았다면 여기에 기본 메시지 추가 가능
    }
  } else if (!repCounted && violatedRules.isEmpty && nextRepState == currentRepState) {
    // 횟수 카운트도 없고, 규칙 위반도 없고, 상태 변화도 없으면 기본 메시지 유지
    feedbackMessage = "자세가 좋습니다.";
  }


  return Tuple4(repCounted, feedbackMessage, violatedRules, nextRepState);
}

// 튜플을 위한 간단한 클래스 정의 (Dart 3.0부터는 내장 Tuple 지원)
class Tuple4<T1, T2, T3, T4> {
  final T1 item1;
  final T2 item2;
  final T3 item3;
  final T4 item4;

  Tuple4(this.item1, this.item2, this.item3, this.item4);
}

extension PoseLandmarkExtension on PoseLandmark {
  Offset toOffset() {
    return Offset(x, y);
  }
}