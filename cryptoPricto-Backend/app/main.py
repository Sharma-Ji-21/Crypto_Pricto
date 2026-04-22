from fastapi import FastAPI, Request
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse
from sqlalchemy.orm import Session

from app.api.routes import router
from app.core.config import settings
from app.db.base import Base
from app.db.models import ErrorLog
from app.db.session import engine


app = FastAPI(title=settings.app_name, version=settings.app_version)
app.include_router(router, prefix=settings.api_prefix)


@app.on_event("startup")
def on_startup() -> None:
    Base.metadata.create_all(bind=engine)


def _store_error(path: str, method: str, message: str, details: dict | None = None) -> None:
    db = Session(bind=engine)
    try:
        db.add(ErrorLog(path=path, method=method, message=message, details=details))
        db.commit()
    finally:
        db.close()


@app.exception_handler(RequestValidationError)
def validation_exception_handler(request: Request, exc: RequestValidationError):
    _store_error(
        path=request.url.path,
        method=request.method,
        message="Validation error",
        details={"errors": exc.errors()},
    )
    return JSONResponse(
        status_code=422,
        content={"status": "error", "error_code": 422, "message": "Validation error"},
    )


@app.exception_handler(Exception)
def unhandled_exception_handler(request: Request, exc: Exception):
    _store_error(
        path=request.url.path,
        method=request.method,
        message=str(exc),
    )
    return JSONResponse(
        status_code=500,
        content={"status": "error", "error_code": 500, "message": "Internal server error"},
    )
