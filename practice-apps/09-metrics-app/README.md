# 09 – Metrics app (for Prometheus + Grafana)
Run: `pip install -r requirements.txt && python app.py`; `./traffic.sh` generates load.
Endpoints: `/`, `/work`, `/error` (50% 500s), `/metrics`.
Metrics: `app_requests_total{endpoint,status}`, `app_request_latency_seconds` (histogram), `app_requests_in_progress`.
You write: prometheus.yml (scrape `<app>:5000/metrics`) and Grafana provisioning.
Practice: config bind mounts, Prometheus/Grafana services, persistent volumes.
