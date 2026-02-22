.PHONY: up down clean logs test

up:
	bash scripts/docker_up.sh

down:
	bash scripts/docker_down.sh

clean:
	bash scripts/docker_clean.sh

logs:
	bash scripts/docker_logs.sh

test:
	bash scripts/test_all.sh
