# Exercises – 06 Go notes API + MongoDB

## Exercise 0: Get the code into your own repo
- Copy this folder into your own Git repository and push it. Run `go mod tidy` and commit `go.sum`.
- Read `main.go`: the connection comes from `MONGO_URI`, `MONGO_DB`, `PORT`. Why not hardcode credentials in the URI?

## Exercise 1: Start a MongoDB container
- Start `mongo` from the official image with `MONGO_INITDB_ROOT_USERNAME` and `MONGO_INITDB_ROOT_PASSWORD`, publish 27017
- Export `MONGO_URI=mongodb://user:password@localhost:27017/?authSource=admin`, run `go run .`
- Create notes with curl (`POST /notes`), list them, delete one

## Exercise 2: Start a Mongo GUI container
- Start `mongo-express` from the official image and give it the Mongo credentials (`ME_CONFIG_MONGODB_URL` or the admin env vars) plus its own login
- Open it in the browser and find your `notes` database. It cannot reach `localhost` of your machine, find out why.

## Exercise 3: Use docker-compose for Mongo and the GUI
- Compose file with both containers, GUI connecting to host `mongo` (service name)
- Add a named volume for `/data/db`; test that notes survive `down` / `up -d`

## Exercise 4: Dockerize the app (twice)
- First a simple single-stage `Dockerfile` using the `golang` image. Note the image size (`docker images`).
- Then a **multi-stage** build: build in `golang` with `CGO_ENABLED=0`, run the binary in `gcr.io/distroless/static` (or `scratch`). Compare sizes.
- Add `.dockerignore`

## Exercise 5: Build and push the Docker image
Create a docker hosted repository on Nexus (or use Docker Hub / GitHub Container Registry if you don't have Nexus), then:
- Build the image: `docker build -t <registry>/my-notes-api:1.0 .`
- `docker login <registry>`, then `docker push <registry>/my-notes-api:1.0`
- Change the compose `image:` to the full registry path and check that `docker compose pull` works

## Exercise 6: Add the app to docker-compose
- Add the app with `MONGO_URI` using the host `mongo`
- Healthcheck on Mongo: `["CMD", "mongosh", "--quiet", "--eval", "db.adminCommand('ping')"]`, and `depends_on` with `condition: service_healthy`
- All credentials via `${VAR}` / `.env` (commit `.env.example`, ignore `.env`)

## Exercise 7: Run on a server with docker-compose
- If your registry uses plain http (like Nexus), add it to `insecure-registries` in the server's Docker daemon config and restart Docker
- Run `docker login` on the server so it is allowed to pull the image
- No hardcoded host in the code, but `MONGO_URI` must use the service name `mongo`. Test the API from your laptop with the server IP.
- Copy `docker-compose.yaml` (and any config files it mounts) to the server
- Set the needed environment variables on the server (export them or create a `.env` file there)
- Run `docker compose up -d`, then check `docker compose ps` and `docker compose logs`

## Exercise 8: Open ports
- Open only the port users need (8080) in the server firewall. Never open database or cache ports.
- Test from your browser or with `curl http://<server-ip>:8080/health`
