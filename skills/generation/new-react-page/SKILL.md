---
name: new-react-page
description: Scaffold a new React page — page component, API hooks, route registration, MSW tests for loading/error/empty/success states
argument-hint: "[PageName] [feature] [route-path] [type: list|detail|form|dashboard] [data requirements]"
disable-model-invocation: true
allowed-tools: Read, Write, Edit, Glob
---

# Scaffold New React Page

Create a new page component with routing, API integration, loading/error/empty states, and layout.

## Required Input

Use `$ARGUMENTS` to determine:
- **Page name**: e.g., `InvoiceList`, `CustomerDetail`, `Dashboard`
- **Feature**: Which feature directory this belongs to (e.g., `billing`, `customers`)
- **Route path**: e.g., `/invoices`, `/customers/:customerId`
- **Data requirements**: What API data this page needs
- **Page type**: List (filters/pagination), Detail (single entity), Form (create/edit), or Dashboard (aggregations)

Read the feature's existing API module and types before generating.

## Files to Generate

### 1. Page Component (`{PageName}Page.tsx`)

Located in `src/features/{feature}/components/`.

**For List Pages:**
- Fetch data using the feature's React Query hook.
- Filter controls (status, search) synced to URL search params.
- Pagination controls.
- Handle loading (`<LoadingSpinner />`), error (`<ErrorDisplay />`), and empty (`<EmptyState />`) states.
- Page header with title and primary action button.

**For Detail Pages:**
- Extract entity ID from route params with `useParams`.
- Fetch data using the feature's React Query hook.
- Handle loading, error, and not-found states.
- Display entity details in a structured layout.
- Include action buttons (edit, delete, status transitions).

**For Form Pages:**
- React Hook Form with Zod validation schema.
- All form fields with proper input types and validation.
- Submission with the feature's mutation hook.
- Field-level validation errors.
- Redirect on success. Disable submit during submission.

**For Dashboard Pages:**
- Parallel React Query hooks for multiple data sources.
- Metrics in card components.
- Handle partial loading (show data as it arrives).

### 2. API Functions (modify `{feature}-api.ts` if needed)

- Add new API functions the page requires.

### 3. React Query Hooks (modify `{feature}-queries.ts` if needed)

- Add query or mutation hooks.
- Follow the query key factory pattern.
- Invalidate related queries on mutations.

### 4. Types (modify `{feature}-types.ts` if needed)

- Add new TypeScript types for request/response data.

### 5. Route Registration (modify `routes.tsx`)

- Add new route with lazy loading.
- Place inside the `ProtectedRoute` wrapper.

### 6. Supporting Components (new files if needed)

- Extract reusable sub-components used only by this page.
- Place in the feature's `components/` directory.

### 7. Test File (`{PageName}Page.test.tsx`)

- Use `renderWithProviders`.
- Mock API responses with MSW.
- Test: successful data render, loading state, error state, empty state.
- Test primary user interaction.

## Component Rules

- Named exports only. No default exports.
- Handle all async states.
- Tailwind CSS for styling.
- `clsx` for conditional class names.
- Extract non-trivial logic into custom hooks.

## Output Format

Generate each file completely with all imports. For modifications, show additions with context.
