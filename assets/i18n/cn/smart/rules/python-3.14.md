# Python 3.14 开发规则

本规则适用于 Python 3.14 项目，强制使用最新的语法、标准库特性及类型注解规范。所有生成的代码必须严格遵循以下约定。

---

## 一、类型注解

### 1. 延迟求值（PEP 649 & 749）

Python 3.14 原生实现注解延迟求值——注解不再在定义时立即执行，而是按需求值。

- **禁止** `from __future__ import annotations`，Python 3.14 已原生延迟求值所有注解。
- **前向引用**：直接使用当前作用域中尚未定义的类名，无需字符串包裹。

```python
class Node:
    def children(self) -> list[Node]:  # ✅ 直接引用 Node，无需 'Node'
        ...

class Response:
    data: list[Item]        # ✅ 即使 Item 定义在后面也无需字符串
    error: Error | None
```

### 2. 内置泛型

- **联合类型**：使用 `X | Y`，不用 `Union[X, Y]`；使用 `X | None`，不用 `Optional[X]`。
- **泛型容器**：`list[int]`、`dict[str, int]`、`tuple[int, str]`、`set[int]`。**禁止** `typing.List`、`typing.Dict` 等已弃用别名。
- **类型别名**：优先使用 `type` 语句（Python 3.12+）：

```python
type Vector = list[float]
type Matrix = list[Vector]
type JsonValue = str | int | float | bool | None | list[JsonValue] | dict[str, JsonValue]
type Callback[T] = (T) -> None
```

**禁止**普通变量赋值 `Vector = list[float]` 作类型别名（除非兼容旧工具）。

### 3. 泛型类与函数（PEP 695，Python 3.12+）

使用 `[T]` 语法定义泛型，**禁止** 旧的 `TypeVar` 写法：

```python
# ✅ 3.12+ 新语法
class Stack[T]:
    def __init__(self) -> None:
        self._items: list[T] = []

    def push(self, item: T) -> None:
        self._items.append(item)

    def pop(self) -> T:
        return self._items.pop()

def first[T](items: list[T]) -> T:
    return items[0]

# 带约束的泛型（T 只能是 int、float 或 str）
def maximum[T: (int, float, str)](a: T, b: T) -> T:
    return a if a > b else b

# 带上界（T 必须是 Comparable 的子类）
class SortedList[T: Comparable]:
    ...
```

**约束 vs 上界：**
- `T: (int, float, str)` — 约束：T 只能**恰好是**这几种类型之一
- `T: Comparable` — 上界：T 必须是 `Comparable` 的子类/子类型

### 4. `@override` 装饰器（PEP 698，Python 3.12+）

在子类中覆盖父类方法时，必须加 `@override`，让静态检查器发现拼写错误或签名不匹配：

```python
from typing import override

class Animal:
    def speak(self) -> str: ...

class Dog(Animal):
    @override
    def speak(self) -> str:  # ✅ 检查器验证父类确有此方法
        return "woof"
```

### 5. `Self` 类型

方法返回自身实例时，使用 `Self` 而非类名，确保子类继承时返回类型正确：

```python
from typing import Self

class Builder:
    def set_name(self, name: str) -> Self:
        self.name = name
        return self

class AdvancedBuilder(Builder):
    def set_level(self, level: int) -> Self:
        self.level = level
        return self

# AdvancedBuilder().set_name("x").set_level(2) 返回 AdvancedBuilder
```

### 6. `Never` 与穷举检查

`assert_never()` 让静态检查器在遗漏分支时报错：

```python
from typing import Literal, Never, assert_never

type Status = Literal["pending", "active", "closed"]

def handle(status: Status) -> str:
    match status:
        case "pending": return "等待中"
        case "active":  return "进行中"
        case "closed":  return "已关闭"
        case _ as unreachable:
            assert_never(unreachable)  # 新增 Status 值未处理时在此编译报错
```

### 7. Literal 类型

使用 `Literal["a", "b"]` 表示有限值集合：

```python
from typing import Literal

type Direction = Literal["north", "south", "east", "west"]
type HttpMethod = Literal["GET", "POST", "PUT", "DELETE", "PATCH"]

def route(method: HttpMethod, path: str) -> None: ...
```

### 8. TypedDict 增强（PEP 655）

```python
from typing import TypedDict, NotRequired, Required

class UserFilter(TypedDict):
    username: str
    email: NotRequired[str]
    page: NotRequired[int]

class Config(TypedDict, total=False):
    host: Required[str]   # total=False 下仍为必填
    port: int
    debug: bool
```

### 9. `assert_type()` 静态验证

在单元测试或关键位置显式验证推断类型：

```python
from typing import assert_type

x = [1, 2, 3]
assert_type(x, list[int])   # 静态检查器验证 x 的推断类型；运行时无开销
```

---

## 二、枚举（`enum`）

### 1. 优先使用 `StrEnum` / `IntEnum`（Python 3.11+）

```python
from enum import StrEnum, IntEnum, auto

class Status(StrEnum):
    PENDING = "pending"
    ACTIVE = "active"
    CLOSED = "closed"

class Priority(IntEnum):
    LOW = 1
    MEDIUM = 2
    HIGH = 3

# StrEnum 实例与字符串互通，JSON 序列化自然
Status.ACTIVE == "active"  # ✅ True
```

**禁止** 混用 `class Color(str, Enum):` 多重继承写法，3.11+ 一律用 `StrEnum`。

### 2. `auto()` 生成值

```python
class Color(StrEnum):
    RED = auto()    # 自动为 "red"
    GREEN = auto()  # 自动为 "green"
    BLUE = auto()   # 自动为 "blue"
```

---

## 三、异步编程

### 1. 入口点

```python
import asyncio

async def main() -> None:
    ...

if __name__ == "__main__":
    asyncio.run(main())
```

**禁止**：
- ❌ `loop = asyncio.get_event_loop()`
- ❌ `loop.run_until_complete(coro)`
- ❌ `asyncio._get_running_loop()`（私有 API）

### 2. 结构化并发（TaskGroup，Python 3.11+）

```python
async def fetch_all(urls: list[str]) -> list[bytes]:
    async with asyncio.TaskGroup() as tg:
        tasks = [tg.create_task(fetch(url)) for url in urls]
    return [task.result() for task in tasks]
```

`TaskGroup` 的优势：任意子任务失败时**自动取消其他任务**，所有异常汇总为 `ExceptionGroup`。推荐作为默认选择，`asyncio.gather()` 仍可用于简单场景。

### 3. 超时控制（Python 3.11+）

```python
async def fetch_with_timeout(url: str) -> bytes:
    async with asyncio.timeout(5.0):
        return await fetch(url)

# 共享截止时间
async def pipeline() -> None:
    async with asyncio.timeout(10.0):
        data = await step1()
        result = await step2(data)  # 两步共用 10s 预算
```

### 4. 异常组（`except*`，Python 3.11+）

```python
try:
    async with asyncio.TaskGroup() as tg:
        tg.create_task(risky_op1())
        tg.create_task(risky_op2())
except* ValueError as eg:
    for exc in eg.exceptions:
        logger.error("ValueError: %s", exc)
except* IOError as eg:
    logger.error("IOError: %d errors", len(eg.exceptions))
```

### 5. 流量控制（Semaphore）

```python
sem = asyncio.Semaphore(10)  # 最多 10 个并发

async def bounded_fetch(url: str) -> bytes:
    async with sem:
        return await fetch(url)
```

### 6. 协程与生成器语义速查

| 类型 | 驱动方式 | 限制 |
|------|---------|------|
| 原生协程 `async def` | `await` | ❌ 不能 `.send()` |
| 同步生成器 `def` + `yield` | `next()` / `.send()` | ✅ 完整迭代协议 |
| 异步生成器 `async def` + `yield` | `async for` / `await anext()` | ❌ 无 `.send()` |

### 7. 上下文变量（`contextvars`）

跨协程/线程安全传递请求级上下文（如 request_id、user）：

```python
from contextvars import ContextVar

request_id: ContextVar[str] = ContextVar("request_id", default="-")

async def handler():
    request_id.set(uuid4().hex)
    await process()

async def process():
    logger.info("request=%s", request_id.get())  # 自动获取当前协程的值
```

**禁止**使用全局变量或 `threading.local()` 在 async 代码中传递上下文。

### 8. 子解释器并发（PEP 734，Python 3.14）

CPU 密集任务可用 `InterpreterPoolExecutor` 实现真正并行（每个解释器独立 GIL）：

```python
from concurrent.futures import InterpreterPoolExecutor

with InterpreterPoolExecutor(max_workers=4) as pool:
    results = list(pool.map(heavy_cpu_task, data))
```

相比多进程：启动开销更小，数据传递更灵活；相比多线程：不受 GIL 限制。

### 9. Free-threaded CPython（PEP 703）

Python 3.14 可选构建支持无 GIL（`python3.14t`）。在多线程 CPU 密集场景性能显著提升，但：
- 只在 **`python3.14t`** 构建下生效
- **确认所有原生扩展兼容无 GIL 模式**才能使用
- 默认构建仍带 GIL，普通项目无需切换

---

## 四、新标准库特性

### 1. 模板字符串（t-strings, PEP 750）

**关键区别：** t-strings 返回 `Template` 对象，**不是字符串**，允许库在渲染前处理插值（转义、验证、参数化）：

```python
# 安全 SQL 构建（需配合支持 t-strings 的库）
query = t"SELECT * FROM users WHERE name = {user_name} AND age > {min_age}"
# query 是 Template 对象，库可安全提取插值并参数化，防止注入

# 安全 HTML 渲染
html = t"<div class={cls}>{content}</div>"
```

**警告：** `str(t"...")` 会失去安全性。**禁止**直接转字符串，应始终通过支持 t-strings 的库渲染。

### 2. 临时切换工作目录（`contextlib.chdir`，Python 3.11+）

```python
from contextlib import chdir

with chdir("/tmp/sandbox"):
    result = subprocess.run(["make", "build"], capture_output=True)
# 退出 with 块后自动恢复原工作目录
```

### 3. Zstandard 压缩（PEP 784）

```python
import compression.zstd as zstd

compressed = zstd.compress(data, level=3)
decompressed = zstd.decompress(compressed)

with zstd.open("archive.zst", "wb") as f:
    f.write(large_data)
```

相比 `gzip`，同等压缩率下速度提升 3-10 倍。

### 4. 分块迭代（`itertools.batched()`，Python 3.12+）

```python
from itertools import batched

records = list(range(1000))
for chunk in batched(records, 100):
    db.bulk_insert(list(chunk))
```

### 5. TOML 解析（`tomllib`，Python 3.11+）

```python
import tomllib

with open("pyproject.toml", "rb") as f:  # 必须以 "rb" 打开
    config = tomllib.load(f)
```

### 6. `pathlib.Path.walk()`（Python 3.12+）

替代 `os.walk`，返回 `Path` 对象：

```python
from pathlib import Path

for root, dirs, files in Path("src").walk():
    for f in files:
        if f.endswith(".py"):
            print(root / f)
```

**禁止** 在新代码中使用 `os.walk()` 或字符串拼接路径。

### 7. `datetime.UTC`（Python 3.11+）

```python
from datetime import datetime, UTC

now = datetime.now(UTC)       # ✅ 时区感知
# datetime.now(timezone.utc)  ❌ 旧写法，Python 3.12+ 不推荐
```

**禁止** `datetime.utcnow()`（返回 naive datetime，3.12+ 已弃用）。

### 8. `zip(..., strict=True)`（Python 3.10+）

长度不等时立即报错，防止静默截断：

```python
for k, v in zip(keys, values, strict=True):
    ...
# 若长度不等：ValueError: zip() argument 2 is shorter than argument 1
```

**禁止** 不加 `strict=True` 的 `zip()` 在成对数据场景——静默截断是常见 bug 源。

### 9. 缓存装饰器

```python
from functools import cache, lru_cache

@cache              # 无大小限制（仅当输入空间小且有限时使用）
def factorial(n: int) -> int: ...

@lru_cache(maxsize=1024)   # 有界缓存（推荐默认）
def expensive(x: int) -> int: ...
```

**陷阱：** `@cache` 无限增长——对用户输入驱动的函数**禁止**使用，改用 `@lru_cache(maxsize=...)`。

### 10. 改进的错误提示

Python 3.14 持续改进：
- `IndexError`：显示列表长度和出错索引
- `AttributeError`：提示拼写相近的属性名
- `NameError`：提示作用域内相近变量名
- `TypeError`：参数错误时显示函数签名

---

## 五、数据类（`dataclass`）

### 1. 优先使用 `slots=True`

```python
from dataclasses import dataclass, field

@dataclass(slots=True, frozen=True)
class Point:
    x: float
    y: float

    def distance_from_origin(self) -> float:
        return (self.x ** 2 + self.y ** 2) ** 0.5
```

`slots=True` 减少内存占用，提升属性访问速度；`frozen=True` 使实例不可变，可作字典键。

### 2. 可变默认值用 `field(default_factory=...)`

```python
@dataclass
class Config:
    tags: list[str] = field(default_factory=list)
    metadata: dict[str, str] = field(default_factory=dict)
```

❌ **禁止** `tags: list[str] = []`（所有实例共享同一列表）。

### 3. `KW_ONLY` 分隔符

```python
from dataclasses import dataclass, KW_ONLY

@dataclass
class Request:
    method: str
    path: str
    _: KW_ONLY              # 之后的字段只能通过关键字传入
    timeout: float = 30.0
    headers: dict[str, str] = field(default_factory=dict)
```

---

## 六、结构化模式匹配（`match`）

### 1. 基本解构

```python
def process_event(event: dict) -> None:
    match event:
        case {"type": "click", "x": int(x), "y": int(y)}:
            handle_click(x, y)
        case {"type": "key", "key": str(k)} if k.startswith("F"):
            handle_function_key(k)
        case {"type": "resize", "width": int(w), "height": int(h)}:
            handle_resize(w, h)
        case {"type": str(unknown)}:
            logger.warning("未知事件类型: %s", unknown)
```

### 2. 类解构（dataclass / 命名元组）

```python
match response:
    case Response(status=200, data=list(items)):
        process_items(items)
    case Response(status=404):
        raise NotFoundError
    case Response(status=int(code)):
        raise HttpError(code)
```

### 3. OR 模式

```python
match status:
    case "ok" | "active" | "running":
        handle_ok()
    case "error" | "failed":
        handle_error()
```

### 4. 守卫（`if` 子句）

```python
match point:
    case Point(x=0, y=0):
        return "原点"
    case Point(x=x, y=y) if x == y:
        return "对角线"
    case Point(x=x, y=y) if x > 0 and y > 0:
        return "第一象限"
```

### 5. 序列模式（`[...]`、`[head, *tail]`）

```python
match command:
    case []:
        return "空命令"
    case [cmd]:
        run(cmd)
    case [cmd, *args]:
        run(cmd, args=args)
    case [cmd, flag, *args] if flag.startswith("-"):
        run(cmd, args=args, flags=[flag])
```

### 6. 结合 `assert_never()`

确保所有分支被覆盖（见第一节第 6 点）。

---

## 七、禁止事项

| 禁止 | 替代方案 |
|------|---------|
| `from __future__ import annotations` | 无需导入，3.14 原生支持 |
| `Optional[X]` | `X \| None` |
| `Union[X, Y]` | `X \| Y` |
| `typing.List`, `typing.Dict` 等 | `list`, `dict` 等内置泛型 |
| `T = TypeVar("T")` | `def f[T](...)` / `class C[T]:` |
| 原生协程调用 `.send()` | 只能 `await` |
| `asyncio.get_event_loop()` | `asyncio.run()` |
| `asyncio._get_running_loop()` 等私有 API | 使用公共 API |
| 字符串包裹前向引用 `'ClassName'` | 直接写类名 |
| 可变默认值 `field: list = []` | `field(default_factory=list)` |
| `datetime.utcnow()` | `datetime.now(UTC)` |
| `class C(str, Enum):` 多重继承 | `class C(StrEnum):` |
| `os.walk()` / 字符串拼接路径 | `pathlib.Path.walk()` / `Path / "sub"` |
| `zip(a, b)` 无 `strict=True`（成对数据） | `zip(a, b, strict=True)` |
| `@cache` 用于无界输入空间 | `@lru_cache(maxsize=...)` |
| async 中用 `threading.local()` | `contextvars.ContextVar` |
| `# type: ignore` 无解释注释 | 修复类型错误或附注释 |

---

## 八、工具链配置

```toml
[tool.pyright]
pythonVersion = "3.14"
typeCheckingMode = "strict"
reportMissingTypeStubs = false

[tool.mypy]
python_version = "3.14"
strict = true
warn_return_any = true
warn_unused_ignores = true

[tool.ruff]
target-version = "py314"
line-length = 88

[tool.ruff.lint]
select = ["E", "F", "I", "UP", "ANN", "B", "SIM", "PL", "RUF"]
# UP  — pyupgrade：flag 过时语法
# ANN — 强制函数注解
# B   — bugbear：常见陷阱
# SIM — 代码简化建议
# PL  — pylint 子集
# RUF — ruff 专有规则
ignore = ["ANN101", "ANN102"]  # 忽略 self/cls 注解要求

[tool.ruff.lint.isort]
known-first-party = ["myapp"]
```

---

## 九、通用实践

### 1. 类型注解覆盖

- 所有公共函数和方法必须有完整的参数和返回值注解。
- 私有方法（`_` 前缀）建议覆盖。
- 禁止 `# type: ignore` 无解释。

### 2. 异步 IO 边界

- `async def` 内**禁止**调用阻塞 IO（`time.sleep`、`requests.get`、同步 DB 驱动）——必然阻塞事件循环。
- 旧同步库必须调用时，用 `asyncio.to_thread(sync_fn, ...)` 放入线程池。
- CPU 密集任务用 `InterpreterPoolExecutor`（真并行）或 `ProcessPoolExecutor`。

### 3. 上下文管理

- 任何需要清理的资源使用 `with` / `async with`（文件、锁、连接、事务）。
- **禁止**手动 `open()` 不配 `close()`，或 `try/finally` 可简化为 `with` 时坚持用 `try/finally`。

### 4. 日期时间

- 默认**时区感知**：`datetime.now(UTC)` 或 `datetime.now(ZoneInfo("Asia/Shanghai"))`。
- 存储/传输用 UTC，展示时转换到用户时区。
- ISO 8601 格式：`dt.isoformat()` 输出，`datetime.fromisoformat(s)` 解析（3.11+ 支持完整 ISO 格式）。

---

遵循以上规则可确保 Python 3.14 代码充分利用语言演进带来的安全性、可读性与性能提升。
