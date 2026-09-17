# Contributing

Thanks for considering a contribution to APEX AI Router.

## Development setup (gateway)

```sh
cd gateway
uv sync
uv run pytest
uv run ruff check .
```

## Ground rules

- **No customer or production data, anywhere** — not in code, tests, fixtures,
  or benchmark tasks. Benchmark tasks and demo data must be synthetic
  (invented schemas, `example.com`/`example.test` values).
- **No fabricated numbers.** Don't add benchmark results, compatibility
  claims, or performance numbers that weren't actually measured in this
  repository. If something wasn't tested, say so.
- **No hard-coded vendor/model identity logic.** The router reasons about
  logical targets (`efficient`, `capable`, `judge`), never about a specific
  provider or model name, in code.
- **No secrets committed.** `.env.example` holds placeholders only; real
  values go in a local `.env` (git-ignored) or your deployment's secret
  store.
- Keep PRs scoped — prefer several small PRs over one large one.

## Tests

New functionality should come with tests. Gateway tests live in
`gateway/tests/` (`unit/`, `integration/`, `contract/`). Integration tests
should exercise the mock upstream model servers in
`gateway/src/apex_ai_router/mocks/`, not real paid providers — CI never
has live provider credentials.

## Commit messages

Plain, descriptive commit messages. No AI-attribution trailers.
