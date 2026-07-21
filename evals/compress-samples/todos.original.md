# Project TODOs

## This week

1. We really need to fix the flaky test in `auth.spec.ts` — it basically
   fails about one in five runs on CI, which is really slowing down the
   team.
2. It would be good to add rate limiting to the `/api/login` endpoint. You
   should make sure to use the existing `RateLimiter` middleware rather than
   writing a new one.
3. Please remember to update the deployment docs at
   https://wiki.example.com/deploy once the new pipeline ships.

## Someday

- It might be worth considering a migration to `pnpm`, however this isn't
  urgent and shouldn't block anything else.
- Investigate why `npm run build` is basically taking twice as long as it
  used to; probably worth profiling with `--verbose` first.
