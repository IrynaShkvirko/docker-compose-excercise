# 05 – Redis visit counter + rate limiter
Run: `pip install -r requirements.txt && python app.py` (needs Redis on localhost:6379).
Env: `REDIS_HOST`, `REDIS_PORT`, `PORT` (5000), `RATE_LIMIT` (5), `RATE_WINDOW_SECONDS` (60).
Endpoints: `GET /visit`, `GET /limited` (429 after 5 calls/min), `GET /health`.
Practice: service-name DNS, restart policies, `docker compose logs -f`.
