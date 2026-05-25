import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

val googleServicesFile = file("google-services.json")
if (googleServicesFile.exists()) {
    apply(plugin = "com.google.gms.google-services")
}

val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

fun resolveKeyStoreProp(key: String): String? {
    val fileValue = keystoreProperties[key] as? String
    if (fileValue != null && !fileValue.startsWith("\${") && fileValue.isNotEmpty()) {
        return fileValue
    }
    val envKey = when (key) {
        "storePassword" -> "KEYSTORE_PASSWORD"
        "keyPassword" -> "KEY_PASSWORD"
        "keyAlias" -> "KEY_ALIAS"
        else -> key.uppercase()
    }
    return System.getenv(envKey) ?: fileValue
}

android {
    namespace = "com.omnivium.mobile"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    signingConfigs {
        if (keystorePropertiesFile.exists()) {
            create("release") {
                keyAlias = resolveKeyStoreProp("keyAlias")
                keyPassword = resolveKeyStoreProp("keyPassword")
                storeFile = resolveKeyStoreProp("storeFile")?.let { file(it) }
                storePassword = resolveKeyStoreProp("storePassword")
            }
        }
    }

    defaultConfig {
        applicationId = "com.omnivium.mobile"
        minSdk = 24
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        ndk {
            abiFilters += listOf("arm64-v8a", "armeabi-v7a")
        }
    }

    buildTypes {
        release {
            if (keystorePropertiesFile.exists()) {
                signingConfig = signingConfigs.getByName("release")
            }
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
        debug {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
