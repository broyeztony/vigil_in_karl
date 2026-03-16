.PHONY: up down clean setup mock mock-5000 mock-ramp discovery logs watch-db test test-churn test-10m-start test-10m-stop

TMUX_SESSION ?= vik10m
START_USERS ?= 32
TARGET_USERS ?= 5000
STEP_USERS ?= 32
RAMP_INTERVAL_SEC ?= 0.2
TEST_DURATION_SEC ?= 600
TENANT_ID ?= 00000000-0000-0000-0000-000000000001
PROVIDER_API_URL ?= http://127.0.0.1:8080
DATABASE_URL ?= postgres://vigil:vigil@127.0.0.1:55432/vigil?sslmode=disable
USER_SYNC_MS ?= 1200
EMAIL_POLL_MS ?= 1200
METRICS_LOG_MS ?= 2000
WATCH_DB_INTERVAL ?= 2
AUTO_ATTACH ?= 1

up:
	docker compose up -d postgres

down:
	docker compose down

clean:
	docker compose down -v

setup:
	bash scripts/wait_db.sh
	karl run cmd/setup.k

mock:
	karl run cmd/mock_server.k

mock-5000:
	MOCK_INITIAL_USERS=5000 karl run cmd/mock_server.k

mock-ramp:
	bash scripts/mock_ramp_users.sh

discovery:
	karl run cmd/discovery.k

logs:
	docker compose logs -f postgres

watch-db:
	bash scripts/watch_db.sh

test:
	bash scripts/test_all.sh

test-churn:
	bash scripts/test_user_churn.sh

test-10m-start:
	@command -v tmux >/dev/null || { echo "tmux not found in PATH"; exit 1; }
	@tmux has-session -t "$(TMUX_SESSION)" 2>/dev/null && { echo "tmux session $(TMUX_SESSION) already exists"; exit 1; } || true
	@$(MAKE) clean
	@$(MAKE) up
	@$(MAKE) setup
	@tmux new-session -d -s "$(TMUX_SESSION)" -n run -c "$(CURDIR)" \
		"TENANT_ID=$(TENANT_ID) PROVIDER_API_URL=$(PROVIDER_API_URL) DATABASE_URL=$(DATABASE_URL) USER_SYNC_MS=$(USER_SYNC_MS) EMAIL_POLL_MS=$(EMAIL_POLL_MS) METRICS_LOG_MS=$(METRICS_LOG_MS) make discovery"
	@tmux split-window -h -t "$(TMUX_SESSION):run" -c "$(CURDIR)" \
		"WATCH_DB_INTERVAL=$(WATCH_DB_INTERVAL) make watch-db"
	@tmux split-window -v -t "$(TMUX_SESSION):run.1" -c "$(CURDIR)" \
		"START_USERS=$(START_USERS) TARGET_USERS=$(TARGET_USERS) STEP_USERS=$(STEP_USERS) RAMP_INTERVAL_SEC=$(RAMP_INTERVAL_SEC) make mock-ramp"
	@tmux select-layout -t "$(TMUX_SESSION):run" even-horizontal
	@tmux new-window -d -t "$(TMUX_SESSION):1" -n timer -c "$(CURDIR)" \
		"sleep $(TEST_DURATION_SEC); tmux list-panes -t $(TMUX_SESSION):run -F '#{pane_id}' | xargs -I{} tmux send-keys -t {} C-c; make down; echo '10m test finished'; sleep 2; tmux kill-session -t $(TMUX_SESSION) 2>/dev/null || true"
	@tmux select-window -t "$(TMUX_SESSION):run"
	@if [ "$(AUTO_ATTACH)" = "1" ]; then \
		if [ -n "$$TMUX" ]; then tmux switch-client -t "$(TMUX_SESSION)"; else tmux attach -t "$(TMUX_SESSION)"; fi; \
	else \
		echo "started tmux session: $(TMUX_SESSION)"; \
		echo "attach with: tmux attach -t $(TMUX_SESSION)"; \
	fi

test-10m-stop:
	@command -v tmux >/dev/null || { echo "tmux not found in PATH"; exit 1; }
	@if tmux has-session -t "$(TMUX_SESSION)" 2>/dev/null; then \
		tmux list-panes -a -t "$(TMUX_SESSION)" -F '#{pane_id}' | xargs -I{} tmux send-keys -t {} C-c; \
		tmux kill-session -t "$(TMUX_SESSION)"; \
		echo "stopped tmux session: $(TMUX_SESSION)"; \
	else \
		echo "tmux session $(TMUX_SESSION) not running"; \
	fi
	@$(MAKE) down
