import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
} else {
    val appKeystorePropertiesFile = file("key.properties")
    if (appKeystorePropertiesFile.exists()) {
        keystoreProperties.load(FileInputStream(appKeystorePropertiesFile))
    }
}

android {
    namespace = "com.family.spendly.spendly"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.family.spendly.spendly"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            val keyAliasProp = keystoreProperties.getProperty("keyAlias") ?: System.getenv("KEY_ALIAS") ?: "spendly"
            val keyPasswordProp = keystoreProperties.getProperty("keyPassword") ?: System.getenv("KEY_PASSWORD") ?: "spendlyapp2026"
            val storePasswordProp = keystoreProperties.getProperty("storePassword") ?: System.getenv("STORE_PASSWORD") ?: "spendlyapp2026"
            val storeFileProp = keystoreProperties.getProperty("storeFile") ?: "spendly-release.jks"

            keyAlias = keyAliasProp
            keyPassword = keyPasswordProp
            storePassword = storePasswordProp

            val customStoreFile = file(storeFileProp)
            val parentStoreFile = rootProject.file(storeFileProp)
            val appStoreFile = file("spendly-release.jks")

            storeFile = when {
                customStoreFile.exists() -> customStoreFile
                parentStoreFile.exists() -> parentStoreFile
                appStoreFile.exists() -> appStoreFile
                else -> null
            }
        }
    }

    buildTypes {
        release {
            val releaseSigningConfig = signingConfigs.getByName("release")
            signingConfig = if (releaseSigningConfig.storeFile != null && releaseSigningConfig.storeFile!!.exists()) {
                releaseSigningConfig
            } else {
                signingConfigs.getByName("debug")
            }
        }
    }
}

flutter {
    source = "../.."
}
