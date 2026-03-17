PROJECT_ROOT := $(realpath $(dir $(abspath $(lastword $(MAKEFILE_LIST))))../..)

# Compose stack for LiteLLM, Prometheus and Grafana
up:
	@docker compose up -d --build

down:
	@docker compose down --remove-orphans

# Development
sh-prod:
	@docker exec -it litellm-dev /bin/bash

# Run build from .github/workflows/build-and-push-ecr.yml
run-wf:
	@docker run --rm -p 4000:4000 \
	--name litellm-dev \
	-v $(PROJECT_ROOT)/config.yaml:/app/config.yaml \
	-e LITELLM_MASTER_KEY=your-secret-key \
	litellm-dev:local --config=/app/config.yaml --port 4000

get-ip:
	@docker network inspect flow_monitoring | jq '.[].IPAM.Config | .[].Gateway'