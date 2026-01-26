# Python Best Practices and Patterns

This document covers Python coding patterns and best practices for writing clean, maintainable code.

## Type Hints

Use type hints for function signatures (PEP 484, Python 3.9+):

```python
# Good
def calculate_total(prices: list[float], tax_rate: float) -> float:
    return sum(prices) * (1 + tax_rate)

def get_user(user_id: int) -> dict[str, any] | None:
    return database.query(user_id)

# Bad
def calculate_total(prices, tax_rate):  # No type hints
    return sum(prices) * (1 + tax_rate)
```

**Benefits:**
- Early error detection with type checkers (mypy)
- Better IDE autocomplete
- Self-documenting code

## Context Managers

Always use context managers for resource management:

```python
# Good
with open('file.txt', 'r') as f:
    data = f.read()
    # File automatically closed

# Good: custom context manager
from contextlib import contextmanager

@contextmanager
def database_connection():
    conn = create_connection()
    try:
        yield conn
    finally:
        conn.close()

# Bad
f = open('file.txt', 'r')
data = f.read()
f.close()  # Easy to forget or skip on error
```

**Common use cases:**
- File operations
- Database connections
- Locks and semaphores
- Network connections

## String Formatting

Prefer f-strings over older methods:

```python
name = "Alice"
age = 30

# Good: f-strings (Python 3.6+)
message = f"Hello, {name}! You are {age} years old."
formatted = f"Total: ${price:.2f}"

# Acceptable: str.format() for complex templates
template = "User {name} ({age})"
message = template.format(name=name, age=age)

# Bad: % formatting (outdated)
message = "Hello, %s! You are %d years old." % (name, age)

# Bad: string concatenation
message = "Hello, " + name + "! You are " + str(age) + " years old."
```

## Mutable Default Arguments

Never use mutable objects as default arguments:

```python
# Bad - DANGER!
def add_item(item, items=[]):  # [] created once, shared across calls!
    items.append(item)
    return items

# Calling multiple times causes unexpected behavior
add_item(1)  # [1]
add_item(2)  # [1, 2] - NOT [2]!

# Good
def add_item(item, items=None):
    if items is None:
        items = []
    items.append(item)
    return items
```

**Rule:** Use `None` as default, create mutable object inside function.

## Pathlib vs os.path

Use `pathlib.Path` for path operations:

```python
from pathlib import Path

# Good: pathlib
config_path = Path.home() / '.config' / 'app' / 'settings.json'
if config_path.exists():
    content = config_path.read_text()

# Bad: os.path (old way)
import os
config_path = os.path.join(os.path.expanduser('~'), '.config', 'app', 'settings.json')
if os.path.exists(config_path):
    with open(config_path) as f:
        content = f.read()
```

**Benefits:**
- More readable with `/` operator
- Methods like `.exists()`, `.read_text()`, `.mkdir()`
- Cross-platform path handling

## List Comprehensions

Use comprehensions for simple transformations:

```python
# Good: readable comprehension
squares = [x**2 for x in range(10)]
even_numbers = [x for x in range(20) if x % 2 == 0]
names = [user['name'] for user in users if user['active']]

# Bad: loop for simple transformation
squares = []
for x in range(10):
    squares.append(x**2)

# Bad: complex comprehension (use regular loop)
result = [
    process_item(x, y, z)
    for x in items
    if x.valid
    for y in x.subitems
    if y.status == 'active'
    for z in y.values
]  # Too complex - use regular loop!
```

**Rule:** Use comprehensions when they're more readable than a loop. If logic is complex, use a regular loop.

## Dictionary and Set Comprehensions

```python
# Dictionary comprehension
word_lengths = {word: len(word) for word in words}
squared = {x: x**2 for x in range(10)}

# Set comprehension
unique_lengths = {len(word) for word in words}
```

## Generator Expressions

Use generators for large sequences to save memory:

```python
# Good: generator (memory efficient)
total = sum(x**2 for x in range(1000000))

# Bad: list comprehension (wastes memory)
total = sum([x**2 for x in range(1000000)])

# Good: generator for file processing
lines = (line.strip() for line in open('file.txt'))
```

## Enumerate and Zip

Use built-in functions for iteration:

```python
# Good: enumerate for index + value
for i, item in enumerate(items):
    print(f"{i}: {item}")

# Bad
for i in range(len(items)):
    print(f"{i}: {items[i]}")

# Good: zip for parallel iteration
for name, age in zip(names, ages):
    print(f"{name} is {age} years old")

# Bad
for i in range(len(names)):
    print(f"{names[i]} is {ages[i]} years old")
```

## Unpacking

Use tuple unpacking for cleaner code:

```python
# Good: unpacking
x, y = get_coordinates()
first, *middle, last = items
name, age, *rest = user_data

# Good: swap variables
a, b = b, a

# Bad
coords = get_coordinates()
x = coords[0]
y = coords[1]
```

## with Statement for Multiple Resources

```python
# Good: multiple context managers
with open('input.txt') as infile, open('output.txt', 'w') as outfile:
    outfile.write(infile.read())

# Python 3.10+: parenthesized context managers
with (
    open('input.txt') as infile,
    open('output.txt', 'w') as outfile,
    database_connection() as db
):
    process_data(infile, outfile, db)
```

## Exception Handling

Be specific with exception types:

```python
# Good: specific exception
try:
    result = int(user_input)
except ValueError:
    print("Invalid number")

# Good: multiple specific exceptions
try:
    data = fetch_data(url)
except requests.Timeout:
    print("Request timed out")
except requests.ConnectionError:
    print("Connection failed")

# Bad: bare except
try:
    risky_operation()
except:  # Catches everything, including KeyboardInterrupt!
    pass

# Acceptable: catch and re-raise
try:
    operation()
except Exception as e:
    log_error(e)
    raise
```

## Dataclasses

Use dataclasses for simple data containers (Python 3.7+):

```python
from dataclasses import dataclass

# Good: dataclass
@dataclass
class User:
    name: str
    age: int
    email: str
    active: bool = True

# Bad: manual __init__
class User:
    def __init__(self, name, age, email, active=True):
        self.name = name
        self.age = age
        self.email = email
        self.active = active
```

## Property Decorators

Use properties for computed attributes:

```python
class Circle:
    def __init__(self, radius):
        self._radius = radius

    @property
    def radius(self):
        return self._radius

    @radius.setter
    def radius(self, value):
        if value < 0:
            raise ValueError("Radius cannot be negative")
        self._radius = value

    @property
    def area(self):
        return 3.14159 * self._radius ** 2
```

## Avoid Anti-Patterns

### Don't check type with `type()`

```python
# Bad
if type(x) == list:
    pass

# Good: use isinstance()
if isinstance(x, list):
    pass

# Better: duck typing
try:
    x.append(item)
except AttributeError:
    # Not list-like
    pass
```

### Don't compare to True/False

```python
# Bad
if is_valid == True:
    pass

# Good
if is_valid:
    pass

# Bad
if len(items) > 0:
    pass

# Good
if items:
    pass
```

### Don't use `len()` for empty check

```python
# Bad
if len(items) == 0:
    pass

# Good
if not items:
    pass
```

## Performance Tips

### Use `in` for membership tests

```python
# Good: set for fast lookup
valid_ids = {1, 2, 3, 4, 5}
if user_id in valid_ids:
    pass

# Bad: list for lookup (O(n))
valid_ids = [1, 2, 3, 4, 5]
if user_id in valid_ids:
    pass
```

### Use `str.join()` for concatenation

```python
# Good
result = ', '.join(names)

# Bad
result = ''
for name in names:
    result += name + ', '
```

## References

- [PEP 8 -- Style Guide for Python Code](https://www.python.org/dev/peps/pep-0008/)
- [PEP 20 -- The Zen of Python](https://www.python.org/dev/peps/pep-0020/)
- [PEP 484 -- Type Hints](https://www.python.org/dev/peps/pep-0484/)
- [Python Documentation: Context Managers](https://docs.python.org/3/library/contextlib.html)
