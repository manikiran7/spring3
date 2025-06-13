pipeline {
    agent any

    tools {
        maven 'Maven3'
        jdk 'Java21'
    }

    environment {
        NEXUS_CREDENTIALS_ID = 'NEXUS_CREDENTIALS_ID'
        DOCKERHUB_CREDS = 'dockerhub-creds'
        IMAGE_NAME = 'manikiran7/simple-customer-app'
    }

    stages {
        stage('Checkout') {
            steps {
                git branch: env.BRANCH_NAME, url: 'https://github.com/betawins/hiring-app.git'
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
                    sh 'docker image prune -af'
                    def imageTag = "${IMAGE_NAME}:${env.BUILD_NUMBER}"
                    sh "docker build -t ${imageTag} ."
                }
            }
        }

        stage('Push Docker Image') {
            steps {
                script {
                    def imageTag = "${IMAGE_NAME}:${env.BUILD_NUMBER}"
                    docker.withRegistry('', DOCKERHUB_CREDS) {
                        sh "docker push ${imageTag}"
                    }
                }
            }
        }

        stage('Deploy to Tomcat') {
            steps {
                script {
                    def pom = readMavenPom file: 'pom.xml'
                    def warFile = "target/${pom.artifactId}-${pom.version}.war"
                    def deployPath = "/featureapp"
                    sh """
                        curl -u tomcat:tomcatpass --upload-file ${warFile} \\
                        http://54.163.1.219:8080/manager/text/deploy?path=${deployPath}&update=true
                    """
                }
            }
        }
    }

    post {
        failure {
            slackSend(
                color: 'danger',
                message: "Build failed for branch ${env.BRANCH_NAME} in job ${env.JOB_NAME} #${env.BUILD_NUMBER}",
                channel: '#team',
                tokenCredentialId: 'slack-token'
            )
        }
    }
}
