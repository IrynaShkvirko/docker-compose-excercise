import os
import random
import time

from flask import Flask, Response, jsonify
from prometheus_client import CONTENT_TYPE_LATEST, Counter, Gauge, Histogram, generate_latest

app = Flask(__name__)

REQUESTS = Counter("app_requests_total", "Total requests", ["endpoint", "status"])
LATENCY = Histogram("app_request_latency_seconds", "Request latency", ["endpoint"])
IN_PROGRESS = Gauge("app_requests_in_progress", "Requests currently being handled")


@app.get("/")
def index():
    REQUESTS.labels("/", "200").inc()
    return jsonify(message="metrics demo", try_=["/work", "/error", "/metrics"])


@app.get("/work")
def work():
    with IN_PROGRESS.track_inprogress(), LATENCY.labels("/work").time():
        time.sleep(random.uniform(0.05, 0.6))
    REQUESTS.labels("/work", "200").inc()
    return jsonify(status="done")


@app.get("/error")
def error():
    if random.random() < 0.5:
        REQUESTS.labels("/error", "500").inc()
        return jsonify(error="random failure"), 500
    REQUESTS.labels("/error", "200").inc()
    return jsonify(status="lucky")


@app.get("/metrics")
def metrics():
    return Response(generate_latest(), mimetype=CONTENT_TYPE_LATEST)


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=int(os.getenv("PORT", "5000")))
