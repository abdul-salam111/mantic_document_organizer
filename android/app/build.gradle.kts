import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Release signing, per project — see SIGNING.md for how to generate a
// keystore and android/key.properties for THIS project. key.properties is
// git-ignored (android/.gitignore) and never committed; only a
// key.properties.example template is. If key.properties doesn't exist
// (a fresh clone, before anyone has set up signing), release builds fall
// back to the debug signing key so `flutter build apk --release` and
// `flutter run --release` keep working out of the box.
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.mantic.document.organizer"
    // receive_sharing_intent ("Share into Mantic" from other apps) requires
    // at least 37.
    compileSdk = 37
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        // flutter_local_notifications requires this (its own build.gradle
        // enables it for itself, but consuming apps below API 26 must also
        // enable it, or the build fails with a desugaring error).
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.mantic.document.organizer"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = 35
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (keystorePropertiesFile.exists()) {
            create("release") {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            // Real signing when android/key.properties exists (see
            // SIGNING.md), otherwise falls back to the debug key so the
            // template still builds without any signing setup.
            signingConfig = if (keystorePropertiesFile.exists()) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    // OCR is called through MainActivity's method channel. This replaces the
    // CocoaPods-only Flutter ML Kit bridge while keeping Android ML Kit local.
    implementation("com.google.mlkit:text-recognition:16.0.1")
}
