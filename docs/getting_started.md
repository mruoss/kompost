# Getting Started

## Installation

Each release comes with a set of [container
images](https://github.com/mruoss/kompost/pkgs/container/kompost) (debian, slim
and alpine). Download the manifest from the [release
page](https://github.com/mruoss/kompost/releases/tag/v0.2.3) and apply it to
your cluster:

```bash
curl -L https://github.com/mruoss/kompost/releases/download/v0.3.0/manifest-alpine.yaml | kubectl apply -f -
```

This installs the CRDs, creates a namespace `kompost` and installs Kompost inside it.
Once installed, make sure the operator runs:

```
kubectl describe -n kompost deploy/kompost
```

## Helm Chart

There is a helm chart you can use to install Kompost. Checkout the templates and
default values on [Artifact
Hub](https://artifacthub.io/packages/helm/kompost/kompost)

```
helm template -n kompost kompost oci://ghcr.io/mruoss/kompost --version 0.1.0
```

## Work with Kompos

Once the operator is installed, you can work with the Kompos. Check out their
documentation:

- [Postgres](postgres)
- [Temporal](temporal)
