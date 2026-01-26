# Python Naming Conventions (PEP 8)

This document outlines naming standards for Python code following PEP 8 guidelines.

## Classes

**Convention:** PascalCase (CapWords)

```python
# Good
class UserAccount:
    pass

class DataProcessor:
    pass

class HTTPConnection:
    pass

# Bad
class user_account:  # Should be PascalCase
    pass

class dataProcessor:  # Should start with capital
    pass
```

**Rule:** Class names should use PascalCase convention with no underscores.

## Functions and Methods

**Convention:** snake_case

```python
# Good
def get_user_data():
    pass

def process_payment():
    pass

def calculate_total_price():
    pass

# Bad
def getUserData():  # Should be snake_case
    pass

def ProcessPayment():  # Should be lowercase
    pass
```

**Rule:** Function and method names should use snake_case with underscores between words.

## Variables

**Convention:** snake_case

```python
# Good
user_id = 123
total_count = 0
is_active = True
customer_name = "John"

# Bad
userId = 123  # Should be snake_case
TotalCount = 0  # Should be lowercase
IsActive = True  # Should be lowercase
```

**Rule:** Variable names should use snake_case and be descriptive.

## Constants

**Convention:** UPPER_SNAKE_CASE

```python
# Good
MAX_RETRIES = 3
API_KEY = "..."
DEFAULT_TIMEOUT = 30
PI = 3.14159

# Bad
max_retries = 3  # Should be uppercase
ApiKey = "..."  # Should be uppercase with underscores
default_timeout = 30  # Should be uppercase
```

**Rule:** Module-level constants should use UPPER_SNAKE_CASE.

## Private Members

**Convention:** Leading underscore

```python
class MyClass:
    def __init__(self):
        self._internal_cache = {}  # Good: private attribute
        self.public_data = []  # Good: public attribute

    def _internal_method(self):  # Good: private method
        pass

    def public_method(self):  # Good: public method
        self._internal_method()
```

**Rule:**
- Use single leading underscore `_name` for internal/private members
- Use double leading underscore `__name` only for name mangling (rare)
- Never use trailing underscores except to avoid keyword conflicts

## Modules and Packages

**Convention:** snake_case, short, descriptive

```python
# Good module names
user_auth.py
data_utils.py
api_client.py
config.py

# Bad module names
UserAuth.py  # Should be lowercase
dataUtils.py  # Should use underscores
APIClient.py  # Should be lowercase
my_really_long_module_name_that_is_too_descriptive.py  # Too long
```

**Rule:** Module names should be short, lowercase, with underscores if needed.

## Special Cases

### Acronyms in Names

```python
# Good
class HTTPServer:  # Acronym at start: all caps
    pass

class HtmlParser:  # Acronym in middle: only first letter caps
    pass

def parse_json_data():  # Acronyms in snake_case: lowercase
    pass

# Bad
class HttpServer:  # Inconsistent
    pass

class HTMLParser:  # Too many caps in middle
    pass
```

### Single Letter Variables

Acceptable only in specific contexts:

```python
# Good: mathematical contexts
for i in range(10):
    pass

# Good: comprehensions with clear context
squares = [x**2 for x in numbers]

# Good: exception handling
try:
    pass
except Exception as e:
    pass

# Bad: unclear meaning
def process(d):  # What is 'd'?
    for x in d:  # What is 'x'?
        pass
```

## Framework-Specific Naming

### Django Models

Django models should use singular PascalCase:

```python
# Good
class User(models.Model):
    pass

class BlogPost(models.Model):  # Singular, not BlogPosts
    pass

# Bad
class Users(models.Model):  # Should be singular
    pass

class blog_post(models.Model):  # Should be PascalCase
    pass
```

### FastAPI Routes

FastAPI route functions should be descriptive verbs:

```python
# Good
@app.get("/users")
async def get_users():
    pass

@app.post("/users")
async def create_user():
    pass

# Bad
@app.get("/users")
async def users():  # Not descriptive
    pass
```

## Summary Table

| Element | Convention | Example |
|---------|-----------|---------|
| Classes | PascalCase | `UserAccount`, `DataProcessor` |
| Functions/Methods | snake_case | `get_user_data()`, `calculate_total()` |
| Variables | snake_case | `user_id`, `total_count` |
| Constants | UPPER_SNAKE_CASE | `MAX_RETRIES`, `API_KEY` |
| Private members | `_leading_underscore` | `_internal_method()`, `_cache` |
| Modules/Packages | snake_case (short) | `user_auth`, `data_utils` |

## References

- [PEP 8 -- Style Guide for Python Code](https://www.python.org/dev/peps/pep-0008/)
- [PEP 8 Naming Conventions](https://www.python.org/dev/peps/pep-0008/#naming-conventions)
