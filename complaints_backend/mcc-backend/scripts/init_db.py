"""Create all tables, triggers, seed data and views from db/schema.sql
in the database named in DATABASE_URL.

    python -m scripts.init_db            # create (fails if tables exist)
    python -m scripts.init_db --reset    # DROP and recreate the database (dev/test only!)
"""
import re
import sys
from pathlib import Path

import pymysql
from sqlalchemy.engine import make_url

from app.core.config import settings

SCHEMA = Path(__file__).resolve().parents[1] / "db" / "schema.sql"


def split_sql(sql: str) -> list[str]:
    """Split on ';' but honour DELIMITER blocks (triggers)."""
    statements, delim, buf = [], ";", []
    for line in sql.splitlines():
        stripped = line.strip()
        m = re.match(r"(?i)^DELIMITER\s+(\S+)", stripped)
        if m:
            delim = m.group(1)
            continue
        buf.append(line)
        if stripped.endswith(delim):
            stmt = "\n".join(l for l in buf if not l.strip().startswith("--")).rstrip()
            stmt = stmt[: -len(delim)]
            if stmt.strip():
                statements.append(stmt)
            buf = []
    return statements


def run(database_url: str = settings.DATABASE_URL, reset: bool = False) -> None:
    url = make_url(database_url)
    dbname = url.database
    conn = pymysql.connect(host=url.host, port=url.port or 3306, user=url.username, password=url.password or "",
                           charset="utf8mb4", autocommit=True)
    with conn.cursor() as cur:
        if reset:
            cur.execute(f"DROP DATABASE IF EXISTS `{dbname}`")
        cur.execute(f"CREATE DATABASE IF NOT EXISTS `{dbname}` DEFAULT CHARACTER SET utf8mb4 "
                    f"DEFAULT COLLATE utf8mb4_0900_ai_ci")
        cur.execute(f"USE `{dbname}`")
        sql = SCHEMA.read_text(encoding="utf-8")
        for stmt in split_sql(sql):
            head = stmt.strip().split(None, 2)[:2]
            if head and head[0].upper() == "USE":
                continue
            if [h.upper() for h in head] == ["CREATE", "DATABASE"]:
                continue
            cur.execute(stmt)
    conn.close()
    print(f"Schema applied to {dbname}")


if __name__ == "__main__":
    run(reset="--reset" in sys.argv)
