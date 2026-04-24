# SQLAlchemy 2.0 Development Rules

These rules apply to SQLAlchemy 2.0+ projects, enforcing declarative mapping, async support, and modern query style. All models, sessions, and queries must follow these conventions.

---

## 1. Declarative Base and Naming Conventions

### 1.1 Base Class

Use `DeclarativeBase` as the base. **Forbidden**: the deprecated `declarative_base()` factory.

```python
from sqlalchemy.orm import DeclarativeBase

class Base(DeclarativeBase):
    pass
```

### 1.2 Constraint Naming Convention (critical for stable Alembic migrations)

Configure naming templates explicitly. Without them, auto-generated constraint names vary across dialects/versions and cause unstable migration diffs:

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

### 1.3 Type Annotation Map (`type_annotation_map`)

Customize the Python-to-SQL type mapping to avoid repeating `mapped_column(String(255))` everywhere:

```python
from datetime import datetime
from decimal import Decimal
from sqlalchemy import String, Numeric, DateTime
from sqlalchemy.orm import DeclarativeBase

class Base(DeclarativeBase):
    type_annotation_map = {
        str: String(255),                          # Default VARCHAR(255)
        Decimal: Numeric(12, 2),                   # Unified monetary precision
        datetime: DateTime(timezone=True),         # Timezone-aware project-wide
    }
```

---

## 2. Model Field Definition

### 2.1 `Mapped` + `mapped_column`

Use `Mapped[T]` annotations with `mapped_column()`, replacing the old `Column`:

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

**When `mapped_column()` can be omitted:** type is resolved via `type_annotation_map`, no constraints, no custom parameters:

```python
bio: Mapped[str]             # ✅ Equivalent to mapped_column(), uses String(255) from map
```

**Optional fields use `| None`:**

```python
age: Mapped[int | None]
deleted_at: Mapped[datetime | None]
```

### 2.2 Timestamp Fields

Use `server_default` + `onupdate` so the database generates audit timestamps:

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

**Note:** `default=` runs in Python; `server_default=` runs in the database (works for migrations and raw SQL inserts too). Audit fields **must** use `server_default`.

### 2.3 PostgreSQL-Specific Types

Use dialect-specific types from `sqlalchemy.dialects.postgresql`:

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

**Note:** `metadata` is reserved by SQLAlchemy. Use `metadata_` (or another name) with `mapped_column("metadata", ...)` to specify the actual column name.

### 2.4 Constraints

Inline column-level constraints:

```python
from sqlalchemy import CheckConstraint

amount: Mapped[float] = mapped_column(
    CheckConstraint("amount >= 0", name="check_amount_positive"),
)
```

Table-level constraints in `__table_args__`:

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

Application-level validation via `@validates` is fine, but **does not replace** database constraints.

### 2.5 Mixin Reuse

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

## 3. Relationships and Foreign Keys

### 3.1 Bidirectional Relationships

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

### 3.2 Cascade Behavior

| Common value | Meaning |
|-------------|---------|
| `"save-update"` | Default: saving parent cascades to children |
| `"delete"` | Deleting parent deletes children |
| `"delete-orphan"` | Removing a child from the parent collection deletes it |
| `"all, delete-orphan"` | Common combo: parent fully owns child lifecycle |

**ORM cascade** and database **`ondelete=`** should be configured together: ORM layer prevents inconsistency at application level, DB layer enforces constraints at storage level.

### 3.3 One-to-One

Use `uselist=False`:

```python
profile: Mapped["Profile"] = relationship(back_populates="user", uselist=False)
```

### 3.4 Many-to-Many

Use `secondary` with an association table:

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

When the association table has **extra fields** (e.g. `added_at`), use the Association Object pattern (explicit class) instead of `secondary=`.

---

## 4. Sessions and Transactions

### 4.1 Async Session (default)

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
    expire_on_commit=False,      # Critical: avoid implicit IO after commit
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

`expire_on_commit=False` is **mandatory**. The default `True` expires all attributes after commit, causing implicit IO on next access — in async context this raises `MissingGreenlet` or produces surprise round trips.

### 4.2 Async Lazy Loading (`AsyncAttrs`)

Default lazy-load is **unavailable** in async context — it raises `MissingGreenlet`. Two solutions:

**Option A — `AsyncAttrs` mixin (recommended):**

```python
from sqlalchemy.ext.asyncio import AsyncAttrs

class Base(AsyncAttrs, DeclarativeBase):
    pass

# Usage:
user = await session.get(User, 1)
addresses = await user.awaitable_attrs.addresses  # ✅ async lazy-load
```

**Option B — Eager loading (more predictable performance):**

```python
from sqlalchemy.orm import selectinload

stmt = select(User).options(selectinload(User.addresses)).where(User.id == uid)
user = (await session.execute(stmt)).scalar_one()
# user.addresses is loaded; no await needed
```

### 4.3 Transaction Control

**Implicit transactions (recommended):** Operations inside `async with AsyncSessionLocal()` belong to the same transaction. The `yield` + outer commit/rollback pattern handles it automatically.

**Explicit nested transactions (SAVEPOINT):**

```python
async with session.begin_nested():   # SAVEPOINT
    session.add(obj)
    # Failure only rolls back to SAVEPOINT, outer transaction unaffected
```

### 4.4 Sync Session (only when necessary)

```python
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

engine = create_engine("sqlite:///app.db")
SessionLocal = sessionmaker(bind=engine, expire_on_commit=False)

def get_db():
    with SessionLocal() as session:
        yield session
```

**Forbidden**: manual `session.close()` — rely on the context manager.

---

## 5. Query Statements (2.0 Style)

### 5.1 Core Pattern

**Abandon** `session.query()` entirely. Use `select()` + `execute()`:

```python
from sqlalchemy import select

stmt = select(User).where(User.username == "alice")
result = await session.execute(stmt)
user = result.scalar_one_or_none()
```

### 5.2 Result Extraction Reference

| Method | Returns | Raises |
|--------|---------|--------|
| `.scalar_one()` | Single object | Errors if not exactly 1 row |
| `.scalar_one_or_none()` | Object or `None` | Errors on multiple rows |
| `.scalars().first()` | First object or `None` | Never raises |
| `.scalars().all()` | List of objects | Never raises |
| `.scalars().unique().all()` | Deduplicated (required with `joinedload`) | |

### 5.3 Dynamic Conditions

```python
stmt = select(User).where(User.is_active.is_(True))
if username:
    stmt = stmt.where(User.username == username)
if created_after:
    stmt = stmt.where(User.created_at >= created_after)
stmt = stmt.order_by(User.created_at.desc()).limit(50)
```

### 5.4 Loading Strategies

| Strategy | SQL behavior | When to use |
|---------|-------------|-------------|
| `selectinload` | Main query + `IN (...)` for children | Collections (default recommendation) |
| `joinedload` | Single JOIN | Many-to-one, one-to-one |
| `contains_eager` | Manual JOIN, tell ORM results are loaded | With hand-written JOINs |
| `raiseload` | Forbid lazy-load (access raises) | Strict production mode |

```python
from sqlalchemy.orm import selectinload, joinedload

stmt = (
    select(User)
    .options(
        selectinload(User.addresses),       # one-to-many
        joinedload(User.profile),            # one-to-one
    )
    .where(User.id == uid)
)
```

### 5.5 Aggregation and Grouping

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

### 5.6 UPSERT (PostgreSQL / SQLite / MySQL)

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

### 5.7 `RETURNING` Clause

Fetch results in a single round-trip:

```python
from sqlalchemy import insert, update

stmt = insert(User).values(...).returning(User.id, User.created_at)
result = await session.execute(stmt)
row = result.one()
```

### 5.8 Bulk Operations

```python
# Bulk insert
await session.execute(
    insert(User),
    [{"username": "u1", "email": "..."}, {"username": "u2", "email": "..."}],
)

# IN query to avoid N+1
stmt = select(User).where(User.id.in_(user_ids))
```

### 5.9 CTE (Common Table Expression)

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

## 6. View Mapping (Read-Only)

Views must use a separate `MetaData` to prevent `Base.metadata.create_all` from creating them as tables:

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

Execute view DDL (`CREATE OR REPLACE VIEW ...`) manually inside `lifespan`. **Forbidden**: registering views in `Base.metadata`.

---

## 7. Alembic Migrations

### 7.1 Principles

- Use **Alembic** for all schema changes. **Forbidden**: `Base.metadata.create_all()` in production.
- For async drivers, `alembic/env.py` must wrap migrations with `connection.run_sync(do_run_migrations)`.

### 7.2 Autogenerate

```bash
alembic revision --autogenerate -m "add user email index"
```

**Always review generated migrations:**
- Check for unexpected drop/alter (usually from missing naming conventions)
- Verify `server_default` and check constraints are synced correctly
- Data migrations must be written manually — autogenerate won't do it

### 7.3 Migration File Naming

In `alembic.ini`:

```ini
file_template = %%(year)d%%(month).2d%%(day).2d_%%(hour).2d%%(minute).2d_%%(slug)s
```

Generates files like `20260424_1530_add_user_email_index.py` — time-ordered and easy to sort.

---

## 8. Testing

### 8.1 Transaction Rollback Pattern (recommended)

Run each test in a transaction and roll back at the end. Perfect isolation, no cleanup needed:

```python
import pytest
from sqlalchemy.ext.asyncio import AsyncSession

@pytest.fixture
async def session(async_engine) -> AsyncSession:
    async with async_engine.connect() as conn:
        trans = await conn.begin()
        async_session = AsyncSession(bind=conn, expire_on_commit=False)
        # Nested SAVEPOINT so app-level commits work
        await conn.begin_nested()
        yield async_session
        await async_session.close()
        await trans.rollback()
```

### 8.2 In-Memory SQLite for Unit Tests

```python
engine = create_async_engine("sqlite+aiosqlite:///:memory:")
```

**Caveat:** SQLite does not support `ARRAY`, `JSONB`, or some `CHECK` syntaxes. For realistic tests, use the same DB as production (PostgreSQL via testcontainers).

---

## 9. Performance Best Practices

### 9.1 Connection Pool

```python
create_async_engine(
    url,
    pool_size=10,          # Persistent connections
    max_overflow=20,       # Burst ceiling
    pool_pre_ping=True,    # Ping before checkout to avoid dead connections
    pool_recycle=3600,     # Recycle every hour (avoids cloud DB idle disconnects)
)
```

### 9.2 Query Optimization

- **Forbidden**: querying in loops (N+1). Use `in_()` or `selectinload`.
- Use `stream()` for large result sets:
  ```python
  result = await session.stream(select(User))
  async for user in result.scalars():
      process(user)
  ```
- Use `session.execute(insert(User), [dict, ...])` for batches, not `session.add()` in a loop.
- Set `echo="debug"` in development to inspect SQL; disable in production.

### 9.3 Transaction Boundaries

- Long transactions hold row locks — commit promptly.
- For read-heavy scenarios, use a separate connection with `AUTOCOMMIT` isolation.

---

## 10. Forbidden Patterns

| Forbidden | Replacement |
|-----------|------------|
| `declarative_base()` | `class Base(DeclarativeBase)` |
| `Column()` without `Mapped` annotation | `mapped_column()` + `Mapped[T]` |
| `session.query(...)` | `session.execute(select(...))` |
| Sync `Session` in async context | `AsyncSession` |
| Accessing relationship attrs in async without prep | `selectinload` or `AsyncAttrs.awaitable_attrs` |
| Registering view `Table` in `Base.metadata` | Separate `MetaData` |
| `Base.metadata.create_all()` in production | Alembic migrations |
| No naming convention | `MetaData(naming_convention=...)` |
| `expire_on_commit=True` with async | `expire_on_commit=False` |
| Queries in loops (N+1) | `in_()` / `selectinload` / bulk ops |
| Python-level `default=` for audit timestamps | `server_default=func.now()` |

---

## 11. Project Integration

- **FastAPI integration:** Provide `AsyncSession` via dependency injection — see FastAPI rules sections 1 and 4.
- **Table creation:** Use `await conn.run_sync(Base.metadata.create_all)` in dev/test only; production always uses Alembic.
- **Type checking:** Use `sqlalchemy[mypy]` or `sqlalchemy-stubs`; `pyright` works out-of-the-box with `Mapped[T]`.
- **Dependencies:**
  ```bash
  uv add 'sqlalchemy[asyncio]' asyncpg alembic
  ```

---

Following these rules keeps SQLAlchemy 2.0 code correct, type-safe, and avoids the most common async-context pitfalls.
