# Python 3.14 Development Rules

These rules apply to Python 3.14 projects. All generated code must strictly follow these conventions to use the latest syntax, standard library features, and type annotation standards.

---

## 1. Type Annotations

### 1.1 Deferred Evaluation (PEP 649 & 749)

Python 3.14 natively implements deferred annotation evaluation — annotations are no longer executed at definition time, but evaluated on demand.

- **Forbidden**: `from __future__ import annotations` — Python 3.14 natively defers all annotations.
- **Forward references**: use class names directly even when not yet defined in the current scope. No string wrapping needed.

```python
class Node:
    def children(self) -> list[Node]:  # ✅ Direct reference, no 'Node' string
        ...

class Response:
    data: list[Item]        # ✅ Works even if Item is defined later
    error: Error | None
```

### 1.2 Built-in Generics

- **Union types**: use `X | Y`, not `Union[X, Y]`; use `X | None`, not `Optional[X]`.
- **Generic containers**: `list[int]`, `dict[str, int]`, `tuple[int, str]`, `set[int]`. **Forbidden**: `typing.List`, `typing.Dict`, and other deprecated aliases.
- **Type aliases**: prefer the `type` statement (Python 3.12+):

```python
type Vector = list[float]
type Matrix = list[Vector]
type JsonValue = str | int | float | bool | None | list[JsonValue] | dict[str, JsonValue]
type Callback[T] = (T) -> None
```

**Forbidden**: plain variable assignment `Vector = list[float]` as a type alias (unless tooling compatibility requires it).

### 1.3 Generic Classes and Functions (PEP 695, Python 3.12+)

Use `[T]` syntax for generics. **Forbidden**: old `TypeVar` style.

```python
# ✅ New 3.12+ syntax
class Stack[T]:
    def __init__(self) -> None:
        self._items: list[T] = []

    def push(self, item: T) -> None:
        self._items.append(item)

    def pop(self) -> T:
        return self._items.pop()

def first[T](items: list[T]) -> T:
    return items[0]

# Constrained generic (T must be int, float, or str)
def maximum[T: (int, float, str)](a: T, b: T) -> T:
    return a if a > b else b

# Bounded generic (T must be a subtype of Comparable)
class SortedList[T: Comparable]:
    ...
```

**Constraint vs bound:**
- `T: (int, float, str)` — constraint: T must be **exactly** one of these types
- `T: Comparable` — bound: T must be a subtype of `Comparable`

### 1.4 `@override` Decorator (PEP 698, Python 3.12+)

Mark overriding methods with `@override` so static checkers catch typos and signature mismatches:

```python
from typing import override

class Animal:
    def speak(self) -> str: ...

class Dog(Animal):
    @override
    def speak(self) -> str:  # ✅ Checker verifies parent class has this method
        return "woof"
```

### 1.5 `Self` Type

Use `Self` instead of the class name when a method returns its own instance, ensuring correct return types in subclasses:

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

# AdvancedBuilder().set_name("x").set_level(2) returns AdvancedBuilder, not Builder
```

### 1.6 `Never` and Exhaustiveness Checking

`assert_never()` makes the static checker error on missed branches:

```python
from typing import Literal, Never, assert_never

type Status = Literal["pending", "active", "closed"]

def handle(status: Status) -> str:
    match status:
        case "pending": return "waiting"
        case "active":  return "running"
        case "closed":  return "done"
        case _ as unreachable:
            assert_never(unreachable)  # Compile error if a new Status value is unhandled
```

### 1.7 Literal Types

Use `Literal["a", "b"]` for finite value sets:

```python
from typing import Literal

type Direction = Literal["north", "south", "east", "west"]
type HttpMethod = Literal["GET", "POST", "PUT", "DELETE", "PATCH"]

def route(method: HttpMethod, path: str) -> None: ...
```

### 1.8 TypedDict Enhancements (PEP 655)

```python
from typing import TypedDict, NotRequired, Required

class UserFilter(TypedDict):
    username: str
    email: NotRequired[str]
    page: NotRequired[int]

class Config(TypedDict, total=False):
    host: Required[str]   # Required even in a total=False TypedDict
    port: int
    debug: bool
```

### 1.9 `assert_type()` Static Verification

Explicitly verify inferred types in unit tests or critical spots:

```python
from typing import assert_type

x = [1, 2, 3]
assert_type(x, list[int])   # Static checker verifies x's inferred type; zero runtime cost
```

---

## 2. Enums

### 2.1 Prefer `StrEnum` / `IntEnum` (Python 3.11+)

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

# StrEnum instances are interchangeable with strings; JSON serialization is natural
Status.ACTIVE == "active"  # ✅ True
```

**Forbidden**: the multiple-inheritance pattern `class Color(str, Enum):` — use `StrEnum` in 3.11+.

### 2.2 `auto()` for Value Generation

```python
class Color(StrEnum):
    RED = auto()    # Automatically "red"
    GREEN = auto()  # Automatically "green"
    BLUE = auto()   # Automatically "blue"
```

---

## 3. Async Programming

### 3.1 Entry Point

```python
import asyncio

async def main() -> None:
    ...

if __name__ == "__main__":
    asyncio.run(main())
```

**Forbidden**:
- ❌ `loop = asyncio.get_event_loop()`
- ❌ `loop.run_until_complete(coro)`
- ❌ `asyncio._get_running_loop()` (private API)

### 3.2 Structured Concurrency (TaskGroup, Python 3.11+)

```python
async def fetch_all(urls: list[str]) -> list[bytes]:
    async with asyncio.TaskGroup() as tg:
        tasks = [tg.create_task(fetch(url)) for url in urls]
    return [task.result() for task in tasks]
```

`TaskGroup` advantages: automatically cancels remaining tasks when any subtask fails, and aggregates all exceptions into an `ExceptionGroup`. Prefer as the default choice; `asyncio.gather()` remains fine for simple cases.

### 3.3 Timeout Control (Python 3.11+)

```python
async def fetch_with_timeout(url: str) -> bytes:
    async with asyncio.timeout(5.0):
        return await fetch(url)

# Share a single deadline
async def pipeline() -> None:
    async with asyncio.timeout(10.0):
        data = await step1()
        result = await step2(data)  # Both steps share the 10s budget
```

### 3.4 Exception Groups (`except*`, Python 3.11+)

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

### 3.5 Concurrency Limiting (Semaphore)

```python
sem = asyncio.Semaphore(10)  # Max 10 concurrent requests

async def bounded_fetch(url: str) -> bytes:
    async with sem:
        return await fetch(url)
```

### 3.6 Coroutine and Generator Reference

| Type | How to drive | Restriction |
|------|-------------|-------------|
| Native coroutine `async def` | `await` | ❌ No `.send()` |
| Sync generator `def` + `yield` | `next()` / `.send()` | ✅ Full iterator protocol |
| Async generator `async def` + `yield` | `async for` / `await anext()` | ❌ No `.send()` |

### 3.7 Context Variables (`contextvars`)

Thread/coroutine-safe request-scoped context (e.g. request_id, user):

```python
from contextvars import ContextVar

request_id: ContextVar[str] = ContextVar("request_id", default="-")

async def handler():
    request_id.set(uuid4().hex)
    await process()

async def process():
    logger.info("request=%s", request_id.get())  # Automatically gets current coroutine's value
```

**Forbidden**: global variables or `threading.local()` for async context passing.

### 3.8 Subinterpreter Concurrency (PEP 734, Python 3.14)

CPU-bound tasks can use `InterpreterPoolExecutor` for true parallelism (each subinterpreter has its own GIL):

```python
from concurrent.futures import InterpreterPoolExecutor

with InterpreterPoolExecutor(max_workers=4) as pool:
    results = list(pool.map(heavy_cpu_task, data))
```

Compared to multiprocessing: smaller startup overhead, more flexible data passing. Compared to multithreading: not limited by the GIL.

### 3.9 Free-threaded CPython (PEP 703)

Python 3.14 optionally ships a no-GIL build (`python3.14t`). Significant speedup for multi-threaded CPU-bound code, but:
- Only active under the **`python3.14t`** build
- **Verify all native extensions are compatible** with free-threaded mode
- Default build still has the GIL; regular projects need no change

---

## 4. New Standard Library Features

### 4.1 Template Strings (t-strings, PEP 750)

**Key distinction**: t-strings return a `Template` object, **not a string**, allowing libraries to process interpolations before rendering (escaping, validation, parameterization):

```python
# Safe SQL building (requires a t-string-aware library)
query = t"SELECT * FROM users WHERE name = {user_name} AND age > {min_age}"
# query is a Template object; libraries safely extract interpolations to parameterize them

# Safe HTML rendering
html = t"<div class={cls}>{content}</div>"
```

**Warning**: `str(t"...")` loses all safety guarantees. **Forbidden**: direct string conversion — always render through a t-string-aware library.

### 4.2 Temporary Directory Change (`contextlib.chdir`, Python 3.11+)

```python
from contextlib import chdir

with chdir("/tmp/sandbox"):
    result = subprocess.run(["make", "build"], capture_output=True)
# Original directory is restored on exit
```

### 4.3 Zstandard Compression (PEP 784)

```python
import compression.zstd as zstd

compressed = zstd.compress(data, level=3)
decompressed = zstd.decompress(compressed)

with zstd.open("archive.zst", "wb") as f:
    f.write(large_data)
```

3-10× faster than `gzip` at equivalent ratios.

### 4.4 Chunked Iteration (`itertools.batched()`, Python 3.12+)

```python
from itertools import batched

records = list(range(1000))
for chunk in batched(records, 100):
    db.bulk_insert(list(chunk))
```

### 4.5 TOML Parsing (`tomllib`, Python 3.11+)

```python
import tomllib

with open("pyproject.toml", "rb") as f:  # Must open as "rb"
    config = tomllib.load(f)
```

### 4.6 `pathlib.Path.walk()` (Python 3.12+)

Replaces `os.walk`, returning `Path` objects:

```python
from pathlib import Path

for root, dirs, files in Path("src").walk():
    for f in files:
        if f.endswith(".py"):
            print(root / f)
```

**Forbidden**: `os.walk()` or string path concatenation in new code.

### 4.7 `datetime.UTC` (Python 3.11+)

```python
from datetime import datetime, UTC

now = datetime.now(UTC)       # ✅ Timezone-aware
# datetime.now(timezone.utc)  ❌ Old style, discouraged in 3.12+
```

**Forbidden**: `datetime.utcnow()` — returns naive datetime, deprecated in 3.12+.

### 4.8 `zip(..., strict=True)` (Python 3.10+)

Raises immediately when lengths differ — prevents silent truncation:

```python
for k, v in zip(keys, values, strict=True):
    ...
# If lengths differ: ValueError: zip() argument 2 is shorter than argument 1
```

**Forbidden**: `zip()` without `strict=True` on paired data — silent truncation is a common bug source.

### 4.9 Cache Decorators

```python
from functools import cache, lru_cache

@cache              # Unlimited (use only when input space is small and finite)
def factorial(n: int) -> int: ...

@lru_cache(maxsize=1024)   # Bounded (recommended default)
def expensive(x: int) -> int: ...
```

**Trap**: `@cache` grows unbounded. **Forbidden**: using it on functions driven by user input — use `@lru_cache(maxsize=...)`.

### 4.10 Improved Error Messages

Python 3.14 continues improving error output:
- `IndexError`: shows list length and failing index
- `AttributeError`: suggests similar attribute names
- `NameError`: suggests similar in-scope variable names
- `TypeError`: shows function signature on argument mismatch

---

## 5. Dataclass Best Practices

### 5.1 Prefer `slots=True`

```python
from dataclasses import dataclass, field

@dataclass(slots=True, frozen=True)
class Point:
    x: float
    y: float

    def distance_from_origin(self) -> float:
        return (self.x ** 2 + self.y ** 2) ** 0.5
```

`slots=True` reduces memory and speeds up attribute access; `frozen=True` makes instances immutable and hashable.

### 5.2 Mutable Defaults Use `field(default_factory=...)`

```python
@dataclass
class Config:
    tags: list[str] = field(default_factory=list)
    metadata: dict[str, str] = field(default_factory=dict)
```

❌ **Forbidden**: `tags: list[str] = []` — mutable default shared across all instances.

### 5.3 `KW_ONLY` Sentinel

```python
from dataclasses import dataclass, KW_ONLY

@dataclass
class Request:
    method: str
    path: str
    _: KW_ONLY               # All subsequent fields are keyword-only
    timeout: float = 30.0
    headers: dict[str, str] = field(default_factory=dict)
```

---

## 6. Structural Pattern Matching (`match`)

### 6.1 Basic Destructuring

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
            logger.warning("Unknown event type: %s", unknown)
```

### 6.2 Class Destructuring (dataclass / named tuple)

```python
match response:
    case Response(status=200, data=list(items)):
        process_items(items)
    case Response(status=404):
        raise NotFoundError
    case Response(status=int(code)):
        raise HttpError(code)
```

### 6.3 OR Patterns

```python
match status:
    case "ok" | "active" | "running":
        handle_ok()
    case "error" | "failed":
        handle_error()
```

### 6.4 Guards (`if` clauses)

```python
match point:
    case Point(x=0, y=0):
        return "origin"
    case Point(x=x, y=y) if x == y:
        return "diagonal"
    case Point(x=x, y=y) if x > 0 and y > 0:
        return "first quadrant"
```

### 6.5 Sequence Patterns (`[...]`, `[head, *tail]`)

```python
match command:
    case []:
        return "empty command"
    case [cmd]:
        run(cmd)
    case [cmd, *args]:
        run(cmd, args=args)
    case [cmd, flag, *args] if flag.startswith("-"):
        run(cmd, args=args, flags=[flag])
```

### 6.6 Combining with `assert_never()`

Ensure all branches are covered (see section 1.6).

---

## 7. Forbidden Patterns

| Forbidden | Replacement |
|-----------|------------|
| `from __future__ import annotations` | Not needed — 3.14 native |
| `Optional[X]` | `X \| None` |
| `Union[X, Y]` | `X \| Y` |
| `typing.List`, `typing.Dict`, etc. | `list`, `dict`, built-in generics |
| `T = TypeVar("T")` | `def f[T](...)` / `class C[T]:` |
| `.send()` on native coroutines | `await` only |
| `asyncio.get_event_loop()` | `asyncio.run()` |
| `asyncio._get_running_loop()` and other private APIs | Public API only |
| String-wrapped forward references `'ClassName'` | Use class name directly |
| Mutable default `field: list = []` | `field(default_factory=list)` |
| `datetime.utcnow()` | `datetime.now(UTC)` |
| `class C(str, Enum):` multiple inheritance | `class C(StrEnum):` |
| `os.walk()` / string path concatenation | `pathlib.Path.walk()` / `Path / "sub"` |
| `zip(a, b)` without `strict=True` on paired data | `zip(a, b, strict=True)` |
| `@cache` on unbounded input space | `@lru_cache(maxsize=...)` |
| `threading.local()` in async code | `contextvars.ContextVar` |
| `# type: ignore` without explanation | Fix the type error or add a comment |

---

## 8. Toolchain Configuration

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
# UP  — pyupgrade: flag outdated syntax
# ANN — enforce function annotations
# B   — bugbear: common footguns
# SIM — simplification suggestions
# PL  — pylint subset
# RUF — ruff-specific rules
ignore = ["ANN101", "ANN102"]  # Skip self/cls annotation requirements

[tool.ruff.lint.isort]
known-first-party = ["myapp"]
```

---

## 9. General Practices

### 9.1 Annotation Coverage

- All public functions and methods must have complete parameter and return type annotations.
- Private methods (`_` prefix) are recommended but not required.
- Forbidden: `# type: ignore` without an explanatory comment.

### 9.2 Async IO Boundaries

- **Forbidden**: blocking IO inside `async def` (`time.sleep`, `requests.get`, synchronous DB drivers) — blocks the event loop.
- When legacy sync libraries are unavoidable, dispatch with `asyncio.to_thread(sync_fn, ...)`.
- CPU-bound tasks: use `InterpreterPoolExecutor` (true parallelism) or `ProcessPoolExecutor`.

### 9.3 Context Management

- Every resource needing cleanup uses `with` / `async with` (files, locks, connections, transactions).
- **Forbidden**: manual `open()` without `close()`, or `try/finally` when `with` would simplify.

### 9.4 Date and Time

- Default to **timezone-aware**: `datetime.now(UTC)` or `datetime.now(ZoneInfo("Asia/Shanghai"))`.
- Store/transmit in UTC; convert to user timezone only for display.
- ISO 8601 format: `dt.isoformat()` for output, `datetime.fromisoformat(s)` for parsing (3.11+ supports full ISO format).

---

Following these rules ensures Python 3.14 code fully leverages the language's latest safety, readability, and performance improvements.
