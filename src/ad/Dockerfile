FROM eclipse-temurin:21-jdk AS builder

WORKDIR /usr/src/app/

COPY ./src/ad/gradlew ./src/ad/settings.gradle ./src/ad/build.gradle ./
COPY ./src/ad/gradle ./gradle

RUN chmod +x ./gradlew
RUN ./gradlew --no-daemon downloadRepos

COPY ./src/ad/ .
COPY ./pb ./proto
RUN ./gradlew --no-daemon installDist -PprotoSourceDir=./proto

#####################################################

FROM eclipse-temurin:21-jre

WORKDIR /usr/src/app/
RUN groupadd --system --gid 10001 app && useradd --system --uid 10001 --gid app app

COPY --chown=app:app --from=builder /usr/src/app/build/install/opentelemetry-demo-ad/ ./

ENV AD_PORT=9099

USER 10001:10001
ENTRYPOINT ["./bin/Ad"]

