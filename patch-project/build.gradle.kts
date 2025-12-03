plugins {
    java
}

java {
    toolchain {
        languageVersion = JavaLanguageVersion.of(8)
    }
    sourceCompatibility = JavaVersion.VERSION_1_4
    targetCompatibility = JavaVersion.VERSION_1_4
}
repositories {
    mavenCentral()
}

dependencies {
    compileOnly(files("../original/lsd.jar"))
}

// Read jar base name from -PjarBaseName=..., NOTE: you should be on a patch branch when building ie 'patch/full-screen'
val jarBaseName: String = (findProperty("jarBaseName") as String?) ?: "NOT_ON_PATCH_BRANCH"

tasks.jar {
    archiveBaseName.set(jarBaseName)
    archiveVersion.set("")   // no -version suffix
}