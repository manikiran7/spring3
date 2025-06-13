# Stage 1: Build the WAR using Maven
FROM maven:3.8.5-openjdk-8 AS builder

WORKDIR /app

# Copy the Maven project files
COPY pom.xml .
COPY src ./src

# Build the WAR file
RUN mvn clean package -DskipTests

# Stage 2: Deploy to Tomcat using the built WAR
FROM tomcat:9.0

# Remove default webapps to clean image
RUN rm -rf /usr/local/tomcat/webapps/*

# Copy the WAR built in Stage 1 to ROOT.war
COPY --from=builder /app/target/*.war /usr/local/tomcat/webapps/featureapp.war

# Expose default port
EXPOSE 8080

# Start Tomcat
CMD ["catalina.sh", "run"]
