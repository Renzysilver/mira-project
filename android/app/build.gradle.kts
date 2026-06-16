import org.jetbrains.kotlin.gradle.dsl.JvmTarget  // ← ADD: needed for JvmTarget.JVM_17

plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")             // ← ADD: this is what was missing
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

@Suppress("DEPRECATION_ERROR")                     // ← ADD: silences AGP 9.0 android { } error
android {
    namespace = "com.example.mira"
    compileSdk = 36
    ndkVersion = "28.2.13676358"
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.valilucifer.mira"
        minSdk = 24
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = JvmTarget.JVM_17               // ← Works now that the plugin is applied
    }
}

flutter {
    source = "../.."
}