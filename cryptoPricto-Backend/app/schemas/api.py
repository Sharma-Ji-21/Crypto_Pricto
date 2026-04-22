from datetime import datetime

from pydantic import BaseModel, ConfigDict, Field, field_validator

from app.ml.pipeline import normalize_crypto, validate_horizon


class HealthResponse(BaseModel):
    status: str
    timestamp: datetime


class CryptoListResponse(BaseModel):
    cryptos: list[str]


class PredictRequest(BaseModel):
    crypto: str = Field(description="Bitcoin | Ethereum | Dogecoin")
    horizon: int = Field(description="Forecast horizon: 1, 7, or 14")

    @field_validator("crypto")
    @classmethod
    def validate_crypto(cls, value: str) -> str:
        normalize_crypto(value)
        return value

    @field_validator("horizon")
    @classmethod
    def validate_horizon_field(cls, value: int) -> int:
        validate_horizon(value)
        return value


class PredictionPoint(BaseModel):
    date: str
    predicted_price: float


class Metrics(BaseModel):
    rmse: float
    mae: float
    mda: float


class PredictResponse(BaseModel):
    model_config = ConfigDict(protected_namespaces=())

    status: str = "success"
    crypto: str
    horizon: int
    model_used: str
    predictions: list[PredictionPoint]
    metrics: Metrics


class ErrorResponse(BaseModel):
    status: str = "error"
    error_code: int
    message: str


class HistoryItem(BaseModel):
    model_config = ConfigDict(from_attributes=True, protected_namespaces=())

    id: int
    crypto: str
    model_used: str
    rmse: float
    mae: float
    mda: float
    created_at: datetime


class HistoryResponse(BaseModel):
    history: list[HistoryItem]


class PredictionDetailResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True, protected_namespaces=())

    id: int
    crypto: str
    horizon: int
    model_used: str
    predictions: list[PredictionPoint]
    metrics: Metrics
    created_at: datetime


class ErrorLogItem(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    path: str
    method: str
    message: str
    details: dict | None
    created_at: datetime


class ErrorLogResponse(BaseModel):
    errors: list[ErrorLogItem]
