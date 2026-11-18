# Exercises – 04 Todo API + PostgreSQL

## Exercise 0: Get the code into your own repo
- Copy this folder into your own Git repository and push it
- Read `main.py`: the DB connection comes from `DATABASE_URL`. Why must the password not be hardcoded or committed?

## Exercise 1: Start a Postgres container
- Start `postgres` from the official image. Set `POSTGRES_USER=todo`, `POSTGRES_PASSWORD`, `POSTGRES_DB=todos` and publish 5432
- Create the table: mount `db/init.sql` into `/docker-entrypoint-initdb.d/` (or run it with `docker exec ... psql`)
- Export `DATABASE_URL` (`postgresql://user:password@localhost:5432/todos`), create a venv, install requirements and run `uvicorn main:app --port 8000`
- Open http://localhost:8000/docs, create/update/delete todos

## Exercise 2: Start a DB GUI container
- Start `dpage/pgadmin4` (or `adminer`) with the official image. For pgAdmin set `PGADMIN_DEFAULT_EMAIL` and `PGADMIN_DEFAULT_PASSWORD`.
- Log in and register your Postgres server. Hostname `localhost` will fail from inside the container: work out why (that is what the next exercise fixes).
- Check the rows created through the API are visible

## Exercise 3: Use docker-compose for Postgres and the GUI
- Compose file with both containers; the GUI connects to the host name `postgres` (service name)
- Add a named volume for `/var/lib/postgresql/data` and mount `init.sql`
- Prove the volume works: create a todo, `docker compose down`, `up -d`, todo still there. Then `down -v` and see it gone.

## Exercise 4: Dockerize the API
- Write a `Dockerfile` (`python:3.12-slim`): install `requirements.txt` first, copy the code, `CMD uvicorn main:app --host 0.0.0.0 --port 8000`
- Add `.dockerignore`. Build and run the image against your compose Postgres.

## Exercise 5: Build and push the Docker image
Create a docker hosted repository on Nexus (or use Docker Hub / GitHub Container Registry if you don't have Nexus), then:
- Build the image: `docker build -t <registry>/my-todo-api:1.0 .`
- `docker login <registry>`, then `docker push <registry>/my-todo-api:1.0`
- Change the compose `image:` to the full registry path and check that `docker compose pull` works

## Exercise 6: Add the API to docker-compose
- Add the API service, with `DATABASE_URL` using the host `postgres`, not localhost
- Healthcheck for Postgres, and make the API wait for it:
```yaml
api:
  depends_on:
    postgres:
      condition: service_healthy
postgres:
  healthcheck:
    test: ["CMD-SHELL", "pg_isready -U todo -d todos"]
    interval: 10s
    timeout: 5s
    retries: 5
```
- Make all credentials configurable via `${VAR}` / `.env` (commit `.env.example`, ignore `.env`). No secrets in the compose file.

## Exercise 7: Run on a server with docker-compose
- If your registry uses plain http (like Nexus), add it to `insecure-registries` in the server's Docker daemon config and restart Docker
- Run `docker login` on the server so it is allowed to pull the image
- There is no hardcoded host in the code, but `DATABASE_URL` must use the service name `postgres`. Test the API from your laptop with the server IP.
- Copy `docker-compose.yaml` (and any config files it mounts) to the server
- Set the needed environment variables on the server (export them or create a `.env` file there)
- Run `docker compose up -d`, then check `docker compose ps` and `docker compose logs`

## Exercise 8: Open ports
- Open only the port users need (8000) in the server firewall. Never open database or cache ports.
- Test from your browser or with `curl http://<server-ip>:8000/health`
