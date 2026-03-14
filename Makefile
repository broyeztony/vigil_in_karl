.PHONY: up down clean setup mock discovery logs watch-db test

up:
	docker compose up -d postgres

down:
	docker compose down

clean:
	docker compose down -v

setup:
	karl run cmd/setup.k

mock:
	karl run cmd/mock_server.k

discovery:
	karl run cmd/discovery.k

logs:
	docker compose logs -f postgres

watch-db:
	bash scripts/watch_db.sh

test:
	bash scripts/test_all.sh
