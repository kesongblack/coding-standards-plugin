# Next.js Testing Standards

## Test Directory Structure

Organize tests alongside source files or in dedicated directories.

**Colocated (Recommended):**
```
src/
├── components/
│   ├── Button.tsx
│   ├── Button.test.tsx           # Unit test next to component
│   ├── UserCard.tsx
│   └── UserCard.test.tsx
├── hooks/
│   ├── useAuth.ts
│   └── useAuth.test.ts
├── lib/
│   ├── utils.ts
│   └── utils.test.ts
└── app/
    └── api/
        └── users/
            ├── route.ts
            └── route.test.ts
e2e/                              # E2E tests separate
├── auth.spec.ts
└── checkout.spec.ts
```

**Separate Directory (Alternative):**
```
__tests__/
├── components/
│   ├── Button.test.tsx
│   └── UserCard.test.tsx
├── hooks/
│   └── useAuth.test.ts
└── api/
    └── users.test.ts
e2e/
└── auth.spec.ts
```

### Why?
- Easy to find tests
- Tests move with code
- Clear test scope

---

## Jest Configuration

Configure Jest for Next.js with proper transforms.

**Good (`jest.config.js`):**
```javascript
const nextJest = require('next/jest');

const createJestConfig = nextJest({
  dir: './',
});

const customJestConfig = {
  setupFilesAfterEnv: ['<rootDir>/jest.setup.js'],
  testEnvironment: 'jest-environment-jsdom',
  moduleNameMapper: {
    '^@/(.*)$': '<rootDir>/src/$1',
  },
  collectCoverageFrom: [
    'src/**/*.{js,jsx,ts,tsx}',
    '!src/**/*.d.ts',
    '!src/**/index.ts',
  ],
};

module.exports = createJestConfig(customJestConfig);
```

**Setup file (`jest.setup.js`):**
```javascript
import '@testing-library/jest-dom';
```

### Why?
- Next.js SWC transforms
- Path alias support
- Proper DOM environment

---

## Component Testing with React Testing Library

Test components by user behavior, not implementation.

**Good:**
```tsx
import { render, screen, fireEvent } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { Button } from './Button';

describe('Button', () => {
  it('renders with correct text', () => {
    render(<Button>Click me</Button>);

    expect(screen.getByRole('button', { name: /click me/i })).toBeInTheDocument();
  });

  it('calls onClick when clicked', async () => {
    const handleClick = jest.fn();
    const user = userEvent.setup();

    render(<Button onClick={handleClick}>Submit</Button>);

    await user.click(screen.getByRole('button'));

    expect(handleClick).toHaveBeenCalledTimes(1);
  });

  it('is disabled when loading', () => {
    render(<Button loading>Submit</Button>);

    expect(screen.getByRole('button')).toBeDisabled();
  });
});
```

**Bad:**
```tsx
describe('Button', () => {
  it('renders', () => {
    const { container } = render(<Button>Click</Button>);

    // Bad: Testing implementation details
    expect(container.querySelector('.btn-class')).toBeTruthy();
    expect(container.firstChild).toHaveStyle({ color: 'blue' });
  });
});
```

### Why?
- Tests user experience
- Resilient to refactoring
- Accessible queries

---

## Testing Async Components

Handle async operations properly.

**Good:**
```tsx
import { render, screen, waitFor } from '@testing-library/react';
import { UserProfile } from './UserProfile';

// Mock fetch
global.fetch = jest.fn();

describe('UserProfile', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  it('displays user data after loading', async () => {
    (fetch as jest.Mock).mockResolvedValueOnce({
      ok: true,
      json: async () => ({ name: 'John Doe', email: 'john@example.com' }),
    });

    render(<UserProfile userId="1" />);

    // Check loading state
    expect(screen.getByText(/loading/i)).toBeInTheDocument();

    // Wait for data
    await waitFor(() => {
      expect(screen.getByText('John Doe')).toBeInTheDocument();
    });

    expect(screen.queryByText(/loading/i)).not.toBeInTheDocument();
  });

  it('displays error on fetch failure', async () => {
    (fetch as jest.Mock).mockRejectedValueOnce(new Error('Network error'));

    render(<UserProfile userId="1" />);

    await waitFor(() => {
      expect(screen.getByText(/error/i)).toBeInTheDocument();
    });
  });
});
```

### Why?
- Tests async behavior
- Covers loading states
- Handles errors

---

## Testing Custom Hooks

Use renderHook for testing hooks in isolation.

**Good:**
```tsx
import { renderHook, act } from '@testing-library/react';
import { useCounter } from './useCounter';

describe('useCounter', () => {
  it('initializes with default value', () => {
    const { result } = renderHook(() => useCounter());

    expect(result.current.count).toBe(0);
  });

  it('initializes with provided value', () => {
    const { result } = renderHook(() => useCounter(10));

    expect(result.current.count).toBe(10);
  });

  it('increments count', () => {
    const { result } = renderHook(() => useCounter());

    act(() => {
      result.current.increment();
    });

    expect(result.current.count).toBe(1);
  });

  it('decrements count', () => {
    const { result } = renderHook(() => useCounter(5));

    act(() => {
      result.current.decrement();
    });

    expect(result.current.count).toBe(4);
  });
});
```

### Why?
- Isolated hook testing
- Tests state updates
- No component wrapper needed

---

## Testing with Context Providers

Wrap components that need context.

**Good:**
```tsx
import { render, screen } from '@testing-library/react';
import { AuthProvider } from '@/contexts/AuthContext';
import { UserMenu } from './UserMenu';

const renderWithAuth = (ui: React.ReactElement, { user = null } = {}) => {
  return render(
    <AuthProvider initialUser={user}>
      {ui}
    </AuthProvider>
  );
};

describe('UserMenu', () => {
  it('shows login button when not authenticated', () => {
    renderWithAuth(<UserMenu />);

    expect(screen.getByRole('button', { name: /login/i })).toBeInTheDocument();
  });

  it('shows user name when authenticated', () => {
    renderWithAuth(<UserMenu />, {
      user: { id: '1', name: 'John Doe' },
    });

    expect(screen.getByText('John Doe')).toBeInTheDocument();
  });
});
```

**Create reusable wrapper:**
```tsx
// test-utils.tsx
import { render, RenderOptions } from '@testing-library/react';
import { AuthProvider } from '@/contexts/AuthContext';
import { ThemeProvider } from '@/contexts/ThemeContext';

const AllProviders = ({ children }: { children: React.ReactNode }) => {
  return (
    <ThemeProvider>
      <AuthProvider>
        {children}
      </AuthProvider>
    </ThemeProvider>
  );
};

const customRender = (ui: React.ReactElement, options?: RenderOptions) =>
  render(ui, { wrapper: AllProviders, ...options });

export * from '@testing-library/react';
export { customRender as render };
```

### Why?
- Provides required context
- Reusable test setup
- Cleaner test code

---

## API Route Testing

Test Next.js API routes directly.

**Good:**
```tsx
import { createMocks } from 'node-mocks-http';
import { GET, POST } from '@/app/api/users/route';

describe('/api/users', () => {
  describe('GET', () => {
    it('returns list of users', async () => {
      const { req } = createMocks({
        method: 'GET',
      });

      const response = await GET(req);
      const data = await response.json();

      expect(response.status).toBe(200);
      expect(Array.isArray(data)).toBe(true);
    });
  });

  describe('POST', () => {
    it('creates a new user', async () => {
      const { req } = createMocks({
        method: 'POST',
        body: {
          name: 'John Doe',
          email: 'john@example.com',
        },
      });

      const response = await POST(req);
      const data = await response.json();

      expect(response.status).toBe(201);
      expect(data.name).toBe('John Doe');
    });

    it('returns 400 for invalid data', async () => {
      const { req } = createMocks({
        method: 'POST',
        body: {},
      });

      const response = await POST(req);

      expect(response.status).toBe(400);
    });
  });
});
```

### Why?
- Tests API logic
- Validates responses
- Catches errors

---

## Mocking External Services

Mock external APIs and services.

**Good:**
```tsx
// __mocks__/stripe.ts
export const Stripe = jest.fn().mockImplementation(() => ({
  customers: {
    create: jest.fn().mockResolvedValue({ id: 'cus_123' }),
    retrieve: jest.fn().mockResolvedValue({ id: 'cus_123', email: 'test@example.com' }),
  },
  paymentIntents: {
    create: jest.fn().mockResolvedValue({ id: 'pi_123', status: 'succeeded' }),
  },
}));

// In test
jest.mock('stripe');

import { PaymentService } from './PaymentService';

describe('PaymentService', () => {
  it('creates payment intent', async () => {
    const service = new PaymentService();
    const result = await service.createPayment(1000);

    expect(result.status).toBe('succeeded');
  });
});
```

**Mock fetch globally:**
```tsx
// jest.setup.js
global.fetch = jest.fn();

// In test
beforeEach(() => {
  (fetch as jest.Mock).mockClear();
});

it('fetches data', async () => {
  (fetch as jest.Mock).mockResolvedValueOnce({
    ok: true,
    json: async () => ({ data: 'test' }),
  });

  // Test code...
});
```

### Why?
- Isolates tests
- Predictable results
- No external dependencies

---

## E2E Testing with Playwright

End-to-end testing for critical flows.

**Good (`playwright.config.ts`):**
```typescript
import { defineConfig, devices } from '@playwright/test';

export default defineConfig({
  testDir: './e2e',
  fullyParallel: true,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 0,
  workers: process.env.CI ? 1 : undefined,
  reporter: 'html',
  use: {
    baseURL: 'http://localhost:3000',
    trace: 'on-first-retry',
  },
  projects: [
    { name: 'chromium', use: { ...devices['Desktop Chrome'] } },
    { name: 'firefox', use: { ...devices['Desktop Firefox'] } },
  ],
  webServer: {
    command: 'npm run dev',
    url: 'http://localhost:3000',
    reuseExistingServer: !process.env.CI,
  },
});
```

**E2E test (`e2e/auth.spec.ts`):**
```typescript
import { test, expect } from '@playwright/test';

test.describe('Authentication', () => {
  test('user can login', async ({ page }) => {
    await page.goto('/login');

    await page.fill('[name="email"]', 'user@example.com');
    await page.fill('[name="password"]', 'password123');
    await page.click('button[type="submit"]');

    await expect(page).toHaveURL('/dashboard');
    await expect(page.locator('h1')).toContainText('Dashboard');
  });

  test('shows error for invalid credentials', async ({ page }) => {
    await page.goto('/login');

    await page.fill('[name="email"]', 'invalid@example.com');
    await page.fill('[name="password"]', 'wrongpassword');
    await page.click('button[type="submit"]');

    await expect(page.locator('.error-message')).toBeVisible();
  });
});
```

### Why?
- Tests real user flows
- Cross-browser testing
- Catches integration issues

---

## Testing Server Components

Test React Server Components appropriately.

**Good:**
```tsx
// For server components, test the rendered output
import { render } from '@testing-library/react';
import { UserList } from './UserList';

// Mock the data fetching
jest.mock('@/lib/db', () => ({
  getUsers: jest.fn().mockResolvedValue([
    { id: '1', name: 'John' },
    { id: '2', name: 'Jane' },
  ]),
}));

describe('UserList', () => {
  it('renders list of users', async () => {
    const component = await UserList();
    const { getByText } = render(component);

    expect(getByText('John')).toBeInTheDocument();
    expect(getByText('Jane')).toBeInTheDocument();
  });
});
```

### Why?
- Tests async server components
- Mocks data layer
- Validates output

---

## Snapshot Testing

Use snapshots sparingly for UI consistency.

**Good:**
```tsx
import { render } from '@testing-library/react';
import { Button } from './Button';

describe('Button snapshots', () => {
  it('matches primary variant', () => {
    const { container } = render(<Button variant="primary">Click</Button>);
    expect(container).toMatchSnapshot();
  });

  it('matches disabled state', () => {
    const { container } = render(<Button disabled>Click</Button>);
    expect(container).toMatchSnapshot();
  });
});
```

**Bad:**
```tsx
// Don't snapshot entire pages
it('matches page', () => {
  const { container } = render(<EntirePage />);
  expect(container).toMatchSnapshot();  // Too fragile
});
```

### Why?
- Catches UI regressions
- Use for stable components
- Avoid for dynamic content

---

## Test Coverage Targets

| Category | Minimum Coverage |
|----------|-----------------|
| Components | 80% |
| Hooks | 90% |
| Utilities | 95% |
| API Routes | 85% |
| Critical paths | 100% |

---

## Anti-Patterns

### Don't Test Implementation Details
```tsx
// Bad
it('updates internal state', () => {
  const { result } = renderHook(() => useCounter());
  // Accessing internal implementation
  expect(result.current._internalState).toBe(0);
});

// Good - test behavior
it('shows updated count', () => {
  render(<Counter />);
  fireEvent.click(screen.getByRole('button'));
  expect(screen.getByText('1')).toBeInTheDocument();
});
```

### Don't Use Test IDs When Accessible Queries Work
```tsx
// Bad
<button data-testid="submit-btn">Submit</button>
screen.getByTestId('submit-btn');

// Good
<button>Submit</button>
screen.getByRole('button', { name: /submit/i });
```

### Don't Forget to Clean Up
```tsx
// Bad - leaks between tests
let mockFn;
beforeEach(() => {
  mockFn = jest.fn();
});

// Good
beforeEach(() => {
  jest.clearAllMocks();
});

afterEach(() => {
  cleanup();
});
```
