import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    id("com.google.gms.google-services")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")

if (!keystorePropertiesFile.exists()) {
    throw GradleException(
        "Missing android/key.properties. Release signing cannot continue."
    )
}

keystoreProperties.load(FileInputStream(keystorePropertiesFile))

val releaseStoreFile =
    keystoreProperties["storeFile"]?.toString()
        ?: throw GradleException("Missing storeFile in android/key.properties")

val releaseStorePassword =
    keystoreProperties["storePassword"]?.toString()
        ?: throw GradleException("Missing storePassword in android/key.properties")

val releaseKeyAlias =
    keystoreProperties["keyAlias"]?.toString()
        ?: throw GradleException("Missing keyAlias in android/key.properties")

val releaseKeyPassword =
    keystoreProperties["keyPassword"]?.toString()
        ?: throw GradleException("Missing keyPassword in android/key.properties")

android {
    namespace = "com.nikoliahealthsystem.trabajo_hub"

    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    defaultConfig {
        applicationId = "com.nikoliahealthsystem.trabajo_hub"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            keyAlias = releaseKeyAlias
            keyPassword = releaseKeyPassword
            storeFile = file(releaseStoreFile)
            storePassword = releaseStorePassword
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
}