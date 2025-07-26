plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.first_app"
    compileSdk = 36


    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.first_app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 24
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }
    splits {
        abi {
            isEnable = true
            reset()
            include("armeabi-v7a", "arm64-v8a", "x86", "x86_64") // 모든 주요 ABI 포함
            isUniversalApk = false // 각 ABI별 APK 생성 (선택 사항)
        }
    }

    packaging {
        resources {
            excludes += listOf("/META-INF/{AL2.0,LGPL2.1}")
        }
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
    // 이 위치에 dependencies 블록이 있으면 안 됩니다.
    // dependencies {
    //     implementation("com.google.mediapipe:tasks-vision:latest.release")
    // }
}

// dependencies 블록은 여기에 와야 합니다!
dependencies {
    // 여기에 다른 종속성들이 이미 있을 수 있습니다.
    implementation("com.google.mediapipe:tasks-vision:latest.release")
}

flutter {
    source = "../.."
}