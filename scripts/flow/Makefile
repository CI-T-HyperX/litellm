PROJECT_ROOT := $(realpath $(dir $(abspath $(lastword $(MAKEFILE_LIST))))../..)
FLOW_DIR     := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
JMETER_DIR   := $(FLOW_DIR)jmeter

# Compose stack for LiteLLM, Prometheus and Grafana
up:
	@docker compose up -d --build

down:
	@docker compose down --remove-orphans

get-ip:
	@docker network inspect flow_monitoring | jq '.[].IPAM.Config | .[].Gateway'

# Development
sh-prod:
	@docker exec -it litellm-dev /bin/bash

# Run performance tests using JMeter
performance-tests:
	$(eval RUN_ID := $(shell date +%Y%m%d_%H%M%S))
	@mkdir -p $(JMETER_DIR)/report/$(RUN_ID)
	@docker run --rm --network host \
		-v $(JMETER_DIR):/jmeter \
		justb4/jmeter:5.5 \
		-n \
		-t /jmeter/latency-probe.jmx \
		-l /jmeter/report/$(RUN_ID)/results.jtl \
		-e \
		-o /jmeter/report/$(RUN_ID)

# Run build from .github/workflows/build-and-push-ecr.yml
run-wf:
	@docker run --rm -p 4000:4000 \
	--name litellm-dev \
	-v $(PROJECT_ROOT)/config.yaml:/app/config.yaml \
	-e LITELLM_MASTER_KEY=your-secret-key \
	litellm-dev:local --config=/app/config.yaml --port 4000

# Fetch origin, reset local develop-flow branch to match remote, and verify sync
dev-sync:
	@bash $(dir $(abspath $(lastword $(MAKEFILE_LIST))))sync_develop_flow.sh
