# vigil_in_karl

First-principles rebuild of Vigil in Karl.

## Stack

- PostgreSQL (Docker)
- Karl services:
  - `cmd/setup.k`
  - `cmd/mock_server.k`
  - `cmd/discovery.k`

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
