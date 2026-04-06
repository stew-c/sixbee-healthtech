FROM mcr.microsoft.com/dotnet/sdk:10.0-preview AS build
WORKDIR /src

COPY SixBee.sln .
COPY src/api/SixBee.Api.csproj src/api/

# Copy class library projects if they exist (added in later tasks)
COPY src/SixBee.Core/*.csproj src/SixBee.Core/
COPY src/SixBee.Appointments/*.csproj src/SixBee.Appointments/
COPY src/SixBee.Appointments.Data/*.csproj src/SixBee.Appointments.Data/
COPY src/SixBee.Auth/*.csproj src/SixBee.Auth/
COPY src/SixBee.Auth.Data/*.csproj src/SixBee.Auth.Data/
COPY src/SixBee.Migrations/*.csproj src/SixBee.Migrations/

RUN dotnet restore src/api/SixBee.Api.csproj

COPY . .
RUN dotnet publish src/api/SixBee.Api.csproj -c Release -o /app/publish

FROM mcr.microsoft.com/dotnet/aspnet:10.0-preview AS runtime
WORKDIR /app
COPY --from=build /app/publish .
ENV ASPNETCORE_URLS=http://+:5000
ENTRYPOINT ["dotnet", "SixBee.Api.dll"]
