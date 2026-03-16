# Setup and Installation

This document explains how to set up and run the project locally.

## Prerequisites

*   [.NET 8 SDK](https://dotnet.microsoft.com/download/dotnet/8.0)
*   [Docker](https://www.docker.com/products/docker-desktop)
*   [Git](https://git-scm.com/downloads)

## Getting Started

1.  **Clone the repository:**

    ```bash
    git clone https://github.com/your-username/Futsal.git
    cd Futsal
    ```

2.  **Run the application:**

    ```bash
    cd FutsalApi/FutsalApi.AppHost
    dotnet run
    ```

This will start the application and all its dependencies using the Aspire AppHost. You can then access the API at the URLs listed in the console output.

## Environment Matrix

Use the following matrix to keep the Flutter and Web clients aligned to the same API route roots (`User`, `Booking`, `FutsalGround`, `Reviews`, etc.) and base endpoint.

| Environment | API Base Endpoint | Flutter configuration | Web configuration |
| --- | --- | --- | --- |
| Development | `http://localhost:5485/` | `--dart-define=APP_ENV=dev` (or `--dart-define=API_BASE_URL=http://localhost:5485/`) | `FutsalApi.UI.Web/appsettings.Development.json` → `ApiEndpoints:ApiBaseUrl` |
| Staging | `https://staging-api.futsalapp.com/` | `--dart-define=APP_ENV=staging` (or explicit `API_BASE_URL`) | `FutsalApi.UI.Web/appsettings.Staging.json` → `ApiEndpoints:ApiBaseUrl` |
| Production | `https://api.futsalapp.com/` | `--dart-define=APP_ENV=prod` (or explicit `API_BASE_URL`) | `FutsalApi.UI.Web/appsettings.json` → `ApiEndpoints:ApiBaseUrl` |

### Startup validation logs

* Flutter logs the selected environment and API endpoint during startup.
* Web logs the resolved `ApiEndpoints:ApiBaseUrl` during startup.

These logs help validate that the intended environment endpoint is active before making API calls.
