# Use Maven with Java 21 to build the application
FROM maven:3.9.6-eclipse-temurin-21

WORKDIR /app

# Copy Maven project files
COPY pom.xml .
COPY src ./src

# Build the WAR file
RUN mvn clean package -DskipTests

# WAR will be available at: /app/target/*.war

# This image is just for building — not for running
