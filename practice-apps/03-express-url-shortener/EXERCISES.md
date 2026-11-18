# Exercises – 03 Express URL shortener
This app keeps data in memory and has no database, so exercises 1–3 use the official Node image and show why state matters.

## Exercise 0: Get the code into your own repo
- Copy this folder into your own Git repository and push it
- Read `server.js`: find the env vars (`PORT`, `BASE_URL`, `NODE_ENV`). `BASE_URL` is used to build the short links: why must it change per environment?

## Exercise 1: Run locally, then in a stock Node container
- `npm install && npm start`. Shorten a URL with curl, open the short link in the browser, check `/stats`.
- Run it again with the official `node:20-alpine` image without building anything: bind-mount the folder, set env vars, publish the port, run `npm install && node server.js`
- Restart the container and check `/stats`: the data is gone. Write down why.

## Exercise 2: Second container on the same network
- Create a user-defined network, run the app on it, then call `/shorten` from a `curlimages/curl` container using the app's container name
- Test that a short link created this way works in your browser (hint: what does `BASE_URL` need to be?)

## Exercise 3: Use docker-compose
- Compose file for the Node container with the bind mount, env vars from `${...}` and the port mapping
- Test `up -d`, `logs -f`, `down`

## Exercise 4: Dockerize the app
- Write a `Dockerfile` (`node:20-alpine`): copy `package*.json`, run `npm ci --omit=dev`, then copy the code
- Run as the non-root user (`USER node`), set `NODE_ENV=production`, add `.dockerignore` (`node_modules`)
- Add a build arg for the Node version and build with `--build-arg`

## Exercise 5: Build and push the Docker image
Create a docker hosted repository on Nexus (or use Docker Hub / GitHub Container Registry if you don't have Nexus), then:
- Build the image: `docker build -t <registry>/my-url-shortener:1.0 .`
- `docker login <registry>`, then `docker push <registry>/my-url-shortener:1.0`
- Change the compose `image:` to the full registry path and check that `docker compose pull` works

## Exercise 6: Switch compose to your image
- Use your image, drop the bind mount; `PORT`, `BASE_URL`, `NODE_ENV` all configurable from `.env`
- Add a healthcheck calling `/health` and `restart: unless-stopped`

## Exercise 7: Run on a server with docker-compose
- If your registry uses plain http (like Nexus), add it to `insecure-registries` in the server's Docker daemon config and restart Docker
- Run `docker login` on the server so it is allowed to pull the image
- Set `BASE_URL` to `http://<server-ip>:3000` (it defaults to localhost). Create a short link and open it from your own laptop, not on the server.
- Copy `docker-compose.yaml` (and any config files it mounts) to the server
- Set the needed environment variables on the server (export them or create a `.env` file there)
- Run `docker compose up -d`, then check `docker compose ps` and `docker compose logs`

## Exercise 8: Open ports
- Open only the port users need (3000) in the server firewall. Never open database or cache ports.
- Test from your browser or with `curl http://<server-ip>:3000/health`
