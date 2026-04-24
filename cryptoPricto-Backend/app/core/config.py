from pathlib import Path

from pydantic import Field
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    app_name: str = "CryptoPricto"
    app_version: str = "1.0.0"
    api_prefix: str = "/api"

    database_url: str = Field(
        default="postgresql+psycopg2://postgres:postgres@localhost:5432/crypto_forecast"
    )

    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8")


settings = Settings()

ROOT_DIR = Path(__file__).resolve().parents[2]
DATA_DIR = ROOT_DIR / "data"
MODELS_DIR = ROOT_DIR / "models"
