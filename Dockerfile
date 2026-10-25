# Fase 1: Runtime-omgeving instellen (Lichte productie-image)
FROM ://microsoft.com AS base
WORKDIR /app
EXPOSE 5000

# Maak de vaste map aan voor de SQLite-database binnen de container
RUN mkdir -p /app/data && chown -R www-data:www-data /app/data
USER www-data

# Fase 2: Bouwen en publiceren (Zware SDK-image)
FROM ://microsoft.com AS build
WORKDIR /src

# Kopieer de solution en alle projectbestanden los om NuGet-dependencies effectief te cachen
COPY ["Rise.sln", "./"]
COPY ["src/Rise.Server/Rise.Server.csproj", "src/Rise.Server/"]
COPY ["src/Rise.Domain/Rise.Domain.csproj", "src/Rise.Domain/"]
COPY ["src/Rise.Services/Rise.Services.csproj", "src/Rise.Services/"]
COPY ["src/Rise.Persistence/Rise.Persistence.csproj", "src/Rise.Persistence/"]
COPY ["src/Rise.Shared/Rise.Shared.csproj", "src/Rise.Shared/"]
COPY ["src/Rise.Client/Rise.Client.csproj", "src/Rise.Client/"]

# Herstel alle NuGet-pakketten
RUN dotnet restore "Rise.sln"

# Kopieer de rest van de broncode en compileer de applicatie
COPY . .
RUN dotnet build "Rise.sln" -c Release --no-restore

# Publiceer de code naar de appmap
FROM build AS publish
RUN dotnet publish "src/Rise.Server/Rise.Server.csproj" -c Release -o /app/publish --no-build

# Fase 3: Definitieve container samenstellen
FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .

# Configureer de omgevingsvariabelen voor productie en netwerkpoorten
ENV ASPNETCORE_URLS=http://+:5000
ENV ASPNETCORE_ENVIRONMENT=Production

ENTRYPOINT ["dotnet", "Rise.Server.dll"]
