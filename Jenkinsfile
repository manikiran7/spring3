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
                git url: 'https://github.com/manikiran7/spring3.git', branch: 'main'
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
                script {
                    withCredentials([usernamePassword(credentialsId: NEXUS_CREDENTIALS_ID, passwordVariable: 'NEXUS_PASSWORD', usernameVariable: 'NEXUS_USERNAME')]) {
                        def nexusSettings = """
<settings>
  <servers>
    <server>
      <id>nexus</id>
      <username>${NEXUS_USERNAME}</username>
      <password>${NEXUS_PASSWORD}</password>
    </server>
  </servers>
</settings>
"""
                        writeFile(file: 'nexus-settings.xml', text: nexusSettings)
                        sh "mvn deploy -DskipTests -s nexus-settings.xml"
                    }
                }
            }
        }

        stage('Docker Build & Push') {
            steps {
                script {
                    withCredentials([usernamePassword(credentialsId: 'dockerhub-creds', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                        def imageTag = "manikiran7/simple-customer-app:${env.BUILD_NUMBER}"
                        sh """
                            docker build -t ${imageTag} .
                            echo "${DOCKER_PASS}" | docker login -u "${DOCKER_USER}" --password-stdin
                            docker push ${imageTag}
                            docker tag ${imageTag} manikiran7/simple-customer-app:latest
                            docker push manikiran7/simple-customer-app:latest
                            docker rmi ${imageTag} manikiran7/simple-customer-app:latest || true
                        """
                    }
                }
            }
        }

        stage('Deploy to Tomcat') {
            steps {
                script {
                    withCredentials([usernamePassword(credentialsId: TOMCAT_CREDENTIALS_ID, passwordVariable: 'TOMCAT_PASSWORD', usernameVariable: 'TOMCAT_USERNAME')]) {
                        def tomcatSettings = """
<settings>
  <servers>
    <server>
      <id>tomcat-server</id>
      <username>${TOMCAT_USERNAME}</username>
      <password>${TOMCAT_PASSWORD}</password>
    </server>
  </servers>
</settings>
"""
                        writeFile(file: 'tomcat-settings.xml', text: tomcatSettings)
                        sh "mvn tomcat7:redeploy -s tomcat-settings.xml"
                    }
                }
            }
        }
    }

    post {
        always {
            cleanWs()
            slackSend (
                channel: '#team',
                color: '#CCCC00',
                message: "Project *${env.JOB_NAME}* - Build #${env.BUILD_NUMBER} has finished with status: *${currentBuild.currentResult}* (<${env.BUILD_URL}|Open>)"
            )
        }
        success {
            slackSend (
                channel: '#team',
                color: 'good',
                message: "✅ SUCCESS: *${env.JOB_NAME}* - Build #${env.BUILD_NUMBER} deployed successfully!"
            )
        }
        failure {
            slackSend (
                channel: '#team',
                color: 'danger',
                message: "❌ FAILURE: *${env.JOB_NAME}* - Build #${env.BUILD_NUMBER} failed!"
            )
        }
        unstable {
            slackSend (
                channel: '#team',
                color: 'warning',
                message: "⚠️ UNSTABLE: *${env.JOB_NAME}* - Build #${env.BUILD_NUMBER} is unstable!"
            )
        }
    }
}
