plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.verotech_app"

    // ✅ Hard-coded versions (no flutter.* indirection)
    compileSdk = 35
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.example.verotech_app"

        // ✅ Raise mins to satisfy Firebase + plugins
        minSdk = 23
        targetSdk = 34

        // keep using Flutter-managed versionCode/Name (safe to leave)
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // Optional: enable if you ever hit 65K refs; not required for minSdk 23
        // multiDexEnabled = true
    }

    buildTypes {
        release {
            // Signing with debug key so `flutter run --release` works
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}
