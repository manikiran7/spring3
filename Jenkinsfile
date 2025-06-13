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
    }

    stages {
        stage('Checkout') {
            steps {
                git url: 'https://github.com/manikiran7/simple.git', branch: 'main'
            }
        }

        stage('Build') {
            steps {
                sh 'mvn clean package -DskipTests'
            }
        }

        stage('SonarQube Analysis') {
            steps {
                withSonarQubeEnv("${SONARQUBE_ENV}") {
                    sh 'mvn sonar:sonar -Dsonar.projectKey=SimpleCustomerApp'
                }
            }
        }

        stage('Upload to Nexus') {
            steps {
                withCredentials([usernamePassword(credentialsId: NEXUS_CREDENTIALS_ID, passwordVariable: 'NEXUS_PASSWORD', usernameVariable: 'NEXUS_USERNAME')]) {
                    sh """
                        mvn deploy -DskipTests \
                          -Dnexus.username=$NEXUS_USERNAME \
                          -Dnexus.password=$NEXUS_PASSWORD
                    """
                }
            }
        }

        stage('Deploy to Tomcat') {
            steps {
                withCredentials([usernamePassword(credentialsId: TOMCAT_CREDENTIALS_ID, usernameVariable: 'TOMCAT_USERNAME', passwordVariable: 'TOMCAT_PASSWORD')]) {
                    sh """
                        mvn tomcat7:redeploy \
                          -Dtomcat.username=$TOMCAT_USERNAME \
                          -Dtomcat.password=$TOMCAT_PASSWORD
                    """
                }
            }
        }

        stage('Docker Build & Push') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'dockerhub-creds', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                    sh """
                        echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin
                        docker build -t manikiran7/ncodeit-hello-world:${BUILD_NUMBER} .
                        docker tag manikiran7/ncodeit-hello-world:${BUILD_NUMBER} manikiran7/ncodeit-hello-world:latest
                        docker push manikiran7/ncodeit-hello-world:${BUILD_NUMBER}
                        docker push manikiran7/ncodeit-hello-world:latest
                        docker rmi manikiran7/ncodeit-hello-world:${BUILD_NUMBER} || true
                        docker rmi manikiran7/ncodeit-hello-world:latest || true
                        docker logout
                    """
                }
            }
        }
    }

    post {
        always {
            cleanWs()
            echo 'Pipeline cleanup complete.'
            slackSend (
                channel: '#team',
                color: '#CCCC00',
                message: "Project *${env.JOB_NAME}* - Build #${env.BUILD_NUMBER} finished with *${currentBuild.currentResult}* (<${env.BUILD_URL}|Open>)"
            )
        }
        success {
            slackSend (
                channel: '#team',
                color: 'good',
                message: "✅ SUCCESS: *${env.JOB_NAME}* - Build #${env.BUILD_NUMBER} deployed! (<${env.BUILD_URL}|Open>)"
            )
        }
        failure {
            slackSend (
                channel: '#team',
                color: 'danger',
                message: "❌ FAILURE: *${env.JOB_NAME}* - Build #${env.BUILD_NUMBER} failed. (<${env.BUILD_URL}|Open>)"
            )
        }
        unstable {
            slackSend (
                channel: '#team',
                color: 'warning',
                message: "⚠️ UNSTABLE: *${env.JOB_NAME}* - Build #${env.BUILD_NUMBER} unstable. (<${env.BUILD_URL}|Open>)"
            )
        }
    }
}
