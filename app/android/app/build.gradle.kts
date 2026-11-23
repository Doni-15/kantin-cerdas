import java.util.Properties

plugins {
    id("com.android.application")
    id("dev.flutter.flutter-gradle-plugin")
}

// Apply Google Services automatically when the project owner supplies
// app/android/app/google-services.json manually. Do not commit or forge this file.
val hasGoogleServicesConfig = file("google-services.json").isFile
if (hasGoogleServicesConfig) {
    apply(plugin = "com.google.gms.google-services")
}

val releaseSigning = rootProject.file("key.properties").takeIf { it.isFile }?.let { file ->
    Properties().apply { file.inputStream().use { load(it) } }
}

android {
    namespace = "id.kantincerdas.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = namespace
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        manifestPlaceholders["authEmailLinkHost"] =
            providers.environmentVariable("AUTH_EMAIL_LINK_HOST").orElse("auth.kantincerdas.invalid").get()
    }

    releaseSigning?.let { properties ->
        signingConfigs.create("release") {
            fun property(name: String) = checkNotNull(
                properties.getProperty(name)?.takeUnless { it.isBlank() },
            ) { "android/key.properties requires $name." }

            storeFile = rootProject.file(property("storeFile"))
            storePassword = property("storePassword")
            keyAlias = property("keyAlias")
            keyPassword = property("keyPassword")
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.findByName("release")
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
