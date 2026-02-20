# Scaffold New React Page

Create a new page component with routing, API integration, loading/error/empty states, and layout.

## Required Input

Provide the following:
- **Page name**: e.g., `InvoiceList`, `CustomerDetail`, `Dashboard`
- **Feature**: Which feature directory this belongs to (e.g., `billing`, `customers`)
- **Route path**: e.g., `/invoices`, `/customers/:customerId`
- **Data requirements**: What API data this page needs
- **Page type**: List page (with filters/pagination), Detail page (single entity), Form page (create/edit), or Dashboard page (aggregations)

## Files to Generate

### 1. Page Component (`{PageName}Page.tsx`)

Located in `src/features/{feature}/components/`.

**For List Pages:**
- Fetch data using the feature's React Query hook.
- Include filter controls (status, search) synced to URL search params.
- Include pagination controls.
- Handle loading state with `<LoadingSpinner />`.
- Handle error state with `<ErrorDisplay />`.
- Handle empty state with `<EmptyState />` including a call-to-action.
- Include a page header with title and primary action button (e.g., "Create Invoice").

**For Detail Pages:**
- Extract entity ID from route params with `useParams`.
- Fetch data using the feature's React Query hook with the entity ID.
- Handle loading, error, and not-found states.
- Display entity details in a structured layout.
- Include action buttons (edit, delete, status transitions).

**For Form Pages:**
- Use React Hook Form with Zod validation schema.
- Include all form fields with proper input types and validation.
- Handle submission with the feature's mutation hook.
- Show field-level validation errors.
- Redirect to the detail or list page on success.
- Disable submit button during submission.

**For Dashboard Pages:**
- Fetch multiple data sources using parallel React Query hooks.
- Display metrics in card components.
- Include charts or data visualizations as needed.
- Handle partial loading (show data as it arrives).

### 2. API Functions (modify `{feature}-api.ts` if needed)

- Add any new API functions the page requires.
- Follow the existing API module pattern.

### 3. React Query Hooks (modify `{feature}-queries.ts` if needed)

- Add query or mutation hooks for new API functions.
- Follow the query key factory pattern.
- Invalidate related queries on mutations.

### 4. Types (modify `{feature}-types.ts` if needed)

- Add any new TypeScript types for request/response data.

### 5. Route Registration (modify `routes.tsx`)

- Add the new route with lazy loading.
- Place inside the `ProtectedRoute` wrapper.

### 6. Supporting Components (new files if needed)

- Extract reusable sub-components used only by this page.
- Place in the feature's `components/` directory.

### 7. Test File (`{PageName}Page.test.tsx`)

- Use `renderWithProviders` from test utilities.
- Mock API responses with MSW.
- Test: successful data render, loading state, error state, empty state.
- Test primary user interaction (create button, filter selection, form submission).

## Output Format

Generate each file completely with all imports. For modifications to existing files, show the additions with context.

## Component Rules

- Named exports only. No default exports.
- Handle all async states: loading, error, empty, success.
- Use Tailwind CSS utilities for styling.
- Use `clsx` for conditional class names.
- Extract non-trivial logic into custom hooks.
