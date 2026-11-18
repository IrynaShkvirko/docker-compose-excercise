import time


def slow_square(n: int) -> int:
    """Pretend to do expensive work."""
    time.sleep(5)
    return n * n
