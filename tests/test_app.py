import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent.parent / "app"))
from app import app  # noqa: E402

client = app.test_client()


def test_health(monkeypatch):
    monkeypatch.setenv("APP_VERSION", "9.9.9")
    assert client.get("/health").get_json() == {"status": "UP", "version": "9.9.9"}


def test_index_names_owner():
    assert client.get("/").get_json()["owner"] == "Samir Kumar Gupta"


def test_visits_without_redis_is_503(monkeypatch):
    monkeypatch.delenv("REDIS_HOST", raising=False)
    assert client.get("/visits").status_code == 503
