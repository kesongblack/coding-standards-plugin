# FastAPI Standards

This document covers FastAPI-specific coding standards and best practices.

## Router Organization

### Project Structure

```
app/
├── main.py              # FastAPI app instance
├── dependencies.py      # Shared dependencies
├── config.py            # Configuration
├── routers/             # API routes
│   ├── __init__.py
│   ├── users.py
│   ├── items.py
│   └── auth.py
├── schemas/             # Pydantic models
│   ├── __init__.py
│   ├── user.py
│   └── item.py
├── models/              # Database models
│   ├── __init__.py
│   └── user.py
├── services/            # Business logic
│   ├── __init__.py
│   └── auth.py
└── database.py          # Database connection
```

### Router Definition

```python
# routers/users.py
from fastapi import APIRouter, Depends, HTTPException, status
from ..schemas.user import UserCreate, UserResponse, UserUpdate
from ..dependencies import get_current_user, get_db

router = APIRouter(
    prefix="/users",
    tags=["users"],
    responses={404: {"description": "Not found"}},
)

@router.get("/", response_model=list[UserResponse])
async def list_users(
    skip: int = 0,
    limit: int = 100,
    db: Session = Depends(get_db)
):
    """List all users with pagination."""
    users = db.query(User).offset(skip).limit(limit).all()
    return users

@router.get("/{user_id}", response_model=UserResponse)
async def get_user(user_id: int, db: Session = Depends(get_db)):
    """Get user by ID."""
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    return user

@router.post("/", response_model=UserResponse, status_code=status.HTTP_201_CREATED)
async def create_user(
    user: UserCreate,
    db: Session = Depends(get_db)
):
    """Create new user."""
    db_user = User(**user.dict())
    db.add(db_user)
    db.commit()
    db.refresh(db_user)
    return db_user
```

### Main App

```python
# main.py
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from .routers import users, items, auth
from .config import settings

app = FastAPI(
    title="My API",
    description="API for managing users and items",
    version="1.0.0",
    docs_url="/docs",
    redoc_url="/redoc",
)

# CORS configuration
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.ALLOWED_ORIGINS,  # Don't use ["*"] in production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include routers
app.include_router(auth.router)
app.include_router(users.router)
app.include_router(items.router)

@app.get("/")
async def root():
    """Health check endpoint."""
    return {"status": "ok", "version": "1.0.0"}

@app.get("/health")
async def health_check():
    """Detailed health check."""
    return {
        "status": "healthy",
        "database": "connected",  # Add actual DB check
    }
```

## Pydantic Models

### Schema Definition

```python
# schemas/user.py
from pydantic import BaseModel, EmailStr, Field, validator
from typing import Optional
from datetime import datetime

class UserBase(BaseModel):
    """Shared user properties."""
    email: EmailStr
    username: str = Field(..., min_length=3, max_length=50)
    full_name: Optional[str] = None

class UserCreate(UserBase):
    """Properties required for user creation."""
    password: str = Field(..., min_length=8)

    @validator('password')
    def validate_password(cls, v):
        """Ensure password meets requirements."""
        if not any(char.isdigit() for char in v):
            raise ValueError('Password must contain at least one digit')
        if not any(char.isupper() for char in v):
            raise ValueError('Password must contain at least one uppercase letter')
        return v

class UserUpdate(BaseModel):
    """Properties that can be updated."""
    email: Optional[EmailStr] = None
    full_name: Optional[str] = None

class UserResponse(UserBase):
    """Properties returned to client."""
    id: int
    is_active: bool
    created_at: datetime

    class Config:
        orm_mode = True  # Allow ORM models to be converted

class UserInDB(UserBase):
    """Properties stored in database."""
    id: int
    hashed_password: str
    is_active: bool
    created_at: datetime

    class Config:
        orm_mode = True
```

### Advanced Validation

```python
from pydantic import BaseModel, validator, root_validator
from typing import Optional

class ItemCreate(BaseModel):
    name: str
    description: Optional[str] = None
    price: float = Field(..., gt=0, description="Price must be positive")
    tax: Optional[float] = Field(None, ge=0, le=1)

    @validator('name')
    def name_must_not_be_empty(cls, v):
        """Validate name is not just whitespace."""
        if not v or not v.strip():
            raise ValueError('Name cannot be empty')
        return v.strip()

    @root_validator
    def check_price_with_tax(cls, values):
        """Validate price and tax combination."""
        price = values.get('price')
        tax = values.get('tax')
        if price and tax and (price * (1 + tax)) > 1000:
            raise ValueError('Total price with tax cannot exceed 1000')
        return values
```

## Dependency Injection

### Common Dependencies

```python
# dependencies.py
from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from sqlalchemy.orm import Session
from jose import JWTError, jwt
from .database import SessionLocal
from .config import settings

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="token")

def get_db():
    """Database session dependency."""
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

async def get_current_user(
    token: str = Depends(oauth2_scheme),
    db: Session = Depends(get_db)
) -> User:
    """Get current authenticated user."""
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    try:
        payload = jwt.decode(token, settings.SECRET_KEY, algorithms=["HS256"])
        username: str = payload.get("sub")
        if username is None:
            raise credentials_exception
    except JWTError:
        raise credentials_exception

    user = db.query(User).filter(User.username == username).first()
    if user is None:
        raise credentials_exception
    return user

async def get_current_active_user(
    current_user: User = Depends(get_current_user)
) -> User:
    """Ensure user is active."""
    if not current_user.is_active:
        raise HTTPException(status_code=400, detail="Inactive user")
    return current_user

def require_admin(
    current_user: User = Depends(get_current_active_user)
) -> User:
    """Require admin privileges."""
    if not current_user.is_admin:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Admin privileges required"
        )
    return current_user
```

### Using Dependencies

```python
# routers/items.py
from fastapi import APIRouter, Depends
from ..dependencies import get_current_active_user, require_admin, get_db

router = APIRouter(prefix="/items", tags=["items"])

@router.get("/")
async def list_items(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """List items - requires authentication."""
    items = db.query(Item).filter(Item.owner_id == current_user.id).all()
    return items

@router.delete("/{item_id}")
async def delete_item(
    item_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_admin)  # Admin only
):
    """Delete item - requires admin."""
    item = db.query(Item).filter(Item.id == item_id).first()
    if not item:
        raise HTTPException(status_code=404, detail="Item not found")
    db.delete(item)
    db.commit()
    return {"message": "Item deleted"}
```

## Async Operations

### Async Database Operations

```python
from sqlalchemy.ext.asyncio import AsyncSession, create_async_engine
from sqlalchemy.orm import sessionmaker

# Async database setup
engine = create_async_engine("postgresql+asyncpg://user:pass@localhost/db")
AsyncSessionLocal = sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)

async def get_async_db():
    """Async database session."""
    async with AsyncSessionLocal() as session:
        yield session

# Async route
@router.get("/users/{user_id}")
async def get_user_async(
    user_id: int,
    db: AsyncSession = Depends(get_async_db)
):
    """Get user asynchronously."""
    result = await db.execute(
        select(User).where(User.id == user_id)
    )
    user = result.scalar_one_or_none()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    return user
```

### Async External API Calls

```python
import httpx
from fastapi import HTTPException

async def fetch_external_data(url: str) -> dict:
    """Fetch data from external API asynchronously."""
    async with httpx.AsyncClient() as client:
        try:
            response = await client.get(url, timeout=10.0)
            response.raise_for_status()
            return response.json()
        except httpx.HTTPError as e:
            raise HTTPException(
                status_code=503,
                detail=f"External service unavailable: {str(e)}"
            )

@router.get("/external-data")
async def get_external_data():
    """Endpoint that fetches external data."""
    data = await fetch_external_data("https://api.example.com/data")
    return data
```

### Background Tasks

```python
from fastapi import BackgroundTasks
import logging

logger = logging.getLogger(__name__)

def send_email_notification(email: str, message: str):
    """Background task to send email."""
    logger.info(f"Sending email to {email}")
    # Email sending logic here
    time.sleep(5)  # Simulate slow operation
    logger.info(f"Email sent to {email}")

@router.post("/users/")
async def create_user(
    user: UserCreate,
    background_tasks: BackgroundTasks,
    db: Session = Depends(get_db)
):
    """Create user and send welcome email in background."""
    db_user = User(**user.dict())
    db.add(db_user)
    db.commit()

    # Add background task
    background_tasks.add_task(
        send_email_notification,
        user.email,
        "Welcome to our platform!"
    )

    return db_user
```

## Error Handling

### Custom Exception Handlers

```python
# main.py
from fastapi import FastAPI, Request, status
from fastapi.responses import JSONResponse
from fastapi.exceptions import RequestValidationError

app = FastAPI()

class BusinessLogicError(Exception):
    """Custom business logic exception."""
    def __init__(self, message: str):
        self.message = message

@app.exception_handler(BusinessLogicError)
async def business_logic_exception_handler(request: Request, exc: BusinessLogicError):
    """Handle business logic errors."""
    return JSONResponse(
        status_code=status.HTTP_400_BAD_REQUEST,
        content={"detail": exc.message}
    )

@app.exception_handler(RequestValidationError)
async def validation_exception_handler(request: Request, exc: RequestValidationError):
    """Customize validation error response."""
    return JSONResponse(
        status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
        content={"detail": exc.errors(), "body": exc.body}
    )
```

### Raising Exceptions

```python
from fastapi import HTTPException, status

@router.post("/items/")
async def create_item(item: ItemCreate, db: Session = Depends(get_db)):
    """Create item with validation."""
    # Check if item already exists
    existing = db.query(Item).filter(Item.name == item.name).first()
    if existing:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Item with this name already exists"
        )

    # Business logic validation
    if item.price > 10000:
        raise BusinessLogicError("Item price cannot exceed 10000")

    db_item = Item(**item.dict())
    db.add(db_item)
    db.commit()
    return db_item
```

## Testing

### Test Structure

```python
# tests/test_users.py
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from ..main import app
from ..dependencies import get_db
from ..database import Base

# Test database setup
SQLALCHEMY_DATABASE_URL = "sqlite:///./test.db"
engine = create_engine(SQLALCHEMY_DATABASE_URL, connect_args={"check_same_thread": False})
TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

Base.metadata.create_all(bind=engine)

def override_get_db():
    """Override database dependency for tests."""
    try:
        db = TestingSessionLocal()
        yield db
    finally:
        db.close()

app.dependency_overrides[get_db] = override_get_db

client = TestClient(app)

def test_create_user():
    """Test user creation."""
    response = client.post(
        "/users/",
        json={
            "email": "test@example.com",
            "username": "testuser",
            "password": "TestPass123"
        }
    )
    assert response.status_code == 201
    data = response.json()
    assert data["email"] == "test@example.com"
    assert "id" in data

def test_read_user():
    """Test reading user."""
    response = client.get("/users/1")
    assert response.status_code == 200
    data = response.json()
    assert data["id"] == 1

def test_read_user_not_found():
    """Test user not found."""
    response = client.get("/users/999")
    assert response.status_code == 404
```

### Testing with Authentication

```python
def get_auth_token() -> str:
    """Get authentication token for tests."""
    response = client.post(
        "/token",
        data={"username": "testuser", "password": "testpass"}
    )
    return response.json()["access_token"]

def test_protected_route():
    """Test route requiring authentication."""
    token = get_auth_token()
    response = client.get(
        "/users/me",
        headers={"Authorization": f"Bearer {token}"}
    )
    assert response.status_code == 200
```

### Async Tests

```python
import pytest
from httpx import AsyncClient
from ..main import app

@pytest.mark.asyncio
async def test_async_endpoint():
    """Test async endpoint."""
    async with AsyncClient(app=app, base_url="http://test") as ac:
        response = await ac.get("/users/")
    assert response.status_code == 200
```

## Security

### CORS Configuration

```python
from fastapi.middleware.cors import CORSMiddleware

# Bad - allows all origins
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # DON'T DO THIS IN PRODUCTION
)

# Good - specific origins
app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "https://yourdomain.com",
        "https://app.yourdomain.com",
    ],
    allow_credentials=True,
    allow_methods=["GET", "POST", "PUT", "DELETE"],
    allow_headers=["*"],
)
```

### OAuth2 with JWT

```python
from datetime import datetime, timedelta
from jose import jwt
from passlib.context import CryptContext

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

def verify_password(plain_password: str, hashed_password: str) -> bool:
    """Verify password against hash."""
    return pwd_context.verify(plain_password, hashed_password)

def get_password_hash(password: str) -> str:
    """Hash password."""
    return pwd_context.hash(password)

def create_access_token(data: dict, expires_delta: timedelta = None) -> str:
    """Create JWT access token."""
    to_encode = data.copy()
    expire = datetime.utcnow() + (expires_delta or timedelta(minutes=15))
    to_encode.update({"exp": expire})
    return jwt.encode(to_encode, settings.SECRET_KEY, algorithm="HS256")

@router.post("/token")
async def login(form_data: OAuth2PasswordRequestForm = Depends(), db: Session = Depends(get_db)):
    """Login endpoint."""
    user = db.query(User).filter(User.username == form_data.username).first()
    if not user or not verify_password(form_data.password, user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect username or password",
            headers={"WWW-Authenticate": "Bearer"},
        )
    access_token = create_access_token(data={"sub": user.username})
    return {"access_token": access_token, "token_type": "bearer"}
```

### Rate Limiting

```python
from slowapi import Limiter, _rate_limit_exceeded_handler
from slowapi.util import get_remote_address
from slowapi.errors import RateLimitExceeded

limiter = Limiter(key_func=get_remote_address)
app.state.limiter = limiter
app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)

@router.get("/limited")
@limiter.limit("5/minute")
async def limited_route(request: Request):
    """Route with rate limiting."""
    return {"message": "This route is rate limited"}
```

## Production Configuration

```python
# config.py
from pydantic import BaseSettings

class Settings(BaseSettings):
    """Application settings."""
    app_name: str = "My API"
    debug: bool = False
    database_url: str
    secret_key: str
    allowed_origins: list[str] = []

    class Config:
        env_file = ".env"

settings = Settings()

# main.py
app = FastAPI(
    title=settings.app_name,
    debug=settings.debug,
    docs_url="/docs" if settings.debug else None,  # Disable docs in production
    redoc_url="/redoc" if settings.debug else None,
)
```

## References

- [FastAPI Documentation](https://fastapi.tiangolo.com/)
- [Pydantic Documentation](https://docs.pydantic.dev/)
- [SQLAlchemy Async](https://docs.sqlalchemy.org/en/14/orm/extensions/asyncio.html)
