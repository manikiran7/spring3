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
                script {
                    withCredentials([usernamePassword(credentialsId: NEXUS_CREDENTIALS_ID, passwordVariable: 'NEXUS_PASSWORD', usernameVariable: 'NEXUS_USERNAME')]) {
                        def nexusSettingsContent = """<?xml version="1.0" encoding="UTF-8"?>
<settings xmlns="http://maven.apache.org/SETTINGS/1.1.0"
          xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xsi:schemaLocation="http://maven.apache.org/SETTINGS/1.1.0 http://maven.apache.org/xsd/settings-1.1.0.xsd">
  <servers>
    <server>
      <id>nexus</id>
      <username>${NEXUS_USERNAME}</username>
      <password>${NEXUS_PASSWORD}</password>
    </server>
  </servers>
  <mirrors>
    <mirror>
      <id>nexus-all-repos</id>
      <name>Nexus Public Repository All</name>
      <url>http://54.172.209.151:8081/repository/maven-public/</url>
      <mirrorOf>*</mirrorOf>
    </mirror>
  </mirrors>
  <profiles>
    <profile>
      <id>nexus</id>
      <activation>
        <activeByDefault>true</activeByDefault>
      </activation>
      <repositories>
        <repository>
          <id>central</id>
          <url>http://54.172.209.151:8081/repository/maven-public/</url>
          <releases><enabled>true</enabled></releases>
          <snapshots><enabled>true</enabled></snapshots>
        </repository>
      </repositories>
      <pluginRepositories>
        <pluginRepository>
          <id>central</id>
          <url>http://54.172.209.151:8081/repository/maven-public/</url>
          <releases><enabled>true</enabled></releases>
          <snapshots><enabled>true</enabled></snapshots>
        </pluginRepository>
      </pluginRepositories>
    </profile>
  </profiles>
</settings>
"""
                        writeFile(file: 'nexus-settings.xml', text: nexusSettingsContent)
                        sh "mvn deploy -DskipTests -s nexus-settings.xml"
                    }
                }
            }
        }

        stage('Deploy to Tomcat') {
            steps {
                script {
                    withCredentials([usernamePassword(credentialsId: TOMCAT_CREDENTIALS_ID, passwordVariable: 'TOMCAT_PASSWORD', usernameVariable: 'TOMCAT_USERNAME')]) {
                        def tomcatSettingsContent = """<?xml version="1.0" encoding="UTF-8"?>
<settings xmlns="http://maven.apache.org/SETTINGS/1.1.0"
          xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xsi:schemaLocation="http://maven.apache.org/SETTINGS/1.1.0 http://maven.apache.org/xsd/settings-1.1.0.xsd">
  <servers>
    <server>
      <id>tomcat-server</id>
      <username>${TOMCAT_USERNAME}</username>
      <password>${TOMCAT_PASSWORD}</password>
    </server>
  </servers>
</settings>
"""
                        writeFile(file: 'tomcat-settings.xml', text: tomcatSettingsContent)
                        sh "mvn tomcat7:redeploy -s tomcat-settings.xml"
                    }
                }
            }
        }

        stage('Docker Build & Push') {
            steps {
                script {
                    withCredentials([usernamePassword(credentialsId: 'dockerhub-creds', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                        sh '''
                            echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin
                            docker build -t manikiran7/ncodeit-hello-world:${BUILD_NUMBER} .
                            docker tag manikiran7/ncodeit-hello-world:${BUILD_NUMBER} manikiran7/ncodeit-hello-world:latest
                            docker push manikiran7/ncodeit-hello-world:${BUILD_NUMBER}
                            docker push manikiran7/ncodeit-hello-world:latest
                            docker rmi manikiran7/ncodeit-hello-world:${BUILD_NUMBER} || true
                            docker rmi manikiran7/ncodeit-hello-world:latest || true
                            docker logout
                        '''
                    }
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
                message: "Project *${env.JOB_NAME}* - Build #${env.BUILD_NUMBER} has finished with status: *${currentBuild.currentResult}* (<${env.BUILD_URL}|Open in Jenkins>)"
            )
        }
        success {
            echo 'Pipeline finished successfully!'
            slackSend (
                channel: '#team',
                color: 'good',
                message: "SUCCESS: Project *${env.JOB_NAME}* - Build #${env.BUILD_NUMBER} deployed successfully! (<${env.BUILD_URL}|Open in Jenkins>)"
            )
        }
        failure {
            echo 'Pipeline failed!'
            slackSend (
                channel: '#team',
                color: 'danger',
                message: "FAILURE: Project *${env.JOB_NAME}* - Build #${env.BUILD_NUMBER} failed! (<${env.BUILD_URL}|Open in Jenkins>)"
            )
        }
        unstable {
            slackSend (
                channel: '#team',
                color: 'warning',
                message: "UNSTABLE: Project *${env.JOB_NAME}* - Build #${env.BUILD_NUMBER} is unstable! (<${env.BUILD_URL}|Open in Jenkins>)"
            )
        }
    }
}
