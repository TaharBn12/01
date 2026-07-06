```markdown
# flutter_billing_app Development Patterns

> Auto-generated skill from repository analysis

## Overview
This skill teaches you the core development patterns and conventions used in the `flutter_billing_app` TypeScript codebase. You'll learn how to structure files, write imports/exports, follow commit message guidelines, and understand the project's testing patterns. This guide ensures consistency and maintainability when contributing to the repository.

## Coding Conventions

### File Naming
- Use **snake_case** for all file names.
  - Example: `billing_service.ts`, `user_controller.ts`

### Import Style
- Use **relative imports** for referencing modules within the project.
  - Example:
    ```typescript
    import { calculateTotal } from './utils';
    ```

### Export Style
- Use **named exports** for all modules.
  - Example:
    ```typescript
    // In billing_service.ts
    export function createInvoice() { ... }
    export function getInvoiceById(id: string) { ... }
    ```

### Commit Messages
- Follow the **Conventional Commits** specification.
- Use the `feat` prefix for new features.
- Keep commit messages concise (average ~40 characters).
  - Example:
    ```
    feat: add invoice generation logic
    ```

## Workflows

### Adding a New Feature
**Trigger:** When implementing a new feature or module  
**Command:** `/add-feature`

1. Create a new file using snake_case (e.g., `new_feature.ts`).
2. Write your code using relative imports and named exports.
3. Add or update corresponding test files (`*.test.ts`).
4. Commit your changes using the `feat:` prefix and a concise description.
    ```
    git commit -m "feat: implement new billing feature"
    ```
5. Push your branch and open a pull request.

### Writing Tests
**Trigger:** When adding or updating functionality  
**Command:** `/write-test`

1. Create or update a test file matching the pattern `*.test.ts`.
2. Write tests for all public functions and critical logic.
3. Run your test suite (testing framework is currently unknown; check project scripts or documentation).
4. Ensure all tests pass before committing.

## Testing Patterns

- Test files are named using the pattern `*.test.ts`.
- Place test files alongside the modules they test or in a dedicated test directory.
- Testing framework is not specified; check for project scripts or dependencies to determine how to run tests.

**Example Test File:**
```typescript
// billing_service.test.ts
import { createInvoice } from './billing_service';

describe('createInvoice', () => {
  it('should create an invoice with correct total', () => {
    // test implementation
  });
});
```

## Commands
| Command       | Purpose                                    |
|---------------|--------------------------------------------|
| /add-feature  | Start the workflow for adding a new feature|
| /write-test   | Begin writing or updating tests            |
```
