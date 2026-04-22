from dataclasses import dataclass
from pathlib import Path

from app.core.config import DATA_DIR, MODELS_DIR


WINDOW = 30
LSTM_FEATURES = [
    "Close",
    "Volume",
    "RSI",
    "MACD",
    "BB_Position",
    "ATR_14",
    "Log_Return",
]


@dataclass(frozen=True)
class CoinAsset:
    display_name: str
    data_file: Path
    model_file: Path


COIN_ASSETS = {
    "bitcoin": CoinAsset(
        display_name="Bitcoin",
        data_file=DATA_DIR / "coin_Bitcoin.csv",
        model_file=MODELS_DIR / "btc_lstm.keras",
    ),
    "ethereum": CoinAsset(
        display_name="Ethereum",
        data_file=DATA_DIR / "coin_Ethereum.csv",
        model_file=MODELS_DIR / "eth_lstm.keras",
    ),
    "dogecoin": CoinAsset(
        display_name="Dogecoin",
        data_file=DATA_DIR / "coin_Dogecoin.csv",
        model_file=MODELS_DIR / "doge_lstm.keras",
    ),
}

SUPPORTED_CRYPTOS = [asset.display_name for asset in COIN_ASSETS.values()]
SUPPORTED_HORIZONS = {1, 7, 14}
