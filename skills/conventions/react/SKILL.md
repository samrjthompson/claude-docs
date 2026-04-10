---
name: react-conventions
description: React/TypeScript conventions — feature-based structure, functional components, state management hierarchy, React Query, forms, routing, Tailwind, authentication, Vitest/MSW testing
user-invocable: false
paths: "**/*.tsx,**/*.ts,**/vite.config*,**/tsconfig*.json,**/package.json"
---

# React / TypeScript Technical Standards

React applications built with TypeScript, Vite, and Tailwind CSS. Builds on universal engineering standards.

Reference files in this skill directory:
- [component-patterns.md](component-patterns.md) — API integration, routing, form handling, styling
- [testing-and-auth.md](testing-and-auth.md) — testing setup, MSW, auth flow, TypeScript conventions

---

## Project Structure

```
src/
├── app/
│   ├── App.tsx                    # Root component, providers, router
│   ├── routes.tsx                 # Route definitions
│   └── providers/
│       ├── AuthProvider.tsx
│       ├── QueryProvider.tsx
│       └── ThemeProvider.tsx
├── features/
│   ├── billing/
│   │   ├── api/
│   │   │   ├── billing-api.ts     # API functions
│   │   │   └── billing-queries.ts # React Query hooks
│   │   ├── components/
│   │   │   ├── InvoiceList.tsx
│   │   │   ├── InvoiceDetail.tsx
│   │   │   └── CreateInvoiceForm.tsx
│   │   ├── hooks/
│   │   │   └── use-invoice-filters.ts
│   │   ├── types/
│   │   │   └── billing-types.ts
│   │   └── index.ts               # Public API for the feature
├── shared/
│   ├── components/
│   │   ├── Button.tsx
│   │   ├── DataTable.tsx
│   │   ├── ErrorBoundary.tsx
│   │   └── EmptyState.tsx
│   ├── hooks/
│   │   ├── use-debounce.ts
│   │   └── use-pagination.ts
│   ├── lib/
│   │   ├── http-client.ts         # Axios wrapper with auth interceptors
│   │   ├── auth.ts                # Token management
│   │   └── format.ts              # Date, currency, number formatters
│   ├── types/
│   │   └── api-types.ts           # PageResponse, ApiError, shared types
│   └── utils/
│       └── test-utils.tsx         # renderWithProviders helper
└── main.tsx
```

### Structure Rules

- **Feature-based.** Mirror the backend's package-by-feature. Each feature directory contains its API calls, components, hooks, and types.
- **Public API via index.ts.** Each feature exports only what other features need. Internal components are not exported.
- **Shared for cross-cutting components.** Components used across 3+ features live in `shared/`. Others stay in the owning feature.
- **No barrel exports at the root.** Import from the specific feature: `import { InvoiceList } from '@/features/billing'`.
- **Path alias `@/`** maps to `src/` in `tsconfig.json` and `vite.config.ts`.

---

## Component Design Patterns

### Functional Components Only

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
      <PageHeader title={`Invoice ${invoice.invoiceNumber}`} subtitle={invoice.customerName} />
      <InvoiceStatusBadge status={invoice.status} />
      <InvoiceLineItemsTable items={invoice.lineItems} />
    </div>
  );
}
```

### Component Rules

- **Named exports only.** Never default exports.
- **One component per file.** Small helper components used only within a parent may share the file.
- **Explicit `Props` interfaces.** `InvoiceDetailProps`, not `Props`.
- **Destructure props in the function signature.**
- **No prop spreading.** Never `{...props}` to pass through unknown props.
- **Handle all states.** Loading, error, and empty states are explicit. No blank screens.

### Custom Hooks

- Named `use-{description}.ts` (kebab-case file, camelCase function).
- One hook per file unless closely related.
- Hooks do not render UI — they return data and callbacks.
- Feature-specific in `features/{feature}/hooks/`. Cross-cutting in `shared/hooks/`.

---

## State Management

Use the simplest mechanism that solves the problem:

1. **`useState`** — UI state local to a single component: form field values, toggle states, modal open/close.
2. **`useSearchParams`** — State that should be shareable via URL: filters, pagination, sort order, active tab.
3. **React Query** — All data fetched from the API. Handles caching, refetching, synchronisation.
4. **`createContext`** — State many components in a subtree need: current user, theme, feature flags. Keep contexts small.
5. **Zustand** — Complex client-side state not from the server, needed across unrelated trees. Rarely needed.

### React Query Pattern

```tsx
// features/billing/api/billing-queries.ts
const billingKeys = {
  all: ['invoices'] as const,
  lists: () => [...billingKeys.all, 'list'] as const,
  list: (filters: InvoiceFilters) => [...billingKeys.all, 'list', filters] as const,
  detail: (id: string) => [...billingKeys.all, 'detail', id] as const,
};

export function useInvoices(filters: InvoiceFilters) {
  return useQuery({
    queryKey: billingKeys.list(filters),
    queryFn: () => billingApi.listInvoices(filters),
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
- **URL state for anything bookmarkable** — filtered lists, active tab, current page.
- **Context for auth and theme only** in most applications.
- **Derived state is computed, not stored.** Use `useMemo`, not separate `useState`.

---

## TypeScript Conventions

### Strict Mode

```json
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

- **No `any`.** Use `unknown` when truly unknown, then narrow.
- **No type assertions (`as Type`)** unless absolutely necessary. If you need one, the types are wrong — fix them.
- **`interface` for object shapes** (props, API responses). `type` for unions, intersections, mapped types.
- **Discriminated unions for state machines:**

```typescript
type InvoiceState =
  | { status: 'loading' }
  | { status: 'error'; error: Error }
  | { status: 'success'; data: Invoice };
```

- **No enums.** Use `as const` objects or union types:

```typescript
const InvoiceStatus = {
  DRAFT: 'DRAFT',
  SENT: 'SENT',
  PAID: 'PAID',
} as const;

type InvoiceStatus = typeof InvoiceStatus[keyof typeof InvoiceStatus];
```

- **`export type { ... }`** for type-only exports.
