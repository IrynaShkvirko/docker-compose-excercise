import json
import os
import threading
from datetime import datetime, timezone

from flask import Flask, jsonify, request

app = Flask(__name__)
DATA_FILE = os.getenv("DATA_FILE", "posts.json")
lock = threading.Lock()


def load():
    try:
        with open(DATA_FILE) as f:
            return json.load(f)
    except FileNotFoundError:
        return []


def save(posts):
    with open(DATA_FILE, "w") as f:
        json.dump(posts, f, indent=2)


@app.get("/api/posts")
def list_posts():
    return jsonify(load())


@app.post("/api/posts")
def create_post():
    data = request.get_json(silent=True) or {}
    if not data.get("title") or not data.get("body"):
        return jsonify(error="title and body required"), 400
    with lock:
        posts = load()
        post = {"id": len(posts) + 1, "title": data["title"], "body": data["body"],
                "created": datetime.now(timezone.utc).isoformat()}
        posts.append(post)
        save(posts)
    return jsonify(post), 201


@app.get("/api/health")
def health():
    return jsonify(status="ok")


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=int(os.getenv("PORT", "5000")))
