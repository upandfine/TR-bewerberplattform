# .NET 9 SDK - enthält dotnet-Compiler/-Runtime + Test-Tools.
# Bewusst kein separater Runtime-Container (Multi-Stage), damit
# Teilnehmende direkt 'dotnet test' im Container ausführen können.
FROM mcr.microsoft.com/dotnet/sdk:9.0

ENV DOTNET_CLI_TELEMETRY_OPTOUT=1 \
    DOTNET_NOLOGO=1 \
    # NuGet-Cache außerhalb des bind-gemounteten /work,
    # damit er Builds überdauert.
    NUGET_PACKAGES=/nuget-packages

WORKDIR /work

# .csproj-Dateien zuerst kopieren und Pakete restoren -> Image
# enthält alle Abhängigkeiten, spätere "dotnet run/test" sind schnell.
COPY src/Bewerbung.Api/Bewerbung.Api.csproj src/Bewerbung.Api/
COPY tests/Bewerbung.Tests/Bewerbung.Tests.csproj tests/Bewerbung.Tests/
RUN dotnet restore src/Bewerbung.Api \
 && dotnet restore tests/Bewerbung.Tests

EXPOSE 8080
CMD ["dotnet", "run", "--project", "src/Bewerbung.Api", \
     "--no-launch-profile", "--urls", "http://0.0.0.0:8080"]
