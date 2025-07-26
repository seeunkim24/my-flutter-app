package com.example.first_app // 이 패키지 이름이 정확한지 확인하세요.

// GPU 가속을 위해 필요
import android.os.Bundle
import com.google.mediapipe.tasks.core.BaseOptions
import com.google.mediapipe.tasks.core.Delegate
import com.google.mediapipe.tasks.vision.core.RunningMode
import com.google.mediapipe.tasks.vision.poselandmarker.PoseLandmarker
import com.google.mediapipe.tasks.vision.poselandmarker.PoseLandmarker.PoseLandmarkerOptions
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    private var poseLandmarker: PoseLandmarker? = null // PoseLandmarker 인스턴스 선언

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // 앱이 시작될 때 PoseLandmarker를 초기화합니다.
        setupPoseLandmarker()
    }

    private fun setupPoseLandmarker() {
        // PoseLandmarkerOptions.Builder를 사용하여 옵션을 설정합니다.
        val optionsBuilder = PoseLandmarkerOptions.builder()
            .setBaseOptions(
                BaseOptions.builder() // assets 폴더에 있는 모델 파일 이름을 지정합니다.
                    // 'pose_landmarker_full.task' 파일이 assets 폴더에 있어야 합니다.
                    .setModelAssetPath("pose_landmarker_full.task") // GPU 가속을 사용하도록 설정합니다.
                    // 이는 성능 향상에 매우 중요하며, 일부 기기에서 충돌을 방지할 수 있습니다.
                    .setDelegate(Delegate.GPU)
                    .build()
            ) // 실행 모드를 LIVE_STREAM으로 설정합니다.
            // 카메라에서 실시간으로 들어오는 비디오 스트림을 처리하는 데 필수적입니다.
            .setRunningMode(RunningMode.LIVE_STREAM)

        try {
            // 설정된 옵션을 기반으로 PoseLandmarker 인스턴스를 생성합니다.
            poseLandmarker = PoseLandmarker.createFromOptions(this, optionsBuilder.build())
            println("PoseLandmarker 초기화 성공!") // 로그 확인용
        } catch (e: Exception) {
            // PoseLandmarker 초기화 실패 시 오류를 출력합니다.
            // 이 오류는 주로 모델 파일이 없거나, GPU Delegate 호환성 문제일 수 있습니다.
            System.err.println("PoseLandmarker 초기화 실패: " + e.message)
            e.printStackTrace()
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        // 액티비티가 종료될 때 PoseLandmarker 리소스를 해제합니다.
        if (poseLandmarker != null) {
            poseLandmarker!!.close()
            println("PoseLandmarker 리소스 해제 완료.") // 로그 확인용
        }
    }
}