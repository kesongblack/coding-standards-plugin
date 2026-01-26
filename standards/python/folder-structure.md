# Python Project Structure

This document outlines recommended folder structures and organization patterns for Python projects.

## Standard Python Project Layout

### Basic Structure

```
myproject/
├── src/
│   └── myproject/
│       ├── __init__.py
│       ├── core.py
│       ├── utils.py
│       └── models/
│           ├── __init__.py
│           └── user.py
├── tests/
│   ├── __init__.py
│   ├── test_core.py
│   └── test_models/
│       ├── __init__.py
│       └── test_user.py
├── docs/
│   └── README.md
├── .gitignore
├── pyproject.toml
├── requirements.txt
└── README.md
```

### Alternative Flat Structure

For simpler projects:

```
myproject/
├── myproject/
│   ├── __init__.py
│   ├── core.py
│   └── utils.py
├── tests/
│   ├── __init__.py
│   └── test_core.py
├── pyproject.toml
├── requirements.txt
└── README.md
```

## Package Structure

### Using __init__.py

Every package directory needs `__init__.py`:

```
myproject/
├── __init__.py          # Makes myproject a package
├── core.py
└── subpackage/
    ├── __init__.py      # Makes subpackage a package
    └── module.py
```

**Purpose:**
- Marks directory as Python package
- Can expose public API
- Can run initialization code

### Package __init__.py Example

```python
# myproject/__init__.py

# Expose public API
from .core import main_function, ImportantClass
from .utils import helper_function

# Version info
__version__ = "1.0.0"

# Package-level constants
DEFAULT_CONFIG = {...}

# All public exports
__all__ = [
    "main_function",
    "ImportantClass",
    "helper_function",
]
```

## Avoiding Circular Imports

### Problem: Circular Dependencies

```python
# Bad - circular import
# file: models/user.py
from models.post import Post

class User:
    def get_posts(self) -> list[Post]:
        pass

# file: models/post.py
from models.user import User  # Circular!

class Post:
    def get_author(self) -> User:
        pass
```

### Solution 1: Dependency Injection

```python
# Good - pass dependencies as parameters
# file: models/user.py
class User:
    def get_posts(self):
        from models.post import Post  # Import inside method
        return Post.query.filter_by(user_id=self.id)

# file: models/post.py
class Post:
    def get_author(self):
        from models.user import User
        return User.query.get(self.author_id)
```

### Solution 2: Type Hints with TYPE_CHECKING

```python
# Good - use TYPE_CHECKING for type hints only
# file: models/user.py
from typing import TYPE_CHECKING

if TYPE_CHECKING:
    from models.post import Post  # Only imported for type checking

class User:
    def get_posts(self) -> list['Post']:  # String annotation
        from models.post import Post  # Runtime import
        return Post.query.filter_by(user_id=self.id)
```

### Solution 3: Restructure Code

```python
# Better - move shared types to separate module
# file: models/types.py
from typing import Protocol

class UserLike(Protocol):
    id: int
    name: str

class PostLike(Protocol):
    id: int
    title: str

# file: models/user.py
from models.types import PostLike

class User:
    def get_posts(self) -> list[PostLike]:
        pass
```

## Relative vs Absolute Imports

### Absolute Imports (Recommended)

```python
# Good - clear and explicit
from myproject.models.user import User
from myproject.utils.helpers import format_date
from myproject.core import process_data
```

### Relative Imports

```python
# Acceptable within same package
# file: myproject/models/post.py
from .user import User  # Same package
from ..utils import helper  # Parent package
from . import base  # Current package

# Avoid going up too many levels
from ...something import x  # Hard to follow
```

## Module Organization

### Single Responsibility

Each module should have one clear purpose:

```
myproject/
├── models/          # Data models only
│   ├── user.py
│   └── post.py
├── services/        # Business logic
│   ├── auth.py
│   └── notification.py
├── utils/           # Helper functions
│   ├── date.py
│   └── validation.py
└── api/             # API endpoints
    ├── routes.py
    └── schemas.py
```

### Module Size

Keep modules focused and reasonably sized:

- **Ideal:** 200-400 lines
- **Maximum:** ~500 lines before splitting
- If larger, consider splitting into subpackages

### Example: Splitting Large Module

```python
# Before: user.py (1000 lines)
class User:
    # ... 500 lines ...

class UserRepository:
    # ... 300 lines ...

class UserValidator:
    # ... 200 lines ...

# After: Split into package
user/
├── __init__.py       # Expose public API
├── model.py          # User class
├── repository.py     # UserRepository
└── validation.py     # UserValidator
```

## Configuration Management

### Separate Configuration from Code

```
myproject/
├── config/
│   ├── __init__.py
│   ├── base.py        # Base configuration
│   ├── development.py # Dev settings
│   ├── production.py  # Prod settings
│   └── testing.py     # Test settings
└── .env              # Environment variables (not in git!)
```

### Example Configuration Structure

```python
# config/base.py
import os

class Config:
    SECRET_KEY = os.environ.get('SECRET_KEY')
    DATABASE_URL = os.environ.get('DATABASE_URL')

# config/development.py
from .base import Config

class DevelopmentConfig(Config):
    DEBUG = True
    TESTING = False

# config/production.py
from .base import Config

class ProductionConfig(Config):
    DEBUG = False
    TESTING = False

# config/__init__.py
import os
from .development import DevelopmentConfig
from .production import ProductionConfig

config = {
    'development': DevelopmentConfig,
    'production': ProductionConfig,
}

def get_config():
    env = os.environ.get('ENVIRONMENT', 'development')
    return config[env]
```

## Common Directory Purposes

### docs/

Documentation files:

```
docs/
├── api/           # API documentation
├── guides/        # User guides
├── architecture/  # Architecture docs
└── README.md
```

### scripts/

Utility scripts:

```
scripts/
├── setup.sh       # Setup script
├── deploy.sh      # Deployment
└── migrate.py     # Database migrations
```

### tests/

Test files mirroring source structure:

```
tests/
├── unit/
│   └── test_models/
├── integration/
│   └── test_api/
├── fixtures/      # Test data
│   └── sample_data.json
└── conftest.py    # Pytest configuration
```

## Framework-Specific Structures

### Django Project Structure

```
myproject/
├── myproject/          # Project package
│   ├── settings/
│   │   ├── base.py
│   │   ├── development.py
│   │   └── production.py
│   ├── urls.py
│   └── wsgi.py
├── apps/               # Django apps
│   ├── users/
│   │   ├── migrations/
│   │   ├── models.py
│   │   ├── views.py
│   │   ├── urls.py
│   │   └── admin.py
│   └── posts/
│       ├── migrations/
│       ├── models.py
│       └── views.py
├── static/
├── media/
├── templates/
└── manage.py
```

See [Django structure guide](frameworks/django.md#structure) for details.

### FastAPI Project Structure

```
myapp/
├── app/
│   ├── main.py         # FastAPI app
│   ├── dependencies.py # Shared dependencies
│   ├── routers/        # API routes
│   │   ├── users.py
│   │   └── items.py
│   ├── schemas/        # Pydantic models
│   │   ├── user.py
│   │   └── item.py
│   ├── models/         # Database models
│   │   └── user.py
│   └── services/       # Business logic
│       └── auth.py
└── tests/
```

See [FastAPI structure guide](frameworks/fastapi.md#structure) for details.

### Data Science Project Structure

```
myproject/
├── data/
│   ├── raw/           # Original data
│   ├── processed/     # Cleaned data
│   └── external/      # Third-party data
├── notebooks/         # Jupyter notebooks
│   ├── exploratory/
│   └── analysis/
├── src/
│   ├── data/          # Data loading/processing
│   ├── features/      # Feature engineering
│   ├── models/        # Model training
│   └── visualization/ # Plotting
├── models/            # Trained models
├── reports/           # Generated reports
└── requirements.txt
```

See [Data Science structure guide](frameworks/datascience.md#structure) for details.

## File Naming Conventions

- **Modules:** `snake_case.py`
- **Packages:** `snake_case/`
- **Test files:** `test_*.py` or `*_test.py`
- **Configuration:** `config.py`, `settings.py`
- **Constants:** `constants.py` or `config.py`

## What NOT to Do

### Avoid Deep Nesting

```python
# Bad - too deep
from myproject.api.v1.endpoints.users.handlers.authentication import login

# Good - flatter structure
from myproject.api.users import login
```

### Avoid Generic Names

```python
# Bad
utils.py         # Too generic
helpers.py       # What kind of helpers?
common.py        # What's common?

# Good
date_utils.py    # Specific purpose
validation.py    # Clear responsibility
formatting.py    # Focused module
```

### Avoid Single-File Packages

```python
# Bad - unnecessary package for single file
models/
└── __init__.py  # Contains all model code

# Good - just use a module
models.py        # Single file
```

## References

- [Python Packaging User Guide](https://packaging.python.org/)
- [The Hitchhiker's Guide to Python - Structuring Your Project](https://docs.python-guide.org/writing/structure/)
- [PEP 8 - Package and Module Names](https://www.python.org/dev/peps/pep-0008/#package-and-module-names)
