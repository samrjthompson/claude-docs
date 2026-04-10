# API Integration, Routing, Forms, and Styling

## HTTP Client

```typescript
// shared/lib/http-client.ts
const httpClient: AxiosInstance = axios.create({
  baseURL: import.meta.env.VITE_API_BASE_URL,
  headers: { 'Content-Type': 'application/json' },
  timeout: 30_000,
});

httpClient.interceptors.request.use(async (config) => {
  const token = getAccessToken();
  if (token) config.headers.Authorization = `Bearer ${token}`;
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
```

## Feature API Modules

```typescript
// features/billing/api/billing-api.ts
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

  deleteInvoice: async (id: string): Promise<void> => {
    await httpClient.delete(`/api/v1/invoices/${id}`);
  },
};
```

### Shared API Types

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

### API Rules

- **One API module per feature.** All HTTP calls for billing live in `billing-api.ts`.
- **Type every request and response.** No `any`. Response types match backend DTOs.
- **Centralised HTTP client.** All requests go through `httpClient` with auth interceptors.
- **API base URL from `VITE_API_BASE_URL`.** Never hardcoded.
- **Errors handled at the query level.** React Query `onError` callbacks. Components check `error` from hooks.

---

## Routing

```tsx
// app/routes.tsx
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
    ],
  },
]);
```

### Routing Rules

- React Router v6+ with data router API.
- **Lazy load all page components.** `lazy()` for code splitting at route level.
- **Protected routes** wrap all authenticated pages.
- **URL parameters for resource IDs.** `/invoices/:invoiceId`, never `/invoices?id=123`.
- **Search params for filters/pagination.** `/invoices?status=DRAFT&page=2`.
- **Plural nouns.** `/invoices`, `/customers`.
- **Flat route structure.** Avoid deeply nested routes.

---

## Form Handling

```tsx
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

  const { register, handleSubmit, control, formState: { errors, isSubmitting } } =
    useForm<CreateInvoiceFormData>({
      resolver: zodResolver(createInvoiceSchema),
      defaultValues: { lineItems: [{ description: '', quantity: 1, unitPrice: 0 }] },
    });

  const onSubmit = async (data: CreateInvoiceFormData) => {
    try {
      const invoice = await createInvoice.mutateAsync(data);
      navigate(`/invoices/${invoice.id}`);
    } catch {
      // Error displayed via createInvoice.error
    }
  };

  return (
    <form onSubmit={handleSubmit(onSubmit)} className="space-y-6">
      <CustomerSelect control={control} error={errors.customerId?.message} />
      <LineItemsFieldArray control={control} errors={errors.lineItems} />
      <Button type="submit" loading={isSubmitting}>Create Invoice</Button>
    </form>
  );
}
```

### Form Rules

- **React Hook Form** for all forms.
- **Zod for schema validation.** Infer TypeScript types from schemas.
- **Field-level error display** immediately below the field.
- **Disable submit during submission.** Show loading state.
- **Redirect on success.** Navigate to the created or updated resource.

---

## Styling with Tailwind CSS

### Conventions

- **Utility-first.** Apply Tailwind utilities directly in JSX.
- **Component extraction over `@apply`.** When a utility combination repeats, extract a React component:

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
```

- **Mobile-first responsive.** `sm:`, `md:`, `lg:` prefixes. Design for mobile first.
- **No inline styles.** Use `style` prop never. Add to `tailwind.config.ts` if Tailwind lacks the utility.

### Class Name Organisation

Order within a `className` string:
1. Layout (display, position, overflow)
2. Sizing (width, height, max-width)
3. Spacing (margin, padding, gap)
4. Typography (font, text, leading)
5. Backgrounds and borders
6. Effects (shadow, opacity, transition)
7. Responsive and state variants last

Use `clsx` for conditional classes:

```tsx
import { clsx } from 'clsx';

function Button({ variant, size, className, ...props }: ButtonProps) {
  return (
    <button
      className={clsx(
        'inline-flex items-center justify-center rounded-md font-medium transition-colors',
        variant === 'primary' && 'bg-blue-600 text-white hover:bg-blue-700',
        variant === 'secondary' && 'bg-gray-100 text-gray-900 hover:bg-gray-200',
        size === 'sm' && 'h-8 px-3 text-sm',
        size === 'md' && 'h-10 px-4 text-sm',
        className,
      )}
      {...props}
    />
  );
}
```
