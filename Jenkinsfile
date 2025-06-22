pipeline {
    agent any

    tools {
        maven "Maven3"
        jdk "Java21"   // Use Java11 if your app supports it
    }

    environment {
        SONARQUBE_ENV = 'MySonarQube'
        NEXUS_CREDENTIAL_ID = 'nexus-new'
        NEXUS_URL = '35.153.175.117:8081'
        NEXUS_REPOSITORY = 'ncodeit-hello-world'
        DOCKER_IMAGE = 'manikiran7/ncodeit-hello-world'
        DOCKERHUB_CREDENTIALS = 'dockerhub-creds'
        TOMCAT_URL = 'http://13.219.99.189:8081/manager/text'
        TOMCAT_CREDENTIALS = 'tomcat-manager-credentials'
        SLACK_CHANNEL = '#team'
        SLACK_CREDENTIALS = 'slack-token'
        NVM_DIR = "$HOME/.nvm"
        PATH = "${NVM_DIR}/versions/node/v16.20.2/bin:${PATH}"
        SKIP_SONAR = 'true'       // Change to 'false' to enable
        SKIP_TESTS = 'true'       // Change to 'false' to run tests
    }

    stages {
        stage('Checkout') {
            steps {
                deleteDir()
                wrap([$class: 'AnsiColorBuildWrapper', 'colorMapName': 'xterm']) {
                    git branch: 'main', url: 'https://github.com/manikiran7/spring3.git'
                }
            }
        }

        stage('Code Quality - SonarQube') {
            when {
                expression { return env.SKIP_SONAR != 'true' }
            }
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
                    sh '''
                        if [ "$SKIP_TESTS" = "true" ]; then
                            mvn clean install -DskipTests
                        else
                            mvn clean install
                        fi
                    '''
                }
            }
        }

        stage('Upload to Nexus') {
            steps {
                wrap([$class: 'AnsiColorBuildWrapper', 'colorMapName': 'xterm']) {
                    script {
                        def artifactPath = "target/ncodeit-hello-world-3.0.war"
                        if (!fileExists(artifactPath)) {
                            error "WAR file not found: ${artifactPath}"
                        }

                        nexusArtifactUploader(
                            nexusVersion: 'nexus3',
                            protocol: 'http',
                            nexusUrl: NEXUS_URL,
                            groupId: 'com.ncodeit',
                            version: "${BUILD_NUMBER}",
                            repository: NEXUS_REPOSITORY,
                            credentialsId: NEXUS_CREDENTIAL_ID,
                            artifacts: [[
                                artifactId: 'ncodeit-hello-world',
                                classifier: '',
                                file: artifactPath,
                                type: 'war'
                            ]]
                        )
                    }
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                wrap([$class: 'AnsiColorBuildWrapper', 'colorMapName': 'xterm']) {
                    script {
                        def warFile = "target/ncodeit-hello-world-3.0.war"
                        if (!fileExists(warFile)) {
                            error("WAR file not found! Ensure Maven build was successful.")
                        }

                        // Cleanup old containers and images
                        sh """
                        docker ps -a --filter "ancestor=${DOCKER_IMAGE}" --format "{{.ID}}" | xargs -r docker stop || true
                        docker ps -a --filter "ancestor=${DOCKER_IMAGE}" --format "{{.ID}}" | xargs -r docker rm || true
                        docker images ${DOCKER_IMAGE} --format "{{.Repository}}:{{.Tag}}" | grep -v ":${BUILD_NUMBER}" | xargs -r docker rmi || true
                        """

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
                    withCredentials([usernamePassword(credentialsId: TOMCAT_CREDENTIALS, usernameVariable: 'TOMCAT_USER', passwordVariable: 'TOMCAT_PASS')]) {
                        sh '''
                            curl -v -T target/ncodeit-hello-world-3.0.war \
                            -u $TOMCAT_USER:$TOMCAT_PASS \
                            "http://13.219.99.189:8081/manager/text/deploy?path=/maniapp&update=true"
                        '''
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
                message: "✅ Job '${env.JOB_NAME} [${env.BUILD_NUMBER}]' succeeded: ${env.BUILD_URL}"
            )
        }
        failure {
            slackSend(
                channel: "${env.SLACK_CHANNEL}",
                color: "danger",
                message: "❌ Job '${env.JOB_NAME} [${env.BUILD_NUMBER}]' failed: ${env.BUILD_URL}"
            )
        }
    }
}
