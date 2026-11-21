plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val deviceTest = providers.gradleProperty("healthJournalDeviceTest").orNull == "true"
val backupProbe = providers.gradleProperty("healthJournalBackupProbe").orNull == "true"
require(!backupProbe || deviceTest) { "The backup probe requires the isolated device-test build." }
val distribution = providers.gradleProperty("healthJournalDistribution").orNull == "true"
require(!deviceTest || !distribution) {
    "The isolated device-test package cannot use distribution signing."
}

android {
    namespace = "com.repasscloud.healthjournal"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    buildFeatures { buildConfig = true }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.repasscloud.healthjournal"
        manifestPlaceholders["journalAppLabel"] = "Health Journal"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    val distributionSigning = if (distribution) {
        fun signingValue(name: String): String =
            providers.environmentVariable(name).orNull?.takeIf { it.isNotBlank() }
                ?: error("Missing signing environment variable: $name")

        val signingStore = file(signingValue("HEALTH_JOURNAL_KEYSTORE"))
        require(signingStore.isFile) { "Android signing keystore could not be opened." }
        signingConfigs.create("distribution") {
            storeFile = signingStore
            storePassword = signingValue("HEALTH_JOURNAL_STORE_PASSWORD")
            keyAlias = signingValue("HEALTH_JOURNAL_KEY_ALIAS")
            keyPassword = signingValue("HEALTH_JOURNAL_KEY_PASSWORD")
        }
    } else null

    flavorDimensions += "environment"
    productFlavors {
        create("production") {
            dimension = "environment"
            signingConfig = distributionSigning ?: signingConfigs.getByName("debug")
            if (deviceTest) {
                applicationIdSuffix = if (backupProbe) ".backupprobe" else ".devicetest"
                manifestPlaceholders["journalAppLabel"] =
                    if (backupProbe) "Health Journal Backup Probe" else "Health Journal Device Test"
            }
        }
        create("review") {
            dimension = "environment"
            signingConfig = signingConfigs.getByName("debug")
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

val verifyRxTermsCatalogue by tasks.registering(Exec::class) {
    workingDir(rootProject.projectDir.parentFile)
    commandLine("python3", "tool/rxterms/catalogue.py", "verify")
}
tasks.matching { it.name.startsWith("compileFlutterBuild") }.configureEach {
    dependsOn(verifyRxTermsCatalogue)
}
