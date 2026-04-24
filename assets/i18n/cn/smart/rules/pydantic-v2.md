# Pydantic V2 开发规则

本规则适用于 Pydantic V2（≥ 2.5.x）项目，结合 Python 3.10+ 特性，强调类型安全、校验严格性与序列化控制。所有模型、校验器、设置类必须遵循以下约定。

---

## 一、模型定义

### 1. 声明方式

使用 `BaseModel` 创建模型，所有配置放入 `model_config` 中，使用 `ConfigDict`：

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

- **禁止** V1 的 `class Config` 内部类。
- **禁止** `from_orm()`、`dict()`、`parse_obj()` 等 V1 方法。
- 字段类型必须使用 Python 3.10+ 内置泛型（`list[int]`、`str | None`），**禁止** `typing.List`、`typing.Optional`。

### 2. 常用 `ConfigDict` 参数

| 配置项 | 用途 | 推荐 |
|--------|------|------|
| `from_attributes` | 允许从 ORM / 任意对象属性构建（替代 V1 `orm_mode`） | ORM 模型设 `True` |
| `validate_assignment` | 字段赋值时重新校验 | 可变模型推荐开 |
| `extra` | `'ignore'`（默认）/ `'forbid'` / `'allow'` | API 入参用 `'forbid'` |
| `str_strip_whitespace` | 自动去除字符串前后空白 | API 入参推荐开 |
| `validate_default` | 默认值是否走校验器 | 严格场景开 |
| `populate_by_name` | 允许同时用字段名和 alias 填值 | 与 alias 配合 |
| `frozen` | 实例不可变（可哈希） | 值对象推荐 |
| `arbitrary_types_allowed` | 允许非 Pydantic 类型作字段 | 谨慎使用 |
| `revalidate_instances` | `'never'` / `'always'` / `'subclass-instances'` | 继承场景用 `'always'` |

**性能提示：** `validate_assignment` 全局开启会在每次字段赋值触发完整校验，对高频修改的模型影响明显；仅在确实需要赋值守卫的模型上开。

### 3. `Field()` 与约束

使用 `Field()` 声明默认值、约束和元数据：

```python
from pydantic import BaseModel, Field

class Product(BaseModel):
    name: str = Field(min_length=1, max_length=100)
    price: float = Field(gt=0, le=1_000_000, description="含税价")
    tags: list[str] = Field(default_factory=list, max_length=20)
    slug: str = Field(pattern=r"^[a-z0-9-]+$")
    rating: int = Field(ge=0, le=5)
```

**常用约束速查：**

| 类型 | 约束 |
|------|------|
| 数值 | `gt`, `ge`, `lt`, `le`, `multiple_of` |
| 字符串 | `min_length`, `max_length`, `pattern` |
| 集合 | `min_length`, `max_length` |
| 小数 | `max_digits`, `decimal_places` |

**默认值的陷阱：** 可变默认值**必须**使用 `Field(default_factory=list)`，**禁止** `Field(default=[])`（Pydantic V2 会报错）。

### 4. 别名（Alias）

处理 camelCase API / 多源数据：

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

- `validation_alias`：输入时接受哪些名字
- `serialization_alias`：输出时用哪个名字
- `AliasChoices`：多个候选名字（按顺序匹配）
- `AliasPath`：从嵌套路径取值（`{"address": {"city": "北京"}}`）
- `populate_by_name=True`：允许同时用字段名和 alias

### 5. 判别联合（Discriminated Unions）

多态模型用 `discriminator` 实现 O(1) 验证与精准错误定位：

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

**禁止** 对多态场景使用普通 `Union` 无判别字段——Pydantic 会按顺序尝试每个分支，错误信息含糊且性能差。

### 6. 计算字段（Computed Fields）

从其他字段派生的只读属性使用 `@computed_field`，自动出现在序列化输出中：

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

### 7. 泛型模型（PEP 695 语法）

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

### 8. `RootModel`（集合作为根）

当根结构是列表/字典（无包装对象）时使用 `RootModel`：

```python
from pydantic import RootModel

class UserList(RootModel[list[User]]):
    pass

users = UserList.model_validate([{"id": 1, "name": "alice"}])
for u in users.root:
    print(u.name)
```

**禁止** 用 `BaseModel` 加 `items: list[User]` 字段来包装——会引入多余层级。

---

## 二、校验器

### 1. 字段校验器（`field_validator`）

```python
from pydantic import BaseModel, field_validator

class User(BaseModel):
    username: str
    email: str

    @field_validator("username", mode="after")
    @classmethod
    def check_username(cls, v: str) -> str:
        if len(v) < 3:
            raise ValueError("用户名至少 3 个字符")
        return v.lower()
```

**`mode` 三值对比：**

| mode | 输入 | 典型用途 |
|------|------|---------|
| `"before"` | 原始输入（类型转换**前**） | 规范化、宽容转换 |
| `"after"`（默认） | 已转换后的值 | 业务校验 |
| `"wrap"` | `(cls, value, handler)` | 完全接管，可在 handler 前后插逻辑 |

**多字段共用校验器：**

```python
@field_validator("name", "title", mode="after")
@classmethod
def strip_and_check(cls, v: str) -> str:
    v = v.strip()
    if not v:
        raise ValueError("不能为空")
    return v
```

### 2. 模型校验器（`model_validator`）

跨字段校验使用 `model_validator`：

```python
from typing import Self
from pydantic import BaseModel, model_validator

class SignUp(BaseModel):
    password: str
    confirm_password: str

    @model_validator(mode="after")
    def verify_password_match(self) -> Self:
        if self.password != self.confirm_password:
            raise ValueError("两次密码不一致")
        return self
```

**注意：** `mode="after"` 下校验器接收 `self`（模型实例），**不需要** `@classmethod`；`mode="before"` 接收字典，**必须** `@classmethod`。

### 3. 校验器纯净原则

**禁止**在校验器中执行：
- 数据库查询 / HTTP 请求（阻塞 + 副作用）
- 日志写入 / 消息发送
- 修改外部状态

外部资源相关的校验放在依赖注入层或服务层，校验器**只做纯函数**的规范化和约束。

### 4. `Annotated` 重用校验约束

多处复用的验证逻辑提取为 `Annotated` 类型：

```python
from typing import Annotated
from pydantic import AfterValidator, BeforeValidator

def _strip(v: str) -> str:
    return v.strip()

def _check_not_empty(v: str) -> str:
    if not v:
        raise ValueError("不能为空")
    return v

TrimmedStr = Annotated[str, BeforeValidator(_strip), AfterValidator(_check_not_empty)]

class Post(BaseModel):
    title: TrimmedStr
    summary: TrimmedStr
```

---

## 三、序列化

### 1. `model_dump` vs `model_dump_json`

```python
user.model_dump()                      # dict
user.model_dump(exclude={"password"})  # 排除字段
user.model_dump(exclude_unset=True)    # 跳过未显式设置
user.model_dump(exclude_none=True)     # 跳过 None
user.model_dump(by_alias=True)         # 使用 serialization_alias

user.model_dump_json()                 # str（比 json.dumps(model_dump()) 更快）
user.model_dump_json(indent=2)
```

**性能：** 输出 JSON 时直接用 `model_dump_json()`，**禁止** `json.dumps(model.model_dump())`——后者多一次 Python 层往返。

### 2. 自定义序列化器

**字段级（`field_serializer`）：**

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

**模型级（`model_serializer`）：**

```python
from pydantic import model_serializer

class Point(BaseModel):
    x: float
    y: float

    @model_serializer
    def serialize(self) -> list[float]:
        return [self.x, self.y]
```

### 3. `SecretStr` / `SecretBytes`

敏感字段使用 `SecretStr`，防止日志/序列化意外泄漏：

```python
from pydantic import BaseModel, SecretStr

class Credentials(BaseModel):
    username: str
    password: SecretStr

creds = Credentials(username="u", password="p@ss")
print(creds)                    # username='u' password=SecretStr('**********')
creds.model_dump()              # {"username": "u", "password": SecretStr("**********")}
creds.password.get_secret_value()  # 'p@ss' — 必须显式获取
```

---

## 四、反序列化与 `TypeAdapter`

### 1. `model_validate` vs `model_validate_json`

```python
User.model_validate({"name": "alice", "age": 30})        # dict
User.model_validate_json('{"name":"alice","age":30}')    # JSON 字符串（更快）
User.model_validate(orm_user)                            # ORM 对象（需 from_attributes=True）
```

**性能：** 从字符串解析时用 `model_validate_json()`，比 `json.loads` + `model_validate` 快 2-3×——V2 内部绕过 Python dict 直接走 Rust 解析器。

### 2. `TypeAdapter`（无需 BaseModel 的校验）

对任意类型进行校验/序列化，而不定义模型：

```python
from typing import Annotated
from pydantic import TypeAdapter, Field

# 校验原生类型
IntList = TypeAdapter(list[int])
IntList.validate_python([1, 2, 3])
IntList.validate_json("[1,2,3]")

# 带约束
PositiveIntList = TypeAdapter(list[Annotated[int, Field(gt=0)]])
PositiveIntList.validate_python([1, 2, 3])      # ✅
PositiveIntList.validate_python([1, -1, 3])     # ❌ ValidationError

# 复杂嵌套
Config = TypeAdapter(dict[str, list[int]])
Config.validate_python({"a": [1, 2], "b": [3, 4]})
```

`TypeAdapter` 应**实例化一次**并复用（内部缓存编译结果），**禁止**在请求路径上重复 `TypeAdapter(...)`。

---

## 五、`pydantic-settings`

### 1. 基础配置

```python
from pydantic_settings import BaseSettings, SettingsConfigDict
from pydantic import Field, SecretStr

class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        env_prefix="APP_",            # APP_DATABASE_URL 映射到 database_url
        case_sensitive=False,
        extra="ignore",
    )

    database_url: str
    secret_key: SecretStr
    debug: bool = False
    allowed_origins: list[str] = Field(default_factory=list)
```

### 2. 嵌套配置

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
    db: DbSettings  # 通过 DB__HOST, DB__PORT 等注入，或 APP_DB__HOST
```

### 3. 单例模式

配合 `@lru_cache` 确保全局单例，避免每次读环境变量：

```python
from functools import lru_cache

@lru_cache
def get_settings() -> Settings:
    return Settings()
```

**禁止**在模块顶层直接 `settings = Settings()` ——测试时无法替换。

### 4. 必填字段处理

类型检查器无法识别 env 自动注入，因此**必填**字段有两种写法：

```python
# 写法 A：无默认值（pyright 报错但运行时正确）
database_url: str

# 写法 B：空字符串 + 校验器（类型检查友好）
database_url: str = ""

@field_validator("database_url")
@classmethod
def check_not_empty(cls, v: str) -> str:
    if not v:
        raise ValueError("DATABASE_URL 必须设置")
    return v
```

---

## 六、测试

### 1. `model_construct`（跳过校验的快速构造）

在 fixture 和测试中构造对象时，若输入已被信任，使用 `model_construct()` 绕过校验：

```python
user = User.model_construct(id=1, name="alice", created_at=datetime.now())
```

**仅在测试/内部代码中使用**，生产代码必须用 `model_validate()` 或构造器。

### 2. 部分模型（测试时）

```python
def make_user(**overrides) -> User:
    defaults = {"id": 1, "name": "alice", "email": "a@x.com"}
    return User(**(defaults | overrides))

def test_user_validation():
    user = make_user(name="bob")
    assert user.name == "bob"
```

---

## 七、V1 → V2 迁移速查

| V1 | V2 |
|----|----|
| `class Config:` | `model_config = ConfigDict(...)` |
| `orm_mode = True` | `from_attributes=True` |
| `allow_population_by_field_name` | `populate_by_name` |
| `.dict()` | `.model_dump()` |
| `.json()` | `.model_dump_json()` |
| `.parse_obj()` | `.model_validate()` |
| `.parse_raw()` | `.model_validate_json()` |
| `.from_orm()` | `.model_validate(obj)`（需 `from_attributes=True`） |
| `@validator` | `@field_validator` + `@classmethod` |
| `@root_validator` | `@model_validator` |
| `Config.schema_extra` | `model_config = {"json_schema_extra": ...}` |
| `Field(const=True)` | `Literal[value]` 或 `Field(frozen=True)` |

---

## 八、禁止事项

| 禁止 | 替代 |
|------|------|
| `class Config:` 内部类 | `model_config = ConfigDict(...)` |
| `from_orm()` / `dict()` / `parse_obj()` | `model_validate()` / `model_dump()` |
| `typing.List`、`typing.Optional` | `list`、`X \| None` |
| `Union[A, B]` 多态场景无 `discriminator` | `Field(discriminator=...)` |
| `Field(default=[])` 可变默认 | `Field(default_factory=list)` |
| 校验器忘记 `@classmethod`（`before`/`wrap` 模式） | 必须加 `@classmethod` |
| 校验器内副作用（DB / HTTP） | 外部逻辑放服务层 |
| `json.dumps(m.model_dump())` | `m.model_dump_json()` |
| `json.loads(s)` + `model_validate(...)` | `model_validate_json(s)` |
| `BaseModel` 包装根列表 | `RootModel[list[T]]` |
| 请求路径重复 `TypeAdapter(T)` | 模块级实例化一次复用 |
| 明文存储密码/密钥字段 | `SecretStr` |
| 模块顶层实例化 `Settings()` | `@lru_cache` + `get_settings()` |

---

## 九、性能与最佳实践

- **快速路径**：JSON 输入优先 `model_validate_json`；JSON 输出优先 `model_dump_json`。
- **避免热路径开销**：`validate_assignment` 按需开启；`revalidate_instances="always"` 仅在继承复杂时使用。
- **批量校验**：`TypeAdapter(list[User]).validate_python(rows)` 比循环单个 `model_validate` 快。
- **OpenAPI / JSON Schema**：通过 `Model.model_json_schema()` 获取 schema，`Field(description=...)` 与 `json_schema_extra` 丰富文档。
- **向前兼容**：在模型上同时使用 `validation_alias`（接受旧字段名）和 `serialization_alias`（输出新字段名），实现平滑迁移。

---

## 十、通用原则

- 面向 Python 3.10+，使用 `X | Y` 联合类型与 PEP 695 泛型语法。
- 字段名遵循 `snake_case`；对接 camelCase 时用 `alias`，不要在代码里直接写 camelCase。
- **输入模型**（API 入参）推荐 `extra="forbid"` + `str_strip_whitespace=True`。
- **输出模型**（API 响应）独立定义，不直接复用 ORM 映射的内部模型——防止内部字段泄漏。
- 与 SQLAlchemy 协作时，在独立的 `schemas/` 模块管理 Pydantic 模型，与 `models/` 中 ORM 模型解耦。

---

遵循以上规则可保证 Pydantic V2 代码类型安全、校验严格、性能优异，并为 FastAPI / 数据管道等场景提供稳固基础。
