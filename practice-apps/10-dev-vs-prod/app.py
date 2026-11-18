import logging
import os

from flask import Flask, jsonify

APP_ENV = os.getenv("APP_ENV", "development")
LOG_LEVEL = os.getenv("LOG_LEVEL", "DEBUG" if APP_ENV == "development" else "INFO")
logging.basicConfig(level=LOG_LEVEL)

app = Flask(__name__)


@app.get("/")
def index():
    app.logger.debug("index called")
    return jsonify(message="Hello!", env=APP_ENV)


@app.get("/config")
def config():
    """Shows effective config so you can verify which compose file/profile is active."""
    return jsonify(env=APP_ENV, log_level=LOG_LEVEL,
                   debug=app.debug, greeting=os.getenv("GREETING", "(unset)"))


@app.get("/health")
def health():
    return jsonify(status="ok")


if __name__ == "__main__":
    # Reloader restarts on code change - useful with a bind mount in dev.
    dev = APP_ENV == "development"
    app.run(host="0.0.0.0", port=int(os.getenv("PORT", "5000")), debug=dev, use_reloader=dev)
