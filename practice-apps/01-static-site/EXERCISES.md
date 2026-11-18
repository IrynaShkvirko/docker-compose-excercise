# Exercises – 01 Static site (nginx)
This app has no database, so exercises 1–3 practice running the official nginx image and compose before you build your own image.

## Exercise 0: Get the code into your own repo
- Copy this folder into your own Git repository and push it
- Look at the code: it is plain HTML/CSS, there are no env vars. Note which things you *would* make configurable (e.g. the host port).

## Exercise 1: Serve the site with the official nginx container
- Run `nginx:alpine` and publish container port 80 on host port 8080
- Bind-mount this folder to `/usr/share/nginx/html` (read-only) so you don't need to build anything
- Open http://localhost:8080, edit `index.html`, refresh and see the change instantly

## Exercise 2: Customize nginx with a config file
- Write an `nginx.conf` (or `default.conf`) that adds a custom response header and a custom 404 page
- Mount it into the container (`/etc/nginx/conf.d/default.conf`), restart the container
- Use `docker logs` and `docker exec -it <name> sh` to inspect access logs and the files inside

## Exercise 3: Use docker-compose for it
- Create a compose file with the nginx service, both bind mounts and the port mapping
- Make the host port configurable (`${HOST_PORT:-8080}`)
- Test with `docker compose up -d`, `docker compose logs`, `docker compose down`

## Exercise 4: Dockerize the site
- Write a `Dockerfile`: `FROM nginx:alpine`, copy the site (and your nginx config) into the image
- Add a `.dockerignore`. Build and run it **without** any bind mount and check that it still works.

## Exercise 5: Build and push the Docker image
Create a docker hosted repository on Nexus (or use Docker Hub / GitHub Container Registry if you don't have Nexus), then:
- Build the image: `docker build -t <registry>/my-static-site:1.0 .`
- `docker login <registry>`, then `docker push <registry>/my-static-site:1.0`
- Change the compose `image:` to the full registry path and check that `docker compose pull` works

## Exercise 6: Switch compose to your image
- Replace the bind mount with your image (keep the bind mount only in a dev setup)
- Add a healthcheck (e.g. `wget -qO- http://localhost/ || exit 1`) and `restart: unless-stopped`
- Keep config outside the file: host port from `.env` (commit `.env.example`, ignore `.env`)

## Exercise 7: Run on a server with docker-compose
- If your registry uses plain http (like Nexus), add it to `insecure-registries` in the server's Docker daemon config and restart Docker
- Run `docker login` on the server so it is allowed to pull the image
- Nothing is hardcoded in this site, but check that every link and asset loads when you open it via the server IP, not localhost
- Copy `docker-compose.yaml` (and any config files it mounts) to the server
- Set the needed environment variables on the server (export them or create a `.env` file there)
- Run `docker compose up -d`, then check `docker compose ps` and `docker compose logs`

## Exercise 8: Open ports
- Open only the port users need (8080) in the server firewall. Never open database or cache ports.
- Test from your browser or with `curl http://<server-ip>:8080`
