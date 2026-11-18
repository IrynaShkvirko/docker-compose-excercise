# 08 – Job queue (web + worker + Redis)
One codebase, two processes — build one image, run it with different commands:
- web: `python app.py` (port 5000) — `POST /jobs {"n": 7}`, `GET /jobs/<id>`, `GET /health`
- worker: `python worker.py`
Env: `REDIS_HOST`, `REDIS_PORT`, `PORT`.
Practice: shared image with different `command`, `docker compose up --scale worker=3`.
