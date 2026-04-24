# Pydantic V2 开发规则

## 1. 模型定义

- 使用 `BaseModel` 创建模型，模型配置统一放在 `model_config` 中，使用 `ConfigDict`。
- **禁止**使用 V1 的 `class Config` 内部类，立即弃用 `from_orm` 等方法。
- 字段类型优先使用 Python 内置泛型（`list[int]`, `dict[str, int]`, `str | None`），避免 `typing.List`、`typing.Dict`、`typing.Optional`。

```python
from pydantic import BaseModel, ConfigDict

class User(BaseModel):
    model_config = ConfigDict(from_attributes=True, validate_assignment=True)
    name: str
    age: int | None = None
```

## 2. 配置项常用 `ConfigDict` 参数

| 配置项 | 用途 |
|--------|------|
| `from_attributes` | 允许从 ORM 对象构建模型（替代旧 `orm_mode`）。 |
| `validate_assignment` | 字段赋值时重新校验。 |
| `extra` | 控制额外字段：`'ignore'`（默认）、`'forbid'`、`'allow'`。 |
| `str_strip_whitespace` | 自动去除 `str` 字段前后空白。 |
| `validate_default` | 默认值是否也走校验器。 |

## 3. 字段校验器 (`field_validator`)

- 必须使用 `@classmethod`，第一个参数是 `cls`。
- `mode` 参数三个值：
  - `"before"`：在类型转换前运行，拿到原始输入值，返回处理后值。
  - `"after"`（默认）：在类型转换后运行。
  - `"wrap"`：完全接管校验，接收 `(cls, value, handler)`，可在 `handler` 前后插逻辑。

```python
@field_validator("name", mode="after")
@classmethod
def check_name(cls, v: str) -> str:
    if len(v) < 3:
        raise ValueError("名称至少3个字符")
    return v
```

## 4. 模型校验器 (`model_validator`)

- 必须用 `@classmethod`，`mode` 同样有 `"before"`, `"after"`, `"wrap"`。
- `"before"` 接收原始数据字典，返回字典。
- `"after"` 接收模型实例或字典（取决于配置），常用于跨字段校验。

```python
@model_validator(mode="after")
@classmethod
def verify_password_match(cls, values):
    if values.password != values.confirm_password:
        raise ValueError("密码不匹配")
    return values
```

## 5. 性能与类型注解

- 所有校验器方法**必须**声明返回值类型，否则 mypy/pyright 可能会报错。
- 对于不修改值的校验器，应该返回输入值（或抛出异常），而不是返回 `None`。
- 优先使用 `model_validate` 构建模型对象，而不是直接调用构造函数（可接受字典或其他模型）。
- 支持 ORM 对象转换为模型时，需要设置 `from_attributes=True`，然后使用 `User.model_validate(orm_obj)`。

## 6. 从环境变量加载配置 (`pydantic-settings`)

- 继承 `BaseSettings`，使用 `model_config` 指定环境文件等。
- 类型检查器无法识别环境变量自动注入，因此必填字段需要提供默认值（如空字符串），再配合 `field_validator` 确保非空。

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
            raise ValueError("DATABASE_URL 必须设置")
        return v
```

## 7. 禁止事项

- 禁止使用 `from_orm()`，必须用 `model_validate()`。
- 禁止使用 `typing.List`、`typing.Dict` 等，使用内置 `list`, `dict`。
- 禁止 `class Config` 内部类，一律使用 `model_config = ConfigDict(...)`。
- 所有 `field_validator` 和 `model_validator` 必须加上 `@classmethod`。

## 8. 通用原则

- 代码面向 Python 3.10+，积极使用 `X | Y` 联合类型和新泛型语法。
- 校验器保持纯净：只做校验，不进行外部副作用（如数据库调用），外部逻辑应放在依赖注入层。
- 字段名遵循 `snake_case`，Pydantic 会自动映射 JSON 的 `camelCase` 等，但明确使用 `alias` 时除外。

---

遵循以上规则可以确保生成的 Pydantic V2 代码符合最新规范，类型安全且易于维护。
