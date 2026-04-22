from __future__ import annotations

from functools import lru_cache

import numpy as np
import pandas as pd
from sklearn.metrics import mean_absolute_error, mean_squared_error
from sklearn.preprocessing import MinMaxScaler
from tensorflow.keras.models import load_model

from app.core.constants import COIN_ASSETS, LSTM_FEATURES, SUPPORTED_HORIZONS, WINDOW


def normalize_crypto(crypto: str) -> str:
    key = crypto.strip().lower()
    if key not in COIN_ASSETS:
        raise ValueError("crypto must be Bitcoin, Ethereum, or Dogecoin")
    return key


def validate_horizon(horizon: int) -> int:
    if horizon not in SUPPORTED_HORIZONS:
        raise ValueError("horizon must be one of 1, 7, or 14")
    return horizon


def compute_rsi(series: pd.Series, period: int = 14) -> pd.Series:
    delta = series.diff()
    gain = delta.clip(lower=0).ewm(com=period - 1, min_periods=period).mean()
    loss = (-delta.clip(upper=0)).ewm(com=period - 1, min_periods=period).mean()
    return 100 - (100 / (1 + gain / loss))


def prepare_lstm_frame(raw_df: pd.DataFrame) -> pd.DataFrame:
    d = (
        raw_df[["Date", "Open", "High", "Low", "Close", "Volume"]]
        .copy()
        .sort_values("Date")
        .reset_index(drop=True)
    )

    d["EMA_12"] = d["Close"].ewm(span=12, adjust=False).mean()
    d["EMA_26"] = d["Close"].ewm(span=26, adjust=False).mean()
    d["MACD"] = d["EMA_12"] - d["EMA_26"]
    d["RSI"] = compute_rsi(d["Close"])

    bb_mid = d["Close"].rolling(20).mean()
    bb_std = d["Close"].rolling(20).std()
    d["BB_Position"] = (d["Close"] - (bb_mid - 2 * bb_std)) / (4 * bb_std + 1e-9)

    tr = pd.concat(
        [
            d["High"] - d["Low"],
            (d["High"] - d["Close"].shift(1)).abs(),
            (d["Low"] - d["Close"].shift(1)).abs(),
        ],
        axis=1,
    ).max(axis=1)
    d["ATR_14"] = tr.rolling(14).mean()

    d["Log_Return"] = np.log(d["Close"] / d["Close"].shift(1))
    d["target"] = d["Log_Return"].shift(-1)

    d = d.replace([np.inf, -np.inf], np.nan).dropna().reset_index(drop=True)
    return d


def make_sequences(X: np.ndarray, y: np.ndarray, window: int) -> tuple[np.ndarray, np.ndarray]:
    xs, ys = [], []
    for i in range(window, len(X)):
        xs.append(X[i - window : i])
        ys.append(y[i])
    return np.array(xs), np.array(ys)


def load_price_data(crypto_key: str) -> pd.DataFrame:
    asset = COIN_ASSETS[crypto_key]
    if not asset.data_file.exists():
        raise FileNotFoundError(f"Data file missing: {asset.data_file}")

    df = pd.read_csv(asset.data_file)
    df["Date"] = pd.to_datetime(df["Date"])
    df = df.sort_values("Date").reset_index(drop=True)
    return df


@lru_cache(maxsize=8)
def get_lstm_model(model_path: str):
    return load_model(model_path)


def compute_backtest_metrics(model, d: pd.DataFrame) -> dict[str, float]:
    scaler = MinMaxScaler()
    X_all = scaler.fit_transform(d[LSTM_FEATURES])
    targets = d["target"].values

    X_seq, y_seq = make_sequences(X_all, targets, WINDOW)
    if len(X_seq) < 5:
        raise ValueError("Not enough sequence data to evaluate model")

    split_seq = int(len(X_seq) * 0.8)
    X_test_s = X_seq[split_seq:]
    y_test_s = y_seq[split_seq:]

    preds_log = model.predict(X_test_s, verbose=0).flatten()

    rmse = float(np.sqrt(mean_squared_error(y_test_s, preds_log)))
    mae = float(mean_absolute_error(y_test_s, preds_log))
    mda = float(np.mean(np.sign(y_test_s) == np.sign(preds_log)))

    return {
        "rmse": round(rmse, 6),
        "mae": round(mae, 6),
        "mda": round(mda, 4),
    }


def forecast_prices(crypto: str, horizon: int) -> dict:
    crypto_key = normalize_crypto(crypto)
    validate_horizon(horizon)

    asset = COIN_ASSETS[crypto_key]
    if not asset.model_file.exists():
        raise FileNotFoundError(f"Model file missing: {asset.model_file}")

    raw_df = load_price_data(crypto_key)
    d = prepare_lstm_frame(raw_df)

    model = get_lstm_model(str(asset.model_file))
    metrics = compute_backtest_metrics(model, d)

    scaler = MinMaxScaler()
    X_all = scaler.fit_transform(d[LSTM_FEATURES])

    if len(X_all) < WINDOW:
        raise ValueError("Not enough data to build the inference window")

    recent_window = X_all[-WINDOW:].copy()
    rolling_df = raw_df[["Date", "Open", "High", "Low", "Close", "Volume"]].copy()

    predictions = []

    for _ in range(horizon):
        next_log_return = float(model.predict(recent_window[np.newaxis, :, :], verbose=0)[0][0])

        prev_row = rolling_df.iloc[-1]
        prev_close = float(prev_row["Close"])
        next_close = float(prev_close * np.exp(next_log_return))
        next_date = pd.to_datetime(prev_row["Date"]) + pd.Timedelta(days=1)

        next_row = {
            "Date": next_date,
            "Open": prev_close,
            "High": max(prev_close, next_close),
            "Low": min(prev_close, next_close),
            "Close": next_close,
            "Volume": float(prev_row["Volume"]),
        }

        rolling_df = pd.concat([rolling_df, pd.DataFrame([next_row])], ignore_index=True)

        engineered = prepare_lstm_frame(rolling_df)
        next_feature_row = engineered.iloc[-1:][LSTM_FEATURES]
        next_scaled = scaler.transform(next_feature_row)[0]

        recent_window = np.vstack([recent_window[1:], next_scaled])

        predictions.append(
            {
                "date": next_date.strftime("%Y-%m-%d"),
                "predicted_price": round(next_close, 6),
            }
        )

    return {
        "crypto": asset.display_name,
        "horizon": horizon,
        "model_used": "LSTM",
        "predictions": predictions,
        "metrics": metrics,
    }
