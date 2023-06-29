CLUSTER_NAME=kompost-test
ELIXIR_IMAGE=hexpm/elixir:1.15.0-erlang-26.0.1-alpine-3.18.2
ERLANG_IMAGE=hexpm/erlang:26.0.1-alpine-3.18.2

.PHONY: docker_compose
docker_compose:
	docker-compose -f test/integration/docker-compose.yml up -d --remove-orphans

.PHONY: test
#test: docker_compose
test: ## Run integration tests using k3d `make cluster`
	MIX_ENV=test mix compile
	MIX_ENV=test mix kompost.gen.periphery
	MIX_ENV=test mix kompost.gen.manifest
	mix test --include integration --cover

.PHONY: e2e
e2e: SHELL := /bin/bash
e2e:
	MIX_ENV=test mix compile
	docker buildx build --build-arg ELIXIR_IMAGE=${ELIXIR_IMAGE} --build-arg ERLANG_IMAGE=${ERLANG_IMAGE} -t kompost:e2e --load .
	kind load docker-image --name ${CLUSTER_NAME} kompost:e2e
	MIX_ENV=test mix kompost.gen.periphery
	kubectl config use-context kind-${CLUSTER_NAME} 
	MIX_ENV=prod mix compile
	MIX_ENV=prod mix kompost.gen.manifest --image kompost:e2e --out - | kubectl apply -f -
	POSTGRES_HOST=postgres.postgres.svc.cluster.local TEMPORAL_HOST=temporal.temporal.svc.cluster.local mix test --include integration --include e2e --no-start --cover

