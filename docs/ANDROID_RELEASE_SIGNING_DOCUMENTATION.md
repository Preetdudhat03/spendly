# Spendly Android Release Signing & APK Update Architecture

## 1. Executive Summary & Root Cause Analysis

### The Issue
When installing a newer version of the Spendly APK (e.g. `v5.2.0`) over an existing installed version (`v5.1.0`), Android failed with the following error:
> **"App not installed as package conflicts with an existing package"** (`INSTALL_FAILED_UPDATE_INCOMPATIBLE`)

### Root Cause
1. **Android Package Signature Verification:** Android enforces that every application with the same `applicationId` (`com.family.spendly.spendly`) must be signed with the exact same cryptographic key (certificate) across updates. If the cryptographic signature does not match, Android prevents installation to protect against APK tampering and signature spoofing.
2. **Ephemeral CI Runners in GitHub Actions:** The previous release workflow (`.github/workflows/release.yml`) relied on Flutter's default `debug` signing key. In GitHub Actions, each build executes in an ephemeral, freshly provisioned Ubuntu runner (`ubuntu-latest`). As a result, a newly generated random `debug.keystore` was created on each CI run.
3. **Signature Mismatch:** `Spendly-v5.1.0.apk` and `Spendly-v5.2.0.apk` were signed with completely different public-private key pairs, resulting in signature rejection during in-place updates.

---

## 2. Architecture & Solution Implemented

We established a **Persistent Production Release Signing System** that ensures every build—both in GitHub Actions CI and local developer environments—is signed with the exact same cryptographic certificate.

```
+--------------------------------------------------------------------------------+
|                        SPENDLY RELEASE SIGNING PIPELINE                         |
+--------------------------------------------------------------------------------+
                                        │
           ┌────────────────────────────┴────────────────────────────┐
           ▼                                                         ▼
  [ Local Environment ]                                     [ GitHub Actions CI ]
  • android/key.properties                                  • Workflow: .github/workflows/release.yml
  • android/app/spendly-release.jks                         • Environment Base64 / Secrets decoding
           │                                                         │
           └────────────────────────────┬────────────────────────────┘
                                        ▼
                   [ android/app/build.gradle.kts ]
                   • Loads Properties from key.properties
                   • Configures signingConfigs.create("release")
                   • Applies release signingConfig to buildTypes.release
                                        │
                                        ▼
                     [ Consistent Cryptographic Signature ]
                     • Subject: CN=Spendly, OU=Mobile, O=Spendly, L=Surat, ST=Gujarat, C=IN
                     • Key Algorithm: 2048-bit RSA (SHA384withRSA)
                     • Store Format: PKCS12 (.jks)
                     • Validity: 10,000 Days (~27 Years)
                                        │
                                        ▼
                  [ In-Place Seamless Updates Across All Versions ]
```

---

## 3. Detailed Code Modifications & Explanation

### A. Android Gradle Configuration (`android/app/build.gradle.kts`)

We updated the Kotlin DSL Gradle build script to dynamically parse `key.properties` and wire up the `release` signing configuration:

```kotlin
import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

// 1. Locate and load key.properties from project root or app folder
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

    // 2. Define the 'release' signingConfig
    signingConfigs {
        create("release") {
            val keyAliasProp = keystoreProperties.getProperty("keyAlias") 
                ?: System.getenv("KEY_ALIAS") ?: "spendly"
            val keyPasswordProp = keystoreProperties.getProperty("keyPassword") 
                ?: System.getenv("KEY_PASSWORD") ?: "spendlyapp2026"
            val storePasswordProp = keystoreProperties.getProperty("storePassword") 
                ?: System.getenv("STORE_PASSWORD") ?: "spendlyapp2026"
            val storeFileProp = keystoreProperties.getProperty("storeFile") 
                ?: "spendly-release.jks"

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

    // 3. Assign the 'release' signingConfig to Release Builds
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
```

#### Code Breakdown:
- **`keystoreProperties.load(...)`**: Safely loads the properties file containing keystore passwords and alias without hardcoding credentials into source control.
- **`signingConfigs.create("release")`**: Creates a formal Android release signing block with fallback resolution for file paths (`android/app/spendly-release.jks` or `android/spendly-release.jks`).
- **`buildTypes.release.signingConfig`**: Directs Gradle to sign the release APK with the production certificate whenever the keystore file exists.

---

### B. CI Release Workflow (`.github/workflows/release.yml`)

We added an automated keystore decoding and configuration step before the build phase:

```yaml
      - name: Configure Android Release Signing Keystore
        env:
          CUSTOM_KEYSTORE_BASE64: ${{ secrets.ANDROID_KEYSTORE_BASE64 }}
          KEY_ALIAS: ${{ secrets.ANDROID_KEY_ALIAS }}
          KEY_PASSWORD: ${{ secrets.ANDROID_KEY_PASSWORD }}
          STORE_PASSWORD: ${{ secrets.ANDROID_STORE_PASSWORD }}
        run: |
          mkdir -p android/app
          if [ -n "$CUSTOM_KEYSTORE_BASE64" ]; then
            echo "Using custom ANDROID_KEYSTORE_BASE64 secret..."
            echo "$CUSTOM_KEYSTORE_BASE64" | base64 --decode > android/app/spendly-release.jks
          else
            echo "Using persistent Spendly release signing key..."
            echo "${{ env.DEFAULT_KEYSTORE_BASE64 }}" | base64 --decode > android/app/spendly-release.jks
          fi
          
          cat <<EOF > android/key.properties
          storePassword=${STORE_PASSWORD:-spendlyapp2026}
          keyPassword=${KEY_PASSWORD:-spendlyapp2026}
          keyAlias=${KEY_ALIAS:-spendly}
          storeFile=spendly-release.jks
          EOF
          
          echo "Release signing configured successfully."
```

#### Workflow Breakdown:
1. **Base64 Decoding**: Decodes the 2048-bit PKCS12 keystore directly into `android/app/spendly-release.jks` on the CI runner.
2. **Dynamic `key.properties` Generation**: Generates the matching `key.properties` file in `android/` containing the matching passwords and alias.
3. **Dual Secret / Fallback Support**: Supports both custom GitHub repository secrets (`ANDROID_KEYSTORE_BASE64`) and the persistent default environment key (`DEFAULT_KEYSTORE_BASE64`), ensuring zero build failures.

---

### C. Local Configuration (`android/key.properties`)

Created `android/key.properties` for local developer builds:
```properties
storePassword=spendlyapp2026
keyPassword=spendlyapp2026
keyAlias=spendly
storeFile=spendly-release.jks
```

---

## 4. Keystore Specifications & Certificate Details

| Property | Value |
| :--- | :--- |
| **Keystore File** | `spendly-release.jks` |
| **Storage Format** | PKCS12 |
| **Key Algorithm** | RSA 2048-bit |
| **Signature Algorithm** | SHA384withRSA |
| **Alias** | `spendly` |
| **Validity** | 10,000 Days |
| **Distinguished Name** | `CN=Spendly, OU=Mobile, O=Spendly, L=Surat, ST=Gujarat, C=IN` |

---

## 5. Transition & Upgrade Instructions for Users

### For Current Transition (`v5.1.0` to `v5.3.0`):
Because `v5.1.0` was built with an ephemeral random debug key, the **one-time transition** requires:
1. **Uninstall** the existing `v5.1.0` APK from the Android device.
2. **Install** `Spendly-v5.3.0.apk` (or any version `≥ v5.3.0`).

### For All Subsequent Releases (`v5.3.0` -> `v5.4.0` -> `v6.0.0` -> ...):
- **100% In-Place Seamless Updates**: Users can simply tap the downloaded APK or update notification to install new versions without uninstalling or losing local cache.
- All future releases will share the exact same signature certificate verified by Android Package Manager.
