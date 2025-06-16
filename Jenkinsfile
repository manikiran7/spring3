pipeline {
    agent any

    tools {
        maven 'Maven3'
        jdk 'Java21'
    }

    environment {
        NEXUS_CREDENTIALS_ID = 'nexus-new'
        DOCKERHUB_CREDS = 'dockerhub-creds'
        IMAGE_NAME = 'manikiran7/simple-customer-app'
        SONARQUBE_ENV = 'MySonarQube'
    }

    stages {
        stage('Checkout') {
            steps {
                git branch: 'clean-simple', url: 'https://github.com/betawins/hiring-app.git'
            }
        }

        stage('SonarQube Analysis') {
            steps {
                withSonarQubeEnv("${SONARQUBE_ENV}") {
                    sh 'mvn sonar:sonar'
                }
            }
        }

        stage('Maven Build') {
            steps {
                sh 'mvn clean install'
            }
        }

        stage('Upload to Nexus') {
            steps {
                script {
                    def pom = readMavenPom file: 'pom.xml'
                    def artifactPath = "target/${pom.artifactId}-${pom.version}.war"
                    sh "ls -l ${artifactPath}"
                    nexusArtifactUploader(
                        nexusVersion: 'nexus3',
                        protocol: 'http',
                        nexusUrl: 'http://3.86.4.253:8081',
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
                    sh 'docker image prune -af'
                    def imageTag = "${IMAGE_NAME}:${env.BUILD_NUMBER}"
                    env.IMAGE_TAG = imageTag
                    sh "docker build -t ${imageTag} ."
                }
            }
        }

        stage('Push Docker Image') {
            steps {
                wrap([$class: 'AnsiColorBuildWrapper', 'colorMapName': 'xterm']) {
                    withCredentials([usernamePassword(credentialsId: DOCKERHUB_CREDS, usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                        sh """
                            echo "\$DOCKER_PASS" | docker login -u "\$DOCKER_USER" --password-stdin
                            docker tag \${IMAGE_TAG} \${IMAGE_NAME}:latest
                            docker push \${IMAGE_TAG}
                            docker push \${IMAGE_NAME}:latest
                            docker logout
                        """
                    }
                }
            }
        }

        stage('Deploy to Tomcat') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'tomcat-manager-credentials', usernameVariable: 'TOMCAT_USER', passwordVariable: 'TOMCAT_PASS')]) {
                    script {
                        def pom = readMavenPom file: 'pom.xml'
                        def warFile = "target/${pom.artifactId}-${pom.version}.war"
                        def deployPath = "/featureapp"

                        sh """
                            # Undeploy old app if exists (ignore errors)
                            curl -s -o /dev/null -w "%{http_code}" -u \$TOMCAT_USER:\$TOMCAT_PASS \\
                            "http://54.163.1.219:8080/manager/text/undeploy?path=${deployPath}" || true

                            # Deploy new WAR
                            curl --fail -u \$TOMCAT_USER:\$TOMCAT_PASS --upload-file ${warFile} \\
                            "http://54.163.1.219:8080/manager/text/deploy?path=${deployPath}&update=true"
                        """
                    }
                }
            }
        }
    }

    post {
        failure {
            slackSend(
                color: 'danger',
                message: "❌ Build failed for branch ${env.BRANCH_NAME} in job ${env.JOB_NAME} #${env.BUILD_NUMBER}",
                channel: '#team',
                tokenCredentialId: 'slack-token'
            )
        }
    }
}
