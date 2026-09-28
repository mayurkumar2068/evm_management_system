"""Create the first ADMIN user (everything else is created through the admin APIs).

    python -m scripts.create_admin --username admin --mobile 9XXXXXXXXX --name "System Admin"
Password is read from the terminal.
"""
import argparse
import getpass

from sqlalchemy import select

from app.core.security import hash_password, new_uuid
from app.db.session import SessionLocal
from app.models import User


def main() -> None:
    p = argparse.ArgumentParser()
    p.add_argument("--username", required=True)
    p.add_argument("--mobile", required=True)
    p.add_argument("--name", default="System Admin")
    p.add_argument("--password")
    a = p.parse_args()
    password = a.password or getpass.getpass("Password (min 8 chars): ")
    if len(password) < 8:
        raise SystemExit("Password too short")
    db = SessionLocal()
    if db.scalar(select(User).where(User.username == a.username)):
        raise SystemExit("Username already exists")
    db.add(User(uuid=new_uuid(), role="ADMIN", name=a.name, mobile=a.mobile, username=a.username,
                password_hash=hash_password(password), preferred_lang="en"))
    db.commit()
    print(f"Admin {a.username} created")


if __name__ == "__main__":
    main()
