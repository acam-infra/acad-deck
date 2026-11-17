"""Load deck.toml from the repository root."""
import pathlib
import tomllib

ROOT = pathlib.Path(__file__).resolve().parents[2]
CONFIG_PATH = ROOT / "deck.toml"


def load_config() -> dict:
    if not CONFIG_PATH.exists():
        raise FileNotFoundError(f"deck.toml not found at {CONFIG_PATH}")
    with open(CONFIG_PATH, "rb") as f:
        return tomllib.load(f)
