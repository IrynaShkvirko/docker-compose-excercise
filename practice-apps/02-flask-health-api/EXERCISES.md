# Exercises – 02 Flask health API
This app has no database, so exercises 1–3 practice the official Python image, container networking and compose.

## Exercise 0: Get the code into your own repo
- Copy this folder into your own Git repository and push it
- Read `app.py`: find the env vars (`PORT`, `APP_NAME`, `APP_ENV`). Why is it better to read them from the environment than to hardcode them?

## Exercise 1: Run the app locally, then in a stock Python container
- Create a virtualenv, `pip install -r requirements.txt`, export the env vars and run `python app.py`. Test `/` and `/health` with curl and the browser.
- Now run it with the official `python:3.12-slim` image **without building anything**: bind-mount the folder, set the env vars with `-e`, publish the port, and use a command that installs the requirements and starts the app

## Exercise 2: Talk to it from a second container
- Create a user-defined network (`docker network create`) and run the app on it with a name
- Run `curlimages/curl` on the same network and call `http://<app-name>:5000/health`
- Notice: it works by container name, and `localhost` does not. Try both.

## Exercise 3: Use docker-compose
- Write a compose file for the Python container (bind mount, env vars, port)
- Add a second service that uses `curlimages/curl` to call the app's `/health` in a loop, and watch its logs
- Compose creates the network for you: confirm the service name works as hostname

## Exercise 4: Dockerize the API
- Write a `Dockerfile` (`python:3.12-slim`). Copy `requirements.txt` and install **before** copying the code, then change `app.py` and rebuild to see the layer cache work.
- Add `.dockerignore` (`__pycache__`, `.venv`, `.git`) and a `HEALTHCHECK` for `/health`

## Exercise 5: Build and push the Docker image
Create a docker hosted repository on Nexus (or use Docker Hub / GitHub Container Registry if you don't have Nexus), then:
- Build the image: `docker build -t <registry>/my-flask-health-api:1.0 .`
- `docker login <registry>`, then `docker push <registry>/my-flask-health-api:1.0`
- Change the compose `image:` to the full registry path and check that `docker compose pull` works

## Exercise 6: Switch compose to your image
- Use your image instead of the stock one and drop the bind mount
- Env vars (`APP_NAME`, `APP_ENV`, `PORT`) come from `.env`/environment (commit `.env.example`, ignore `.env`)
- Add a compose `healthcheck`, `restart: unless-stopped`, and make the pinger wait with `depends_on: condition: service_healthy`

## Exercise 7: Run on a server with docker-compose
- If your registry uses plain http (like Nexus), add it to `insecure-registries` in the server's Docker daemon config and restart Docker
- Run `docker login` on the server so it is allowed to pull the image
- Nothing in the code points at localhost, but set `APP_ENV=production` and check `GET /` shows it. Your pinger service should still use the service name.
- Copy `docker-compose.yaml` (and any config files it mounts) to the server
- Set the needed environment variables on the server (export them or create a `.env` file there)
- Run `docker compose up -d`, then check `docker compose ps` and `docker compose logs`

## Exercise 8: Open ports
- Open only the port users need (5000) in the server firewall. Never open database or cache ports.
- Test from your browser or with `curl http://<server-ip>:5000/health`
