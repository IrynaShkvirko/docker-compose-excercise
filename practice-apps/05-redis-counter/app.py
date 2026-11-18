import os

import redis
from flask import Flask, jsonify, request

app = Flask(__name__)
r = redis.Redis(host=os.getenv("REDIS_HOST", "localhost"),
                port=int(os.getenv("REDIS_PORT", "6379")),
                decode_responses=True)

LIMIT = int(os.getenv("RATE_LIMIT", "5"))
WINDOW = int(os.getenv("RATE_WINDOW_SECONDS", "60"))


@app.get("/visit")
def visit():
    return jsonify(visits=r.incr("visits"))


@app.get("/limited")
def limited():
    key = f"rate:{request.remote_addr}"
    count = r.incr(key)
    if count == 1:
        r.expire(key, WINDOW)
    if count > LIMIT:
        return jsonify(error="rate limit exceeded", retry_after=r.ttl(key)), 429
    return jsonify(calls=count, limit=LIMIT)


@app.get("/health")
def health():
    r.ping()
    return jsonify(status="ok")


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=int(os.getenv("PORT", "5000")))
