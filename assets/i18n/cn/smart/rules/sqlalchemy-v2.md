# SQLAlchemy 2.0 开发规则

本规则适用于 SQLAlchemy 2.0+ 项目，强制使用声明式数据映射、异步支持及现代查询风格。所有模型、会话、查询必须遵循以下约定。

---

## 一、声明式基类与命名约定

### 1. 基类定义

使用 `DeclarativeBase` 作为基类，**禁止**使用已废弃的 `declarative_base()` 工厂函数：

```python
from sqlalchemy.orm import DeclarativeBase

class Base(DeclarativeBase):
    pass
```

### 2. 统一约束命名约定（Alembic 稳定迁移必备）

所有约束必须显式配置命名模板，否则 Alembic 生成的迁移脚本在跨数据库/版本时不稳定：

```python
from sqlalchemy import MetaData
from sqlalchemy.orm import DeclarativeBase

NAMING_CONVENTION = {
    "ix": "ix_%(column_0_label)s",
    "uq": "uq_%(table_name)s_%(column_0_name)s",
    "ck": "ck_%(table_name)s_%(constraint_name)s",
    "fk": "fk_%(table_name)s_%(column_0_name)s_%(referred_table_name)s",
    "pk": "pk_%(table_name)s",
}

class Base(DeclarativeBase):
    metadata = MetaData(naming_convention=NAMING_CONVENTION)
```

### 3. 类型注解映射（`type_annotation_map`）

通过 `type_annotation_map` 自定义 Python 类型到 SQL 类型的默认映射，避免每处都写 `mapped_column(String(255))`：

```python
from datetime import datetime
from decimal import Decimal
from sqlalchemy import String, Numeric, DateTime
from sqlalchemy.orm import DeclarativeBase

class Base(DeclarativeBase):
    type_annotation_map = {
        str: String(255),                          # 默认 VARCHAR(255)
        Decimal: Numeric(12, 2),                   # 金额字段统一精度
        datetime: DateTime(timezone=True),         # 全项目启用时区
    }
```

---

## 二、模型字段定义

### 1. `Mapped` + `mapped_column`

使用 `Mapped[类型]` 注解 + `mapped_column()` 替代旧的 `Column` 定义：

```python
from sqlalchemy.orm import Mapped, mapped_column
from sqlalchemy import String, ForeignKey

class User(Base):
    __tablename__ = "users"

    id: Mapped[int] = mapped_column(primary_key=True)
    username: Mapped[str] = mapped_column(String(50), unique=True)
    email: Mapped[str] = mapped_column(String(100), unique=True)
    is_active: Mapped[bool] = mapped_column(default=True)
```

**省略 `mapped_column()` 的条件：** 类型由 `type_annotation_map` 推断、无约束、无自定义参数：

```python
bio: Mapped[str]             # ✅ 等效于 mapped_column()，采用 map 中的 String(255)
```

**可选字段使用 `| None`：**

```python
age: Mapped[int | None]
deleted_at: Mapped[datetime | None]
```

### 2. 时间戳字段

为审计字段使用 `server_default` + `onupdate`，让数据库负责时间戳：

```python
from datetime import datetime
from sqlalchemy import func

class Audit:
    created_at: Mapped[datetime] = mapped_column(
        server_default=func.now(),
    )
    updated_at: Mapped[datetime] = mapped_column(
        server_default=func.now(),
        onupdate=func.now(),
    )
```

**注意：** `default=` 在 Python 端赋值（无 DB 支持时生效）；`server_default=` 在数据库端生成（迁移、裸 SQL 插入也生效）。审计字段**必须**用 `server_default`。

### 3. PostgreSQL 专用类型

使用方言 `dialects.postgresql` 中的类型：

```python
from sqlalchemy.dialects.postgresql import JSONB, ARRAY, UUID
import uuid

class Document(Base):
    __tablename__ = "documents"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        primary_key=True,
        default=uuid.uuid4,
    )
    tags: Mapped[list[str]] = mapped_column(ARRAY(String))
    metadata_: Mapped[dict] = mapped_column("metadata", JSONB)
```

**注意：** `metadata` 是 SQLAlchemy 保留字，用 `metadata_` 或其他名称，通过 `mapped_column("metadata", ...)` 指定实际列名。

### 4. 约束定义

列级内联约束：

```python
from sqlalchemy import CheckConstraint

amount: Mapped[float] = mapped_column(
    CheckConstraint("amount >= 0", name="check_amount_positive"),
)
```

表级约束放入 `__table_args__`：

```python
from sqlalchemy import UniqueConstraint, Index

class Order(Base):
    __tablename__ = "orders"
    # ...
    __table_args__ = (
        UniqueConstraint("user_id", "order_no"),
        Index("ix_orders_status_created", "status", "created_at"),
        CheckConstraint("amount >= 0"),
    )
```

应用层验证可通过 `@validates` 装饰器实现，但**不能**取代数据库约束。

### 5. Mixin 复用字段

```python
class TimestampMixin:
    created_at: Mapped[datetime] = mapped_column(server_default=func.now())
    updated_at: Mapped[datetime] = mapped_column(
        server_default=func.now(), onupdate=func.now()
    )

class SoftDeleteMixin:
    deleted_at: Mapped[datetime | None] = mapped_column(default=None)

class User(Base, TimestampMixin, SoftDeleteMixin):
    __tablename__ = "users"
    id: Mapped[int] = mapped_column(primary_key=True)
```

---

## 三、关系与外键

### 1. 双向关系

```python
from sqlalchemy import ForeignKey
from sqlalchemy.orm import relationship

class Address(Base):
    __tablename__ = "addresses"
    id: Mapped[int] = mapped_column(primary_key=True)
    email: Mapped[str]
    user_id: Mapped[int] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"))
    user: Mapped["User"] = relationship(back_populates="addresses")

class User(Base):
    __tablename__ = "users"
    # ...
    addresses: Mapped[list["Address"]] = relationship(
        back_populates="user",
        cascade="all, delete-orphan",
    )
```

### 2. 级联行为（cascade）

| 常用值 | 含义 |
|-------|------|
| `"save-update"` | 默认：保存父对象时级联保存子对象 |
| `"delete"` | 删除父对象时删除子对象 |
| `"delete-orphan"` | 从父集合移除的子对象自动删除 |
| `"all, delete-orphan"` | 常用组合：关联管理生命周期 |

**ORM cascade** 与数据库 **`ondelete=`** 应同步配置：ORM 层防止脏数据，DB 层保证约束。

### 3. 一对一

`uselist=False` 定义一对一关系：

```python
profile: Mapped["Profile"] = relationship(back_populates="user", uselist=False)
```

### 4. 多对多

使用 `secondary` 指定关联表：

```python
from sqlalchemy import Table, Column

post_tags = Table(
    "post_tags",
    Base.metadata,
    Column("post_id", ForeignKey("posts.id"), primary_key=True),
    Column("tag_id", ForeignKey("tags.id"), primary_key=True),
)

class Post(Base):
    __tablename__ = "posts"
    # ...
    tags: Mapped[list["Tag"]] = relationship(secondary=post_tags)
```

当关联表**有额外字段**时（如 `added_at`），改用 Association Object 模式（显式类）而非 `secondary=`。

---

## 四、会话与事务

### 1. 异步会话（推荐默认）

```python
from collections.abc import AsyncGenerator
from sqlalchemy.ext.asyncio import (
    AsyncSession,
    async_sessionmaker,
    create_async_engine,
)

async_engine = create_async_engine(
    "postgresql+asyncpg://user:pass@localhost/db",
    pool_size=10,
    max_overflow=20,
    pool_pre_ping=True,
    pool_recycle=3600,
)

AsyncSessionLocal = async_sessionmaker(
    async_engine,
    expire_on_commit=False,      # 关键：避免提交后访问属性触发隐式 IO
    autoflush=False,
)

async def get_db() -> AsyncGenerator[AsyncSession, None]:
    async with AsyncSessionLocal() as session:
        try:
            yield session
            await session.commit()
        except Exception:
            await session.rollback()
            raise
```

`expire_on_commit=False` **必选**。默认的 `True` 会让 commit 后所有属性过期，下次访问时触发隐式 IO——在 async 环境中会引发 `MissingGreenlet` 错误或意外的网络往返。

### 2. 异步 Lazy Loading（`AsyncAttrs`）

异步环境下默认 lazy-load **不可用**，会抛 `MissingGreenlet`。两种解决方案：

**方案 A — `AsyncAttrs` mixin（推荐）：**

```python
from sqlalchemy.ext.asyncio import AsyncAttrs

class Base(AsyncAttrs, DeclarativeBase):
    pass

# 使用时：
user = await session.get(User, 1)
addresses = await user.awaitable_attrs.addresses  # ✅ 异步 lazy-load
```

**方案 B — 预加载（性能更可控）：**

```python
from sqlalchemy.orm import selectinload

stmt = select(User).options(selectinload(User.addresses)).where(User.id == uid)
user = (await session.execute(stmt)).scalar_one()
# user.addresses 已加载，无需 await
```

### 3. 事务控制

**隐式事务（推荐）：** `async with AsyncSessionLocal()` 内的操作属同一事务，上方 `yield` + 外层 commit/rollback 模式会自动管理。

**显式嵌套事务（SAVEPOINT）：**

```python
async with session.begin_nested():   # SAVEPOINT
    session.add(obj)
    # 失败只回滚到 SAVEPOINT，不影响外层事务
```

### 4. 同步会话（仅必要时使用）

```python
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

engine = create_engine("sqlite:///app.db")
SessionLocal = sessionmaker(bind=engine, expire_on_commit=False)

def get_db():
    with SessionLocal() as session:
        yield session
```

**禁止**手动 `session.close()`——依赖上下文管理器。

---

## 五、查询语句（2.0 风格）

### 1. 核心模式

**完全抛弃** `session.query()`，统一使用 `select()` + `execute()`：

```python
from sqlalchemy import select

stmt = select(User).where(User.username == "alice")
result = await session.execute(stmt)
user = result.scalar_one_or_none()
```

### 2. 结果取值速查

| 方法 | 返回 | 异常 |
|------|------|------|
| `.scalar_one()` | 单个对象 | 非 1 行则报错 |
| `.scalar_one_or_none()` | 单对象或 `None` | 多行报错 |
| `.scalars().first()` | 第一个对象或 `None` | 不报错 |
| `.scalars().all()` | 对象列表 | 不报错 |
| `.scalars().unique().all()` | 去重（使用 `joinedload` 时必需） | |

### 3. 条件动态构建

```python
stmt = select(User).where(User.is_active.is_(True))
if username:
    stmt = stmt.where(User.username == username)
if created_after:
    stmt = stmt.where(User.created_at >= created_after)
stmt = stmt.order_by(User.created_at.desc()).limit(50)
```

### 4. 加载策略

| 策略 | SQL 行为 | 适用场景 |
|------|---------|---------|
| `selectinload` | 主查询 + `IN (...)` 加载子集合 | 集合关系，推荐默认 |
| `joinedload` | 单个 JOIN | 多对一、一对一关系 |
| `contains_eager` | 显式 JOIN 后告知 ORM 已加载 | 手动 JOIN 时配合 |
| `raiseload` | 禁止 lazy-load（访问即报错） | 生产严格模式 |

```python
from sqlalchemy.orm import selectinload, joinedload

stmt = (
    select(User)
    .options(
        selectinload(User.addresses),       # 一对多
        joinedload(User.profile),            # 一对一
    )
    .where(User.id == uid)
)
```

### 5. 聚合与分组

```python
from sqlalchemy import func

stmt = (
    select(User.role, func.count().label("total"))
    .group_by(User.role)
    .having(func.count() > 10)
)
rows = (await session.execute(stmt)).all()
for row in rows:
    print(row.role, row.total)
```

### 6. UPSERT（PostgreSQL / SQLite / MySQL）

```python
from sqlalchemy.dialects.postgresql import insert

stmt = (
    insert(User)
    .values(email="a@x.com", username="alice")
    .on_conflict_do_update(
        index_elements=[User.email],
        set_={"username": "alice"},
    )
    .returning(User.id)
)
user_id = (await session.execute(stmt)).scalar_one()
```

### 7. `RETURNING` 子句

一次往返获取插入/更新结果：

```python
from sqlalchemy import insert, update

stmt = insert(User).values(...).returning(User.id, User.created_at)
result = await session.execute(stmt)
row = result.one()
```

### 8. 批量操作

```python
# 批量插入
await session.execute(
    insert(User),
    [{"username": "u1", "email": "..."}, {"username": "u2", "email": "..."}],
)

# IN 查询避免 N+1
stmt = select(User).where(User.id.in_(user_ids))
```

### 9. CTE（公用表表达式）

```python
recent_users_cte = (
    select(User.id, User.created_at)
    .where(User.created_at >= cutoff)
    .cte("recent_users")
)
stmt = (
    select(Post, recent_users_cte.c.created_at)
    .join(recent_users_cte, Post.user_id == recent_users_cte.c.id)
)
```

---

## 六、视图映射（只读）

视图使用独立 `MetaData`，避免被 `Base.metadata.create_all` 当作表创建：

```python
from sqlalchemy import Table, MetaData, Column, Integer, String

view_metadata = MetaData()

active_users_view = Table(
    "active_users",
    view_metadata,
    Column("id", Integer, primary_key=True),
    Column("username", String(50)),
)

class ActiveUser(Base):
    __table__ = active_users_view
```

视图 DDL（`CREATE OR REPLACE VIEW ...`）在 `lifespan` 中手动执行，**禁止**注册到 `Base.metadata`。

---

## 七、Alembic 迁移

### 1. 基本原则

- 使用 **Alembic** 管理所有 schema 变更，**禁止**在生产环境使用 `Base.metadata.create_all()`。
- 异步驱动下，`alembic/env.py` 的迁移运行函数需通过 `connection.run_sync(do_run_migrations)` 转为同步模式。

### 2. 自动生成迁移

```bash
alembic revision --autogenerate -m "add user email index"
```

**每次生成后必须人工复核：**
- 检查是否有"意外"的 drop/alter（通常是命名约定缺失导致）
- 服务端默认值、check 约束是否正确同步
- 数据迁移（data migration）须手写，autogenerate 不会生成

### 3. 迁移命名约定

`alembic.ini` 的 `file_template`：

```ini
file_template = %%(year)d%%(month).2d%%(day).2d_%%(hour).2d%%(minute).2d_%%(slug)s
```

生成形如 `20260424_1530_add_user_email_index.py`，时间有序易排序。

---

## 八、测试

### 1. 事务回滚模式（推荐）

每个测试在事务内运行，结束时 rollback，完美隔离且无需清库：

```python
import pytest
from sqlalchemy.ext.asyncio import AsyncSession

@pytest.fixture
async def session(async_engine) -> AsyncSession:
    async with async_engine.connect() as conn:
        trans = await conn.begin()
        async_session = AsyncSession(bind=conn, expire_on_commit=False)
        # 嵌套 SAVEPOINT 让应用代码的 commit 可以正常工作
        await conn.begin_nested()
        yield async_session
        await async_session.close()
        await trans.rollback()
```

### 2. SQLite 内存库作为单元测试

```python
engine = create_async_engine("sqlite+aiosqlite:///:memory:")
```

**注意：** SQLite 不支持 `ARRAY`、`JSONB`、部分 `CHECK` 语法；真实测试建议用与生产相同的数据库（PostgreSQL testcontainers）。

---

## 九、性能与最佳实践

### 1. 连接池

```python
create_async_engine(
    url,
    pool_size=10,          # 常驻连接数
    max_overflow=20,       # 突发上限
    pool_pre_ping=True,    # 每次检出前 ping，防止连接失效
    pool_recycle=3600,     # 1 小时回收，规避云 DB 空闲断连
)
```

### 2. 查询优化

- **禁止**在循环中查询（N+1）——改用 `in_()` 或 `selectinload`。
- 长列表使用 `yield_per()` 流式处理：
  ```python
  result = await session.stream(select(User))
  async for user in result.scalars():
      process(user)
  ```
- 大量插入使用 `session.execute(insert(User), [dict, ...])` 而非逐个 add。
- 开发阶段开启 `echo="debug"` 观察 SQL；生产环境关闭。

### 3. 事务边界

- 长事务会持有行锁——及时 commit。
- 读多场景可用 `AUTOCOMMIT` 隔离级别的独立连接。

---

## 十、禁止事项

| 禁止 | 替代方案 |
|------|---------|
| `declarative_base()` | `class Base(DeclarativeBase)` |
| `Column()` 无 `Mapped` 注解 | `mapped_column()` + `Mapped[T]` |
| `session.query(...)` | `session.execute(select(...))` |
| 异步环境用同步 `Session` | `AsyncSession` |
| 异步下直接访问关系属性触发 lazy-load | `selectinload` 或 `AsyncAttrs.awaitable_attrs` |
| `Base.metadata` 注册视图 `Table` | 独立 `MetaData` |
| `Base.metadata.create_all()` 作为生产变更方式 | Alembic 迁移 |
| 缺少约束命名约定 | `MetaData(naming_convention=...)` |
| `expire_on_commit=True` 搭配 async | `expire_on_commit=False` |
| 循环内查询（N+1） | `in_()` / `selectinload` / 批量操作 |
| 审计字段使用 Python 端 `default=` | `server_default=func.now()` |

---

## 十一、项目集成建议

- **FastAPI 集成：** 通过依赖注入提供 `AsyncSession`，参见 FastAPI 规则第 1、4 节。
- **建表：** 仅开发/测试环境使用 `await conn.run_sync(Base.metadata.create_all)`；生产统一走 Alembic。
- **类型检查：** 使用 `sqlalchemy[mypy]` 或 `sqlalchemy-stubs`；`pyright` 配合 `Mapped[T]` 已开箱即用。
- **依赖安装：**
  ```bash
  uv add 'sqlalchemy[asyncio]' asyncpg alembic
  ```

---

遵循以上规则可保证 SQLAlchemy 2.0 使用规范、类型安全、并规避异步环境下最常见的陷阱。
