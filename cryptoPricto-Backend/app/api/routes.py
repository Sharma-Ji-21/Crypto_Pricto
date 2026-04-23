from datetime import datetime, timezone

from fastapi import APIRouter, Depends, HTTPException, Request
from sqlalchemy.orm import Session

from app.core.constants import SUPPORTED_CRYPTOS
from app.db.models import ErrorLog, Prediction
from app.db.session import get_db
from app.ml.pipeline import forecast_prices, load_price_data, normalize_crypto
from app.schemas.api import (
    CryptoListResponse,
    ErrorLogResponse,
    ErrorResponse,
    HealthResponse,
    HistoryItem,
    HistoryResponse,
    PredictRequest,
    PredictResponse,
    PredictionDetailResponse,
)

router = APIRouter()


@router.get("/health", response_model=HealthResponse)
def health() -> HealthResponse:
    return HealthResponse(status="ok", timestamp=datetime.now(timezone.utc))


@router.get("/cryptos", response_model=CryptoListResponse)
def get_cryptos() -> CryptoListResponse:
    return CryptoListResponse(cryptos=SUPPORTED_CRYPTOS)


@router.post(
    "/predict",
    response_model=PredictResponse,
    responses={400: {"model": ErrorResponse}, 422: {"model": ErrorResponse}},
)
def predict(payload: PredictRequest, request: Request, db: Session = Depends(get_db)) -> PredictResponse:
    crypto_key = normalize_crypto(payload.crypto)
    try:
        df = load_price_data(crypto_key)
    except FileNotFoundError as exc:
        raise HTTPException(status_code=500, detail=str(exc)) from exc

    last_date = df["Date"].max().date()
    horizon = (payload.target_date - last_date).days

    if horizon <= 0:
        raise HTTPException(status_code=400, detail="Target date must be in future")

    if horizon > 30:
        raise HTTPException(status_code=400, detail="Max prediction window is 30 days")

    try:
        result = forecast_prices(payload.crypto, horizon)
    except ValueError as exc:
        raise HTTPException(status_code=422, detail=str(exc)) from exc
    except FileNotFoundError as exc:
        raise HTTPException(status_code=500, detail=str(exc)) from exc

    final_prediction = result["predictions"][-1]

    prediction_row = Prediction(
        crypto=result["crypto"],
        horizon=horizon,
        model_used=result["model_used"],
        predictions=result["predictions"],
        metrics=result["metrics"],
    )
    db.add(prediction_row)
    db.commit()

    return PredictResponse(
        status="success",
        crypto=result["crypto"],
        target_date=payload.target_date,
        model_used=result["model_used"],
        predicted_price=final_prediction["predicted_price"],
        metrics=result["metrics"],
    )


@router.get("/history", response_model=HistoryResponse)
def history(db: Session = Depends(get_db)) -> HistoryResponse:
    rows = db.query(Prediction).order_by(Prediction.created_at.desc()).all()
    items = []
    for row in rows:
        final_prediction = row.predictions[-1]
        items.append(
            HistoryItem(
                id=row.id,
                crypto=row.crypto,
                target_date=final_prediction["date"],
                predicted_price=final_prediction["predicted_price"],
                model_used=row.model_used,
                rmse=float(row.metrics.get("rmse", 0.0)),
                mae=float(row.metrics.get("mae", 0.0)),
                mda=float(row.metrics.get("mda", 0.0)),
                created_at=row.created_at,
            )
        )
    return HistoryResponse(history=items)


@router.get(
    "/history/{prediction_id}",
    response_model=PredictionDetailResponse,
    responses={404: {"model": ErrorResponse}},
)
def history_detail(prediction_id: int, db: Session = Depends(get_db)) -> PredictionDetailResponse:
    row = db.query(Prediction).filter(Prediction.id == prediction_id).first()
    if row is None:
        raise HTTPException(status_code=404, detail="Prediction not found")

    return PredictionDetailResponse(
        id=row.id,
        crypto=row.crypto,
        horizon=row.horizon,
        model_used=row.model_used,
        predictions=row.predictions,
        metrics=row.metrics,
        created_at=row.created_at,
    )


@router.get("/errors", response_model=ErrorLogResponse)
def list_errors(db: Session = Depends(get_db)) -> ErrorLogResponse:
    rows = db.query(ErrorLog).order_by(ErrorLog.created_at.desc()).limit(200).all()
    return ErrorLogResponse(errors=[row for row in rows])
