"""Standard error format used by every API:

{"error": {"code": "INVALID_STATE", "message": "...", "details": {...}}}
"""
from typing import Any

from fastapi import FastAPI, Request
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse
from starlette.exceptions import HTTPException as StarletteHTTPException


class APIError(Exception):
    def __init__(self, status_code: int, code: str, message: str, details: dict[str, Any] | None = None):
        self.status_code = status_code
        self.code = code
        self.message = message
        self.details = details or {}


def validation_error(message: str, **details) -> APIError:
    return APIError(400, "VALIDATION_ERROR", message, details)


def unauthorized(message: str = "Authentication required") -> APIError:
    return APIError(401, "UNAUTHORIZED", message)


def forbidden(message: str = "You are not allowed to do this") -> APIError:
    return APIError(403, "FORBIDDEN", message)


def not_found(what: str = "Resource") -> APIError:
    return APIError(404, "NOT_FOUND", f"{what} not found")


def invalid_state(message: str, **details) -> APIError:
    return APIError(409, "INVALID_STATE", message, details)


def geo_mismatch(message: str, **details) -> APIError:
    return APIError(422, "GEO_MISMATCH", message, details)


def rate_limited(message: str = "Too many requests") -> APIError:
    return APIError(429, "RATE_LIMITED", message)


def _body(code: str, message: str, details: dict | None = None) -> dict:
    return {"error": {"code": code, "message": message, "details": details or {}}}


_HTTP_CODES = {400: "VALIDATION_ERROR", 401: "UNAUTHORIZED", 403: "FORBIDDEN", 404: "NOT_FOUND",
               405: "METHOD_NOT_ALLOWED", 409: "INVALID_STATE", 413: "PAYLOAD_TOO_LARGE",
               422: "VALIDATION_ERROR", 429: "RATE_LIMITED"}


def register_error_handlers(app: FastAPI) -> None:
    @app.exception_handler(APIError)
    async def _api_error(_: Request, exc: APIError):
        return JSONResponse(status_code=exc.status_code, content=_body(exc.code, exc.message, exc.details))

    @app.exception_handler(RequestValidationError)
    async def _validation(_: Request, exc: RequestValidationError):
        errors = [{"field": ".".join(str(p) for p in e.get("loc", []) if p != "body"), "message": e.get("msg")}
                  for e in exc.errors()]
        return JSONResponse(status_code=400, content=_body("VALIDATION_ERROR", "Invalid request", {"errors": errors}))

    @app.exception_handler(StarletteHTTPException)
    async def _http(_: Request, exc: StarletteHTTPException):
        code = _HTTP_CODES.get(exc.status_code, "ERROR")
        return JSONResponse(status_code=exc.status_code, content=_body(code, str(exc.detail)))
