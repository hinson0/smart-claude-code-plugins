# FastAPI 开发规则（现代语法 · 2026）

本规则适用于 FastAPI ≥ 0.115.x 项目，结合 Python 3.14 特性，强调依赖注入、类型安全与可维护性。所有端点、依赖项、中间件必须遵循以下约定。

---

## 一、依赖注入

### 1. 核心原则

- **Depends 是标记器**，FastAPI 自动解析依赖树；同一请求内相同依赖默认只执行一次（缓存返回值）。
- 依赖项可以是函数、生成器、类实例（`__call__`）等任意可调用对象。
- 依赖注入应保持纯净：**只做协议转换 / 验证 / 资源管理**，不要在依赖中嵌入业务逻辑。

### 2. 类型注解现代化

**必须**使用 `Annotated` 封装依赖别名，严禁在路径操作函数参数中使用 `Depends(...)` 作为默认值：

```python
# ❌ 旧式（禁止）
async def route(db: Session = Depends(get_db)):
    ...

# ✅ 现代
from typing import Annotated
from fastapi import Depends

DbDep = Annotated[AsyncSession, Depends(get_db)]
CurrentUserDep = Annotated[User, Depends(get_current_user)]

async def route(db: DbDep, user: CurrentUserDep):
    ...
```

**命名约定：**
- 别名以 `Dep` 结尾（`DbDep`、`CurrentUserDep`、`TokenDep`、`SettingsDep`）
- 统一放入 `app/deps.py` 或模块级 `deps.py`，避免散落
- 可组合：`AdminUserDep = Annotated[User, Depends(require_admin)]`

**与 `Query`/`Path`/`Header`/`Body`/`Form` 结合时，元数据放入 `Annotated`：**

```python
PageDep = Annotated[int, Query(ge=1, le=1000)]
ItemIdDep = Annotated[int, Path(ge=1)]
AuthHeaderDep = Annotated[str, Header(alias="X-Auth-Token")]

async def list_items(page: PageDep = 1, token: AuthHeaderDep): ...
```

### 3. 资源生命周期管理（yield 依赖）

管理数据库连接、文件句柄等使用 `yield` 生成器依赖：

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

- **禁止**在 `yield` 依赖上设置 `use_cache=False`，会导致资源泄漏。
- `yield` 之后的代码在响应发出**之后**执行，不能通过 `HTTPException` 修改响应。
- 推荐使用 `async with` 上下文管理器自动清理，标准写法同上。

### 4. 灵活依赖控制（dependencies 参数）

使用 `dependencies` 参数在三个级别注册"只执行不注入返回值"的依赖：

| 级别 | 语法示例 | 典型场景 |
|------|---------|---------|
| 路径 | `@app.get("/items", dependencies=[Depends(verify_token)])` | 单接口鉴权 |
| 路由 | `router = APIRouter(dependencies=[Depends(verify_token)])` | 模块级认证 |
| 全局 | `app = FastAPI(dependencies=[Depends(log_request)])` | 全站日志、API Key 校验 |

**执行顺序：** 全局 → 路由 → 路径 → 参数；同级别按列表顺序执行。

### 5. 缓存控制（use_cache）

同一请求内，默认缓存依赖返回值。如需每次重新执行（如时间戳、UUID），在别名中封装：

```python
TimestampDep = Annotated[float, Depends(get_timestamp, use_cache=False)]
```

不要在端点中散落 `use_cache` 配置。

### 6. 类作为依赖项（参数化依赖）

使用 `__call__` 方法实现参数化类依赖：
- `__init__` 接收**配置参数**（如权限等级、限流阈值）
- `__call__` 接收 **HTTP 请求参数**（`Query`、`Header` 等），执行业务逻辑

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
            raise HTTPException(403, "权限不足")
        return user

require_admin = PermissionChecker("admin")
require_editor = PermissionChecker("editor")

AdminUserDep = Annotated[User, Depends(require_admin)]

@app.get("/admin")
async def admin_panel(user: AdminUserDep):
    ...
```

**禁止**在 `__init__` 中直接使用 `Query()`、`Body()` 等 FastAPI 参数，避免 HTTP 细节污染业务类。

### 7. 嵌套依赖

依赖可以通过参数引用其他依赖，FastAPI 自动解析顺序与缓存：

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

依赖链应保持清晰层次：**协议解析 → 数据查询 → 权限校验 → 业务函数**。

---

## 二、路由组织（APIRouter）

### 1. 模块化路由

将相关端点组织到 `APIRouter`，使用 `prefix`、`tags`、`dependencies` 统一配置：

```python
# app/routers/users.py
from fastapi import APIRouter

router = APIRouter(
    prefix="/users",
    tags=["users"],
    dependencies=[Depends(verify_token)],
    responses={401: {"description": "未授权"}, 404: {"description": "未找到"}},
)

@router.get("/{user_id}")
async def get_user(user_id: int, db: DbDep) -> UserOut:
    ...

# app/main.py
from app.routers import users, items
app.include_router(users.router)
app.include_router(items.router, prefix="/api/v1")
```

### 2. 路由命名约定

- 文件名：`app/routers/<resource>.py`（`users.py`、`items.py`、`auth.py`）
- 每个模块导出 `router = APIRouter(...)`
- **禁止**在 `main.py` 中定义业务端点——只负责应用装配与 router 注册

---

## 三、路径操作与请求处理

### 1. 路径参数

使用 `Annotated` 结合 `Path` 声明验证规则：

```python
@app.get("/items/{item_id}")
async def read_item(item_id: Annotated[int, Path(ge=1, le=1_000_000)]):
    ...
```

### 2. 查询参数

```python
# 必填
name: Annotated[str, Query(min_length=1, max_length=100)]

# 可选
keyword: Annotated[str | None, Query()] = None

# 带默认值
limit: Annotated[int, Query(ge=1, le=100)] = 20

# 列表
tags: Annotated[list[str], Query()] = []
```

### 3. 请求体与响应模型

使用 Pydantic 模型作为请求/响应类型：

```python
@router.post("/", response_model=UserOut, status_code=201)
async def create_user(payload: UserCreate, db: DbDep) -> User:
    user = User(**payload.model_dump())
    db.add(user)
    await db.flush()
    return user
```

**返回类型注解**（`-> User`）用于类型检查；**`response_model`**（`UserOut`）用于序列化与过滤。两者可不同——ORM 对象进，Pydantic 模型出，FastAPI 自动转换。

### 4. 响应配置

```python
@router.get(
    "/items/{item_id}",
    response_model=ItemOut,
    response_model_exclude_unset=True,   # 跳过未显式设置的字段
    response_model_exclude_none=True,    # 跳过 None 字段
    status_code=200,
    summary="获取单个 Item",
    description="按 ID 获取 Item 详情",
    responses={404: {"model": ErrorResponse}},
    deprecated=False,
)
async def get_item(item_id: int): ...
```

### 5. 表单与文件

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

### 6. Request 对象

当需要访问原始 ASGI 信息或 `request.state` 时，直接注入 `Request`：

```python
from fastapi import Request

@router.get("/ip")
async def get_ip(request: Request) -> dict[str, str | None]:
    return {"ip": request.client.host if request.client else None}
```

**注意：** `request.client` 返回 `Address(host, port)` 对象或 `None`，并非元组。

### 7. 后台任务（BackgroundTasks）

轻量级后台工作（发邮件、写日志）使用 `BackgroundTasks`：

```python
from fastapi import BackgroundTasks

@router.post("/notify")
async def notify(payload: NotifyIn, tasks: BackgroundTasks) -> dict[str, str]:
    tasks.add_task(send_email, payload.to, payload.subject, payload.body)
    return {"status": "queued"}
```

**后台任务在响应发出后执行**，不影响响应时间。复杂任务应使用 Celery / ARQ / Dramatiq 等专业队列。

### 8. 流式响应

大数据或实时流使用 `StreamingResponse`：

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

Server-Sent Events 使用 `media_type="text/event-stream"`。

### 9. WebSocket

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

WebSocket 中不能使用标准 `HTTPException`，应使用 `WebSocketException` 或 `ws.close(code=1008)`。

### 10. 中间件

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

**内置中间件**（通过 `app.add_middleware()` 注册）：

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

**中间件执行顺序：后注册先执行**（栈式）——调试时注意。

### 11. 异常处理

使用 `HTTPException` 返回标准错误；自定义异常通过 `@app.exception_handler` 注册：

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

覆盖默认验证错误响应：

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

## 四、应用配置

### 1. 生命周期事件

`@app.on_event("startup")` / `"shutdown"` **已废弃**，使用 `lifespan` 异步上下文管理器：

```python
from contextlib import asynccontextmanager
from collections.abc import AsyncIterator

@asynccontextmanager
async def lifespan(app: FastAPI) -> AsyncIterator[None]:
    # 启动
    app.state.db_engine = create_async_engine(settings.database_url)
    await init_db(app.state.db_engine)
    yield
    # 关闭
    await app.state.db_engine.dispose()

app = FastAPI(lifespan=lifespan)
```

生命周期中创建的资源可挂到 `app.state`，端点通过 `request.app.state` 访问。

### 2. 配置管理（pydantic-settings）

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

- `@lru_cache` 确保单例加载，避免每次请求读环境变量。
- 通过 `SettingsDep` 注入到端点，**禁止**在模块顶层直接读取 `os.environ`。

### 3. OpenAPI 元信息

```python
app = FastAPI(
    title="My API",
    version="1.0.0",
    description="...",
    openapi_tags=[
        {"name": "users", "description": "用户相关操作"},
        {"name": "items", "description": "Item 操作"},
    ],
    docs_url="/docs" if settings.debug else None,
    redoc_url=None,
)
```

生产环境建议关闭 `/docs` 与 `/redoc`，或通过认证路由保护。

---

## 五、测试

### 1. 依赖覆盖（dependency_overrides）

测试时使用 `app.dependency_overrides` 替换真实依赖：

```python
from fastapi.testclient import TestClient

def get_test_db():
    return MockSession()

app.dependency_overrides[get_db] = get_test_db

client = TestClient(app)

def test_list_users():
    response = client.get("/users")
    assert response.status_code == 200
    app.dependency_overrides.clear()  # 测试后清理
```

推荐用 pytest fixture + `yield` 自动清理。

### 2. 异步测试

使用 `httpx.AsyncClient` + `pytest-asyncio`：

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

## 六、安全

### 1. OAuth2 Password Bearer

```python
from fastapi.security import OAuth2PasswordBearer

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="auth/login")
TokenDep = Annotated[str, Depends(oauth2_scheme)]

async def get_current_user(token: TokenDep, db: DbDep) -> User:
    ...
```

### 2. API Key（Header / Query / Cookie）

```python
from fastapi.security import APIKeyHeader

api_key_header = APIKeyHeader(name="X-API-Key")
ApiKeyDep = Annotated[str, Depends(api_key_header)]
```

### 3. 范围（Scopes）与 `Security()`

使用 `Security()` 替代 `Depends()` 以支持 OAuth2 scopes：

```python
from fastapi import Security
from fastapi.security import SecurityScopes

async def require_scopes(
    security_scopes: SecurityScopes,
    token: TokenDep,
) -> User:
    # 校验 token 中包含 security_scopes.scopes 要求的范围
    ...

@router.get("/admin", dependencies=[Security(require_scopes, scopes=["admin"])])
async def admin(): ...
```

---

## 七、性能与响应

- 默认启用 `response_model`，利用 Pydantic 过滤/序列化响应，避免手动转换。
- IO 密集操作使用 `async def` + `await`；CPU 密集任务放入线程池或独立进程。
- **禁止**在 `async def` 内调用阻塞 IO（`requests.get`、`time.sleep`、同步数据库驱动）——会阻塞事件循环。
- 大文件下载使用 `StreamingResponse` 或 `FileResponse`，避免一次性读入内存。
- 启用 `GZipMiddleware` 压缩响应；对高频静态响应配置 `Cache-Control`。

---

## 八、禁止事项

| 禁止 | 替代方案 |
|------|---------|
| 参数使用 `= Depends(...)` 默认值 | `Annotated[T, Depends(...)]` 别名 |
| `yield` 依赖设置 `use_cache=False` | 默认缓存，依赖 `async with` 清理 |
| 类依赖 `__init__` 使用 `Query()` / `Body()` | 放入 `__call__` |
| `@app.on_event("startup")` / `"shutdown")` | `lifespan` 异步上下文管理器 |
| 模块顶层读 `os.environ` | `BaseSettings` + `@lru_cache` 依赖注入 |
| 返回原始 ORM 对象无 `response_model` | 显式 `response_model` 控制序列化 |
| `async def` 中调用阻塞 IO | 改用异步库或 `run_in_executor` |
| 在 `main.py` 定义业务端点 | 拆分到 `APIRouter` |
| WebSocket 中 `raise HTTPException` | `WebSocketException` / `ws.close()` |
| 测试时手动 mock 全局状态 | `app.dependency_overrides` |

---

## 九、推荐实践

- **项目结构**：
  ```
  app/
  ├── main.py           # 装配 app + lifespan
  ├── deps.py           # 统一 Annotated 依赖别名
  ├── config.py         # Settings + get_settings
  ├── routers/          # APIRouter 模块
  ├── schemas/          # Pydantic 模型
  ├── models/           # SQLAlchemy 等 ORM 模型
  ├── services/         # 业务逻辑
  └── tests/
  ```
- 所有端点必须声明 `response_model` 或返回类型注解，保证 OpenAPI 文档完整。
- 异常统一抛出自定义业务异常，全局 handler 转换为标准错误响应。
- 启用 `pyright --strict` 或 `mypy --strict` 检查类型覆盖。

---

遵循以上规则可确保 FastAPI 项目类型安全、可测试、可维护，并充分利用现代 Python 与 FastAPI 的特性。
