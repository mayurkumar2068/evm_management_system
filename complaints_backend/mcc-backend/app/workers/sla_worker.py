"""SLA watcher: every 30 s sends sla.warning (80% of stage time) and sla.breached (100%).

Run exactly ONE worker per environment:
    python -m app.workers.sla_worker
or set ENABLE_SLA_WORKER=true to run it inside a single API process.
"""
import logging
import time

from apscheduler.schedulers.background import BackgroundScheduler

from app.core.config import settings
from app.db.session import SessionLocal
from app.services.sla import run_sla_check

log = logging.getLogger("sla_worker")


def tick() -> dict:
    db = SessionLocal()
    try:
        return run_sla_check(db)
    except Exception:  # keep the scheduler alive
        log.exception("SLA check failed")
        db.rollback()
        return {}
    finally:
        db.close()


def start_background() -> BackgroundScheduler:
    sched = BackgroundScheduler(timezone="UTC")
    sched.add_job(tick, "interval", seconds=settings.SLA_WORKER_INTERVAL_SECONDS, max_instances=1, coalesce=True,
                  id="sla_check")
    sched.start()
    return sched


if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(name)s %(message)s")
    log.info("SLA worker started, interval %ss", settings.SLA_WORKER_INTERVAL_SECONDS)
    while True:
        tick()
        time.sleep(settings.SLA_WORKER_INTERVAL_SECONDS)
