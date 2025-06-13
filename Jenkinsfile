pipeline {
    agent any

    tools {
        maven 'Maven3'
        jdk 'Java21'
    }

    environment {
        SONARQUBE_ENV = 'MySonarQube'
        NEXUS_CREDENTIALS_ID = 'nexus-deploy-credentials'
        TOMCAT_CREDENTIALS_ID = 'tomcat-manager-credentials'
        SLACK_CREDENTIALS_ID = 'slack-token'
        DOCKER_IMAGE = 'manikiran7/simple-customer-app'
        DOCKERHUB_CREDENTIALS = 'dockerhub-creds'
    }

    stages {
        stage('Checkout') {
            steps {
                git url: 'https://github.com/manikiran7/simple.git', branch: 'main'
            }
        }

        stage('Code Quality - SonarQube') {
            steps {
                withSonarQubeEnv("${SONARQUBE_ENV}") {
                    sh "mvn clean verify sonar:sonar"
                }
            }
        }

        stage('Build WAR') {
            steps {
                sh 'mvn clean package -DskipTests'
            }
        }

        stage('Upload to Nexus') {
    steps {
        script {
            def pom = readMavenPom file: 'pom.xml'
            def artifactPath = "target/${pom.artifactId}-${pom.version}.war"
            echo "Uploading WAR file: ${artifactPath}"

            nexusArtifactUploader(
                nexusVersion: 'nexus3',
                protocol: 'http',
                nexusUrl: '54.80.161.60:8081',
                groupId: pom.groupId,
                version: pom.version,
                repository: 'SimpleCustomerApp',
                credentialsId: NEXUS_CREDENTIALS_ID,
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


        stage('Build Docker Image') {
            steps {
                script {
                    def imageTag = "${DOCKER_IMAGE}:${BUILD_NUMBER}"
                    def imageLatest = "${DOCKER_IMAGE}:latest"
                    sh "docker rmi ${imageTag} || true"
                    sh "docker rmi ${imageLatest} || true"
                    sh "docker build -t ${imageTag} ."
                    sh "docker tag ${imageTag} ${imageLatest}"
                }
            }
        }

        stage('Push Docker Image') {
            steps {
                withCredentials([usernamePassword(credentialsId: DOCKERHUB_CREDENTIALS, usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                    sh '''
                        echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin
                        docker push manikiran7/simple-customer-app:${BUILD_NUMBER}
                        docker push manikiran7/simple-customer-app:latest
                        docker logout
                    '''
                }
            }
        }

        stage('Deploy to Tomcat') {
            steps {
                script {
                    def pom = readMavenPom file: 'pom.xml'
                    withCredentials([usernamePassword(credentialsId: TOMCAT_CREDENTIALS_ID, usernameVariable: 'TOMCAT_USER', passwordVariable: 'TOMCAT_PASS')]) {
                        sh """
                        curl -T target/${pom.artifactId}-${pom.version}.war \\
                        -u $TOMCAT_USER:$TOMCAT_PASS \\
                        "http://3.84.89.87:8080/manager/text/deploy?path=/featureapp&update=true"
                        """
                    }
                }
            }
        }
    }

    post {
        success {
            slackSend(
                channel: "#team",
                color: "good",
                message: "✅ Job '${env.JOB_NAME} [${env.BUILD_NUMBER}]' succeeded: ${env.BUILD_URL}"
            )
        }
        failure {
            slackSend(
                channel: "#team",
                color: "danger",
                message: "❌ Job '${env.JOB_NAME} [${env.BUILD_NUMBER}]' failed: ${env.BUILD_URL}"
            )
        }
    }
}
