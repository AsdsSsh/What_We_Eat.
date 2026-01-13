plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.what_we_eat"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.what_we_eat"
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
}

flutter {
    source = "../.."
}

// Copy APKs from Gradle output to Flutter's expected output directory so
// `flutter` tooling can find generated APKs reliably.
// This task is intentionally local and is not committed to version control.
tasks.register("copyApkToFlutterOutput") {
    doLast {
        // rootProject is the Android project root; the workspace root is its parent directory
        val workspaceRoot = rootProject.projectDir.parentFile
        val destDir = workspaceRoot.resolve("build/app/outputs/flutter-apk")
        destDir.mkdirs()

        val apkFiles = fileTree("$buildDir/outputs") {
            include("**/*.apk")
        }

        if (apkFiles.isEmpty) {
            logger.lifecycle("No APKs found under: " + file("$buildDir/outputs").absolutePath)
        } else {
            apkFiles.forEach { apk ->
                copy {
                    from(apk)
                    into(destDir)
                }
                logger.lifecycle("Copied " + apk.name + " -> " + destDir.absolutePath)
            }
            logger.lifecycle("Copied " + apkFiles.files.size + " APK(s) to: " + destDir.absolutePath)
        }
    }
}

// Ensure the copy runs after any assemble task (release/debug) so CI or local builds always
// place the APK where `flutter` expects it. Use finalizedBy instead of dependsOn so the
// copy runs after the APK is produced, and use a matching query to avoid failing
// when a specific assemble task doesn't exist in a given build configuration.
tasks.matching { it.name.startsWith("assemble") }.configureEach {
    finalizedBy("copyApkToFlutterOutput")
}
