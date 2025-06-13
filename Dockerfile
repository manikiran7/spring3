FROM tomcat:9-jdk8
COPY app.war /usr/local/tomcat/webapps/spring3.war
