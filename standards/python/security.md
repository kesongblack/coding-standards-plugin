# Python Security Standards

This document covers security best practices for Python applications following OWASP guidelines.

## Secrets Management

### Never Hardcode Secrets

```python
# Bad - NEVER DO THIS
API_KEY = "sk_live_1234567890abcdef"
DATABASE_URL = "postgresql://user:password@localhost/db"
SECRET_KEY = "my-secret-key-12345"

# Good - use environment variables
import os

API_KEY = os.environ.get("API_KEY")
DATABASE_URL = os.environ.get("DATABASE_URL")
SECRET_KEY = os.environ["SECRET_KEY"]  # Required, will fail if missing

# Good - use python-dotenv for development
from dotenv import load_dotenv
load_dotenv()

API_KEY = os.environ["API_KEY"]
```

### Environment Files (.env)

```bash
# .env file (NEVER commit to git!)
API_KEY=your_api_key_here
DATABASE_URL=postgresql://localhost/mydb
SECRET_KEY=your-secret-key
```

**Important:**
- Add `.env` to `.gitignore`
- Provide `.env.example` with dummy values
- Never log or print secrets

### Detecting Hardcoded Secrets

Common patterns to avoid:

```python
# Bad patterns
password = "admin123"
api_key = "1234567890abcdef"
token = "ghp_xxxxxxxxxxxx"
secret = "my-secret"
aws_secret_access_key = "xxxxx"
```

## SQL Injection Prevention

### Use Parameterized Queries

```python
# Bad - VULNERABLE to SQL injection
import sqlite3
user_input = request.args.get('username')
cursor.execute(f"SELECT * FROM users WHERE username = '{user_input}'")
cursor.execute("SELECT * FROM users WHERE id = " + user_id)

# Good - parameterized query (sqlite3)
cursor.execute("SELECT * FROM users WHERE username = ?", (user_input,))
cursor.execute("SELECT * FROM users WHERE id = ?", (user_id,))

# Good - parameterized query (psycopg2/PostgreSQL)
cursor.execute("SELECT * FROM users WHERE username = %s", (user_input,))

# Good - ORM usage (SQLAlchemy)
from sqlalchemy import select
stmt = select(User).where(User.username == user_input)
result = session.execute(stmt)
```

### Django ORM (Safe by Default)

```python
# Good - Django ORM prevents SQL injection
User.objects.filter(username=user_input)
User.objects.get(id=user_id)

# Good - even with raw queries
User.objects.raw("SELECT * FROM users WHERE username = %s", [user_input])

# Bad - only if you build raw SQL strings
query = f"SELECT * FROM users WHERE username = '{user_input}'"  # NEVER!
```

## Path Traversal Prevention

### Validate User Paths

```python
from pathlib import Path

# Bad - VULNERABLE to path traversal
user_file = request.args.get('file')
with open(f"/var/data/{user_file}") as f:  # User could pass "../../etc/passwd"
    content = f.read()

# Good - validate path is within allowed directory
UPLOAD_DIR = Path("/var/data")

def safe_open_file(filename: str):
    filepath = (UPLOAD_DIR / filename).resolve()

    # Check path is within allowed directory
    if not filepath.is_relative_to(UPLOAD_DIR):
        raise ValueError("Access denied")

    with open(filepath) as f:
        return f.read()

# Good - additional validation
def safe_filename(filename: str) -> str:
    """Remove path components and dangerous characters."""
    return Path(filename).name  # Only keep filename, remove any path
```

## Input Validation

### Validate All External Input

```python
from typing import Optional
import re

def validate_email(email: str) -> bool:
    """Validate email format."""
    pattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
    return re.match(pattern, email) is not None

def validate_age(age: str) -> int:
    """Validate and convert age."""
    try:
        age_int = int(age)
        if not 0 <= age_int <= 150:
            raise ValueError("Age must be between 0 and 150")
        return age_int
    except ValueError:
        raise ValueError("Invalid age format")

# Flask example
from flask import request, abort

@app.route('/user')
def get_user():
    user_id = request.args.get('id', type=int)
    if user_id is None or user_id < 1:
        abort(400, "Invalid user ID")

    # Validate allowed values
    sort_by = request.args.get('sort', 'name')
    if sort_by not in ['name', 'age', 'email']:
        abort(400, "Invalid sort field")
```

### Sanitize Output

```python
import html

# Prevent XSS when rendering user input
user_input = request.form['comment']
safe_output = html.escape(user_input)  # Escapes <, >, &, etc.

# Django templates auto-escape by default
# {{ user_input }}  -> automatically escaped

# Jinja2 templates also auto-escape
# {{ user_input }}  -> automatically escaped
```

## Command Injection Prevention

### Never Use shell=True with User Input

```python
import subprocess

# Bad - VULNERABLE to command injection
user_file = request.args.get('file')
subprocess.run(f"cat {user_file}", shell=True)  # User could pass "; rm -rf /"

# Good - use list of arguments, no shell
subprocess.run(["cat", user_file], shell=False)

# Good - validate input first
import shlex
safe_file = shlex.quote(user_file)
subprocess.run(["cat", safe_file], shell=False)
```

## XML/YAML Injection

### Unsafe Deserialization

```python
import yaml

# Bad - VULNERABLE to code execution
user_yaml = request.data
data = yaml.load(user_yaml)  # UNSAFE!

# Good - use safe loader
data = yaml.safe_load(user_yaml)

# Pickle - NEVER use with untrusted data
import pickle

# Bad - EXTREMELY DANGEROUS
user_data = request.data
obj = pickle.loads(user_data)  # Can execute arbitrary code!

# Good - use JSON instead
import json
data = json.loads(request.data)
```

## Cross-Site Scripting (XSS)

### Template Engines (Auto-Escaping)

Most modern frameworks auto-escape:

```python
# Django templates (auto-escape by default)
# template: <p>{{ user_comment }}</p>  # Safe

# To render HTML (be careful!)
# {{ html_content|safe }}  # Only for trusted content

# Jinja2 (auto-escape by default)
# {{ user_input }}  # Safe

# Manual escaping when needed
from markupsafe import escape
safe_html = escape(user_input)
```

## Authentication & Session Security

### Password Hashing

```python
# Good - use bcrypt, argon2, or PBKDF2
import bcrypt

def hash_password(password: str) -> bytes:
    salt = bcrypt.gensalt()
    return bcrypt.hashpw(password.encode(), salt)

def verify_password(password: str, hashed: bytes) -> bool:
    return bcrypt.checkpw(password.encode(), hashed)

# Bad - NEVER use MD5, SHA1, or plain SHA256 for passwords
import hashlib
hashed = hashlib.md5(password.encode()).hexdigest()  # INSECURE!
```

### Session Management

```python
# Flask - use secure session configuration
app.config.update(
    SESSION_COOKIE_SECURE=True,      # HTTPS only
    SESSION_COOKIE_HTTPONLY=True,    # No JavaScript access
    SESSION_COOKIE_SAMESITE='Lax',   # CSRF protection
)

# Django - secure settings
SESSION_COOKIE_SECURE = True
SESSION_COOKIE_HTTPONLY = True
SESSION_COOKIE_SAMESITE = 'Lax'
CSRF_COOKIE_SECURE = True
```

## Denial of Service (DoS) Prevention

### Resource Limits

```python
# Limit file upload size
from flask import Flask
app = Flask(__name__)
app.config['MAX_CONTENT_LENGTH'] = 16 * 1024 * 1024  # 16 MB max

# Limit request processing time
import signal

class TimeoutError(Exception):
    pass

def timeout_handler(signum, frame):
    raise TimeoutError("Request processing timeout")

signal.signal(signal.SIGALRM, timeout_handler)
signal.alarm(30)  # 30 second timeout

# Validate input size
def process_list(items: list):
    if len(items) > 1000:
        raise ValueError("Too many items")

# Use pagination for large results
def get_users(page: int = 1, page_size: int = 50):
    if page_size > 100:
        page_size = 100  # Cap maximum page size
```

## Regular Expression DoS (ReDoS)

### Avoid Catastrophic Backtracking

```python
import re

# Bad - VULNERABLE to ReDoS
pattern = r"(a+)+"  # Catastrophic backtracking
re.match(pattern, "a" * 50 + "!")  # Extremely slow!

# Good - no nested quantifiers
pattern = r"a+"

# Good - use possessive quantifiers or atomic groups (regex module)
import regex
pattern = regex.compile(r"(a++)++")  # Possessive, no backtracking
```

## Security Headers

### Flask Example

```python
from flask import Flask, make_response

@app.after_request
def add_security_headers(response):
    response.headers['X-Content-Type-Options'] = 'nosniff'
    response.headers['X-Frame-Options'] = 'DENY'
    response.headers['X-XSS-Protection'] = '1; mode=block'
    response.headers['Strict-Transport-Security'] = 'max-age=31536000; includeSubDomains'
    response.headers['Content-Security-Policy'] = "default-src 'self'"
    return response
```

## Logging Security

### Don't Log Sensitive Data

```python
import logging

# Bad - logs password
logging.info(f"User login: {username} with password {password}")

# Good - no sensitive data
logging.info(f"User login attempt: {username}")

# Good - sanitize before logging
def sanitize_for_log(data: dict) -> dict:
    sensitive_keys = ['password', 'token', 'api_key', 'secret']
    return {k: '***' if k in sensitive_keys else v for k, v in data.items()}

logging.info(f"Request data: {sanitize_for_log(request_data)}")
```

## Dependency Security

### Keep Dependencies Updated

```bash
# Check for vulnerabilities
pip install safety
safety check

# Update dependencies
pip list --outdated
pip install --upgrade package_name
```

### Pin Dependencies

```
# requirements.txt - pin versions
flask==2.3.0
requests==2.31.0

# Use pip-tools for management
pip install pip-tools
pip-compile requirements.in
```

## Framework-Specific Security

See framework-specific documentation:
- [Django Security](frameworks/django.md#security)
- [FastAPI Security](frameworks/fastapi.md#security)
- [Data Science Security](frameworks/datascience.md#security)

## Security Checklist

- [ ] No hardcoded secrets or credentials
- [ ] Use environment variables for configuration
- [ ] All database queries use parameterization
- [ ] User file paths are validated
- [ ] All external input is validated
- [ ] Output is escaped/sanitized
- [ ] Never use `shell=True` with subprocess
- [ ] Use `yaml.safe_load()`, never `yaml.load()`
- [ ] Never use `pickle.loads()` with untrusted data
- [ ] Passwords hashed with bcrypt/argon2
- [ ] Secure session configuration
- [ ] Security headers configured
- [ ] No sensitive data in logs
- [ ] Dependencies regularly updated
- [ ] Rate limiting on API endpoints

## References

- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [OWASP Python Security](https://cheatsheetseries.owasp.org/cheatsheets/Python_Security_Cheat_Sheet.html)
- [Bandit - Python Security Linter](https://bandit.readthedocs.io/)
