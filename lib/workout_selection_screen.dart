import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:first_app/models.dart';
import 'package:first_app/shoulder_press_screen.dart';
import 'package:shared_preferences/shared_preferences.dart'; // shared_preferences 임포트

class WorkoutSelectionScreen extends StatefulWidget {
  final List<CameraDescription> cameras;

  const WorkoutSelectionScreen({super.key, required this.cameras});

  @override
  State<WorkoutSelectionScreen> createState() => _WorkoutSelectionScreenState();
}

class _WorkoutSelectionScreenState extends State<WorkoutSelectionScreen> {
  Exercise selectedExercise = const Exercise(type: ExerciseType.shoulderPress, name: '숄더 프레스');
  int targetReps = 10;

  @override
  void initState() {
    super.initState();
    _loadTargetReps();
  }

  Future<void> _loadTargetReps() async {
    final prefs = await SharedPreferences.getInstance(); // SharedPreferences 사용
    setState(() {
      targetReps = prefs.getInt('targetReps') ?? 10;
    });
  }

  Future<void> _saveTargetReps(int reps) async {
    final prefs = await SharedPreferences.getInstance(); // SharedPreferences 사용
    await prefs.setInt('targetReps', reps);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('운동 선택'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.only(bottom: 20),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '운동 종류',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    ListTile(
                      leading: const Icon(Icons.fitness_center, size: 40, color: Colors.blueAccent),
                      title: Text(
                        selectedExercise.name,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      subtitle: const Text('덤벨 숄더 프레스 자세 교정'),
                      trailing: const Icon(Icons.check_circle, color: Colors.green),
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('현재 숄더 프레스만 지원됩니다.')),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.only(bottom: 30),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '목표 횟수 설정',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_circle, size: 36, color: Colors.redAccent),
                          onPressed: () {
                            setState(() {
                              if (targetReps > 5) targetReps -= 5;
                              _saveTargetReps(targetReps);
                            });
                          },
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Text(
                            '$targetReps 회',
                            style: Theme.of(context).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle, size: 36, color: Colors.greenAccent),
                          onPressed: () {
                            setState(() {
                              targetReps += 5;
                              _saveTargetReps(targetReps);
                            });
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () {
                if (widget.cameras.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('사용 가능한 카메라가 없습니다.')),
                  );
                  return;
                }
                final frontCamera = widget.cameras.firstWhere(
                      (camera) => camera.lensDirection == CameraLensDirection.front,
                  orElse: () => widget.cameras.first,
                );

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ShoulderPressScreen(
                      camera: frontCamera,
                      exercise: selectedExercise,
                      targetReps: targetReps,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.play_arrow, size: 30),
              label: const Text(
                '운동 시작',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 30),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                backgroundColor: Colors.blue.shade700,
                foregroundColor: Colors.white,
                elevation: 5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
