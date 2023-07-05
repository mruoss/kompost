# The `PostgresClusterInstance` Resource

This resource is used almost exactly like the
[`PostgresInstance`](postgres_instance.md). But since it is cluster-scoped, the
`passwordSecretRef` must reference a secret from the **operator namespace**. The
operator namespace is the namespace kompost runs in (defaults to `"kompost"`)

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: server-credentials
  namespace: kompost
stringData:
  password: secure-password
```

The `PostgresClusterInstance` then references the secret in `spec.passwordSecretRef`:

```yaml
apiVersion: kompost.chuge.li/v1alpha1
kind: PostgresClusterInstance
metadata:
  name: staging-server
  namespace: default
spec:
  hostname: postgres.svc
  port: 5432
  username: postgres
  passwordSecretRef:
    name: server-credentials
    key: password
  ssl:
    enabled: false
```

## Referencing Cluster Intances

When declaring the `PostgresDatabase` resource, use the field `.spec.clusterInstanceRef`
to reference a cluster instance:

```yaml
apiVersion: kompost.chuge.li/v1alpha1
kind: PostgresDatabase
metadata:
  name: staging-server
  namespace: default
spec:
  clusterInstanceRef:
    name: app-database
```
