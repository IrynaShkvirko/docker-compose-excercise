FROM eclipse-temurin:17-jre

ENV DB_USER=appuser \
    DB_PWD=apppassword \
    DB_SERVER=db \
    DB_NAME=appdb

RUN mkdir -p /usr/app

COPY ./build/libs/docker-exercises-project-1.0-SNAPSHOT.jar /usr/app
WORKDIR /usr/app

CMD ["java", "-jar", "docker-exercises-project-1.0-SNAPSHOT.jar"]
