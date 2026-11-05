"""Demo service for ENSP461 Lab 2: health, version and a visit counter."""
import os
import socket
import time

from flask import Flask, jsonify
from redis import Redis
from redis.exceptions import RedisError

app = Flask(__name__)
STARTED = time.monotonic()


def version():
    return os.environ.get("APP_VERSION", "dev")


@app.get("/")
def index():
    return jsonify(
        service="ensp461-lab2",
        owner="Samir Kumar Gupta",
        version=version(),
        served_by=socket.gethostname(),
        environment=os.environ.get("APP_ENV", "local"),
    )


@app.get("/health")
def health():
    return jsonify(status="UP", version=version(), uptime_seconds=int(time.monotonic() - STARTED))


@app.get("/visits")
def visits():
    host = os.environ.get("REDIS_HOST")
    if not host:
        return jsonify(error="REDIS_HOST not set"), 503
    try:
        return jsonify(visits=Redis(host=host, socket_timeout=2).incr("visits"))
    except RedisError as exc:
        return jsonify(error=str(exc)), 503


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
