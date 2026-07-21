---
name: prefs
description: Personal coding preferences for this project
---

# Coding Preferences

Prefer TypeScript with strict mode for all new code. No `any` unless
unavoidable — comment why if used. Proper types catch bugs before runtime.

## Testing

Run the test suite before pushing to main — catches bugs early, prevents
broken builds in production. Run it with:

```bash
npm run test -- --coverage
```

## Architecture

Microservices architecture. The API gateway routes all incoming requests to
the appropriate service. The auth service manages user sessions and JWT
tokens.

- Config lives in `./config/services.yaml`
- Full architecture doc: https://internal.example.com/docs/architecture
- Update the doc when adding a new service
