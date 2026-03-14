# vigil_in_karl

First-principles rebuild of Vigil in Karl.

## Stack

- PostgreSQL (Docker)
- Karl services:
  - `cmd/setup.k`
  - `cmd/mock_server.k`
  - `cmd/discovery.k`

Default DB DSN:
`postgres://vigil:vigil@127.0.0.1:55432/vigil?sslmode=disable`

## Quickstart

```bash
make up
make setup
make mock        # terminal A
make discovery   # terminal B
```

## DB watch

```bash
make watch-db
```

## Stop

```bash
make down        # keep data
make clean       # wipe data
```

## Tests

```bash
make test
```
