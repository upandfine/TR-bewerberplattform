# Maven + Eclipse Temurin 21 fuer Kotlin/Ktor. Bewusst keine
# Multi-Stage - Teilnehmende koennen direkt `mvn` im Container nutzen.
FROM maven:3.9-eclipse-temurin-21

# Maven-Cache liegt AUSSERHALB des Bind-Mount (/work),
# damit Restore Builds ueberdauert (analog zu .NET/Java).
ENV MAVEN_OPTS="-Dmaven.repo.local=/maven-cache"

WORKDIR /work

# pom.xml zuerst kopieren und Dependencies vorab ziehen.
COPY pom.xml /work/pom.xml
RUN mvn -B -Dmaven.repo.local=/maven-cache dependency:go-offline -q || true

EXPOSE 8080
CMD ["mvn", "-B", "-Dmaven.repo.local=/maven-cache", "-q", "compile", "exec:java"]
