pipeline {
    agent any

    tools {
        maven "Maven3"
        jdk "Java21"
    }

    environment {
        SONARQUBE_ENV = 'MySonarQube'
        NEXUS_CREDENTIAL_ID = 'nexus-new'
        NEXUS_URL = '54.80.161.60:8081'
        NEXUS_REPOSITORY = 'SimpleCustomerApp'
        DOCKER_IMAGE = 'manikiran7/simple-customer-app'
        DOCKERHUB_CREDENTIALS = 'dockerhub-creds'
        TOMCAT_URL = 'http://54.163.1.219:8080/manager/text'
        TOMCAT_CREDENTIALS = 'tomcat-manager-credentials'
        SLACK_CHANNEL = '#team'
        SLACK_CREDENTIALS = 'slack-token'
    }

    stages {
        stage('Checkout') {
            steps {
                wrap([$class: 'AnsiColorBuildWrapper', colorMapName: 'xterm']) {
                    git branch: "${env.BRANCH_NAME}", url: 'https://github.com/manikiran7/spring3.git'
                }
            }
        }

        stage('Code Quality - SonarQube') {
            steps {
                wrap([$class: 'AnsiColorBuildWrapper', colorMapName: 'xterm']) {
                    withSonarQubeEnv("${env.SONARQUBE_ENV}") {
                        sh 'mvn clean verify sonar:sonar'
                    }
                }
            }
        }

        stage('Maven Build') {
            steps {
                wrap([$class: 'AnsiColorBuildWrapper', colorMapName: 'xterm']) {
                    sh 'mvn clean package -DskipTests'
                }
            }
        }

        stage('Upload to Nexus') {
            steps {
                wrap([$class: 'AnsiColorBuildWrapper', colorMapName: 'xterm']) {
                    script {
                        def pom = readMavenPom file: 'pom.xml'
                        def artifactPath = "target/${pom.artifactId}-${pom.version}.war"
                        nexusArtifactUploader(
                            nexusVersion: 'nexus3',
                            protocol: 'http',
                            nexusUrl: "${env.NEXUS_URL}",
                            groupId: pom.groupId,
                            version: "${env.BUILD_NUMBER}",
                            repository: "${env.NEXUS_REPOSITORY}",
                            credentialsId: "${env.NEXUS_CREDENTIAL_ID}",
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
                wrap([$class: 'AnsiColorBuildWrapper', colorMapName: 'xterm']) {
                    script {
                        def pom = readMavenPom file: 'pom.xml'
                        def warPath = "target/${pom.artifactId}-${pom.version}.war"

                        if (!fileExists(warPath)) {
                            error "WAR file not found: ${warPath}"
                        }

                        sh """
                            docker ps -a --filter "ancestor=${env.DOCKER_IMAGE}" --format "{{.ID}}" | xargs -r docker stop || true
                            docker ps -a --filter "ancestor=${env.DOCKER_IMAGE}" --format "{{.ID}}" | xargs -r docker rm || true
                            docker images ${env.DOCKER_IMAGE} --format "{{.Repository}}:{{.Tag}}" | grep -v ":${BUILD_NUMBER}" | xargs -r docker rmi || true
                            docker build -t ${env.DOCKER_IMAGE}:${BUILD_NUMBER} .
                            docker tag ${env.DOCKER_IMAGE}:${BUILD_NUMBER} ${env.DOCKER_IMAGE}:latest
                        """
                    }
                }
            }
        }

        stage('Push Docker Image') {
            steps {
                wrap([$class: 'AnsiColorBuildWrapper', colorMapName: 'xterm']) {
                    withCredentials([usernamePassword(credentialsId: "${env.DOCKERHUB_CREDENTIALS}", usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                        sh """
                            echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin
                            docker push ${env.DOCKER_IMAGE}:${BUILD_NUMBER}
                            docker push ${env.DOCKER_IMAGE}:latest
                            docker logout
                        """
                    }
                }
            }
        }

        stage('Deploy to Tomcat') {
            steps {
                wrap([$class: 'AnsiColorBuildWrapper', colorMapName: 'xterm']) {
                    script {
                        def pom = readMavenPom file: 'pom.xml'
                        def warFile = "target/${pom.artifactId}-${pom.version}.war"

                        if (!fileExists(warFile)) {
                            error "WAR file not found: ${warFile}"
                        }

                        withCredentials([usernamePassword(credentialsId: "${env.TOMCAT_CREDENTIALS}", usernameVariable: 'TOMCAT_USER', passwordVariable: 'TOMCAT_PASS')]) {
                            sh """
                                curl -T "${warFile}" \\
                                -u $TOMCAT_USER:$TOMCAT_PASS \\
                                "${env.TOMCAT_URL}/deploy?path=/featureapp&update=true"
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
                channel: "${env.SLACK_CHANNEL}",
                color: "good",
                message: "✅ Job '${env.JOB_NAME} [${env.BUILD_NUMBER}]' succeeded: ${env.BUILD_URL}",
                tokenCredentialId: "${env.SLACK_CREDENTIALS}"
            )
        }

        failure {
            slackSend(
                channel: "${env.SLACK_CHANNEL}",
                color: "danger",
                message: "❌ Job '${env.JOB_NAME} [${env.BUILD_NUMBER}]' failed: ${env.BUILD_URL}",
                tokenCredentialId: "${env.SLACK_CREDENTIALS}"
            )
        }
    }
}
