FROM tomcat:9-jdk8
COPY target/ncodeit-hello-world-3.0.war /usr/local/tomcat/webapps/spring3.war
