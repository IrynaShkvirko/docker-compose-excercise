# Exercises – 10 Dev vs prod config
This app has no database. The exercises focus on running the same app in different environments.

## Exercise 0: Get the code into your own repo
- Copy this folder into your own Git repository and push it
- Read `app.py`: behaviour depends on `APP_ENV`, `LOG_LEVEL`, `GREETING`, `PORT`. These must change per environment, so they must not be hardcoded.

## Exercise 1: Run it in two modes
- Dev: `APP_ENV=development python app.py` (auto reload). Edit a route and see it restart.
- Prod: `APP_ENV=production gunicorn -b 0.0.0.0:5000 app:app`. Compare `GET /config` in both modes.

## Exercise 2: Run both in stock Python containers
- Use the official `python:3.12-slim` image, bind-mount the folder, set env vars with `-e`, and run dev on port 5000 and prod on port 5001 at the same time
- Compare `/config` on both ports

## Exercise 3: Use docker-compose
- A compose file that starts the prod-style container, and a second service for dev with a bind mount
- Share the config with a `.env` file and variable substitution

## Exercise 4: Dockerize the app
- Write one `Dockerfile` (`python:3.12-slim`) with requirements first and `.dockerignore`. The default `CMD` is gunicorn (prod).
- Add a non-root user. The dev setup will override the command; the image stays the same.

## Exercise 5: Build and push the Docker image
Create a docker hosted repository on Nexus (or use Docker Hub / GitHub Container Registry if you don't have Nexus), then:
- Build the image: `docker build -t <registry>/my-dev-vs-prod:1.0 .`
- `docker login <registry>`, then `docker push <registry>/my-dev-vs-prod:1.0`
- Change the compose `image:` to the full registry path and check that `docker compose pull` works

## Exercise 6: Compose base file + override
- `docker-compose.yaml`: your image, prod command, env from `.env`, healthcheck, `restart: unless-stopped`
- `docker-compose.override.yaml`: dev settings (bind mount the code, `APP_ENV=development`, reload command). It is picked up automatically by `docker compose up`.
- Add an optional service with a compose `profile` (e.g. a curl pinger) that only starts with `--profile tools`
- Try `docker compose watch` (a `develop.watch` section) as an alternative to the bind mount

## Exercise 7: Run on a server with docker-compose
- If your registry uses plain http (like Nexus), add it to `insecure-registries` in the server's Docker daemon config and restart Docker
- Run `docker login` on the server so it is allowed to pull the image
- On the server run only the base file (`docker compose -f docker-compose.yaml up -d`) or don't copy the override file, otherwise dev settings get applied. Verify with `GET /config` that `env` is `production`.
- Copy `docker-compose.yaml` (and any config files it mounts) to the server
- Set the needed environment variables on the server (export them or create a `.env` file there)
- Run `docker compose up -d`, then check `docker compose ps` and `docker compose logs`

## Exercise 8: Open ports
- Open only the port users need (5000) in the server firewall. Never open database or cache ports.
- Test from your browser or with `curl http://<server-ip>:5000/config`
