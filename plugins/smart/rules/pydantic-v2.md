# Pydantic V2 Development Rules

## 1. Model Definition

- Use `BaseModel` to create models; put all model configuration in `model_config` using `ConfigDict`.
- **Forbidden**: Using V1's `class Config` inner class; deprecate `from_orm` and similar methods immediately.
- Prefer Python built-in generics for field types (`list[int]`, `dict[str, int]`, `str | None`); avoid `typing.List`, `typing.Dict`, `typing.Optional`.

```python
from pydantic import BaseModel, ConfigDict

class User(BaseModel):
    model_config = ConfigDict(from_attributes=True, validate_assignment=True)
    name: str
    age: int | None = None
```

## 2. Common `ConfigDict` Parameters

| Parameter | Purpose |
|-----------|---------|
| `from_attributes` | Allow building models from ORM objects (replaces `orm_mode`). |
| `validate_assignment` | Re-validate on field assignment. |
| `extra` | Control extra fields: `'ignore'` (default), `'forbid'`, `'allow'`. |
| `str_strip_whitespace` | Automatically strip leading/trailing whitespace from `str` fields. |
| `validate_default` | Whether default values also go through validators. |

## 3. Field Validators (`field_validator`)

- Must use `@classmethod`; first parameter is `cls`.
- Three `mode` values:
  - `"before"`: Runs before type coercion; receives raw input, returns processed value.
  - `"after"` (default): Runs after type coercion.
  - `"wrap"`: Takes full control of validation; receives `(cls, value, handler)`; can insert logic before/after `handler`.

```python
@field_validator("name", mode="after")
@classmethod
def check_name(cls, v: str) -> str:
    if len(v) < 3:
        raise ValueError("Name must be at least 3 characters")
    return v
```

## 4. Model Validators (`model_validator`)

- Must use `@classmethod`; `mode` supports `"before"`, `"after"`, `"wrap"`.
- `"before"`: Receives raw data dict, returns dict.
- `"after"`: Receives model instance; commonly used for cross-field validation.

```python
@model_validator(mode="after")
@classmethod
def verify_password_match(cls, values):
    if values.password != values.confirm_password:
        raise ValueError("Passwords do not match")
    return values
```

## 5. Performance & Type Annotations

- All validator methods **must** declare return types; otherwise mypy/pyright may error.
- Validators that do not modify values must return the input value (or raise), never `None`.
- Prefer `model_validate` to construct model objects rather than calling the constructor directly (accepts dicts or other models).
- When converting ORM objects to models, set `from_attributes=True`, then use `User.model_validate(orm_obj)`.

## 6. Loading Config from Environment Variables (`pydantic-settings`)

- Inherit from `BaseSettings`; use `model_config` to specify env files, etc.
- Type checkers cannot recognize auto-injected env vars, so required fields need a default value (e.g. empty string), combined with `field_validator` to ensure non-empty.

```python
from pydantic_settings import BaseSettings, SettingsConfigDict

class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env")
    database_url: str = ""
    debug: bool = False

    @field_validator("database_url")
    @classmethod
    def check_not_empty(cls, v: str) -> str:
        if not v:
            raise ValueError("DATABASE_URL must be set")
        return v
```

## 7. Forbidden Patterns

- Never use `from_orm()`; always use `model_validate()`.
- Never use `typing.List`, `typing.Dict`, etc.; use built-in `list`, `dict`.
- No `class Config` inner class; always use `model_config = ConfigDict(...)`.
- All `field_validator` and `model_validator` must include `@classmethod`.

## 8. General Principles

- Target Python 3.10+; actively use `X | Y` union types and new generics syntax.
- Keep validators pure: only validate, no external side effects (e.g. database calls); external logic belongs in the dependency injection layer.
- Field names follow `snake_case`; Pydantic auto-maps JSON `camelCase` etc., except when using an explicit `alias`.

---

Following these rules ensures generated Pydantic V2 code conforms to the latest standards, is type-safe, and easy to maintain.
