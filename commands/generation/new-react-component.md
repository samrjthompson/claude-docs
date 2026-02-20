# Create Reusable React Component

Generate a reusable React component with TypeScript props, Tailwind styling, and a test file.

## Required Input

Provide the following:
- **Component name**: PascalCase (e.g., `StatusBadge`, `DataTable`, `ConfirmDialog`)
- **Location**: Feature-specific (`src/features/{feature}/components/`) or shared (`src/shared/components/`)
- **Purpose**: What this component does and when it is used
- **Props**: List of props with types and whether they are required or optional
- **Variants** (if applicable): Visual or behavioural variants (e.g., `primary`, `secondary`, `danger` for a Button)

## Files to Generate

### 1. Component File (`{ComponentName}.tsx`)

- Named export (no default export).
- Props defined as an explicit interface: `{ComponentName}Props`.
- Destructure props in the function signature.
- Use Tailwind CSS for all styling.
- Use `clsx` for conditional class names.
- Support a `className` prop for external customisation.
- Handle edge cases (empty data, missing optional props).
- Include ARIA attributes for accessibility where appropriate.

**Component structure:**
```tsx
interface {ComponentName}Props {
  // Required props first, then optional
}

export function {ComponentName}({ prop1, prop2, className }: {ComponentName}Props) {
  return (
    // JSX with Tailwind classes
  );
}
```

### 2. Test File (`{ComponentName}.test.tsx`)

- Import from `@testing-library/react` and `@testing-library/user-event`.
- Test each variant renders correctly.
- Test user interactions (clicks, hover, keyboard).
- Test edge cases (empty data, long text, missing optional props).
- Test accessibility (proper ARIA attributes, keyboard navigation).
- Use `renderWithProviders` if the component needs context.

**Test structure:**
```tsx
describe('{ComponentName}', () => {
  it('renders with required props', () => {});
  it('applies variant styles correctly', () => {});
  it('handles user interaction', () => {});
  it('renders gracefully with edge case data', () => {});
});
```

## Output Format

Generate both files completely with all imports. The component should be immediately usable with no modifications needed.
