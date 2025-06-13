# Stage 1: Build the WAR using Maven with Java 21
FROM maven:3.9.6-eclipse-temurin-21 AS builder

WORKDIR /app

COPY pom.xml .
COPY src ./src

# Build WAR
RUN mvn clean package -DskipTests

# Stage 2: Runtime with WAR deployed to Tomcat
FROM tomcat:9.0-jdk21-temurin

WORKDIR /usr/local/tomcat

# Clean default apps
RUN rm -rf webapps/*

# Copy WAR from builder stage to webapps with correct name
COPY --from=builder /app/target/*.war webapps/featureapp.war

EXPOSE 8080

CMD ["catalina.sh", "run"]
