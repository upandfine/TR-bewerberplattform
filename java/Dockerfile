# Maven + Eclipse Temurin 21 (LTS). Bewusst keine Multi-Stage,
# damit Teilnehmende direkt `mvn` im Container ausfuehren koennen.
FROM maven:3.9-eclipse-temurin-21

# Maven-Cache liegt AUSSERHALB des Bind-Mount (/work) -> bleibt
# zwischen Builds erhalten, analog zu .NET (NUGET_PACKAGES).
ENV MAVEN_OPTS="-Dmaven.repo.local=/maven-cache" \
    MAVEN_CLI_OPTS="-B -Dmaven.repo.local=/maven-cache"

WORKDIR /work

# pom.xml zuerst kopieren und Abhaengigkeiten vorab herunterladen,
# damit das Image den Maven-Cache schon bestueckt mitbringt.
COPY pom.xml /work/pom.xml
RUN mvn -B -Dmaven.repo.local=/maven-cache dependency:go-offline -q || true

EXPOSE 8080
CMD ["mvn", "-B", "-Dmaven.repo.local=/maven-cache", "spring-boot:run", \
     "-Dspring-boot.run.jvmArguments=-Dserver.address=0.0.0.0 -Dserver.port=8080"]
