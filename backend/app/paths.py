"""Resolved paths for templates and static assets (local dev vs Docker image)."""
from pathlib import Path


def frontend_dir() -> Path:
    """
    Return the `frontend` directory.
    - Docker: /app/frontend (copied next to the app package under /app).
    - Local: repository `frontend/` (sibling of `backend/`).
    """
    app_pkg = Path(__file__).resolve().parent
    install_root = app_pkg.parent
    docker_fe = install_root / "frontend"
    if docker_fe.is_dir() and (docker_fe / "templates").is_dir():
        return docker_fe
    return install_root.parent / "frontend"
