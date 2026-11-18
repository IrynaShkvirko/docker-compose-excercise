# 07 – Blog with reverse proxy
- `backend/` – Flask API under `/api/*` (posts stored in a JSON file; `DATA_FILE` env, `PORT` 5000)
- `frontend/` – static page that calls `/api/...` on the same origin
Goal: nginx in front serves `frontend/` and proxies `/api/` to the backend; only nginx publishes a port.
Practice: custom networks, internal-only services, nginx.conf proxy_pass, a volume for DATA_FILE.
