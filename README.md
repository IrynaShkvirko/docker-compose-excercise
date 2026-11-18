#### This project is for the Devops bootcamp exercise for
#### "Containers - Docker"

A small Spring Boot (Java 17) app that shows a team-members page backed by a MySQL database.
On startup it creates the `team_members` table and seeds it with sample data if the table is empty.

The same repository also holds ten smaller apps under `practice-apps/`. Each one repeats the container exercises (run a container, add a GUI, Compose, Dockerfile, push to a registry, deploy) on a different stack. Details and commands are in that folder's `README.md`, `EXERCISES.md`, and `commands.txt`.

## Practice apps

| App | What it does |
|---|---|
| [01 Static site](practice-apps/01-static-site) | Serves a small HTML and CSS site with nginx. |
| [02 Flask health API](practice-apps/02-flask-health-api) | Returns a greeting and a `/health` check from a Flask process. |
| [03 Express URL shortener](practice-apps/03-express-url-shortener) | Stores short links in memory and redirects callers to the original URL. |
| [04 Todo API](practice-apps/04-todo-postgres) | A FastAPI todo list saved in PostgreSQL, with pgAdmin beside it. |
| [05 Redis counter](practice-apps/05-redis-counter) | Counts visits in Redis and returns 429 after too many calls from one address. |
| [06 Go notes API](practice-apps/06-go-notes-mongo) | Creates, lists, and deletes notes in MongoDB. The image is a multi-stage Go build. |
| [07 Blog](practice-apps/07-blog-proxy) | Nginx serves the page and forwards `/api` to a Flask backend. Only Nginx is published. |
| [08 Job queue](practice-apps/08-job-queue) | A web app enqueues jobs in Redis, and worker containers run them. One image, two commands. |
| [09 Metrics app](practice-apps/09-metrics-app) | Exposes Prometheus metrics. Grafana is provisioned with Prometheus as its data source. |
| [10 Dev vs prod](practice-apps/10-dev-vs-prod) | The same Flask app runs with a reload in development and gunicorn in production. |

## Project structure

| Path | Purpose |
|---|---|
| `src/main/java/com/example` | Application code (`Application`, `AppController`, `DatabaseConfig`) |
| `src/main/resources/static` | Front end (`index.html`, `team.jpg`) |
| `build.gradle` / `settings.gradle` | Gradle build (project name `docker-exercises-project`) |
| `Dockerfile` | Builds the app image from the jar in `build/libs` |
| `docker-compose.yaml` | Runs the app, MySQL and phpMyAdmin together |

## Prerequisites

- **Java 17** (JDK)
- **Gradle** (the repo has no Gradle wrapper, so a local Gradle install is needed)
- **Docker** and **Docker Compose** (v2: `docker compose`)

## Configuration

The app reads its database connection from environment variables:

| Variable | Description | Local run | Docker Compose |
|---|---|---|---|
| `DB_USER` | DB user | `appuser` | `appuser` |
| `DB_PWD` | DB password | `apppassword` | `apppassword` |
| `DB_SERVER` | DB host name (no port; port `3306` is fixed in code) | `localhost` | `mysql` (the compose service name) |
| `DB_NAME` | Database name | `appdb` | `appdb` |

The values `appuser`, `apppassword` and `appdb` match what the `mysql` service in `docker-compose.yaml` creates.

## Run locally (app on your machine, MySQL in Docker)

1. Start only the database (it also creates `appdb` and `appuser`):

   ```bash
   docker compose up -d mysql
   ```

   Wait until it is healthy: `docker compose ps` should show `healthy`.

2. Set the environment variables (macOS/Linux):

   ```bash
   export DB_USER=appuser
   export DB_PWD=apppassword
   export DB_SERVER=localhost
   export DB_NAME=appdb
   ```

   On Windows PowerShell use `$env:DB_USER="appuser"` and so on.

3. Start the app:

   ```bash
   gradle bootRun
   ```

4. Open http://localhost:8080

To stop, press `Ctrl+C`, then `docker compose down` to stop MySQL.

> You can also point `DB_SERVER` at any MySQL server you already run locally, as long as the
> user, password and database exist and it listens on port 3306.

## Run in Docker (everything with Docker Compose)

1. Build the jar. The Dockerfile copies `build/libs/docker-exercises-project-1.0-SNAPSHOT.jar`:

   ```bash
   gradle build
   ```

2. Build the app image with the name and tag that `docker-compose.yaml` expects:

   ```bash
   docker build -t java-mysql-app:1.0 .
   ```

3. Create a `.env` file next to `docker-compose.yaml` (Compose loads it automatically):

   ```
   DB_USER=appuser
   DB_PWD=apppassword
   DB_SERVER=mysql
   DB_NAME=appdb
   ```

4. Start all services:

   ```bash
   docker compose up -d
   ```

   The app container starts only after MySQL reports healthy.

5. Open the services:

   | Service | URL / port |
   |---|---|
   | App | http://localhost:8080 |
   | phpMyAdmin | http://localhost:8083 (log in with `appuser` / `apppassword`, or `root` / `rootpassword`) |
   | MySQL | `localhost:3306` |

Useful commands:

```bash
docker compose ps                  # status of the services
docker compose logs -f my-java-app # follow the app logs
docker compose down                # stop and remove containers (data is kept)
docker compose down -v             # also delete the mysql-data volume (wipes the DB)
```

After changing the code, repeat steps 1 and 2, then run `docker compose up -d --force-recreate my-java-app`.

## Tests and checks

| Command | What it does | Needs |
|---|---|---|
| `gradle test` | Java unit tests | Java 17, Gradle |
| `./scripts/validate.sh` | Validates `docker-compose.yaml` (`docker compose config`) and lints the `Dockerfile` with hadolint | Docker |
| `./scripts/smoke-test.sh` | Builds the jar and image, starts the whole stack, checks `/get-data` returns the 5 seeded members, checks the front page and phpMyAdmin, then tears everything down | Java 17, Gradle, Docker, curl |

The smoke test runs `docker compose down -v`, so it deletes the `mysql-data` volume. It also needs
ports 8080, 8083 and 3306 to be free.

The same checks run in CI on every push and pull request (`.github/workflows/docker-checks.yml`).

## API

| Method | Path | Description |
|---|---|---|
| GET | `/get-data` | Returns all team members as JSON |
| POST | `/update-roles` | Updates member roles from a JSON array of `{ "name": ..., "role": ... }` |

## Troubleshooting

- **Port already in use** (8080, 8083 or 3306): stop the other process or change the host side of the `ports` mapping in `docker-compose.yaml`.
- **App can't connect to the DB in Docker:** make sure `DB_SERVER=mysql`, not `localhost`. Inside a container, `localhost` is the container itself.
- **App can't connect to the DB locally:** make sure the `mysql` container is `healthy` and `DB_SERVER=localhost`.
- **`COPY failed` while building the image:** run `gradle build` first so the jar exists in `build/libs`.
- **Changed DB credentials have no effect:** MySQL only applies `MYSQL_*` variables on first start. Run `docker compose down -v` to recreate the volume.
