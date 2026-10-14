plugins {
    kotlin("multiplatform")
}

kotlin {
    val xcfName = "SharedKit"

    iosArm64 {
        binaries.framework {
            baseName = xcfName
            isStatic = true
        }
    }
    iosSimulatorArm64 {
        binaries.framework {
            baseName = xcfName
            isStatic = true
        }
        testRuns.getByName("test") {
            deviceId = "iPhone 17"
        }
    }

    sourceSets {
        commonMain.dependencies {
        }
        commonTest.dependencies {
            implementation(kotlin("test"))
        }
    }
}
