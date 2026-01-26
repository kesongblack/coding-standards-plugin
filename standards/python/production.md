# Python Production Readiness

This document covers best practices for preparing Python applications for production deployment.

## Logging

### Use logging Module, Not print()

```python
import logging

# Bad - print statements
def process_data(data):
    print(f"Processing {len(data)} items")  # Hard to control, filter, or redirect
    print("Done!")

# Good - structured logging
logger = logging.getLogger(__name__)

def process_data(data):
    logger.info("Processing %d items", len(data))
    logger.debug("Data details: %s", data)
    logger.info("Processing completed")
```

### Logging Configuration

```python
import logging
import logging.config

# Basic configuration
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('app.log'),
        logging.StreamHandler()  # Also log to console
    ]
)

# Advanced configuration
LOGGING_CONFIG = {
    'version': 1,
    'disable_existing_loggers': False,
    'formatters': {
        'standard': {
            'format': '%(asctime)s [%(levelname)s] %(name)s: %(message)s'
        },
        'json': {
            'class': 'pythonjsonlogger.jsonlogger.JsonFormatter',
            'format': '%(asctime)s %(name)s %(levelname)s %(message)s'
        }
    },
    'handlers': {
        'console': {
            'class': 'logging.StreamHandler',
            'formatter': 'standard',
            'level': 'INFO',
        },
        'file': {
            'class': 'logging.handlers.RotatingFileHandler',
            'filename': 'app.log',
            'maxBytes': 10485760,  # 10MB
            'backupCount': 5,
            'formatter': 'json',
            'level': 'DEBUG',
        },
    },
    'root': {
        'level': 'DEBUG',
        'handlers': ['console', 'file'],
    },
    'loggers': {
        'myapp': {
            'level': 'DEBUG',
            'handlers': ['console', 'file'],
            'propagate': False,
        },
    },
}

logging.config.dictConfig(LOGGING_CONFIG)
```

### Logging Levels

```python
import logging

logger = logging.getLogger(__name__)

# DEBUG - detailed diagnostic info
logger.debug("User session data: %s", session_data)

# INFO - general informational messages
logger.info("User %s logged in successfully", username)

# WARNING - something unexpected but not an error
logger.warning("API rate limit approaching: %d/%d requests", current, limit)

# ERROR - error occurred but application continues
logger.error("Failed to process payment for order %s", order_id, exc_info=True)

# CRITICAL - serious error, application may not continue
logger.critical("Database connection lost", exc_info=True)
```

### Structured Logging

```python
import logging
import json

# Add context to logs
logger.info("User action", extra={
    'user_id': user.id,
    'action': 'purchase',
    'amount': 99.99,
    'order_id': order.id,
})

# Use JSON for machine-readable logs
class JsonFormatter(logging.Formatter):
    def format(self, record):
        log_data = {
            'timestamp': self.formatTime(record),
            'level': record.levelname,
            'logger': record.name,
            'message': record.getMessage(),
        }
        if hasattr(record, 'user_id'):
            log_data['user_id'] = record.user_id
        return json.dumps(log_data)
```

## Environment Configuration

### Use Environment Variables

```python
import os
from typing import Optional

# Bad - hardcoded values
DEBUG = True
DATABASE_URL = "postgresql://localhost/mydb"
SECRET_KEY = "my-secret-key"

# Good - environment variables
DEBUG = os.environ.get('DEBUG', 'False').lower() == 'true'
DATABASE_URL = os.environ['DATABASE_URL']  # Required
SECRET_KEY = os.environ['SECRET_KEY']  # Required
API_KEY = os.environ.get('API_KEY')  # Optional

# Better - with type conversion and validation
def get_env_bool(key: str, default: bool = False) -> bool:
    value = os.environ.get(key, str(default))
    return value.lower() in ('true', '1', 'yes')

def get_env_int(key: str, default: Optional[int] = None) -> int:
    value = os.environ.get(key)
    if value is None:
        if default is not None:
            return default
        raise ValueError(f"Required environment variable {key} not set")
    return int(value)

DEBUG = get_env_bool('DEBUG', False)
MAX_WORKERS = get_env_int('MAX_WORKERS', 4)
```

### Environment File Management

```bash
# .env (development only - NOT in git!)
DEBUG=true
DATABASE_URL=postgresql://localhost/mydb_dev
SECRET_KEY=dev-secret-key-not-for-production
LOG_LEVEL=DEBUG

# .env.example (committed to git)
DEBUG=false
DATABASE_URL=postgresql://user:password@host:5432/dbname
SECRET_KEY=your-secret-key-here
LOG_LEVEL=INFO
```

```python
# Load .env in development
from dotenv import load_dotenv
import os

if os.environ.get('ENVIRONMENT') == 'development':
    load_dotenv()
```

## Error Handling

### Graceful Error Handling

```python
import logging

logger = logging.getLogger(__name__)

# Bad - unhandled exceptions
def process_payment(order):
    payment = stripe.charge(order.amount)
    return payment  # Crashes if API fails

# Good - handle expected errors
def process_payment(order):
    try:
        payment = stripe.charge(order.amount)
        return payment
    except stripe.CardError as e:
        logger.warning("Card declined for order %s: %s", order.id, e)
        raise PaymentDeclinedError(str(e))
    except stripe.APIConnectionError as e:
        logger.error("Payment gateway connection failed: %s", e)
        raise PaymentGatewayError("Unable to process payment")
    except Exception as e:
        logger.exception("Unexpected error processing payment for order %s", order.id)
        raise
```

### Custom Exceptions

```python
# Good - domain-specific exceptions
class AppError(Exception):
    """Base exception for application errors."""
    pass

class ValidationError(AppError):
    """Input validation failed."""
    pass

class NotFoundError(AppError):
    """Resource not found."""
    pass

class PaymentError(AppError):
    """Payment processing error."""
    pass

# Usage
def get_user(user_id: int):
    user = db.query(User).get(user_id)
    if not user:
        raise NotFoundError(f"User {user_id} not found")
    return user
```

### Retry Logic for External Services

```python
import time
from typing import Callable, TypeVar

T = TypeVar('T')

def retry(max_attempts: int = 3, delay: float = 1.0):
    """Retry decorator for flaky operations."""
    def decorator(func: Callable[..., T]) -> Callable[..., T]:
        def wrapper(*args, **kwargs) -> T:
            last_exception = None
            for attempt in range(max_attempts):
                try:
                    return func(*args, **kwargs)
                except Exception as e:
                    last_exception = e
                    if attempt < max_attempts - 1:
                        logger.warning(
                            "Attempt %d/%d failed: %s. Retrying in %s seconds...",
                            attempt + 1, max_attempts, e, delay
                        )
                        time.sleep(delay)
            logger.error("All %d attempts failed", max_attempts)
            raise last_exception
        return wrapper
    return decorator

@retry(max_attempts=3, delay=2.0)
def fetch_external_api():
    response = requests.get('https://api.example.com/data')
    response.raise_for_status()
    return response.json()
```

## Health Checks

### Application Health Endpoint

```python
from flask import Flask, jsonify

@app.route('/health')
def health_check():
    """Basic health check endpoint."""
    return jsonify({'status': 'healthy'}), 200

@app.route('/health/detailed')
def detailed_health_check():
    """Detailed health check with dependencies."""
    health_status = {
        'status': 'healthy',
        'checks': {}
    }

    # Check database
    try:
        db.session.execute('SELECT 1')
        health_status['checks']['database'] = 'up'
    except Exception as e:
        health_status['checks']['database'] = f'down: {e}'
        health_status['status'] = 'unhealthy'

    # Check Redis
    try:
        redis_client.ping()
        health_status['checks']['redis'] = 'up'
    except Exception as e:
        health_status['checks']['redis'] = f'down: {e}'
        health_status['status'] = 'unhealthy'

    # Check external API
    try:
        response = requests.get('https://api.example.com/health', timeout=5)
        health_status['checks']['external_api'] = 'up' if response.ok else 'down'
    except Exception as e:
        health_status['checks']['external_api'] = f'down: {e}'

    status_code = 200 if health_status['status'] == 'healthy' else 503
    return jsonify(health_status), status_code
```

## Performance Monitoring

### Basic Metrics

```python
import time
import functools
from typing import Callable

def timer(func: Callable) -> Callable:
    """Measure function execution time."""
    @functools.wraps(func)
    def wrapper(*args, **kwargs):
        start_time = time.time()
        result = func(*args, **kwargs)
        duration = time.time() - start_time
        logger.info("%s executed in %.2f seconds", func.__name__, duration)
        return result
    return wrapper

@timer
def slow_operation():
    # ... expensive operation ...
    pass
```

### Request Tracking

```python
import uuid
from flask import request, g

@app.before_request
def before_request():
    """Add request ID for tracking."""
    g.request_id = request.headers.get('X-Request-ID', str(uuid.uuid4()))
    g.start_time = time.time()
    logger.info("Request started: %s %s", request.method, request.path, extra={
        'request_id': g.request_id,
    })

@app.after_request
def after_request(response):
    """Log request completion."""
    duration = time.time() - g.start_time
    logger.info("Request completed: %s %s - %d", request.method, request.path, response.status_code, extra={
        'request_id': g.request_id,
        'duration': duration,
        'status_code': response.status_code,
    })
    response.headers['X-Request-ID'] = g.request_id
    return response
```

## Deployment Checklist

### Security

- [ ] `DEBUG = False` in production
- [ ] Secrets loaded from environment variables
- [ ] HTTPS/TLS configured
- [ ] Security headers configured
- [ ] CORS properly configured
- [ ] Rate limiting enabled
- [ ] Input validation on all endpoints

### Configuration

- [ ] Environment-specific settings
- [ ] Database connection pooling configured
- [ ] Cache configured (Redis/Memcached)
- [ ] File storage configured (S3/cloud storage)
- [ ] Email service configured

### Logging

- [ ] All `print()` statements removed
- [ ] Logging configured with appropriate levels
- [ ] Log aggregation configured (CloudWatch/Datadog/etc.)
- [ ] No sensitive data in logs

### Monitoring

- [ ] Health check endpoints implemented
- [ ] Error tracking configured (Sentry/Rollbar)
- [ ] Performance monitoring (New Relic/Datadog)
- [ ] Uptime monitoring configured

### Performance

- [ ] Database queries optimized
- [ ] Proper indexing on database
- [ ] Caching implemented where appropriate
- [ ] Static files served via CDN
- [ ] Gzip compression enabled

### Dependencies

- [ ] All dependencies pinned to specific versions
- [ ] No development dependencies in production
- [ ] Security vulnerabilities checked (`safety check`)
- [ ] License compliance verified

### Testing

- [ ] All tests passing
- [ ] Integration tests run against production-like environment
- [ ] Load testing performed
- [ ] Rollback plan documented

## Framework-Specific Production Guides

See framework documentation:
- [Django Production](frameworks/django.md#production)
- [FastAPI Production](frameworks/fastapi.md#production)

## References

- [Python Logging HOWTO](https://docs.python.org/3/howto/logging.html)
- [12-Factor App](https://12factor.net/)
- [OWASP Production Security Checklist](https://owasp.org/www-project-web-security-testing-guide/)
