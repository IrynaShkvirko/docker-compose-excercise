# 10 – Dev vs prod config
Run dev: `APP_ENV=development python app.py` (auto-reload). Prod: `gunicorn -b 0.0.0.0:5000 app:app`.
Env: `APP_ENV`, `LOG_LEVEL`, `GREETING`, `PORT`. `GET /config` shows what is active.
Practice: compose.override.yaml (bind mount + reload), profiles, `docker compose watch`,
different `command` per environment. Optionally pair with any DB service from the other apps.
