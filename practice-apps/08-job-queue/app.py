import os

from flask import Flask, jsonify, request
from redis import Redis
from rq import Queue
from rq.job import Job

import tasks

app = Flask(__name__)
redis_conn = Redis(host=os.getenv("REDIS_HOST", "localhost"), port=int(os.getenv("REDIS_PORT", "6379")))
queue = Queue("jobs", connection=redis_conn)


@app.post("/jobs")
def enqueue():
    n = (request.get_json(silent=True) or {}).get("n")
    if not isinstance(n, int):
        return jsonify(error="integer 'n' required"), 400
    job = queue.enqueue(tasks.slow_square, n)
    return jsonify(id=job.id, status=job.get_status()), 202


@app.get("/jobs/<job_id>")
def status(job_id):
    try:
        job = Job.fetch(job_id, connection=redis_conn)
    except Exception:
        return jsonify(error="not found"), 404
    return jsonify(id=job.id, status=job.get_status(), result=job.result)


@app.get("/health")
def health():
    redis_conn.ping()
    return jsonify(status="ok", queued=len(queue))


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=int(os.getenv("PORT", "5000")))
