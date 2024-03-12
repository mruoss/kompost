# Kompost

To regenerate this document, from the root of this chart directory run:
```shell
docker run --rm --volume "$(pwd):/helm-docs" -u $(id -u) jnorwood/helm-docs:latest
```

![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![Version: 1.0.0](https://img.shields.io/badge/Version-1.0.0-informational?style=flat-square)

A Helm chart for Kompost

## TL;DR
```bash
helm install --version 1.0.0 -n kompost kompost oci://ghcr.io/mruoss/charts/kompost
```

## Installing the Chart
To install the chart with the release name `kompost`:
```bash
helm install --version 1.0.0 -n kompost kompost oci://ghcr.io/mruoss/charts/kompost
```

## Uninstalling the Chart
To uninstall the `kompost` deployment:
```bash
helm uninstall kompost
```
The command removes all the Kubernetes components associated with the chart and deletes the release.

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| affinity | object | `{}` |  |
| containerSecurityContext.capabilities.drop[0] | string | `"ALL"` |  |
| containerSecurityContext.readOnlyRootFilesystem | bool | `true` |  |
| containerSecurityContext.runAsNonRoot | bool | `true` |  |
| containerSecurityContext.runAsUser | int | `1001` |  |
| fullnameOverride | string | `""` | String to fully override `"kompost.fullname"` |
| image.pullPolicy | string | `"IfNotPresent"` | imagePullPolicy applied to the containers |
| image.repository | string | `"ghcr.io/mruoss/kompost"` | Kompost container image repository |
| image.tag | string | `""` | Overrides the image tag whose default is the chart appVersion. |
| imagePullSecrets | list | `[]` | Secrets with credentials to pull images from a private registry |
| kompos.postgres.enabled | bool | `true` | Install CRDS for and run postgres kompo |
| kompos.temporal.enabled | bool | `true` | Install CRDS for and run temporal kompo |
| nameOverride | string | `"kompost"` | Provide a name in place of `kompost` |
| nodeSelector | object | `{}` |  |
| podAnnotations | object | `{}` |  |
| podSecurityContext.runAsNonRoot | bool | `true` |  |
| podSecurityContext.runAsUser | int | `1001` |  |
| replicaCount | int | `1` | The number of pods to run |
| resources | object | `{}` |  |
| revisionHistoryLimit | int | `10` | The number of revisions to keep in history |
| serviceAccount.annotations | object | `{}` | Annotations to add to the service account |
| serviceAccount.create | bool | `true` | Specifies whether a service account should be created |
| serviceAccount.name | string | `""` | If not set and create is true, a name is generated using the fullname template |
| tolerations | list | `[]` |  |
| webhook.certManager.addInjectorAnnotations | bool | `true` | Automatically add the cert-manager.io/inject-ca-from annotation to the webhooks and CRDs. As long as you have the cert-manager CA Injector enabled, this will automatically setup your webhook's CA to the one used by cert-manager. See https://cert-manager.io/docs/concepts/ca-injector |
| webhook.certManager.cert.annotations | object | `{}` | Add extra annotations to the Certificate resource. |
| webhook.certManager.cert.create | bool | `true` | Create a certificate resource within this chart. See https://cert-manager.io/docs/usage/certificate/ |
| webhook.certManager.cert.duration | string | `""` | Set the requested duration (i.e. lifetime) of the Certificate. See https://cert-manager.io/docs/reference/api-docs/#cert-manager.io/v1.CertificateSpec |
| webhook.certManager.cert.issuerRef | object | `{"group":"cert-manager.io","kind":"Issuer","name":"my-issuer"}` | For the Certificate created by this chart, setup the issuer. See https://cert-manager.io/docs/reference/api-docs/#cert-manager.io/v1.IssuerSpec |
| webhook.certManager.cert.renewBefore | string | `""` | How long before the currently issued certificate’s expiry cert-manager should renew the certificate. See https://cert-manager.io/docs/reference/api-docs/#cert-manager.io/v1.CertificateSpec Note that renewBefore should be greater than .webhook.lookaheadInterval since the webhook will check this far in advance that the certificate is valid. |
| webhook.certManager.enabled | bool | `false` | Enabling cert-manager support will disable the built in secret creation and switch to using cert-manager (installed separately) to automatically issue and renew the webhook certificate. This chart does not install cert-manager for you, See https://cert-manager.io/docs/ |