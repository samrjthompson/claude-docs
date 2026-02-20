# React / TypeScript Technical Standards

This layer defines conventions and patterns for React applications built with TypeScript, Vite, and Tailwind CSS. It builds on the base engineering standards and specifies how those principles apply to frontend development.

---

## Project Structure

```
src/
├── app/
│   ├── App.tsx                    # Root component, providers, router
│   ├── routes.tsx                 # Route definitions
│   └── providers/
│       ├── AuthProvider.tsx        # Authentication context
│       ├── QueryProvider.tsx       # React Query provider
│       └── ThemeProvider.tsx       # Theme context if needed
├── features/
│   ├── billing/
│   │   ├── api/
│   │   │   ├── billing-api.ts     # API functions for billing
│   │   │   └── billing-queries.ts # React Query hooks
│   │   ├── components/
│   │   │   ├── InvoiceList.tsx
│   │   │   ├── InvoiceDetail.tsx
│   │   │   ├── CreateInvoiceForm.tsx
│   │   │   └── InvoiceStatusBadge.tsx
│   │   ├── hooks/
│   │   │   └── use-invoice-filters.ts
│   │   ├── types/
│   │   │   └── billing-types.ts
│   │   └── index.ts               # Public API for the feature
│   ├── customers/
│   │   └── ...
│   └── auth/
│       ├── api/
│       │   └── auth-api.ts
│       ├── components/
│       │   ├── LoginPage.tsx
│       │   ├── ProtectedRoute.tsx
│       │   └── AuthGuard.tsx
│       ├── hooks/
│       │   └── use-auth.ts
│       └── types/
│           └── auth-types.ts
├── shared/
│   ├── components/
│   │   ├── Button.tsx
│   │   ├── Input.tsx
│   │   ├── Modal.tsx
│   │   ├── DataTable.tsx
│   │   ├── PageHeader.tsx
│   │   ├── LoadingSpinner.tsx
│   │   ├── ErrorBoundary.tsx
│   │   └── EmptyState.tsx
│   ├── hooks/
│   │   ├── use-debounce.ts
│   │   ├── use-pagination.ts
│   │   └── use-local-storage.ts
│   ├── lib/
│   │   ├── http-client.ts         # Axios/fetch wrapper
│   │   ├── auth.ts                # Token management utilities
│   │   └── format.ts              # Date, currency, number formatters
│   ├── types/
│   │   ├── api-types.ts           # Shared API types (pagination, errors)
│   │   └── common-types.ts
│   └── utils/
│       ├── validation.ts
│       └── test-utils.tsx         # Custom render with providers
├── assets/
│   └── ...
└── main.tsx                       # Entry point
```

### Structure Rules

- **Feature-based organisation.** Mirror the backend's package-by-feature approach. Each feature directory contains everything related to that feature: API calls, components, hooks, and types.
- **Public API via index.ts.** Each feature exports only what other features need through its `index.ts`. Internal components and hooks are not exported.
- **Shared directory for cross-cutting components.** Components used across three or more features live in `shared/components`. Components used by fewer features stay in the feature that owns them.
- **No barrel exports at the root level.** Imports reference the specific feature: `import { InvoiceList } from '@/features/billing'`, not from a global barrel file.
- **Path aliases.** Configure `@/` as an alias for `src/` in `tsconfig.json` and `vite.config.ts`:

```typescript
// vite.config.ts
export default defineConfig({
  resolve: {
    alias: { '@': path.resolve(__dirname, './src') }
  }
});
```

---

## Component Design Patterns

### Functional Components Only

Every component is a function component. No class components, ever.

```tsx
interface InvoiceDetailProps {
  invoiceId: string;
}

export function InvoiceDetail({ invoiceId }: InvoiceDetailProps) {
  const { data: invoice, isLoading, error } = useInvoice(invoiceId);

  if (isLoading) return <LoadingSpinner />;
  if (error) return <ErrorDisplay error={error} />;
  if (!invoice) return <EmptyState message="Invoice not found" />;

  return (
    <div className="space-y-6">
      <PageHeader
        title={`Invoice ${invoice.invoiceNumber}`}
        subtitle={invoice.customerName}
      />
      <InvoiceStatusBadge status={invoice.status} />
      <InvoiceLineItemsTable items={invoice.lineItems} />
      <InvoiceTotalSummary total={invoice.totalAmount} />
    </div>
  );
}
```

### Component Rules

- **Named exports only.** Never use default exports. Named exports enable better refactoring and auto-imports.
- **One component per file.** Small helper components used only within a parent component may share the file, but the file is named after the primary component.
- **Props are explicit interfaces.** Define a `Props` interface for every component that accepts props. Use descriptive names: `InvoiceDetailProps`, not `Props`.
- **Destructure props in the function signature.** `function InvoiceDetail({ invoiceId }: InvoiceDetailProps)`, not `function InvoiceDetail(props: InvoiceDetailProps)`.
- **No prop spreading.** Never use `{...props}` to pass through unknown props. Be explicit about which props a component accepts and passes down.
- **Handle all states.** Every component that depends on async data handles loading, error, and empty states explicitly. No component should render a blank screen while waiting for data.

### Composition Patterns

Prefer composition over configuration. Build complex UI by combining small, focused components.

```tsx
// Good — composed from focused components
<DataTable
  columns={invoiceColumns}
  data={invoices}
  emptyState={<EmptyState message="No invoices yet" action={<CreateInvoiceButton />} />}
  pagination={<Pagination {...paginationProps} />}
/>

// Bad — one massive component with dozens of props
<DataTable
  showPagination
  paginationPosition="bottom"
  emptyMessage="No invoices yet"
  emptyActionLabel="Create Invoice"
  onEmptyAction={handleCreate}
  // ... 20 more props
/>
```

### Custom Hooks

Extract non-trivial logic into custom hooks. A component's JSX should be primarily concerned with rendering.

```tsx
// Hook encapsulates filter logic
export function useInvoiceFilters() {
  const [searchParams, setSearchParams] = useSearchParams();

  const filters = useMemo(() => ({
    status: searchParams.get('status') as InvoiceStatus | null,
    search: searchParams.get('search') ?? '',
    page: parseInt(searchParams.get('page') ?? '0', 10),
  }), [searchParams]);

  const setFilter = useCallback((key: string, value: string | null) => {
    setSearchParams(prev => {
      if (value === null) prev.delete(key);
      else prev.set(key, value);
      prev.set('page', '0'); // Reset page on filter change
      return prev;
    });
  }, [setSearchParams]);

  return { filters, setFilter };
}
```

**Hook rules:**
- Hooks are named `use-{description}.ts` (kebab-case file, camelCase function).
- One hook per file unless closely related hooks share state.
- Hooks do not render UI. They return data and callbacks.
- Feature-specific hooks live in the feature's `hooks/` directory. Cross-cutting hooks live in `shared/hooks/`.

---

## State Management

### Decision Framework

Use the simplest state management that solves the problem:

1. **Component state (`useState`)** — for UI state local to a single component: form field values, toggle states, modal open/close.
2. **URL state (`useSearchParams`)** — for state that should be shareable via URL: filters, pagination, sort order, active tab.
3. **Server state (React Query)** — for data fetched from the API: entities, lists, aggregations. React Query handles caching, refetching, and synchronisation.
4. **Context (`createContext`)** — for state that many components in a subtree need: current user, theme, feature flags. Keep contexts small and focused.
5. **Global state library (Zustand)** — for complex client-side state that does not come from the server and is needed across unrelated component trees. This is rarely needed.

### React Query as Primary State Manager

React Query manages all server state. Never store fetched API data in component state or context.

```tsx
// features/billing/api/billing-queries.ts
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { billingApi } from './billing-api';

const billingKeys = {
  all: ['invoices'] as const,
  lists: () => [...billingKeys.all, 'list'] as const,
  list: (filters: InvoiceFilters) => [...billingKeys.all, 'list', filters] as const,
  details: () => [...billingKeys.all, 'detail'] as const,
  detail: (id: string) => [...billingKeys.all, 'detail', id] as const,
};

export function useInvoices(filters: InvoiceFilters) {
  return useQuery({
    queryKey: billingKeys.list(filters),
    queryFn: () => billingApi.listInvoices(filters),
  });
}

export function useInvoice(id: string) {
  return useQuery({
    queryKey: billingKeys.detail(id),
    queryFn: () => billingApi.getInvoice(id),
    enabled: !!id,
  });
}

export function useCreateInvoice() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: billingApi.createInvoice,
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: billingKeys.lists() });
    },
  });
}
```

### State Rules

- **Never duplicate server state.** If it comes from the API, React Query owns it.
- **URL state for anything bookmarkable.** If a user should be able to share or bookmark the current view (filtered list, specific page, selected tab), put it in the URL.
- **Context for auth and theme only** in most applications. Do not create contexts for feature-specific state.
- **Derived state is computed, not stored.** If a value can be computed from other state, compute it with `useMemo`. Do not store it separately.

---

## API Integration

### HTTP Client

```typescript
// shared/lib/http-client.ts
import axios, { AxiosError, AxiosInstance, InternalAxiosRequestConfig } from 'axios';
import { getAccessToken, refreshToken, clearAuth } from './auth';

const httpClient: AxiosInstance = axios.create({
  baseURL: import.meta.env.VITE_API_BASE_URL,
  headers: { 'Content-Type': 'application/json' },
  timeout: 30_000,
});

httpClient.interceptors.request.use(async (config: InternalAxiosRequestConfig) => {
  const token = getAccessToken();
  if (token) {
    config.headers.Authorization = `Bearer ${token}`;
  }
  return config;
});

httpClient.interceptors.response.use(
  response => response,
  async (error: AxiosError) => {
    if (error.response?.status === 401) {
      try {
        await refreshToken();
        return httpClient(error.config!);
      } catch {
        clearAuth();
        window.location.href = '/login';
      }
    }
    return Promise.reject(error);
  }
);

export { httpClient };
```

### Feature API Modules

```typescript
// features/billing/api/billing-api.ts
import { httpClient } from '@/shared/lib/http-client';
import type {
  Invoice,
  InvoiceSummary,
  CreateInvoiceRequest,
  UpdateInvoiceRequest,
  InvoiceFilters,
} from '../types/billing-types';
import type { PageResponse } from '@/shared/types/api-types';

export const billingApi = {
  listInvoices: async (filters: InvoiceFilters): Promise<PageResponse<InvoiceSummary>> => {
    const { data } = await httpClient.get('/api/v1/invoices', { params: filters });
    return data;
  },

  getInvoice: async (id: string): Promise<Invoice> => {
    const { data } = await httpClient.get(`/api/v1/invoices/${id}`);
    return data;
  },

  createInvoice: async (request: CreateInvoiceRequest): Promise<Invoice> => {
    const { data } = await httpClient.post('/api/v1/invoices', request);
    return data;
  },

  updateInvoice: async (id: string, request: UpdateInvoiceRequest): Promise<Invoice> => {
    const { data } = await httpClient.put(`/api/v1/invoices/${id}`, request);
    return data;
  },

  payInvoice: async (id: string): Promise<Invoice> => {
    const { data } = await httpClient.post(`/api/v1/invoices/${id}/pay`);
    return data;
  },

  deleteInvoice: async (id: string): Promise<void> => {
    await httpClient.delete(`/api/v1/invoices/${id}`);
  },
};
```

### API Integration Rules

- **One API module per feature.** All HTTP calls for billing live in `billing-api.ts`.
- **Type every request and response.** No `any`. API response types match the backend's response DTOs.
- **Centralised HTTP client.** All requests go through the shared `httpClient` with interceptors for auth and error handling.
- **Environment variables for configuration.** API base URL comes from `VITE_API_BASE_URL`, never hardcoded.
- **Handle errors at the query level.** React Query's `onError` callbacks handle API errors. Components check `error` from the query hook.

### Error Handling

```typescript
// shared/types/api-types.ts
export interface ApiError {
  error: {
    code: string;
    message: string;
    details: Array<{ field: string; message: string }>;
    timestamp: string;
    traceId: string;
  };
}

export interface PageResponse<T> {
  content: T[];
  page: number;
  size: number;
  totalElements: number;
  totalPages: number;
}
```

```tsx
// shared/components/ErrorDisplay.tsx
import { AxiosError } from 'axios';
import type { ApiError } from '@/shared/types/api-types';

interface ErrorDisplayProps {
  error: Error;
  onRetry?: () => void;
}

export function ErrorDisplay({ error, onRetry }: ErrorDisplayProps) {
  const message = getErrorMessage(error);

  return (
    <div className="rounded-lg border border-red-200 bg-red-50 p-4">
      <p className="text-sm text-red-800">{message}</p>
      {onRetry && (
        <button
          onClick={onRetry}
          className="mt-2 text-sm font-medium text-red-600 hover:text-red-500"
        >
          Try again
        </button>
      )}
    </div>
  );
}

function getErrorMessage(error: Error): string {
  if (error instanceof AxiosError && error.response?.data) {
    const apiError = error.response.data as ApiError;
    return apiError.error?.message ?? 'An unexpected error occurred';
  }
  return error.message ?? 'An unexpected error occurred';
}
```

---

## Routing

### Route Configuration

```tsx
// app/routes.tsx
import { createBrowserRouter } from 'react-router-dom';
import { ProtectedRoute } from '@/features/auth/components/ProtectedRoute';

export const router = createBrowserRouter([
  {
    path: '/login',
    lazy: () => import('@/features/auth/components/LoginPage'),
  },
  {
    element: <ProtectedRoute />,
    children: [
      {
        path: '/',
        lazy: () => import('@/features/dashboard/components/DashboardPage'),
      },
      {
        path: '/invoices',
        lazy: () => import('@/features/billing/components/InvoiceListPage'),
      },
      {
        path: '/invoices/new',
        lazy: () => import('@/features/billing/components/CreateInvoicePage'),
      },
      {
        path: '/invoices/:invoiceId',
        lazy: () => import('@/features/billing/components/InvoiceDetailPage'),
      },
      {
        path: '/customers',
        lazy: () => import('@/features/customers/components/CustomerListPage'),
      },
      {
        path: '/customers/:customerId',
        lazy: () => import('@/features/customers/components/CustomerDetailPage'),
      },
    ],
  },
]);
```

### Routing Rules

- Use React Router v6+ with the data router API.
- **Lazy load all page components.** Use `lazy()` for code splitting at the route level.
- **Protected routes wrap authenticated pages.** The `ProtectedRoute` component checks authentication and redirects to login if needed.
- **URL parameters for resource IDs.** `/invoices/:invoiceId`, never `/invoices?id=123`.
- **Search params for filters and pagination.** `/invoices?status=DRAFT&page=2`.
- **Plural nouns for resource routes.** `/invoices`, `/customers`, not `/invoice`, `/customer`.
- **Flat route structure.** Avoid deeply nested routes. `/invoices/:invoiceId` is fine. `/customers/:customerId/invoices/:invoiceId/line-items/:itemId` is too deep.

---

## Form Handling

### Controlled Forms with Validation

```tsx
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';

const createInvoiceSchema = z.object({
  customerId: z.string().uuid('Select a valid customer'),
  lineItems: z.array(z.object({
    description: z.string().min(1, 'Description is required').max(255),
    quantity: z.number().positive('Quantity must be positive'),
    unitPrice: z.number().nonnegative('Price must not be negative'),
  })).min(1, 'At least one line item is required'),
  notes: z.string().max(500).optional(),
});

type CreateInvoiceFormData = z.infer<typeof createInvoiceSchema>;

export function CreateInvoiceForm() {
  const createInvoice = useCreateInvoice();
  const navigate = useNavigate();

  const {
    register,
    handleSubmit,
    control,
    formState: { errors, isSubmitting },
  } = useForm<CreateInvoiceFormData>({
    resolver: zodResolver(createInvoiceSchema),
    defaultValues: {
      lineItems: [{ description: '', quantity: 1, unitPrice: 0 }],
    },
  });

  const onSubmit = async (data: CreateInvoiceFormData) => {
    try {
      const invoice = await createInvoice.mutateAsync(data);
      navigate(`/invoices/${invoice.id}`);
    } catch {
      // Error handled by mutation's onError or displayed via createInvoice.error
    }
  };

  return (
    <form onSubmit={handleSubmit(onSubmit)} className="space-y-6">
      <CustomerSelect control={control} error={errors.customerId?.message} />
      <LineItemsFieldArray control={control} errors={errors.lineItems} />
      <TextArea
        label="Notes"
        {...register('notes')}
        error={errors.notes?.message}
      />
      <Button type="submit" loading={isSubmitting}>
        Create Invoice
      </Button>
    </form>
  );
}
```

### Form Rules

- **React Hook Form for all forms.** It handles performance, validation, and submission without unnecessary re-renders.
- **Zod for schema validation.** Define schemas separately, infer TypeScript types from them. Single source of truth for form shape and validation.
- **Field-level error display.** Show validation errors immediately below the relevant field. Never show a generic "form has errors" message without field-specific details.
- **Disable submit during submission.** Show a loading state on the submit button while the API call is in flight.
- **Redirect on success.** After successful form submission, navigate to the created or updated resource.
- **Optimistic defaults.** Pre-populate forms with sensible defaults (quantity of 1, current date, etc.).

---

## Styling with Tailwind CSS

### Conventions

- **Utility-first.** Apply Tailwind utilities directly in JSX. Do not create custom CSS classes for one-off styling.
- **Component extraction over @apply.** When a utility combination repeats, extract a React component, not a CSS class:

```tsx
// Good — reusable component
function Badge({ children, variant }: BadgeProps) {
  const styles = {
    success: 'bg-green-100 text-green-800',
    warning: 'bg-yellow-100 text-yellow-800',
    error: 'bg-red-100 text-red-800',
  };
  return (
    <span className={`inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-medium ${styles[variant]}`}>
      {children}
    </span>
  );
}

// Bad — CSS class with @apply
.badge-success { @apply inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-medium bg-green-100 text-green-800; }
```

- **Consistent spacing scale.** Use Tailwind's spacing scale consistently. Pick a rhythm (4, 6, 8 units) and stick with it for padding and gaps within a feature.
- **Responsive design.** Use Tailwind's responsive prefixes (`sm:`, `md:`, `lg:`) mobile-first. Design for mobile first, add complexity at larger breakpoints.
- **Dark mode.** Use `dark:` variant if the application supports dark mode. Define colour pairs for all custom colours.
- **No inline styles.** Never use the `style` prop. If Tailwind does not have a utility for it, add it to `tailwind.config.ts`.

### Class Name Organisation

Order Tailwind classes consistently within a className string:

1. Layout (display, position, overflow)
2. Sizing (width, height, max-width)
3. Spacing (margin, padding, gap)
4. Typography (font, text, leading)
5. Backgrounds and borders
6. Effects (shadow, opacity, transition)
7. Responsive and state variants last

Use `clsx` or `cn` utility for conditional classes:

```tsx
import { clsx } from 'clsx';

function Button({ variant, size, className, ...props }: ButtonProps) {
  return (
    <button
      className={clsx(
        'inline-flex items-center justify-center rounded-md font-medium transition-colors',
        'focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-offset-2',
        variant === 'primary' && 'bg-blue-600 text-white hover:bg-blue-700',
        variant === 'secondary' && 'bg-gray-100 text-gray-900 hover:bg-gray-200',
        size === 'sm' && 'h-8 px-3 text-sm',
        size === 'md' && 'h-10 px-4 text-sm',
        size === 'lg' && 'h-12 px-6 text-base',
        className,
      )}
      {...props}
    />
  );
}
```

---

## Authentication Flow

### Token Management

```typescript
// shared/lib/auth.ts
const ACCESS_TOKEN_KEY = 'access_token';
const REFRESH_TOKEN_KEY = 'refresh_token';

export function getAccessToken(): string | null {
  return localStorage.getItem(ACCESS_TOKEN_KEY);
}

export function setTokens(accessToken: string, refreshToken: string): void {
  localStorage.setItem(ACCESS_TOKEN_KEY, accessToken);
  localStorage.setItem(REFRESH_TOKEN_KEY, refreshToken);
}

export function clearAuth(): void {
  localStorage.removeItem(ACCESS_TOKEN_KEY);
  localStorage.removeItem(REFRESH_TOKEN_KEY);
}

export async function refreshToken(): Promise<void> {
  const refresh = localStorage.getItem(REFRESH_TOKEN_KEY);
  if (!refresh) throw new Error('No refresh token');

  const response = await fetch(`${import.meta.env.VITE_AUTH_URL}/token`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      grant_type: 'refresh_token',
      client_id: import.meta.env.VITE_AUTH_CLIENT_ID,
      refresh_token: refresh,
    }),
  });

  if (!response.ok) throw new Error('Token refresh failed');

  const data = await response.json();
  setTokens(data.access_token, data.refresh_token);
}
```

### Auth Context

```tsx
// features/auth/components/AuthProvider.tsx
interface AuthContextType {
  user: User | null;
  isAuthenticated: boolean;
  isLoading: boolean;
  login: (redirectUrl?: string) => void;
  logout: () => void;
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

export function AuthProvider({ children }: { children: ReactNode }) {
  const [user, setUser] = useState<User | null>(null);
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    const token = getAccessToken();
    if (token) {
      try {
        const decoded = decodeJwt(token);
        setUser(mapTokenToUser(decoded));
      } catch {
        clearAuth();
      }
    }
    setIsLoading(false);
  }, []);

  const login = useCallback((redirectUrl?: string) => {
    // Redirect to Keycloak login
    window.location.href = buildKeycloakLoginUrl(redirectUrl);
  }, []);

  const logout = useCallback(() => {
    clearAuth();
    setUser(null);
    window.location.href = buildKeycloakLogoutUrl();
  }, []);

  return (
    <AuthContext.Provider value={{
      user,
      isAuthenticated: !!user,
      isLoading,
      login,
      logout,
    }}>
      {children}
    </AuthContext.Provider>
  );
}

export function useAuth(): AuthContextType {
  const context = useContext(AuthContext);
  if (!context) throw new Error('useAuth must be used within AuthProvider');
  return context;
}
```

### Protected Route

```tsx
export function ProtectedRoute() {
  const { isAuthenticated, isLoading } = useAuth();

  if (isLoading) return <FullPageSpinner />;
  if (!isAuthenticated) return <Navigate to="/login" replace />;

  return <Outlet />;
}
```

### Auth Rules

- Store tokens in `localStorage`. Accept the XSS trade-off for SPA convenience — mitigate with CSP headers and input sanitisation.
- Refresh tokens automatically on 401 responses via the HTTP client interceptor.
- Decode the JWT client-side for user info display only. Never trust client-side token validation for security — the backend validates on every request.
- Redirect to Keycloak for login and logout. Do not build custom login forms.
- Extract user roles and permissions from the JWT for UI-level access control (showing/hiding features). This is a UX convenience — the backend enforces real authorisation.

---

## Testing React Components

### Testing Setup

```tsx
// shared/utils/test-utils.tsx
import { render, RenderOptions } from '@testing-library/react';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { MemoryRouter } from 'react-router-dom';
import { AuthContext } from '@/features/auth/components/AuthProvider';

const createTestQueryClient = () => new QueryClient({
  defaultOptions: {
    queries: { retry: false },
    mutations: { retry: false },
  },
});

interface CustomRenderOptions extends Omit<RenderOptions, 'wrapper'> {
  initialRoute?: string;
  user?: User | null;
}

export function renderWithProviders(
  ui: React.ReactElement,
  options: CustomRenderOptions = {},
) {
  const { initialRoute = '/', user = mockUser(), ...renderOptions } = options;

  function Wrapper({ children }: { children: React.ReactNode }) {
    return (
      <QueryClientProvider client={createTestQueryClient()}>
        <AuthContext.Provider value={{
          user,
          isAuthenticated: !!user,
          isLoading: false,
          login: vi.fn(),
          logout: vi.fn(),
        }}>
          <MemoryRouter initialEntries={[initialRoute]}>
            {children}
          </MemoryRouter>
        </AuthContext.Provider>
      </QueryClientProvider>
    );
  }

  return render(ui, { wrapper: Wrapper, ...renderOptions });
}
```

### Component Test Example

```tsx
import { screen, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { http, HttpResponse } from 'msw';
import { server } from '@/test/msw-server';
import { renderWithProviders } from '@/shared/utils/test-utils';
import { InvoiceList } from './InvoiceList';

describe('InvoiceList', () => {
  it('renders invoice list when data loads successfully', async () => {
    server.use(
      http.get('/api/v1/invoices', () =>
        HttpResponse.json({
          content: [
            { id: '1', invoiceNumber: 'INV-001', customerName: 'Acme', status: 'DRAFT', totalAmount: 150 },
          ],
          totalElements: 1,
          totalPages: 1,
          page: 0,
          size: 20,
        }),
      ),
    );

    renderWithProviders(<InvoiceList />);

    await waitFor(() => {
      expect(screen.getByText('INV-001')).toBeInTheDocument();
      expect(screen.getByText('Acme')).toBeInTheDocument();
    });
  });

  it('shows empty state when no invoices exist', async () => {
    server.use(
      http.get('/api/v1/invoices', () =>
        HttpResponse.json({ content: [], totalElements: 0, totalPages: 0, page: 0, size: 20 }),
      ),
    );

    renderWithProviders(<InvoiceList />);

    await waitFor(() => {
      expect(screen.getByText(/no invoices/i)).toBeInTheDocument();
    });
  });

  it('filters invoices by status when filter is selected', async () => {
    const user = userEvent.setup();
    // ... test filter interaction
  });
});
```

### Testing Rules

- **Use Vitest** as the test runner. It integrates natively with Vite.
- **Use Testing Library** for component tests. Query by role, label, and text — not by CSS class or test ID.
- **Use MSW (Mock Service Worker)** for mocking API responses. MSW intercepts at the network level, so tests exercise the real HTTP client and React Query hooks.
- **No snapshot tests.** They break on trivial changes and provide little value. Test behaviour, not markup.
- **User-centric testing.** Test what the user sees and does: rendered text, click interactions, form submissions. Do not test component internals, state values, or implementation details.
- **Cover these scenarios for every page component:** successful data loading, loading state, error state, empty state, and primary user interaction.
- **Use `renderWithProviders`** for every component test. It wraps the component with all necessary providers (router, query client, auth).

---

## TypeScript Conventions

### Strict Mode

```json
// tsconfig.json
{
  "compilerOptions": {
    "strict": true,
    "noUncheckedIndexedAccess": true,
    "noImplicitReturns": true,
    "noFallthroughCasesInSwitch": true,
    "forceConsistentCasingInFileNames": true
  }
}
```

### Type Rules

- **No `any`.** Ever. Use `unknown` when the type is truly unknown, then narrow it.
- **No type assertions (`as Type`)** unless absolutely necessary (e.g., MSW handlers). If you need a type assertion, the types are wrong — fix them.
- **Prefer `interface` for object shapes** that describe data (props, API responses). Use `type` for unions, intersections, and mapped types.
- **Discriminated unions for state machines:**

```typescript
type InvoiceState =
  | { status: 'loading' }
  | { status: 'error'; error: Error }
  | { status: 'success'; data: Invoice };
```

- **Enums are forbidden.** Use `as const` objects or union types:

```typescript
// Good
const InvoiceStatus = {
  DRAFT: 'DRAFT',
  SENT: 'SENT',
  PAID: 'PAID',
  CANCELLED: 'CANCELLED',
} as const;

type InvoiceStatus = typeof InvoiceStatus[keyof typeof InvoiceStatus];

// Bad
enum InvoiceStatus { DRAFT, SENT, PAID, CANCELLED }
```

- **Export types explicitly.** Use `export type { ... }` for type-only exports to ensure they are erased at compile time.
