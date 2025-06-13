pipeline {
    agent any

    tools {
        maven "Maven3"
    }

    environment {
        SONARQUBE_ENV = 'MySonarQube'
        NEXUS_CREDENTIAL_ID = 'Nexus_server'
        NEXUS_URL = '54.80.161.60:8081'
        NEXUS_REPOSITORY = 'ncodeit-hello-world'
        DOCKER_IMAGE = 'manikiran7/ncodeit-hello-world'
        DOCKERHUB_CREDENTIALS = 'dockerhub-creds'
        TOMCAT_URL = 'http://54.163.1.219:8080/manager/text'
        TOMCAT_CREDENTIALS = 'tomcat-creds'
        SLACK_CHANNEL = '#team'
        SLACK_CREDENTIALS = 'slack-token'
    }

    stages {
        stage('Checkout') {
            steps {
                wrap([$class: 'AnsiColorBuildWrapper', 'colorMapName': 'xterm']) {
                    git branch: "${env.BRANCH_NAME}", url: 'https://github.com/manikiran7/spring3.git'
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
                wrap([$class: 'AnsiColorBuildWrapper', 'colorMapName': 'xterm']) {
                    sh "docker rmi ${DOCKER_IMAGE}:latest || true"
                    sh "docker build -t ${DOCKER_IMAGE}:${BUILD_NUMBER} ."
                    sh "docker tag ${DOCKER_IMAGE}:${BUILD_NUMBER} ${DOCKER_IMAGE}:latest"
                }
            }
        }

        stage('Push Docker Image') {
            steps {
                wrap([$class: 'AnsiColorBuildWrapper', 'colorMapName': 'xterm']) {
                    script {
                        docker.withRegistry('', DOCKERHUB_CREDENTIALS) {
                            sh "docker push ${DOCKER_IMAGE}:${BUILD_NUMBER}"
                            sh "docker push ${DOCKER_IMAGE}:latest"
                        }
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
                            "${TOMCAT_URL}/deploy?path=/spring3&update=true"
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
