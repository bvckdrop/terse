# Project TODOs

## This week

1. Fix the flaky test in `auth.spec.ts` — fails about one in five runs on
   CI, slowing down the team.
2. Add rate limiting to the `/api/login` endpoint. Use the existing
   `RateLimiter` middleware rather than writing a new one.
3. Update the deployment docs at https://wiki.example.com/deploy once the
   new pipeline ships.

## Someday

- Consider migrating to `pnpm` — not urgent, shouldn't block anything else.
- Investigate why `npm run build` takes twice as long as it used to; worth
  profiling with `--verbose` first.
