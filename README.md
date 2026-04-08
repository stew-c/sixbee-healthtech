# SixBee HealthTech

Appointment booking system for a healthcare practice in West Yorkshire.

## Getting Started

### Prerequisites

Install frontend dependencies before building or running locally:

```bash
cd src/patient-app && npm install
cd src/admin-app && npm install
```

### Run with Docker

```bash
just start
```

This starts all services via Docker Compose: PostgreSQL, .NET API, patient app, and admin app. Database migrations run automatically on API startup.

| Service     | URL                    |
|-------------|------------------------|
| Patient App | http://localhost:3000   |
| Admin App   | http://localhost:3001   |
| API         | http://localhost:5050   |

Run `just` to see all available commands.

## Default Credentials

The following admin account is seeded on first run.

| Field    | Value              |
| -------- | ------------------ |
| Email    | admin@sixbee.co.uk |
| Password | Admin123!          |
