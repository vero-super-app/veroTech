// android/app/build.gradle.kts
plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    // Flutter plugin must come after Android & Kotlin
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.verotech_app"

    // Match your plugins’ requirement
    compileSdk = 36

    defaultConfig {
        applicationId = "com.example.verotech_app"
        minSdk = flutter.minSdkVersion
        targetSdk = 36

        // Keep Flutter-managed versions
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        debug {
            // 🔴 Never shrink resources in debug
            isMinifyEnabled = false
            isShrinkResources = false
        }
        release {
            // ✅ Required pair: enable both together
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )

            // For convenience so `flutter run --release` works without a keystore
            signingConfig = signingConfigs.getByName("debug")
        }
    }

    // AGP 8.x uses Java 17
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    kotlinOptions { jvmTarget = "17" }

    packaging {
        resources.excludes += "/META-INF/{AL2.0,LGPL2.1}"
    }
}

flutter {
    source = "../.."
}
