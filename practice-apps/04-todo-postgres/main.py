import os
import time

import psycopg2
import psycopg2.extras
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel

DATABASE_URL = os.getenv("DATABASE_URL", "postgresql://todo:todo@localhost:5432/todos")

app = FastAPI(title="Todo API")


def get_conn(retries: int = 10, delay: float = 2.0):
    for attempt in range(retries):
        try:
            return psycopg2.connect(DATABASE_URL, cursor_factory=psycopg2.extras.RealDictCursor)
        except psycopg2.OperationalError:
            if attempt == retries - 1:
                raise
            time.sleep(delay)


class TodoIn(BaseModel):
    title: str


class TodoUpdate(BaseModel):
    title: str | None = None
    done: bool | None = None


@app.get("/health")
def health():
    with get_conn(retries=1) as conn, conn.cursor() as cur:
        cur.execute("SELECT 1")
    return {"status": "ok"}


@app.get("/todos")
def list_todos():
    with get_conn() as conn, conn.cursor() as cur:
        cur.execute("SELECT id, title, done FROM todos ORDER BY id")
        return cur.fetchall()


@app.post("/todos", status_code=201)
def create_todo(todo: TodoIn):
    with get_conn() as conn, conn.cursor() as cur:
        cur.execute("INSERT INTO todos (title) VALUES (%s) RETURNING id, title, done", (todo.title,))
        return cur.fetchone()


@app.patch("/todos/{todo_id}")
def update_todo(todo_id: int, patch: TodoUpdate):
    with get_conn() as conn, conn.cursor() as cur:
        cur.execute(
            "UPDATE todos SET title = COALESCE(%s, title), done = COALESCE(%s, done) "
            "WHERE id = %s RETURNING id, title, done",
            (patch.title, patch.done, todo_id),
        )
        row = cur.fetchone()
    if not row:
        raise HTTPException(404, "todo not found")
    return row


@app.delete("/todos/{todo_id}", status_code=204)
def delete_todo(todo_id: int):
    with get_conn() as conn, conn.cursor() as cur:
        cur.execute("DELETE FROM todos WHERE id = %s", (todo_id,))
        if cur.rowcount == 0:
            raise HTTPException(404, "todo not found")
