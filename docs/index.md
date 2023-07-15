# Kompost

Kompost is a Kubernetes operator providing self-service management for
developers to install infrastructure resources.

It is meant to be installed by infrastructure admins running their applications
on Kubernetes. Once installed it prvides development teams a declarateive way of
creating infrastructure resources by applying Kubernetes resources to their
clusters or committing to their infra repo when using GitOps.

## Links

- [:simple-github: GitHub Repository](https://github.com/mruoss/kompost)
- [:simple-readthedocs: Documentation](https://kompost.chuge.li)
- [:simple-artifacthub: Helm Chart on ArtifactHUB](https://artifacthub.io/packages/helm/kompost/kompost)

## Kompos

Kompost comes with a set of components, aka. Kompos. Kompos are independent
from each other. Each one serves its own set of CRDs and provides a service
on its own.

The most mature Kompo at this moment is [Postgres](postgres). Besides, there
is the [Temporal](temporal) Kompo currently being developed.
