# Getting Started

## Installation

Each release comes with a set of [container
images](https://github.com/mruoss/kompost/pkgs/container/kompost) (debian, slim
and alpine). Download the manifest from the [release
page](https://github.com/mruoss/kompost/releases/tag/v0.2.3) and apply it to
your cluster:

```bash
curl -L https://github.com/mruoss/kompost/releases/download/v0.2.3/manifest-alpine.yaml | kubectl apply -f -
```

This installs the CRDs, creates a namespace `kompost` and installs Kompost inside it.
Once installed, make sure the operator runs:

```
kubectl describe -n kompost deploy/kompost
```

## Helm Chart

There is no helm chart for this operator at the moment.

## Next Step

Start using Kompos.
