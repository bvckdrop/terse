---
name: prefs
description: Personal coding preferences for this project
---

# Coding Preferences

I strongly prefer TypeScript with strict mode enabled for all new code.
Please don't use `any` type unless there's genuinely no way around it, and
if you do, leave a comment explaining the reasoning. I find that taking the
time to properly type things catches a lot of bugs before they ever make it
to runtime.

## Testing

You should always make sure to run the test suite before pushing any changes
to the main branch. This is important because it helps catch bugs early and
prevents broken builds from being deployed to production. Run it with:

```bash
npm run test -- --coverage
```

## Architecture

The application uses a microservices architecture with the following
components. The API gateway handles all incoming requests and routes them
to the appropriate service. The authentication service is responsible for
managing user sessions and JWT tokens.

- Config lives in `./config/services.yaml`
- Full architecture doc: https://internal.example.com/docs/architecture
- Please remember to update the doc if you add a new service
