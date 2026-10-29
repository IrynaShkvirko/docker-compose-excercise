FROM eclipse-temurin:17-jre
EXPOSE 8080
RUN mkdir -p /opt/app
COPY ./build/libs/docker-exercises-project-1.0-SNAPSHOT.jar /opt/app
WORKDIR /opt/app
CMD ["java", "-jar", "docker-exercises-project-1.0-SNAPSHOT.jar"]