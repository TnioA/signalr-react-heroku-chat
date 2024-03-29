FROM mcr.microsoft.com/dotnet/core/aspnet:3.1 AS base
WORKDIR /app

###################
# BUILD .NET
###################
FROM mcr.microsoft.com/dotnet/core/sdk:3.1 AS build-back
WORKDIR /src
COPY ["MyApi/MyApi.csproj", "MyApi/"]
RUN dotnet restore "MyApi/MyApi.csproj"
COPY ./MyApi ./MyApi
WORKDIR /src/MyApi
RUN dotnet build "MyApi.csproj" -c Release -o /app/build
RUN dotnet publish "MyApi.csproj" -c Release -o /app/publish

###################
# BUILD REACT
###################
FROM node:14-alpine AS build-front
WORKDIR /app
COPY ./MyChat/package.json .
COPY ./MyChat/package-lock.json .
RUN npm install --only=production && npm cache clean --force
COPY ./MyChat .
RUN npm run build

###################
# FINAL
###################
FROM base AS final
WORKDIR /app
COPY --from=build-back /app/publish .
COPY --from=build-front /app/build ./wwwroot
RUN useradd -m myappuser
USER myappuser
EXPOSE 80
CMD ASPNETCORE_URLS="http://*:$PORT" dotnet MyApi.dll