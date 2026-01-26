# Python Testing Standards

This document outlines testing best practices for Python projects using pytest.

## Test Structure

### File Organization

Tests should mirror the source structure:

```
project/
├── src/
│   ├── __init__.py
│   ├── users.py
│   └── payments.py
└── tests/
    ├── __init__.py
    ├── test_users.py
    └── test_payments.py
```

### Test File Naming

**Convention:** `test_*.py` or `*_test.py`

```python
# Good
test_users.py
test_payment_processing.py
users_test.py

# Bad
users.py  # Conflicts with source
test.py  # Not specific
testing_users.py  # Wrong prefix
```

### Test Function Naming

**Convention:** `test_function_name_scenario()`

```python
# Good
def test_user_creation_with_valid_data():
    pass

def test_payment_processing_with_insufficient_funds():
    pass

def test_api_returns_404_for_missing_user():
    pass

# Bad
def user_creation():  # Missing 'test_' prefix
    pass

def test_user():  # Not specific enough
    pass

def testUserCreation():  # Should use snake_case
    pass
```

## Pytest Basics

### Simple Test Structure

```python
import pytest
from myapp.users import create_user, delete_user

def test_create_user_success():
    # Arrange
    user_data = {"name": "Alice", "email": "alice@example.com"}

    # Act
    user = create_user(user_data)

    # Assert
    assert user.name == "Alice"
    assert user.email == "alice@example.com"
    assert user.id is not None
```

### Using Fixtures

Fixtures provide reusable setup/teardown:

```python
import pytest

@pytest.fixture
def sample_user():
    """Create a test user for use in tests."""
    user = create_user({"name": "Test", "email": "test@example.com"})
    yield user
    # Cleanup after test
    delete_user(user.id)

def test_user_update(sample_user):
    # sample_user is automatically created and passed
    sample_user.name = "Updated"
    sample_user.save()
    assert sample_user.name == "Updated"

@pytest.fixture(scope="module")
def database():
    """Database connection shared across test module."""
    db = connect_to_test_database()
    yield db
    db.close()
```

**Fixture scopes:**
- `function` (default): New instance per test
- `class`: New instance per test class
- `module`: New instance per module
- `session`: One instance for entire test session

### Parametrized Tests

Test multiple cases with one function:

```python
import pytest

@pytest.mark.parametrize("input,expected", [
    (0, 0),
    (1, 1),
    (2, 4),
    (3, 9),
    (-2, 4),
])
def test_square(input, expected):
    assert square(input) == expected

@pytest.mark.parametrize("email", [
    "invalid",
    "@example.com",
    "user@",
    "user @example.com",
])
def test_invalid_email_rejected(email):
    with pytest.raises(ValueError):
        validate_email(email)
```

### Testing Exceptions

```python
import pytest

def test_division_by_zero():
    with pytest.raises(ZeroDivisionError):
        divide(10, 0)

def test_invalid_input_message():
    with pytest.raises(ValueError, match="age must be positive"):
        create_user(age=-5)
```

### Testing Warnings

```python
import pytest
import warnings

def test_deprecated_function():
    with pytest.warns(DeprecationWarning):
        old_function()
```

## Mocking and Patching

### Mock External Services

```python
from unittest.mock import Mock, patch, MagicMock

def test_api_call():
    with patch('myapp.api.requests.get') as mock_get:
        # Setup mock
        mock_response = Mock()
        mock_response.json.return_value = {"data": "test"}
        mock_response.status_code = 200
        mock_get.return_value = mock_response

        # Test
        result = fetch_data()

        # Verify
        assert result == {"data": "test"}
        mock_get.assert_called_once_with("https://api.example.com/data")

@patch('myapp.database.query')
def test_user_lookup(mock_query):
    mock_query.return_value = {"id": 1, "name": "Alice"}
    user = get_user(1)
    assert user["name"] == "Alice"
```

### Mock Object Methods

```python
def test_save_user():
    user = User(name="Alice")
    user.save = Mock()  # Replace save method with mock

    user.save()
    user.save.assert_called_once()
```

## Code Coverage

### Minimum Requirements

- **Overall project:** 70% minimum
- **Critical paths:** 100% (authentication, payments, validation, security)
- **Utility functions:** 80-90%
- **Configuration/constants:** Can be lower

### Running Coverage

```bash
# Run tests with coverage
pytest --cov=myapp tests/

# Generate HTML report
pytest --cov=myapp --cov-report=html tests/

# Fail if below threshold
pytest --cov=myapp --cov-fail-under=70 tests/
```

### Coverage Configuration

Create `.coveragerc`:

```ini
[run]
source = myapp
omit =
    */tests/*
    */migrations/*
    */__init__.py

[report]
exclude_lines =
    pragma: no cover
    def __repr__
    raise AssertionError
    raise NotImplementedError
    if __name__ == .__main__.:
```

### Marking Code to Skip Coverage

```python
def debug_only_function():  # pragma: no cover
    """This function is only used for debugging."""
    print("Debug info")
```

## Test Organization

### Grouping with Classes

```python
class TestUserAuthentication:
    def test_login_success(self):
        pass

    def test_login_invalid_password(self):
        pass

    def test_logout(self):
        pass

class TestUserProfile:
    def test_update_profile(self):
        pass

    def test_delete_profile(self):
        pass
```

### Using Markers

```python
import pytest

@pytest.mark.slow
def test_large_data_processing():
    # Long-running test
    pass

@pytest.mark.integration
def test_api_integration():
    # Requires external service
    pass

# Run specific markers
# pytest -m "not slow"  # Skip slow tests
# pytest -m integration  # Only integration tests
```

### Skip and Xfail

```python
import pytest

@pytest.mark.skip(reason="Feature not implemented yet")
def test_future_feature():
    pass

@pytest.mark.skipif(sys.version_info < (3, 10), reason="Requires Python 3.10+")
def test_new_syntax():
    pass

@pytest.mark.xfail(reason="Known bug #123")
def test_known_bug():
    # Test that's expected to fail
    pass
```

## Testing Best Practices

### 1. One Assert Per Test (Guideline)

```python
# Good: focused test
def test_user_creation_sets_id():
    user = create_user({"name": "Alice"})
    assert user.id is not None

def test_user_creation_sets_name():
    user = create_user({"name": "Alice"})
    assert user.name == "Alice"

# Acceptable: related assertions
def test_user_creation():
    user = create_user({"name": "Alice", "email": "alice@example.com"})
    assert user.id is not None
    assert user.name == "Alice"
    assert user.email == "alice@example.com"
```

### 2. AAA Pattern (Arrange, Act, Assert)

```python
def test_payment_processing():
    # Arrange
    account = Account(balance=100)

    # Act
    result = account.withdraw(30)

    # Assert
    assert result is True
    assert account.balance == 70
```

### 3. Test Independence

Each test should be independent:

```python
# Bad: tests depend on order
def test_create_user():
    global user
    user = create_user({"name": "Alice"})

def test_update_user():
    user.name = "Bob"  # Depends on test_create_user!

# Good: each test is independent
@pytest.fixture
def user():
    return create_user({"name": "Alice"})

def test_create_user(user):
    assert user.name == "Alice"

def test_update_user(user):
    user.name = "Bob"
    assert user.name == "Bob"
```

### 4. Descriptive Assertions

```python
# Good: clear failure message
def test_user_age():
    user = User(age=25)
    assert user.age > 0, f"Age should be positive, got {user.age}"

# Good: pytest provides good default messages
def test_user_name():
    user = User(name="Alice")
    assert user.name == "Alice"  # Shows: "Alice" != "Bob" on failure
```

### 5. Test Data Builders

```python
def user_data(**kwargs):
    """Builder for test user data."""
    defaults = {
        "name": "Test User",
        "email": "test@example.com",
        "age": 30,
        "active": True,
    }
    return {**defaults, **kwargs}

def test_user_creation():
    # Easy to create variations
    user1 = create_user(user_data())
    user2 = create_user(user_data(name="Alice", age=25))
```

## Framework-Specific Testing

See framework-specific documentation:
- [Django Testing](frameworks/django.md#testing)
- [FastAPI Testing](frameworks/fastapi.md#testing)
- [Data Science Testing](frameworks/datascience.md#testing)

## References

- [Pytest Documentation](https://docs.pytest.org/)
- [Python unittest.mock](https://docs.python.org/3/library/unittest.mock.html)
- [Coverage.py](https://coverage.readthedocs.io/)
