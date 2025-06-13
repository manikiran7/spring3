FROM tomcat:9.0.85-jdk8

# Remove default apps
RUN rm -rf /usr/local/tomcat/webapps/*

# Add WAR file as ROOT app
COPY target/SimpleCustomerApp.war /usr/local/tomcat/webapps/ROOT.war

EXPOSE 8080
CMD ["catalina.sh", "run"]
