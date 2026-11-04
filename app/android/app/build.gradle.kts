import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    FileInputStream(keystorePropertiesFile).use { stream ->
        keystoreProperties.load(stream)
    }
}

val storeFilePath = keystoreProperties.getProperty("storeFile")?.trim()
val resolvedStoreFile =
    if (!storeFilePath.isNullOrEmpty()) {
        rootProject.file(storeFilePath)
    } else {
        null
    }

val hasReleaseKeystore =
    keystorePropertiesFile.exists() &&
        resolvedStoreFile != null &&
        resolvedStoreFile.exists() &&
        !keystoreProperties.getProperty("storePassword").isNullOrBlank() &&
        !keystoreProperties.getProperty("keyAlias").isNullOrBlank() &&
        !keystoreProperties.getProperty("keyPassword").isNullOrBlank()

val isReleaseSigningRequired =
    project.findProperty("requireReleaseSigning")?.toString()?.toBoolean() == true ||
        gradle.startParameter.taskNames.any { taskName ->
            taskName.contains("Release", ignoreCase = true)
        }

if (isReleaseSigningRequired && !hasReleaseKeystore) {
    throw GradleException(
        "Konfigurasi signing rilis Android belum lengkap. " +
            "Salin android/key.properties.example ke android/key.properties dan pastikan " +
            "storeFile, storePassword, keyAlias, serta keyPassword valid untuk build Release.",
    )
}

android {
    namespace = "com.kantincerdas.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.kantincerdas.app"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasReleaseKeystore) {
            create("release") {
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
                storeFile = resolvedStoreFile
                storePassword = keystoreProperties.getProperty("storePassword")
            }
        }
    }

    buildTypes {
        release {
            if (hasReleaseKeystore) {
                signingConfig = signingConfigs.getByName("release")
            }
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
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
