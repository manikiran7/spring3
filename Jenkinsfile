// Define a Jenkins Pipeline
pipeline {
    // Agent: Any available agent can run this pipeline
    agent any

    // Tools: Define the Maven and JDK versions to be used
    tools {
        maven 'Maven3' // Requires a Maven tool configured in Jenkins with alias 'Maven3'
        jdk 'Java21'   // Requires a JDK tool configured in Jenkins with alias 'Java21'
    }

    // Environment Variables: Define variables for credentials and SonarQube setup
    environment {
        // SonarQube server ID as configured in Jenkins
        SONARQUBE_ENV = 'MySonarQube'

        // Jenkins credential IDs for Nexus and Tomcat authentication
        NEXUS_CREDENTIALS_ID = 'nexus-deploy-credentials'
        TOMCAT_CREDENTIALS_ID = 'tomcat-manager-credentials'

        // Jenkins credential ID for Slack notifications
        SLACK_CREDENTIALS_ID = 'slack-token' // Replace with your actual Slack credential ID
    }

    // Stages: Define the different phases of the pipeline
    stages {
        // Stage: Checkout code from Git repository
        stage('Checkout') {
            steps {
                // Clone the Git repository
                git url: 'https://github.com/manikiran7/simple.git', branch: 'main'
            }
        }

        // Stage: Build the Maven project
        stage('Build') {
            steps {
                // Use the configured Maven tool to clean and package the application.
                // -DskipTests skips running unit tests during this build phase.
                sh 'mvn clean package -DskipTests'
            }
        }

        // Stage: Perform SonarQube static code analysis
        stage('SonarQube Analysis') {
            steps {
                // Execute Maven SonarQube analysis within the SonarQube environment
                // This 'withSonarQubeEnv' block links to the SonarQube server configured in Jenkins
                withSonarQubeEnv("${SONARQUBE_ENV}") {
                    // Run the Maven sonar:sonar goal with a defined project key
                    // This project key matches your pom.xml's artifactId/name
                    sh 'mvn sonar:sonar -Dsonar.projectKey=SimpleCustomerApp'
                }
            }
        }

        // Stage: Upload the built artifacts to Nexus Repository Manager
        stage('Upload to Nexus') {
            steps {
                script {
                    // Use 'withCredentials' to securely expose Nexus username and password
                    withCredentials([usernamePassword(credentialsId: NEXUS_CREDENTIALS_ID, passwordVariable: 'NEXUS_PASSWORD', usernameVariable: 'NEXUS_USERNAME')]) {
                        // Dynamically create a Maven settings.xml file with Nexus credentials
                        // This embeds the settings directly in the pipeline logic
                        def nexusSettingsContent = """<?xml version="1.0" encoding="UTF-8"?>
<settings xmlns="http://maven.apache.org/SETTINGS/1.1.0"
          xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xsi:schemaLocation="http://maven.apache.org/SETTINGS/1.1.0 http://maven.apache.org/xsd/settings-1.1.0.xsd">

  <servers>
    <server>
      <!-- The ID 'nexus' must match the distributionManagement/repository ID in your project's pom.xml -->
      <id>nexus</id>
      <username>${NEXUS_USERNAME}</username>
      <password>${NEXUS_PASSWORD}</password>
    </server>
  </servers>

  <mirrors>
    <mirror>
      <id>nexus-all-repos</id>
      <name>Nexus Public Repository All</name>
      <!-- This URL should point to your Nexus public group or release repository -->
      <url>http://54.172.209.151:8081/repository/maven-public/</url>
      <mirrorOf>*</mirrorOf> <!-- Mirrors all repositories, ensuring all dependencies come from Nexus -->
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
                        // Write the content to a temporary settings.xml file in the workspace
                        writeFile(file: 'nexus-settings.xml', text: nexusSettingsContent)
                        
                        // Execute Maven deploy, skipping tests and using the dynamically created settings file
                        // The 'withMaven' step ensures the configured 'Maven3' tool is used.
                        sh "mvn deploy -DskipTests -s nexus-settings.xml"
                    }
                }
            }
        }

        // Stage: Deploy the WAR file to Tomcat
        stage('Deploy to Tomcat') {
            steps {
                script {
                    // Use 'withCredentials' to securely expose Tomcat username and password
                    withCredentials([usernamePassword(credentialsId: TOMCAT_CREDENTIALS_ID, passwordVariable: 'TOMCAT_PASSWORD', usernameVariable: 'TOMCAT_USERNAME')]) {
                        // Dynamically create a Maven settings.xml file specific for Tomcat deployment
                        def tomcatSettingsContent = """<?xml version="1.0" encoding="UTF-8"?>
<settings xmlns="http://maven.apache.org/SETTINGS/1.1.0"
          xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xsi:schemaLocation="http://maven.apache.org/SETTINGS/1.1.0 http://maven.apache.org/xsd/settings-1.1.0.xsd">

  <servers>
    <server>
      <!-- The ID 'tomcat-server' must match the <id> configured in your project's pom.xml
           for the tomcat7-maven-plugin or similar deployment plugin. -->
      <id>tomcat-server</id>
      <username>${TOMCAT_USERNAME}</username>
      <password>${TOMCAT_PASSWORD}</password>
    </server>
  </servers>
</settings>
"""
                        // Write the content to a temporary settings.xml file
                        writeFile(file: 'tomcat-settings.xml', text: tomcatSettingsContent)

                        // Execute Maven tomcat7:redeploy goal, using the dynamically created settings file
                        // The 'withMaven' step ensures the configured 'Maven3' tool is used.
                        sh "mvn tomcat7:redeploy -s tomcat-settings.xml"
                    }
                }
            }
        }
    }

    // Post-build actions: Define actions to run after all stages
    post {
        // Always execute this block, regardless of build status
        always {
            cleanWs() // Clean the workspace, removing all generated files, including the temporary settings.xml files
            echo 'Pipeline cleanup complete.'
            // Send a Slack notification for the overall build status
            slackSend (
                channel: '#team', // Replace with your Slack channel
                color: '#CCCC00', // Yellow for always
                message: "Project *${env.JOB_NAME}* - Build #${env.BUILD_NUMBER} has finished with status: *${currentBuild.currentResult}* (<${env.BUILD_URL}|Open in Jenkins>)"
            )
        }
        // Execute this block only if the pipeline succeeds
        success {
            echo 'Pipeline finished successfully!'
            // Send a success Slack notification
            slackSend (
                channel: '#team', // Replace with your Slack channel
                color: 'good',    // Green for success
                message: "SUCCESS: Project *${env.JOB_NAME}* - Build #${env.BUILD_NUMBER} deployed successfully! (<${env.BUILD_URL}|Open in Jenkins>)"
            )
        }
        // Execute this block only if the pipeline fails
        failure {
            echo 'Pipeline failed!'
            // Send a failure Slack notification
            slackSend (
                channel: '#team', // Replace with your Slack channel
                color: 'danger',  // Red for failure
                message: "FAILURE: Project *${env.JOB_NAME}* - Build #${env.BUILD_NUMBER} failed! (<${env.BUILD_URL}|Open in Jenkins>)"
            )
        }
        // Execute this block only if the pipeline is unstable (e.g., SonarQube quality gate failed)
        unstable {
            // Send an unstable Slack notification
            slackSend (
                channel: '#team', // Replace with your Slack channel
                color: 'warning', // Orange for unstable
                message: "UNSTABLE: Project *${env.JOB_NAME}* - Build #${env.BUILD_NUMBER} is unstable! (<${env.BUILD_URL}|Open in Jenkins>)"
            )
        }
    }
}
