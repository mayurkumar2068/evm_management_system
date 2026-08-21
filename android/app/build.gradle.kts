import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("dev.flutter.flutter-gradle-plugin")
}

val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
val hasReleaseKeystore = keystorePropertiesFile.exists()
if (hasReleaseKeystore) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.mpsec.mpsecnet"
    compileSdk = 36
    ndkVersion = "28.2.13676358"

    compileOptions {
        // Required by flutter_local_notifications (and other modern AndroidX libs).
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    defaultConfig {
        applicationId = "com.mpsec.mpsecnet"
        minSdk = maxOf(flutter.minSdkVersion, 23)
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    flavorDimensions += "env"
    productFlavors {
        create("dev") {
            dimension = "env"
            applicationIdSuffix = ".dev"
            resValue("string", "app_name", "MPSeCNet DEV")
        }
        create("prod") {
            dimension = "env"
            resValue("string", "app_name", "MPSeCNet")
        }
    }

    signingConfigs {
        if (hasReleaseKeystore) {
            create("release") {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = rootProject.file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            // Store builds require android/key.properties + upload keystore.
            // Missing secrets fail at assemble/bundle*Release (see afterEvaluate below),
            // not at Gradle configuration, so debug/profile sync still works.
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

afterEvaluate {
    tasks.matching {
        it.name.matches(Regex("assemble(.*)Release|bundle(.*)Release"))
    }.configureEach {
        doFirst {
            if (!hasReleaseKeystore) {
                throw GradleException(
                    "Missing android/key.properties. Copy android/key.properties.example " +
                        "and create upload-keystore.jks before building a release AAB/APK. " +
                        "See docs/STORE_RELEASE_CHECKLIST.md.",
                )
            }
            val storeFileName = keystoreProperties["storeFile"] as String?
            val store = storeFileName?.let { rootProject.file(it) }
            if (store == null || !store.exists()) {
                throw GradleException(
                    "Release keystore not found (${store?.path}). " +
                        "See android/key.properties.example and docs/STORE_RELEASE_CHECKLIST.md.",
                )
            }
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_11)
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
