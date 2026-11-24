import java.util.Properties
import java.io.FileInputStream

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")

if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val clientEnvironment = Properties()
val clientEnvironmentFile = rootProject.file("../.env")
if (clientEnvironmentFile.exists()) {
    clientEnvironmentFile.inputStream().use { clientEnvironment.load(it) }
}
val kakaoNativeAppKey = clientEnvironment.getProperty("KAKAO_NATIVE_APP_KEY", "")
    .trim().removeSurrounding("\"").removeSurrounding("'")
require(kakaoNativeAppKey.isEmpty() || kakaoNativeAppKey.matches(Regex("[0-9a-fA-F]{32}"))) {
    "KAKAO_NATIVE_APP_KEY must be a 32-character hexadecimal client key in .env"
}

android {
    namespace = "co.digniche.muntum"
    compileSdk = 36
    ndkVersion = "28.2.13676358"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        manifestPlaceholders["kakaoLoginScheme"] =
            if (kakaoNativeAppKey.isEmpty()) "kakaounconfigured" else "kakao$kakaoNativeAppKey"
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "co.digniche.muntum"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
    
    signingConfigs {
    create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String
            keyPassword = keystoreProperties["keyPassword"] as String
            storeFile = keystoreProperties["storeFile"]?.let { file(it) }
            storePassword = keystoreProperties["storePassword"] as String
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
