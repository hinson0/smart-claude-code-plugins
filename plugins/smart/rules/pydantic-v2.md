# Pydantic V2 Development Rules

These rules apply to Pydantic V2 (≥ 2.5.x) projects combined with Python 3.10+ features, emphasizing type safety, strict validation, and serialization control. All models, validators, and settings classes must follow these conventions.

---

## 1. Model Definition

### 1.1 Declaration

Use `BaseModel` with all configuration inside `model_config` via `ConfigDict`:

```python
from pydantic import BaseModel, ConfigDict

class User(BaseModel):
    model_config = ConfigDict(
        from_attributes=True,
        validate_assignment=True,
        str_strip_whitespace=True,
    )

    name: str
    age: int | None = None
```

- **Forbidden**: V1 `class Config` inner class.
- **Forbidden**: V1 methods such as `from_orm()`, `dict()`, `parse_obj()`.
- Field types must use Python 3.10+ built-in generics (`list[int]`, `str | None`). **Forbidden**: `typing.List`, `typing.Optional`.

### 1.2 Common `ConfigDict` Parameters

| Parameter | Purpose | Recommendation |
|-----------|---------|----------------|
| `from_attributes` | Allow building from ORM / arbitrary object attributes (replaces V1 `orm_mode`) | `True` for ORM models |
| `validate_assignment` | Re-validate on field assignment | Enable for mutable models |
| `extra` | `'ignore'` (default) / `'forbid'` / `'allow'` | Use `'forbid'` for API inputs |
| `str_strip_whitespace` | Auto-strip whitespace from strings | Recommended for API inputs |
| `validate_default` | Whether defaults pass through validators | Enable for strict scenarios |
| `populate_by_name` | Allow both field name and alias | Use with aliases |
| `frozen` | Immutable instances (hashable) | Recommended for value objects |
| `arbitrary_types_allowed` | Allow non-Pydantic types as fields | Use carefully |
| `revalidate_instances` | `'never'` / `'always'` / `'subclass-instances'` | Use `'always'` for inheritance |

**Performance tip:** Enabling `validate_assignment` globally triggers full re-validation on every field assignment. Enable only on models where assignment guards are actually needed.

### 1.3 `Field()` and Constraints

Use `Field()` for defaults, constraints, and metadata:

```python
from pydantic import BaseModel, Field

class Product(BaseModel):
    name: str = Field(min_length=1, max_length=100)
    price: float = Field(gt=0, le=1_000_000, description="Price including tax")
    tags: list[str] = Field(default_factory=list, max_length=20)
    slug: str = Field(pattern=r"^[a-z0-9-]+$")
    rating: int = Field(ge=0, le=5)
```

**Common constraints:**

| Type | Constraints |
|------|-------------|
| Numeric | `gt`, `ge`, `lt`, `le`, `multiple_of` |
| String | `min_length`, `max_length`, `pattern` |
| Collection | `min_length`, `max_length` |
| Decimal | `max_digits`, `decimal_places` |

**Mutable default trap:** Use `Field(default_factory=list)` for mutable defaults. **Forbidden**: `Field(default=[])` — Pydantic V2 raises an error.

### 1.4 Aliases

Handle camelCase APIs and multi-source data:

```python
from pydantic import BaseModel, Field, AliasChoices, AliasPath

class User(BaseModel):
    model_config = ConfigDict(populate_by_name=True)

    user_id: int = Field(alias="userId")
    email: str = Field(
        validation_alias=AliasChoices("email", "emailAddress", "mail"),
    )
    city: str = Field(validation_alias=AliasPath("address", "city"))
    display_name: str = Field(serialization_alias="displayName")
```

- `validation_alias`: names accepted on input
- `serialization_alias`: name used on output
- `AliasChoices`: multiple candidate names (matched in order)
- `AliasPath`: extract from a nested path (`{"address": {"city": "NYC"}}`)
- `populate_by_name=True`: allow both field name and alias on input

### 1.5 Discriminated Unions

Use `discriminator` for polymorphic models — O(1) validation with precise error locations:

```python
from typing import Literal
from pydantic import BaseModel, Field

class Cat(BaseModel):
    kind: Literal["cat"]
    meow_volume: int

class Dog(BaseModel):
    kind: Literal["dog"]
    bark_loudness: int

class Pet(BaseModel):
    animal: Cat | Dog = Field(discriminator="kind")

Pet.model_validate({"animal": {"kind": "cat", "meow_volume": 5}})
```

**Forbidden**: using plain `Union` without a discriminator for polymorphic scenarios — Pydantic tries each branch in order, error messages are ambiguous, performance is poor.

### 1.6 Computed Fields

Derived read-only properties use `@computed_field`, automatically appearing in serialization output:

```python
from pydantic import BaseModel, computed_field

class Rectangle(BaseModel):
    width: float
    height: float

    @computed_field
    @property
    def area(self) -> float:
        return self.width * self.height

Rectangle(width=3, height=4).model_dump()
# {"width": 3.0, "height": 4.0, "area": 12.0}
```

### 1.7 Generic Models (PEP 695 syntax)

```python
from pydantic import BaseModel

class Page[T](BaseModel):
    items: list[T]
    total: int
    page: int

class User(BaseModel):
    id: int
    name: str

user_page = Page[User].model_validate({
    "items": [{"id": 1, "name": "alice"}],
    "total": 1,
    "page": 1,
})
```

### 1.8 `RootModel` (Collection at Root)

When the root structure is a list/dict (no wrapper object), use `RootModel`:

```python
from pydantic import RootModel

class UserList(RootModel[list[User]]):
    pass

users = UserList.model_validate([{"id": 1, "name": "alice"}])
for u in users.root:
    print(u.name)
```

**Forbidden**: wrapping with `BaseModel` + `items: list[User]` — introduces an unnecessary layer.

---

## 2. Validators

### 2.1 Field Validators (`field_validator`)

```python
from pydantic import BaseModel, field_validator

class User(BaseModel):
    username: str
    email: str

    @field_validator("username", mode="after")
    @classmethod
    def check_username(cls, v: str) -> str:
        if len(v) < 3:
            raise ValueError("Username must be at least 3 characters")
        return v.lower()
```

**`mode` comparison:**

| mode | Input | Typical use |
|------|-------|-------------|
| `"before"` | Raw input (before type coercion) | Normalization, lenient conversion |
| `"after"` (default) | Value after type coercion | Business validation |
| `"wrap"` | `(cls, value, handler)` | Full control, insert logic around handler |

**Shared validator for multiple fields:**

```python
@field_validator("name", "title", mode="after")
@classmethod
def strip_and_check(cls, v: str) -> str:
    v = v.strip()
    if not v:
        raise ValueError("Cannot be empty")
    return v
```

### 2.2 Model Validators (`model_validator`)

Cross-field validation uses `model_validator`:

```python
from typing import Self
from pydantic import BaseModel, model_validator

class SignUp(BaseModel):
    password: str
    confirm_password: str

    @model_validator(mode="after")
    def verify_password_match(self) -> Self:
        if self.password != self.confirm_password:
            raise ValueError("Passwords do not match")
        return self
```

**Note:** `mode="after"` validators receive `self` (the model instance) and **do not need** `@classmethod`. `mode="before"` receives a dict and **must have** `@classmethod`.

### 2.3 Validator Purity

**Forbidden** in validators:
- Database queries / HTTP requests (blocking + side effects)
- Log writes / message dispatch
- External state mutation

Validation requiring external resources belongs in the dependency injection or service layer. Validators are **pure functions** for normalization and constraint checks.

### 2.4 Reusable Constraints via `Annotated`

Extract frequently reused validation logic as `Annotated` types:

```python
from typing import Annotated
from pydantic import AfterValidator, BeforeValidator

def _strip(v: str) -> str:
    return v.strip()

def _check_not_empty(v: str) -> str:
    if not v:
        raise ValueError("Cannot be empty")
    return v

TrimmedStr = Annotated[str, BeforeValidator(_strip), AfterValidator(_check_not_empty)]

class Post(BaseModel):
    title: TrimmedStr
    summary: TrimmedStr
```

---

## 3. Serialization

### 3.1 `model_dump` vs `model_dump_json`

```python
user.model_dump()                      # dict
user.model_dump(exclude={"password"})  # exclude fields
user.model_dump(exclude_unset=True)    # skip unset
user.model_dump(exclude_none=True)     # skip None
user.model_dump(by_alias=True)         # use serialization_alias

user.model_dump_json()                 # str (faster than json.dumps(model_dump()))
user.model_dump_json(indent=2)
```

**Performance:** For JSON output, use `model_dump_json()` directly. **Forbidden**: `json.dumps(model.model_dump())` — wastes a Python-layer round-trip.

### 3.2 Custom Serializers

**Field-level (`field_serializer`):**

```python
from datetime import datetime
from pydantic import BaseModel, field_serializer

class Event(BaseModel):
    name: str
    timestamp: datetime

    @field_serializer("timestamp")
    def serialize_timestamp(self, v: datetime) -> str:
        return v.isoformat()
```

**Model-level (`model_serializer`):**

```python
from pydantic import model_serializer

class Point(BaseModel):
    x: float
    y: float

    @model_serializer
    def serialize(self) -> list[float]:
        return [self.x, self.y]
```

### 3.3 `SecretStr` / `SecretBytes`

Use `SecretStr` for sensitive fields to prevent accidental log/serialization leakage:

```python
from pydantic import BaseModel, SecretStr

class Credentials(BaseModel):
    username: str
    password: SecretStr

creds = Credentials(username="u", password="p@ss")
print(creds)                    # username='u' password=SecretStr('**********')
creds.model_dump()              # {"username": "u", "password": SecretStr("**********")}
creds.password.get_secret_value()  # 'p@ss' — explicit retrieval required
```

---

## 4. Deserialization and `TypeAdapter`

### 4.1 `model_validate` vs `model_validate_json`

```python
User.model_validate({"name": "alice", "age": 30})        # dict
User.model_validate_json('{"name":"alice","age":30}')    # JSON string (faster)
User.model_validate(orm_user)                            # ORM object (requires from_attributes=True)
```

**Performance:** For string input, use `model_validate_json()` — 2-3× faster than `json.loads` + `model_validate` (V2 bypasses the Python dict layer and uses the Rust parser).

### 4.2 `TypeAdapter` (validation without BaseModel)

Validate/serialize arbitrary types without defining a model:

```python
from typing import Annotated
from pydantic import TypeAdapter, Field

# Validate native types
IntList = TypeAdapter(list[int])
IntList.validate_python([1, 2, 3])
IntList.validate_json("[1,2,3]")

# With constraints
PositiveIntList = TypeAdapter(list[Annotated[int, Field(gt=0)]])
PositiveIntList.validate_python([1, 2, 3])      # ✅
PositiveIntList.validate_python([1, -1, 3])     # ❌ ValidationError

# Complex nesting
Config = TypeAdapter(dict[str, list[int]])
Config.validate_python({"a": [1, 2], "b": [3, 4]})
```

Instantiate `TypeAdapter` **once** and reuse it (internal compiled schema is cached). **Forbidden**: `TypeAdapter(...)` on the request path.

---

## 5. `pydantic-settings`

### 5.1 Basic Configuration

```python
from pydantic_settings import BaseSettings, SettingsConfigDict
from pydantic import Field, SecretStr

class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        env_prefix="APP_",            # APP_DATABASE_URL maps to database_url
        case_sensitive=False,
        extra="ignore",
    )

    database_url: str
    secret_key: SecretStr
    debug: bool = False
    allowed_origins: list[str] = Field(default_factory=list)
```

### 5.2 Nested Configuration

```python
class DbSettings(BaseSettings):
    model_config = SettingsConfigDict(env_prefix="DB_")
    host: str
    port: int = 5432
    user: str
    password: SecretStr

class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_nested_delimiter="__")
    debug: bool = False
    db: DbSettings  # Injected via DB__HOST, DB__PORT, etc.
```

### 5.3 Singleton Pattern

Pair with `@lru_cache` for a global singleton, avoiding repeated env reads:

```python
from functools import lru_cache

@lru_cache
def get_settings() -> Settings:
    return Settings()
```

**Forbidden**: module-level `settings = Settings()` — makes test replacement impossible.

### 5.4 Required Field Handling

Type checkers cannot detect env auto-injection. Two approaches for required fields:

```python
# Approach A: no default (pyright errors but runtime is correct)
database_url: str

# Approach B: empty default + validator (type-checker friendly)
database_url: str = ""

@field_validator("database_url")
@classmethod
def check_not_empty(cls, v: str) -> str:
    if not v:
        raise ValueError("DATABASE_URL must be set")
    return v
```

---

## 6. Testing

### 6.1 `model_construct` (validation-free fast construction)

In fixtures and tests with trusted input, use `model_construct()` to bypass validation:

```python
user = User.model_construct(id=1, name="alice", created_at=datetime.now())
```

**Use only in test/internal code** — production code must use `model_validate()` or the constructor.

### 6.2 Partial Models in Tests

```python
def make_user(**overrides) -> User:
    defaults = {"id": 1, "name": "alice", "email": "a@x.com"}
    return User(**(defaults | overrides))

def test_user_validation():
    user = make_user(name="bob")
    assert user.name == "bob"
```

---

## 7. V1 → V2 Migration Reference

| V1 | V2 |
|----|----|
| `class Config:` | `model_config = ConfigDict(...)` |
| `orm_mode = True` | `from_attributes=True` |
| `allow_population_by_field_name` | `populate_by_name` |
| `.dict()` | `.model_dump()` |
| `.json()` | `.model_dump_json()` |
| `.parse_obj()` | `.model_validate()` |
| `.parse_raw()` | `.model_validate_json()` |
| `.from_orm()` | `.model_validate(obj)` (with `from_attributes=True`) |
| `@validator` | `@field_validator` + `@classmethod` |
| `@root_validator` | `@model_validator` |
| `Config.schema_extra` | `model_config = {"json_schema_extra": ...}` |
| `Field(const=True)` | `Literal[value]` or `Field(frozen=True)` |

---

## 8. Forbidden Patterns

| Forbidden | Replacement |
|-----------|------------|
| `class Config:` inner class | `model_config = ConfigDict(...)` |
| `from_orm()` / `dict()` / `parse_obj()` | `model_validate()` / `model_dump()` |
| `typing.List`, `typing.Optional` | `list`, `X \| None` |
| `Union[A, B]` without `discriminator` for polymorphism | `Field(discriminator=...)` |
| `Field(default=[])` mutable default | `Field(default_factory=list)` |
| Validator missing `@classmethod` (`before`/`wrap` modes) | Always add `@classmethod` |
| Side effects in validators (DB / HTTP) | Put external logic in the service layer |
| `json.dumps(m.model_dump())` | `m.model_dump_json()` |
| `json.loads(s)` + `model_validate(...)` | `model_validate_json(s)` |
| Wrapping root list with `BaseModel` | `RootModel[list[T]]` |
| `TypeAdapter(T)` on the request path | Instantiate once at module level |
| Plain-text password/secret fields | `SecretStr` |
| Module-level `Settings()` instance | `@lru_cache` + `get_settings()` |

---

## 9. Performance and Best Practices

- **Fast paths**: prefer `model_validate_json` for JSON input; prefer `model_dump_json` for JSON output.
- **Avoid hot-path overhead**: enable `validate_assignment` selectively; use `revalidate_instances="always"` only for complex inheritance.
- **Batch validation**: `TypeAdapter(list[User]).validate_python(rows)` is faster than looping with `model_validate`.
- **OpenAPI / JSON Schema**: get schema via `Model.model_json_schema()`; enrich documentation with `Field(description=...)` and `json_schema_extra`.
- **Forward compatibility**: combine `validation_alias` (accept old field names) and `serialization_alias` (emit new names) for smooth migrations.

---

## 10. General Principles

- Target Python 3.10+; use `X | Y` unions and PEP 695 generics syntax.
- Field names follow `snake_case`; use `alias` for camelCase interop — never write camelCase in Python code directly.
- **Input models** (API requests): recommend `extra="forbid"` + `str_strip_whitespace=True`.
- **Output models** (API responses): define separately from internal ORM-mapped models to prevent leaking internal fields.
- When integrating with SQLAlchemy, keep Pydantic models in a separate `schemas/` module, decoupled from `models/` (ORM models).

---

Following these rules keeps Pydantic V2 code type-safe, strictly validated, and performant — providing a solid foundation for FastAPI, data pipelines, and other scenarios.
