# FastAPI Development Rules (Modern Syntax · 2026)

These rules apply to FastAPI ≥ 0.115.x projects combined with Python 3.14 features, emphasizing dependency injection, type safety, and maintainability. All endpoints, dependencies, and middleware must follow these conventions.

---

## 1. Dependency Injection

### 1.1 Core Principles

- **`Depends` is a marker.** FastAPI resolves the dependency tree automatically. Within a single request, the same dependency runs only once by default (return value is cached).
- Dependencies can be functions, generators, or class instances with `__call__`.
- Keep dependencies pure: **protocol conversion, validation, resource management only** — never embed business logic.

### 1.2 Modern Type Annotations

**Mandatory**: Use `Annotated` with dependency aliases. Never use `Depends(...)` as a default parameter value.

```python
# ❌ Old style (forbidden)
async def route(db: Session = Depends(get_db)):
    ...

# ✅ Modern
from typing import Annotated
from fastapi import Depends

DbDep = Annotated[AsyncSession, Depends(get_db)]
CurrentUserDep = Annotated[User, Depends(get_current_user)]

async def route(db: DbDep, user: CurrentUserDep):
    ...
```

**Naming conventions:**
- Aliases end with `Dep` (`DbDep`, `CurrentUserDep`, `TokenDep`, `SettingsDep`)
- Centralize in `app/deps.py` or module-level `deps.py` — do not scatter
- Composable: `AdminUserDep = Annotated[User, Depends(require_admin)]`

**Combining with `Query`/`Path`/`Header`/`Body`/`Form`** — put metadata in `Annotated`:

```python
PageDep = Annotated[int, Query(ge=1, le=1000)]
ItemIdDep = Annotated[int, Path(ge=1)]
AuthHeaderDep = Annotated[str, Header(alias="X-Auth-Token")]

async def list_items(page: PageDep = 1, token: AuthHeaderDep): ...
```

### 1.3 Resource Lifecycle (yield dependencies)

Use `yield` generator dependencies for database connections, file handles, etc.:

```python
from collections.abc import AsyncGenerator

async def get_db() -> AsyncGenerator[AsyncSession, None]:
    async with AsyncSessionLocal() as session:
        try:
            yield session
            await session.commit()
        except Exception:
            await session.rollback()
            raise
        finally:
            await session.close()
```

- **Forbidden**: setting `use_cache=False` on `yield` dependencies — causes resource leaks.
- Code after `yield` runs **after** the response is sent; cannot modify the response via `HTTPException`.
- Prefer `async with` context managers for automatic cleanup.

### 1.4 Flexible Dependencies (`dependencies` parameter)

Use the `dependencies` parameter to register "execute-only, no injection" dependencies at three levels:

| Level | Syntax | Typical use |
|-------|--------|-------------|
| Path | `@app.get("/items", dependencies=[Depends(verify_token)])` | Single-endpoint auth |
| Router | `router = APIRouter(dependencies=[Depends(verify_token)])` | Module-level auth |
| Global | `app = FastAPI(dependencies=[Depends(log_request)])` | Site-wide logging, API key check |

**Execution order**: global → router → path → parameters. Within the same level, list order applies.

### 1.5 Cache Control (`use_cache`)

Dependencies are cached per-request by default. For values that must re-execute each call (timestamps, UUIDs), encode in the alias:

```python
TimestampDep = Annotated[float, Depends(get_timestamp, use_cache=False)]
```

Do not scatter `use_cache` in endpoints.

### 1.6 Class-Based Dependencies (parameterized)

Use `__call__` for parameterized class dependencies:
- `__init__` takes **configuration** (role level, rate limit threshold)
- `__call__` takes **HTTP request parameters** (`Query`, `Header`) and executes logic

```python
from fastapi import HTTPException

class PermissionChecker:
    def __init__(self, required_role: str) -> None:
        self.required_role = required_role

    def __call__(
        self,
        user: Annotated[User, Depends(get_current_user)],
    ) -> User:
        if user.role != self.required_role:
            raise HTTPException(403, "insufficient permissions")
        return user

require_admin = PermissionChecker("admin")
require_editor = PermissionChecker("editor")

AdminUserDep = Annotated[User, Depends(require_admin)]

@app.get("/admin")
async def admin_panel(user: AdminUserDep):
    ...
```

**Forbidden**: using `Query()`, `Body()`, etc. in `__init__` — keeps HTTP details out of business classes.

### 1.7 Nested Dependencies

Dependencies can reference other dependencies. FastAPI resolves order and caching automatically:

```python
async def get_token(auth: Annotated[str, Header()]) -> str:
    if not auth.startswith("Bearer "):
        raise HTTPException(401)
    return auth[7:]

async def get_current_user(
    token: Annotated[str, Depends(get_token)],
    db: DbDep,
) -> User:
    user = await db.get(User, decode_jwt(token)["sub"])
    if user is None:
        raise HTTPException(401)
    return user
```

Keep dependency chains in clear layers: **protocol parsing → data lookup → authorization → business function**.

---

## 2. Route Organization (APIRouter)

### 2.1 Modular Routing

Group related endpoints in `APIRouter` with shared `prefix`, `tags`, `dependencies`:

```python
# app/routers/users.py
from fastapi import APIRouter

router = APIRouter(
    prefix="/users",
    tags=["users"],
    dependencies=[Depends(verify_token)],
    responses={401: {"description": "unauthorized"}, 404: {"description": "not found"}},
)

@router.get("/{user_id}")
async def get_user(user_id: int, db: DbDep) -> UserOut:
    ...

# app/main.py
from app.routers import users, items
app.include_router(users.router)
app.include_router(items.router, prefix="/api/v1")
```

### 2.2 Naming Conventions

- File names: `app/routers/<resource>.py` (`users.py`, `items.py`, `auth.py`)
- Each module exports `router = APIRouter(...)`
- **Forbidden**: defining endpoints in `main.py` — it should only wire the app and register routers.

---

## 3. Path Operations and Request Handling

### 3.1 Path Parameters

Use `Annotated` with `Path` for validation:

```python
@app.get("/items/{item_id}")
async def read_item(item_id: Annotated[int, Path(ge=1, le=1_000_000)]):
    ...
```

### 3.2 Query Parameters

```python
# Required
name: Annotated[str, Query(min_length=1, max_length=100)]

# Optional
keyword: Annotated[str | None, Query()] = None

# With default
limit: Annotated[int, Query(ge=1, le=100)] = 20

# List
tags: Annotated[list[str], Query()] = []
```

### 3.3 Request Body and Response Model

Use Pydantic models for request/response types:

```python
@router.post("/", response_model=UserOut, status_code=201)
async def create_user(payload: UserCreate, db: DbDep) -> User:
    user = User(**payload.model_dump())
    db.add(user)
    await db.flush()
    return user
```

The **return annotation** (`-> User`) is for type checking; **`response_model`** (`UserOut`) is for serialization and filtering. They can differ — ORM object in, Pydantic model out, FastAPI converts automatically.

### 3.4 Response Configuration

```python
@router.get(
    "/items/{item_id}",
    response_model=ItemOut,
    response_model_exclude_unset=True,   # skip fields not explicitly set
    response_model_exclude_none=True,    # skip None fields
    status_code=200,
    summary="Get single item",
    description="Retrieve item detail by ID",
    responses={404: {"model": ErrorResponse}},
    deprecated=False,
)
async def get_item(item_id: int): ...
```

### 3.5 Forms and Files

```python
from fastapi import Form, UploadFile, File

@router.post("/upload")
async def upload(
    description: Annotated[str, Form()],
    file: Annotated[UploadFile, File()],
):
    contents = await file.read()
    ...
```

### 3.6 Request Object

Inject `Request` directly when raw ASGI info or `request.state` is needed:

```python
from fastapi import Request

@router.get("/ip")
async def get_ip(request: Request) -> dict[str, str | None]:
    return {"ip": request.client.host if request.client else None}
```

**Note**: `request.client` returns an `Address(host, port)` object or `None`, not a tuple.

### 3.7 Background Tasks

Lightweight background work (send email, write logs) uses `BackgroundTasks`:

```python
from fastapi import BackgroundTasks

@router.post("/notify")
async def notify(payload: NotifyIn, tasks: BackgroundTasks) -> dict[str, str]:
    tasks.add_task(send_email, payload.to, payload.subject, payload.body)
    return {"status": "queued"}
```

Background tasks run **after the response is sent**, so they do not delay response time. For heavy workloads, use a proper queue (Celery, ARQ, Dramatiq).

### 3.8 Streaming Responses

Use `StreamingResponse` for large data or real-time streams:

```python
from fastapi.responses import StreamingResponse

@router.get("/export")
async def export_csv():
    async def generate() -> AsyncGenerator[bytes, None]:
        yield b"id,name\n"
        async for row in db.stream(select(Item)):
            yield f"{row.id},{row.name}\n".encode()

    return StreamingResponse(generate(), media_type="text/csv")
```

For Server-Sent Events use `media_type="text/event-stream"`.

### 3.9 WebSocket

```python
from fastapi import WebSocket, WebSocketDisconnect

@app.websocket("/ws")
async def websocket_endpoint(ws: WebSocket) -> None:
    await ws.accept()
    try:
        while True:
            data = await ws.receive_text()
            await ws.send_text(f"echo: {data}")
    except WebSocketDisconnect:
        logger.info("client disconnected")
```

WebSocket handlers cannot raise standard `HTTPException`; use `WebSocketException` or `ws.close(code=1008)`.

### 3.10 Middleware

```python
from typing import Awaitable, Callable
from fastapi import Request, Response

@app.middleware("http")
async def request_id_middleware(
    request: Request,
    call_next: Callable[[Request], Awaitable[Response]],
) -> Response:
    request.state.request_id = uuid4().hex
    response = await call_next(request)
    response.headers["X-Request-ID"] = request.state.request_id
    return response
```

**Built-in middleware** (register via `app.add_middleware()`):

```python
from fastapi.middleware.cors import CORSMiddleware
from fastapi.middleware.gzip import GZipMiddleware
from fastapi.middleware.trustedhost import TrustedHostMiddleware

app.add_middleware(
    CORSMiddleware,
    allow_origins=["https://example.com"],
    allow_methods=["*"],
    allow_headers=["*"],
    allow_credentials=True,
)
app.add_middleware(GZipMiddleware, minimum_size=1000)
app.add_middleware(TrustedHostMiddleware, allowed_hosts=["example.com", "*.example.com"])
```

**Execution order: last-registered runs first** (stack semantics) — important when debugging.

### 3.11 Exception Handling

Use `HTTPException` for standard errors; register custom exception handlers via `@app.exception_handler`:

```python
from fastapi import HTTPException, Request
from fastapi.responses import JSONResponse

class BusinessError(Exception):
    def __init__(self, code: str, message: str) -> None:
        self.code = code
        self.message = message

@app.exception_handler(BusinessError)
async def business_error_handler(request: Request, exc: BusinessError) -> JSONResponse:
    return JSONResponse(
        status_code=400,
        content={"code": exc.code, "message": exc.message},
    )
```

Override default validation error response:

```python
from fastapi.exceptions import RequestValidationError

@app.exception_handler(RequestValidationError)
async def validation_handler(request: Request, exc: RequestValidationError) -> JSONResponse:
    return JSONResponse(
        status_code=422,
        content={"code": "VALIDATION_ERROR", "errors": exc.errors()},
    )
```

---

## 4. Application Configuration

### 4.1 Lifecycle Events

`@app.on_event("startup")` / `"shutdown"` is **deprecated**. Use the `lifespan` async context manager:

```python
from contextlib import asynccontextmanager
from collections.abc import AsyncIterator

@asynccontextmanager
async def lifespan(app: FastAPI) -> AsyncIterator[None]:
    # startup
    app.state.db_engine = create_async_engine(settings.database_url)
    await init_db(app.state.db_engine)
    yield
    # shutdown
    await app.state.db_engine.dispose()

app = FastAPI(lifespan=lifespan)
```

Resources created in `lifespan` can be attached to `app.state`, accessed in endpoints via `request.app.state`.

### 4.2 Configuration (pydantic-settings)

```python
from pydantic_settings import BaseSettings, SettingsConfigDict
from functools import lru_cache

class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8")

    database_url: str
    secret_key: str
    debug: bool = False

@lru_cache
def get_settings() -> Settings:
    return Settings()

SettingsDep = Annotated[Settings, Depends(get_settings)]
```

- `@lru_cache` ensures single-load semantics, avoiding repeated env reads.
- Inject via `SettingsDep`. **Forbidden**: reading `os.environ` at module top level.

### 4.3 OpenAPI Metadata

```python
app = FastAPI(
    title="My API",
    version="1.0.0",
    description="...",
    openapi_tags=[
        {"name": "users", "description": "User operations"},
        {"name": "items", "description": "Item operations"},
    ],
    docs_url="/docs" if settings.debug else None,
    redoc_url=None,
)
```

Consider disabling `/docs` and `/redoc` in production, or protecting them behind auth.

---

## 5. Testing

### 5.1 Dependency Overrides

Use `app.dependency_overrides` to replace real dependencies in tests:

```python
from fastapi.testclient import TestClient

def get_test_db():
    return MockSession()

app.dependency_overrides[get_db] = get_test_db

client = TestClient(app)

def test_list_users():
    response = client.get("/users")
    assert response.status_code == 200
    app.dependency_overrides.clear()  # clean up after test
```

Prefer pytest fixtures with `yield` for automatic cleanup.

### 5.2 Async Tests

Use `httpx.AsyncClient` with `pytest-asyncio`:

```python
import pytest
from httpx import AsyncClient, ASGITransport

@pytest.mark.asyncio
async def test_async_route():
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        response = await ac.get("/items")
    assert response.status_code == 200
```

---

## 6. Security

### 6.1 OAuth2 Password Bearer

```python
from fastapi.security import OAuth2PasswordBearer

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="auth/login")
TokenDep = Annotated[str, Depends(oauth2_scheme)]

async def get_current_user(token: TokenDep, db: DbDep) -> User:
    ...
```

### 6.2 API Key (Header / Query / Cookie)

```python
from fastapi.security import APIKeyHeader

api_key_header = APIKeyHeader(name="X-API-Key")
ApiKeyDep = Annotated[str, Depends(api_key_header)]
```

### 6.3 Scopes and `Security()`

Use `Security()` instead of `Depends()` for OAuth2 scopes:

```python
from fastapi import Security
from fastapi.security import SecurityScopes

async def require_scopes(
    security_scopes: SecurityScopes,
    token: TokenDep,
) -> User:
    # Validate token contains the scopes listed in security_scopes.scopes
    ...

@router.get("/admin", dependencies=[Security(require_scopes, scopes=["admin"])])
async def admin(): ...
```

---

## 7. Performance and Response

- Always set `response_model` — let Pydantic filter and serialize responses automatically.
- Use `async def` + `await` for IO-bound work; dispatch CPU-bound tasks to a thread pool or separate process.
- **Forbidden**: blocking IO inside `async def` (e.g. `requests.get`, `time.sleep`, synchronous DB drivers) — it blocks the event loop.
- Use `StreamingResponse` or `FileResponse` for large downloads; avoid loading the full payload into memory.
- Enable `GZipMiddleware` for response compression; add `Cache-Control` headers for frequently-requested static responses.

---

## 8. Forbidden Patterns

| Forbidden | Replacement |
|-----------|------------|
| `= Depends(...)` as default parameter value | `Annotated[T, Depends(...)]` alias |
| `use_cache=False` on `yield` dependencies | Default caching; rely on `async with` for cleanup |
| `Query()` / `Body()` in class `__init__` | Put in `__call__` |
| `@app.on_event("startup")` / `"shutdown")` | `lifespan` async context manager |
| Reading `os.environ` at module top level | `BaseSettings` + `@lru_cache` dependency |
| Returning raw ORM object without `response_model` | Set `response_model` explicitly |
| Blocking IO inside `async def` | Use async libraries or `run_in_executor` |
| Defining endpoints in `main.py` | Split into `APIRouter` modules |
| `raise HTTPException` in WebSocket | `WebSocketException` / `ws.close()` |
| Manually mocking global state in tests | `app.dependency_overrides` |

---

## 9. Recommended Project Structure

```
app/
├── main.py           # App assembly + lifespan
├── deps.py           # Centralized Annotated dependency aliases
├── config.py         # Settings + get_settings
├── routers/          # APIRouter modules
├── schemas/          # Pydantic models
├── models/           # SQLAlchemy or other ORM models
├── services/         # Business logic
└── tests/
```

- All endpoints must declare `response_model` or a return type annotation — ensures complete OpenAPI docs.
- Raise custom business exceptions; a global handler converts them into standard error responses.
- Enable `pyright --strict` or `mypy --strict` to verify annotation coverage.

---

Following these rules keeps FastAPI projects type-safe, testable, and maintainable, while fully leveraging modern Python and FastAPI features.
