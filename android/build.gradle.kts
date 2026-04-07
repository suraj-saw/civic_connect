allprojects {
    repositories {
        google()
        mavenCentral()
        val mapboxDownloadsToken = providers.gradleProperty("MAPBOX_DOWNLOADS_TOKEN").orNull
        if (!mapboxDownloadsToken.isNullOrBlank()) {
            maven("https://api.mapbox.com/downloads/v2/releases/maven") {
                credentials {
                    username = "mapbox"
                    password = mapboxDownloadsToken
                }
                authentication {
                    create<BasicAuthentication>("basic")
                }
            }
        }
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

