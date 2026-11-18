# Practice apps
Small apps with app code only. You add the `Dockerfile` and `docker-compose.yaml` for each.

| # | App | Stack | Needs | New concept |
|---|-----|-------|-------|-------------|
| 01 | static-site | HTML/CSS | – | nginx, COPY, bind mount |
| 02 | flask-health-api | Python | – | layer cache, HEALTHCHECK |
| 03 | express-url-shortener | Node | – | npm ci, non-root user, build args |
| 04 | todo-postgres | FastAPI | PostgreSQL | volumes, healthcheck, init.sql |
| 05 | redis-counter | Flask | Redis | service DNS, restart policy |
| 06 | go-notes-mongo | Go | MongoDB | multi-stage, tiny image |
| 07 | blog-proxy | Flask + static | nginx | reverse proxy, networks |
| 08 | job-queue | Flask + RQ | Redis | one image, many commands, --scale |
| 09 | metrics-app | Flask | Prometheus, Grafana | config mounts |
| 10 | dev-vs-prod | Flask | – | override file, profiles, watch |

Each folder has its own README with run command, env vars and endpoints.

Each app folder also has `EXERCISES.md`: the same exercise set as the original Java project
(containers → GUI → compose → Dockerfile → push → compose with app → server → ports), adapted to that app.
