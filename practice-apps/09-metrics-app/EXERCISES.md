# Exercises – 09 Metrics app (Prometheus + Grafana)
The "database" here is Prometheus, and Grafana is the GUI.

## Exercise 0: Get the code into your own repo
- Copy this folder into your own Git repository and push it
- Read `app.py`: find the metrics it exposes and the `PORT` env var. Config for Prometheus/Grafana will be files you write, not hardcoded in the app.

## Exercise 1: Start a Prometheus container
- Run the app locally (`python app.py`) and start `./traffic.sh` for load
- Write `prometheus.yml` scraping the app's `/metrics` (from a container the host is `host.docker.internal:5000`)
- Start `prom/prometheus` from the official image with the file bind-mounted, publish 9090
- Open http://localhost:9090, check Status → Targets is UP, and query `rate(app_requests_total[1m])`

## Exercise 2: Start a Grafana container
- Start `grafana/grafana` from the official image (port 3000, login admin/admin and change the password)
- Add Prometheus as a data source (hint: `localhost` points at the Grafana container itself, so what URL works?)
- Build a panel for the request rate by endpoint and one for p95 latency (`histogram_quantile(0.95, ...)`)

## Exercise 3: Use docker-compose for Prometheus and Grafana
- Compose file with both. Bind-mount `prometheus.yml`
- Named volumes for Prometheus data (`/prometheus`) and Grafana data (`/var/lib/grafana`). Prove dashboards survive `down` / `up -d`.

## Exercise 4: Dockerize the app
- Write a `Dockerfile` (`python:3.12-slim`), requirements first, `.dockerignore`, `HEALTHCHECK` on `/`

## Exercise 5: Build and push the Docker image
Create a docker hosted repository on Nexus (or use Docker Hub / GitHub Container Registry if you don't have Nexus), then:
- Build the image: `docker build -t <registry>/my-metrics-app:1.0 .`
- `docker login <registry>`, then `docker push <registry>/my-metrics-app:1.0`
- Change the compose `image:` to the full registry path and check that `docker compose pull` works

## Exercise 6: Add the app to docker-compose
- Add the app service; change the scrape target to `app:5000` (service name)
- Provision the Grafana data source from a file in `/etc/grafana/provisioning/datasources/` so there are no manual clicks
- Set the Grafana admin password from `${GF_ADMIN_PASSWORD}` (`.env`, commit `.env.example`, ignore `.env`)
- `depends_on` so Prometheus starts after the app, and add a healthcheck for the app

## Exercise 7: Run on a server with docker-compose
- If your registry uses plain http (like Nexus), add it to `insecure-registries` in the server's Docker daemon config and restart Docker
- Run `docker login` on the server so it is allowed to pull the image
- Make sure no config still points at localhost: Prometheus must scrape `app:5000` and Grafana's data source must be `http://prometheus:9090`. Update them if needed.
- Copy `docker-compose.yaml` (and any config files it mounts) to the server
- Set the needed environment variables on the server (export them or create a `.env` file there)
- Run `docker compose up -d`, then check `docker compose ps` and `docker compose logs`

## Exercise 8: Open ports
- Open only the port users need (3000) in the server firewall. Never open database or cache ports.
- Test from your browser or with `curl http://<server-ip>:3000`
