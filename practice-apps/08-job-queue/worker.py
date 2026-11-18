import os
import socket

from redis import Redis
from rq import Queue, Worker

redis_conn = Redis(host=os.getenv("REDIS_HOST", "localhost"), port=int(os.getenv("REDIS_PORT", "6379")))

if __name__ == "__main__":
    # Name includes hostname so scaled replicas are distinguishable in logs.
    Worker([Queue("jobs", connection=redis_conn)], connection=redis_conn,
           name=f"worker-{socket.gethostname()}").work()
