# Practice apps

Each folder is a small app used to practice the same container path: run it, add a GUI, write Compose, build an image, push it, and run it on a server. `EXERCISES.md` is the exercise list. `commands.txt` has the commands. `deploy.sh` builds the image and starts that app on the server.

| # | App | Description |
|---|-----|-------------|
| 01 | [static-site](01-static-site) | A static HTML and CSS site served by nginx. |
| 02 | [flask-health-api](02-flask-health-api) | A Flask API with a greeting and a health check. |
| 03 | [express-url-shortener](03-express-url-shortener) | An Express app that keeps short links in memory and redirects to the original URL. |
| 04 | [todo-postgres](04-todo-postgres) | A FastAPI todo list stored in PostgreSQL, with pgAdmin for browsing the tables. |
| 05 | [redis-counter](05-redis-counter) | A visit counter and per-address rate limiter backed by Redis. |
| 06 | [go-notes-mongo](06-go-notes-mongo) | A Go notes API stored in MongoDB, built with a multi-stage image. |
| 07 | [blog-proxy](07-blog-proxy) | A small blog. Nginx serves the page and proxies `/api` to Flask. |
| 08 | [job-queue](08-job-queue) | A web app and worker processes share one image and run jobs from a Redis queue. |
| 09 | [metrics-app](09-metrics-app) | A Flask app that exposes Prometheus metrics, with Grafana already pointed at Prometheus. |
| 10 | [dev-vs-prod](10-dev-vs-prod) | One Flask app. Development reloads on file changes. Production runs under gunicorn. |
