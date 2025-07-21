pipeline {
    agent any

    tools {
        maven "Maven3"
        jdk "Java21"   // Use Java11 if your app supports it
    }

    environment {
        SONARQUBE_ENV = 'MySonarQube'
        NEXUS_CREDENTIAL_ID = 'nexus-new'
        NEXUS_URL = 'http://54.165.182.236:8081'
        NEXUS_REPOSITORY = 'sample'
        DOCKER_IMAGE = 'manikiran7/firstrepo'
        DOCKERHUB_CREDENTIALS = 'docker-creds'
        TOMCAT_URL = 'http://54.165.182.236:8083/manager/text'
        TOMCAT_CREDENTIALS = 'tomcat-creds'
        NVM_DIR = "$HOME/.nvm"
        PATH = "${NVM_DIR}/versions/node/v16.20.2/bin:${PATH}"
        SKIP_SONAR = 'true'       // Change to 'false' to enable
        SKIP_TESTS = 'true'       // Change to 'false' to run tests
    }

    stages {
        stage('Checkout') {
            steps {
                deleteDir()
                git branch: 'main', url: 'https://github.com/manikiran7/spring3.git'
            }
        }

        stage('Code Quality - SonarQube') {
            when {
                expression { return env.SKIP_SONAR != 'true' }
            }
            steps {
                withSonarQubeEnv("${SONARQUBE_ENV}") {
                    sh "mvn clean verify sonar:sonar"
                }
            }
        }

        stage('Maven Build') {
            steps {
                sh '''
                    if [ "$SKIP_TESTS" = "true" ]; then
                        mvn clean install -DskipTests
                    else
                        mvn clean install
                    fi
                '''
            }
        }

        stage('Upload to Nexus') {
            steps {
                script {
                    def artifactPath = "target/ncodeit-hello-world-3.0.war"
                    if (!fileExists(artifactPath)) {
                        error "WAR file not found: ${artifactPath}"
                    }
                    withCredentials([usernamePassword(credentialsId: NEXUS_CREDENTIAL_ID, usernameVariable: 'NEXUS_USER', passwordVariable: 'NEXUS_PASS')]) {
                        sh """
                        curl -v -u $NEXUS_USER:$NEXUS_PASS \
                        --upload-file ${artifactPath} \
                        ${NEXUS_URL}/repository/${NEXUS_REPOSITORY}/com/ncodeit/ncodeit-hello-world/${BUILD_NUMBER}/ncodeit-hello-world-${BUILD_NUMBER}.war
                        """
                    }
                }
            }
        }

        stage('Build Docker Image') {
            steps {
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

        stage('Push Docker Image') {
            steps {
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

        stage('Deploy to Tomcat') {
            steps {
                withCredentials([usernamePassword(credentialsId: TOMCAT_CREDENTIALS, usernameVariable: 'TOMCAT_USER', passwordVariable: 'TOMCAT_PASS')]) {
                    sh '''
                        curl -v -T target/ncodeit-hello-world-3.0.war \
                        -u $TOMCAT_USER:$TOMCAT_PASS \
                        "http://54.165.182.236:8083/manager/text/deploy?path=/maniapp&update=true"
                    '''
                }
            }
        }
    }
}
