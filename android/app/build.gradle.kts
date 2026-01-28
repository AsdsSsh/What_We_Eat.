plugins {
    id("com.android.application")
    id("kotlin-android")
    // Flutter Gradle 插件必须在 Android 和 Kotlin Gradle 插件之后应用。
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
        // TODO: 指定你自己的唯一应用 ID (https://developer.android.com/studio/build/application-id.html)。
        applicationId = "com.example.what_we_eat"
        // 你可以更新以下值以匹配你的应用需求。
        // 详情请参见: https://flutter.dev/to/review-gradle-config。
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: 为 release 构建添加你自己的签名配置。
            // 暂时使用 debug 密钥进行签名，以便 `flutter run --release` 能工作。
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

// 将 APK 从 Gradle 输出复制到 Flutter 期望的输出目录
// 以便`flutter` 工具能可靠地找到生成的 APK。
// 如果flutter run的时候产生问题可以尝试删除这个任务
tasks.register("copyApkToFlutterOutput") {
    doLast {
        // rootProject 是 Android 项目根目录；工作区根目录为其父目录
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

// 确保在任何 assemble 任务（release/debug）之后运行复制操作，这样 CI 或本地构建总是
// 将 APK 放在 `flutter` 期望的位置。使用 finalizedBy 而不是 dependsOn，以便在 APK 生成之后运行复制，
// 并使用匹配查询以避免在某些构建配置中某个特定的 assemble 任务不存在时失败。
tasks.matching { it.name.startsWith("assemble") }.configureEach {
    finalizedBy("copyApkToFlutterOutput")
}
