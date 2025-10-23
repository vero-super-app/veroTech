// android/app/build.gradle.kts
plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    // Flutter plugin must come after Android & Kotlin
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.vero.vero360"
    compileSdk = 36 

    defaultConfig {
        applicationId = "com.vero.vero360"   
        minSdk = flutter.minSdkVersion      
        targetSdk = 34                     
        versionCode = 10001
        versionName = "1.0.1"
        multiDexEnabled = true
    }

    buildTypes {
        debug {
            isMinifyEnabled = false
            isShrinkResources = false
        }
        release {
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
            // so `flutter run --release` works without uploading a keystore
            signingConfig = signingConfigs.getByName("debug")
        }
    }

    // AGP 8.x uses Java 17
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    kotlinOptions {
        jvmTarget = "17"
    }

    packaging {
        resources {
            excludes += "/META-INF/{AL2.0,LGPL2.1}"
        }
    }
}

// Flutter plugin config (stays OUTSIDE the android {} block)
flutter {
    source = "../.."
}
