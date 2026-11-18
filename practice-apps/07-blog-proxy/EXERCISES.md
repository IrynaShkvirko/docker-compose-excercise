# Exercises – 07 Blog with reverse proxy
Here the "extra container" is nginx instead of a database: it serves the frontend and proxies the API.

## Exercise 0: Get the code into your own repo
- Copy this folder into your own Git repository and push it
- Read `backend/app.py` (`DATA_FILE`, `PORT`) and `frontend/app.js`. Notice the frontend calls `/api/...` on the **same origin**, with no host in the URL.

## Exercise 1: Run it locally and see the problem
- Run the backend (`python app.py` in `backend/`) and serve `frontend/` with `python -m http.server 8080`
- Open the frontend: the posts do not load. Find out why in the browser dev tools (two different ports = two origins).

## Exercise 2: Fix it with an nginx container
- Write an `nginx.conf` that serves `frontend/` at `/` and proxies `/api/` to the backend
- Run the official `nginx:alpine` image with the config and frontend bind-mounted; the backend still runs on your machine (reach it via `host.docker.internal`)
- Open http://localhost:8080 and publish a post

## Exercise 3: Use docker-compose for nginx
- Compose file for the nginx service with its mounts and port
- Test `up -d`, `logs`, edit `index.html`, refresh

## Exercise 4: Dockerize the backend
- Write `backend/Dockerfile` (`python:3.12-slim`), requirements first, `.dockerignore`
- Optional: also `frontend/Dockerfile` (`FROM nginx:alpine` + COPY) so nginx has the site baked in

## Exercise 5: Build and push the Docker image
Create a docker hosted repository on Nexus (or use Docker Hub / GitHub Container Registry if you don't have Nexus), then:
- Build the image: `docker build -t <registry>/my-blog-backend:1.0 .`
- `docker login <registry>`, then `docker push <registry>/my-blog-backend:1.0`
- Change the compose `image:` to the full registry path and check that `docker compose pull` works

## Exercise 6: Add the backend to docker-compose
- Add the backend service. Do **not** publish its port: only nginx is reachable from outside. Point `proxy_pass` at `http://backend:5000`.
- Put them on a custom network
- Set `DATA_FILE=/data/posts.json` and mount a named volume on `/data`; prove posts survive `down` / `up -d`
- Add a healthcheck on `/api/health` and make nginx `depends_on` the backend being healthy

## Exercise 7: Run on a server with docker-compose
- If your registry uses plain http (like Nexus), add it to `insecure-registries` in the server's Docker daemon config and restart Docker
- Run `docker login` on the server so it is allowed to pull the image
- The frontend uses a relative `/api` URL, so it needs no change. Prove why this matters: temporarily change `app.js` to call `http://localhost/api/posts`, open the site from your laptop and watch it fail, then revert.
- Copy `docker-compose.yaml` (and any config files it mounts) to the server
- Set the needed environment variables on the server (export them or create a `.env` file there)
- Run `docker compose up -d`, then check `docker compose ps` and `docker compose logs`

## Exercise 8: Open ports
- Open only the port users need (80) in the server firewall. Never open database or cache ports.
- Test from your browser or with `curl http://<server-ip>:80/api/health`
