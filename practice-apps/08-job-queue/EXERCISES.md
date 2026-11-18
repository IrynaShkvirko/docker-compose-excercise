# Exercises – 08 Job queue (web + worker + Redis)

## Exercise 0: Get the code into your own repo
- Copy this folder into your own Git repository and push it
- Read `app.py` and `worker.py`: both use `REDIS_HOST` / `REDIS_PORT`. Why is it good that the web app and the worker share one codebase and config?

## Exercise 1: Start a Redis container
- Start `redis` from the official image and publish 6379
- In one terminal run the web app (`python app.py`), in another the worker (`python worker.py`)
- `POST /jobs` with `{"n": 7}`, then poll `GET /jobs/<id>` and watch `queued` → `started` → `finished`. Stop the worker and see jobs pile up.

## Exercise 2: Start a GUI container
- Start `eoranged/rq-dashboard` (env `RQ_DASHBOARD_REDIS_URL`, port 9181) or RedisInsight from the official image
- Connect it to Redis and watch the `jobs` queue and the workers while you enqueue jobs

## Exercise 3: Use docker-compose for Redis and the dashboard
- Compose file with both; the dashboard uses the Redis service name
- Add a volume for Redis `/data`; queued jobs should survive a Redis restart (use `--appendonly yes`)

## Exercise 4: Dockerize the app (one image, two commands)
- Write one `Dockerfile` (`python:3.12-slim`) that contains `app.py`, `tasks.py` and `worker.py`
- The default `CMD` runs the web app. Prove the same image can run the worker with `docker run ... python worker.py`

## Exercise 5: Build and push the Docker image
Create a docker hosted repository on Nexus (or use Docker Hub / GitHub Container Registry if you don't have Nexus), then:
- Build the image: `docker build -t <registry>/my-job-queue:1.0 .`
- `docker login <registry>`, then `docker push <registry>/my-job-queue:1.0`
- Change the compose `image:` to the full registry path and check that `docker compose pull` works

## Exercise 6: Add web and worker to docker-compose
- Two services using the same image: `web` (default command, published port) and `worker` (`command: python worker.py`, no ports)
- `REDIS_HOST=redis` on both. Healthcheck on Redis (`redis-cli ping`) and `depends_on` with `condition: service_healthy`
- Scale: `docker compose up -d --scale worker=3`, enqueue 10 jobs and see in the logs which worker took which job
- Make `REDIS_HOST`, `REDIS_PORT` and ports configurable from `.env`

## Exercise 7: Run on a server with docker-compose
- If your registry uses plain http (like Nexus), add it to `insecure-registries` in the server's Docker daemon config and restart Docker
- Run `docker login` on the server so it is allowed to pull the image
- No hardcoded host in the code, but `REDIS_HOST` must be the service name on both web and worker. Enqueue a job from your laptop using the server IP.
- Copy `docker-compose.yaml` (and any config files it mounts) to the server
- Set the needed environment variables on the server (export them or create a `.env` file there)
- Run `docker compose up -d`, then check `docker compose ps` and `docker compose logs`

## Exercise 8: Open ports
- Open only the port users need (5000) in the server firewall. Never open database or cache ports.
- Test from your browser or with `curl http://<server-ip>:5000/health`
