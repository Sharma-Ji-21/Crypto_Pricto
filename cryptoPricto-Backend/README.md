# Crypto Forecast API (Bitcoin, Ethereum, Dogecoin)

FastAPI backend for LSTM-based crypto forecasting using your saved models in `models/` and CSV files in `data/`.

## Features

- `GET /api/v1/health`
- `GET /api/v1/cryptos`
- `POST /api/v1/predict`
- `GET /api/v1/history`
- `GET /api/v1/history/{prediction_id}`
- `GET /api/v1/errors`

## ML Flow (Notebook-Aligned)

1. Validate request (`crypto`, `horizon`)
2. Load pre-trained LSTM `.keras` model from `models/`
3. Load coin OHLCV CSV from `data/`
4. Apply feature engineering:
   - `EMA_12`, `EMA_26`, `MACD`
   - `RSI`
   - `BB_Position`
   - `ATR_14`
   - `Log_Return`
   - `target = Log_Return.shift(-1)`
5. Fit `MinMaxScaler` on LSTM features
6. Build `WINDOW=30` sequences
7. Backtest metrics on 80/20 split (`RMSE`, `MAE`, `MDA`)
8. Iterative horizon prediction:
   - predict log-return
   - convert to price (`next_close = prev_close * exp(log_return)`)
   - append synthetic next-day OHLCV row
   - recompute engineered features
9. Store output in PostgreSQL table `predictions`

## Setup

1. Create virtual environment and install dependencies:

```bash
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

2. Configure env:

```bash
cp .env.example .env
```

3. Ensure PostgreSQL is running and DB exists (`crypto_forecast` by default).

4. Start API:

```bash
uvicorn app.main:app --reload
```

## Request Example

```bash
curl -X POST http://127.0.0.1:8000/api/v1/predict \
  -H "Content-Type: application/json" \
  -d '{"crypto": "Bitcoin", "horizon": 7}'
```

## Database Schema

### `predictions`

- `id` serial primary key
- `crypto` varchar
- `horizon` integer
- `model_used` varchar
- `predictions` jsonb
- `metrics` jsonb
- `created_at` timestamp

### `error_logs`

- `id` serial primary key
- `path` varchar
- `method` varchar
- `message` varchar
- `details` jsonb nullable
- `created_at` timestamp

## Notes

- Supported cryptos: Bitcoin, Ethereum, Dogecoin
- Supported horizons: 1, 7, 14
- Models are loaded from:
  - `models/btc_lstm.keras`
  - `models/eth_lstm.keras`
  - `models/doge_lstm.keras`
