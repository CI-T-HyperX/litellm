PROJECT_ROOT := $(realpath $(dir $(abspath $(lastword $(MAKEFILE_LIST))))../..)

# Test production
build-prod:
	@docker build -t litellm .

run-prod:
	@docker run --rm -p 4000:4000 \
	--name lite-llm-prod \
	-v $(PROJECT_ROOT)/config.yaml:/app/config.yaml \
	-e LITELLM_MASTER_KEY=your-secret-key \
	litellm --config=/app/config.yaml --port 4000

sh-prod:
	@docker exec -it lite-llm-prod /bin/bash

# Run build from .github/workflows/build-and-push-ecr.yml
run-wf:
	@docker run --rm -p 4000:4000 \
	--name litellm-dev \
	-v $(PROJECT_ROOT)/config.yaml:/app/config.yaml \
	-e LITELLM_MASTER_KEY=your-secret-key \
	litellm-dev:local --config=/app/config.yaml --port 4000