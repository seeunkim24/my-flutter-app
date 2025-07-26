import 'package:flutter/material.dart';
import 'package:first_app/models.dart';
import 'package:first_app/workout_selection_screen.dart';
import 'package:camera/camera.dart'; // cameras 변수를 사용하기 위해 임포트

class WorkoutCompletionScreen extends StatelessWidget {
  final WorkoutSession session;
  final List<CameraDescription> cameras; // cameras를 생성자로 받도록 추가

  const WorkoutCompletionScreen({super.key, required this.session, required this.cameras});

  @override
  Widget build(BuildContext context) {
    final Duration duration = session.endTime.difference(session.startTime);
    final String durationString =
        '${duration.inMinutes}분 ${duration.inSeconds.remainder(60)}초';

    return Scaffold(
      appBar: AppBar(
        title: const Text('운동 완료!'),
        automaticallyImplyLeading: false,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '${session.exerciseType.name} 운동을 완료했습니다!',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.green.shade700,
              ),
            ),
            const SizedBox(height: 30),
            Card(
              elevation: 5,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSummaryRow(context, '운동 종류', session.exerciseType.name),
                    _buildSummaryRow(context, '목표 횟수', '${session.targetReps}회'),
                    _buildSummaryRow(context, '완료 횟수', '${session.completedReps}회',
                        isHighlight: true),
                    _buildSummaryRow(context, '운동 시간', durationString),
                    const SizedBox(height: 15),
                    Text(
                      '피드백 요약:',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    if (session.feedbackLog.isEmpty)
                      Text('특별한 피드백이 없습니다.', style: Theme.of(context).textTheme.bodyLarge)
                    else
                      ...session.feedbackLog.reversed.take(5).map((entry) => Padding(
                        padding: const EdgeInsets.only(bottom: 5.0),
                        child: Text(
                          '- ${entry.message} (${entry.timestamp.toIso8601String().substring(11, 19)})',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      )),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),
            Column(
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              WorkoutSelectionScreen(cameras: cameras)), // cameras 전달
                          (route) => false,
                    );
                  },
                  icon: const Icon(Icons.home, size: 28),
                  label: const Text(
                    '운동 선택 화면으로',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 25),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    backgroundColor: Colors.blue.shade700,
                    foregroundColor: Colors.white,
                    elevation: 5,
                  ),
                ),
                const SizedBox(height: 15),
                OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('운동 기록이 로컬에 저장되었습니다.')),
                    );
                  },
                  icon: const Icon(Icons.save, size: 24),
                  label: const Text(
                    '세션 저장',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 25),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    side: BorderSide(color: Colors.blue.shade700, width: 2),
                    foregroundColor: Colors.blue.shade700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(BuildContext context, String title, String value,
      {bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$title:',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal,
              color: isHighlight ? Colors.green.shade600 : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
