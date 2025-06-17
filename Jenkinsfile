pipeline {
    agent { label 'java' }

    tools {
        maven "Maven3"
        jdk "Java21"
    }

    environment {
        SONARQUBE_ENV = 'MySonarQube'
        NEXUS_CREDENTIAL_ID = 'nexus-new'
        NEXUS_URL = '3.89.148.170:8081'
        NEXUS_REPOSITORY = 'ncodeit-hello-world'
        DOCKER_IMAGE = 'manikiran7/ncodeit-hello-world'
        DOCKERHUB_CREDENTIALS = 'dockerhub-creds'
        TOMCAT_URL = 'http://3.91.232.181:8080/manager/text'
        TOMCAT_CREDENTIALS = 'tomcat-manager-credentials'
        SLACK_CHANNEL = '#team'
        SLACK_CREDENTIALS = 'slack-token'
           JAVA_HOME = '/usr/lib/jvm/java-17-amazon-corretto.x86_64'
        PATH = "${JAVA_HOME}/bin:${env.PATH}"
    }

    stages {
        stage('Checkout') {
            steps {
                wrap([$class: 'AnsiColorBuildWrapper', 'colorMapName': 'xterm']) {
                    git branch: 'main', url: 'https://github.com/manikiran7/spring3.git'
                }
            }
        }

        stage('Code Quality - SonarQube') {
            steps {
                wrap([$class: 'AnsiColorBuildWrapper', 'colorMapName': 'xterm']) {
                    withSonarQubeEnv("${SONARQUBE_ENV}") {
                        sh "mvn clean verify sonar:sonar"
                    }
                }
            }
        }

        stage('Maven Build') {
            steps {
                wrap([$class: 'AnsiColorBuildWrapper', 'colorMapName': 'xterm']) {
                    sh "mvn clean package -DskipTests"
                }
            }
        }

        stage('Upload to Nexus') {
            steps {
                wrap([$class: 'AnsiColorBuildWrapper', 'colorMapName': 'xterm']) {
                    script {
                        def pom = readMavenPom file: 'pom.xml'
                        def artifactPath = "target/${pom.artifactId}-${pom.version}.war"
                        nexusArtifactUploader(
                            nexusVersion: 'nexus3',
                            protocol: 'http',
                            nexusUrl: NEXUS_URL,
                            groupId: pom.groupId,
                            version: BUILD_NUMBER,
                            repository: NEXUS_REPOSITORY,
                            credentialsId: NEXUS_CREDENTIAL_ID,
                            artifacts: [[
                                artifactId: pom.artifactId,
                                classifier: '',
                                file: artifactPath,
                                type: pom.packaging
                            ]]
                        )
                    }
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                dir("${WORKSPACE}") {
                    wrap([$class: 'AnsiColorBuildWrapper', 'colorMapName': 'xterm']) {
                        script {
                            if (!fileExists("target/ncodeit-hello-world-3.0.war")) {
                                error("WAR file not found! Ensure Maven build was successful.")
                            }

                            // Cleanup old containers using this image
                            sh '''
                            docker ps -a --filter "ancestor=${DOCKER_IMAGE}" --format "{{.ID}}" | xargs -r docker stop
                            docker ps -a --filter "ancestor=${DOCKER_IMAGE}" --format "{{.ID}}" | xargs -r docker rm
                            '''

                            // Delete all old tags except current build
                            sh '''
                            docker images ${DOCKER_IMAGE} --format "{{.Repository}}:{{.Tag}}" | grep -v ":${BUILD_NUMBER}" | xargs -r docker rmi || true
                            '''
                        }
                        sh "docker build -t ${DOCKER_IMAGE}:${BUILD_NUMBER} ."
                        sh "docker tag ${DOCKER_IMAGE}:${BUILD_NUMBER} ${DOCKER_IMAGE}:latest"
                    }
                }
            }
        }

        stage('Push Docker Image') {
            steps {
                wrap([$class: 'AnsiColorBuildWrapper', 'colorMapName': 'xterm']) {
                    withCredentials([usernamePassword(credentialsId: DOCKERHUB_CREDENTIALS, usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                        sh """
                        echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin
                        docker push ${DOCKER_IMAGE}:${BUILD_NUMBER}
                        docker push ${DOCKER_IMAGE}:latest
                        docker logout
                        """
                    }
                }
            }
        }

        stage('Deploy to Tomcat') {
            steps {
                wrap([$class: 'AnsiColorBuildWrapper', 'colorMapName': 'xterm']) {
                    script {
                        def pom = readMavenPom file: 'pom.xml'
                        withCredentials([usernamePassword(credentialsId: TOMCAT_CREDENTIALS, usernameVariable: 'TOMCAT_USER', passwordVariable: 'TOMCAT_PASS')]) {
                            sh """
                            curl -T target/${pom.artifactId}-${pom.version}.war \\
                            -u $TOMCAT_USER:$TOMCAT_PASS \\
                            "${TOMCAT_URL}/deploy?path=/maniapp&update=true"
                            """
                        }
                    }
                }
            }
        }
    }

    post {
        success {
            slackSend(
                channel: "${SLACK_CHANNEL}",
                color: "good",
                message: "✅ Job '${env.JOB_NAME} [${env.BUILD_NUMBER}]' succeeded: ${env.BUILD_URL}"
            )
        }
        failure {
            slackSend(
                channel: "${SLACK_CHANNEL}",
                color: "danger",
                message: "❌ Job '${env.JOB_NAME} [${env.BUILD_NUMBER}]' failed: ${env.BUILD_URL}"
            )
        }
    }
}
