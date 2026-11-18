import os
import time

from flask import Flask, jsonify

app = Flask(__name__)
START = time.time()


@app.get("/")
def index():
    return jsonify(message=f"Hello-Hello-Hello from {os.getenv('APP_NAME', 'flask-health-api')}",
                   env=os.getenv("APP_ENV", "local"))


@app.get("/health")
def health():
    return jsonify(status="ok", uptime_seconds=round(time.time() - START, 1))


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=int(os.getenv("PORT", "5000")))
