# Testing and Authentication

## Testing Setup

```tsx
// shared/utils/test-utils.tsx
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

## Component Test Example

```tsx
describe('InvoiceList', () => {
  it('renders invoice list when data loads successfully', async () => {
    server.use(
      http.get('/api/v1/invoices', () =>
        HttpResponse.json({
          content: [
            { id: '1', invoiceNumber: 'INV-001', customerName: 'Acme', status: 'DRAFT', totalAmount: 150 },
          ],
          totalElements: 1, totalPages: 1, page: 0, size: 20,
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
});
```

## Testing Rules

- **Vitest** as the test runner.
- **Testing Library** for component tests. Query by role, label, text — not by CSS class or test ID.
- **MSW (Mock Service Worker)** for API mocking. Intercepts at the network level.
- **No snapshot tests.** Test behaviour, not markup.
- **User-centric testing.** Test what the user sees and does.
- **Cover these scenarios for every page component:** successful loading, loading state, error state, empty state, primary user interaction.
- **Use `renderWithProviders`** for every component test.

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

### AuthProvider and ProtectedRoute

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
    window.location.href = buildKeycloakLoginUrl(redirectUrl);
  }, []);

  const logout = useCallback(() => {
    clearAuth();
    setUser(null);
    window.location.href = buildKeycloakLogoutUrl();
  }, []);

  return (
    <AuthContext.Provider value={{ user, isAuthenticated: !!user, isLoading, login, logout }}>
      {children}
    </AuthContext.Provider>
  );
}

export function useAuth(): AuthContextType {
  const context = useContext(AuthContext);
  if (!context) throw new Error('useAuth must be used within AuthProvider');
  return context;
}

export function ProtectedRoute() {
  const { isAuthenticated, isLoading } = useAuth();
  if (isLoading) return <FullPageSpinner />;
  if (!isAuthenticated) return <Navigate to="/login" replace />;
  return <Outlet />;
}
```

## Auth Rules

- Store tokens in `localStorage`. Mitigate XSS with CSP headers and input sanitisation.
- Refresh tokens automatically on 401 via HTTP client interceptor.
- Decode JWT client-side for user info display only. Backend validates on every request.
- Redirect to Keycloak for login/logout. Do not build custom login forms.
- Extract user roles from JWT for UI-level access control (showing/hiding features). Backend enforces real authorisation.
