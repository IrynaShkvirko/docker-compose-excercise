# Exercises – 05 Redis visit counter + rate limiter

## Exercise 0: Get the code into your own repo
- Copy this folder into your own Git repository and push it
- Read `app.py`: find the env vars (`REDIS_HOST`, `REDIS_PORT`, `RATE_LIMIT`, `RATE_WINDOW_SECONDS`, `PORT`) and why they are not hardcoded

## Exercise 1: Start a Redis container
- Start `redis` from the official image and publish 6379
- Export the env vars, create a venv, install requirements and run `python app.py`
- Call `/visit` a few times, call `/limited` until you get a 429. Stop the Redis container and see what `/health` does.

## Exercise 2: Start a Redis GUI container
- Start RedisInsight (`redis/redisinsight`, port 5540) or `redis-commander` from the official image
- Connect it to your Redis (again: `localhost` won't work from inside a container) and look at the keys `visits` and `rate:<ip>`. Watch the TTL of the rate key count down.

## Exercise 3: Use docker-compose for Redis and the GUI
- Compose with both containers; the GUI connects via the service name
- Add a volume for `/data` and start Redis with `--appendonly yes` so data persists
- Test: increase the counter, `docker compose restart redis`, the counter must survive

## Exercise 4: Dockerize the app
- Write a `Dockerfile` (`python:3.12-slim`), install requirements before copying code, add `.dockerignore`
- Build it and run it against your compose Redis

## Exercise 5: Build and push the Docker image
Create a docker hosted repository on Nexus (or use Docker Hub / GitHub Container Registry if you don't have Nexus), then:
- Build the image: `docker build -t <registry>/my-redis-counter:1.0 .`
- `docker login <registry>`, then `docker push <registry>/my-redis-counter:1.0`
- Change the compose `image:` to the full registry path and check that `docker compose pull` works

## Exercise 6: Add the app to docker-compose
- Add the app service with `REDIS_HOST=redis` (service name)
- Healthcheck on Redis (`["CMD", "redis-cli", "ping"]`) and `depends_on` with `condition: service_healthy`
- Make `RATE_LIMIT`, `RATE_WINDOW_SECONDS` and the ports configurable from `.env`, add `restart: unless-stopped`

## Exercise 7: Run on a server with docker-compose
- If your registry uses plain http (like Nexus), add it to `insecure-registries` in the server's Docker daemon config and restart Docker
- Run `docker login` on the server so it is allowed to pull the image
- No hardcoded host in the code, but `REDIS_HOST` must be the service name. Check `/limited` from your laptop: the 429 is per client IP.
- Copy `docker-compose.yaml` (and any config files it mounts) to the server
- Set the needed environment variables on the server (export them or create a `.env` file there)
- Run `docker compose up -d`, then check `docker compose ps` and `docker compose logs`

## Exercise 8: Open ports
- Open only the port users need (5000) in the server firewall. Never open database or cache ports.
- Test from your browser or with `curl http://<server-ip>:5000/health`
