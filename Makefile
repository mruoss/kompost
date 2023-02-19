CLUSTER_NAME=kompost
KUBECONFIG_PATH?=./test/integration/cluster.yaml


test/integration/cluster.yaml:
	$(MAKE) delete.cluster create.cluster
	kind export kubeconfig --kubeconfig ${KUBECONFIG_PATH} --name "${CLUSTER_NAME}" 

.PHONY: test
test: test/integration/cluster.yaml
test: ## Run integration tests using k3d `make cluster`
	MIX_ENV=test mix compile
	MIX_ENV=test mix bonny.gen.manifest -o - | kubectl apply -f -
	kubectl config use-context kind-${CLUSTER_NAME}
	TEST_KUBECONFIG=${KUBECONFIG_PATH} mix test --include integration --cover

.PHONY: create.cluster
create.cluster: 
	kind create cluster --wait 600s --name "${CLUSTER_NAME}"

.PHONY: delete.cluster
delete.cluster:
	- kind delete cluster --kubeconfig ${KUBECONFIG_PATH} --name "${CLUSTER_NAME}"
	rm -f ${KUBECONFIG_PATH}