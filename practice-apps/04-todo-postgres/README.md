# 04 – Todo API + PostgreSQL
Run: `pip install -r requirements.txt && uvicorn main:app --port 8000` (docs at /docs).
Env: `DATABASE_URL` (default `postgresql://todo:todo@localhost:5432/todos`).
The app expects a `todos` table: `db/init.sql` creates it — mount it into `/docker-entrypoint-initdb.d`.
Postgres env to use: POSTGRES_USER=todo, POSTGRES_PASSWORD=todo, POSTGRES_DB=todos.
Practice: named volumes, depends_on + healthcheck, .env file, init scripts.
