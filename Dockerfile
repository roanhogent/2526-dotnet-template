ARG REGISTRY_BASE=mcr
ARG REGISTRY_DOMAIN=microsoft.com

# Fase 1: Runtime-omgeving instellen
FROM ${REGISTRY_BASE}.${REGISTRY_DOMAIN}/dotnet/aspnet:9.0 AS base
WORKDIR /app
EXPOSE 5000

RUN mkdir -p /app/data && chown -R www-data:www-data /app/data
USER www-data

# Fase 2: Bouwen en publiceren
FROM ${REGISTRY_BASE}.${REGISTRY_DOMAIN}/dotnet/sdk:9.0 AS build
WORKDIR /src

# 1. Kopieer de solution file
COPY ["Rise.sln", "./"]

# 2. Kopieer de broncode projectbestanden (src/)
COPY ["src/Rise.Server/Rise.Server.csproj", "src/Rise.Server/"]
COPY ["src/Rise.Domain/Rise.Domain.csproj", "src/Rise.Domain/"]
COPY ["src/Rise.Services/Rise.Services.csproj", "src/Rise.Services/"]
COPY ["src/Rise.Persistence/Rise.Persistence.csproj", "src/Rise.Persistence/"]
COPY ["src/Rise.Shared/Rise.Shared.csproj", "src/Rise.Shared/"]
COPY ["src/Rise.Client/Rise.Client.csproj", "src/Rise.Client/"]

# 3. GEFIXT: Kopieer ook de test-projectbestanden (tests/) zodat de solution compleet is voor de restore!
COPY ["tests/Rise.Domain.Tests/Rise.Domain.Tests.csproj", "tests/Rise.Domain.Tests/"]
COPY ["tests/Rise.Services.Tests/Rise.Services.Tests.csproj", "tests/Rise.Services.Tests/"]
COPY ["tests/Rise.Client.Tests/Rise.Client.Tests.csproj", "tests/Rise.Client.Tests/"]

# Nu zal de restore vlekkeloos slagen!
RUN dotnet restore "Rise.sln"

# Kopieer de rest van alle broncode bestanden en bouw de applicatie
COPY . .
RUN dotnet build "Rise.sln" -c Release --no-restore

FROM build AS publish
RUN dotnet publish "src/Rise.Server/Rise.Server.csproj" -c Release -o /app/publish --no-build

# Fase 3: Definitieve container samenstellen
FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .

ENV ASPNETCORE_URLS=http://+:5000
ENV ASPNETCORE_ENVIRONMENT=Production

ENTRYPOINT ["dotnet", "Rise.Server.dll"]
