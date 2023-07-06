# The `PostgresClusterInstance` Resource

`PostgresClusterInstance` is the cluster-scoped version of the
[`PostgresInstance`](postgres_instance.md) resource and is used almost exactly
the same way. However, since it is cluster-scoped, the `passwordSecretRef` must
reference a secret residing in the **operator namespace**. The operator
namespace is the namespace kompost runs in (defaults to `"kompost"`)

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

## Limiting Allowed Namespaces

By default, the `PostgresClusterInstance` can be referenced by
`PostgresDatabase` resources from any namespace. Access can be limited to a set
of namespaces throug the `kompost.chuge.li/allowed-namespaces` annotation. This
annotation can be set to a list of namespaces as regular expressions.

!!! note Start and End Anchors are added automatically 

    Note that Kompost wraps all regular expressions in `$` and `^` anchors if
    they aren't already.

### Examples

The following resource can be referenced by `PostgresDatabase` resources in
exactly two namespaces: `default` and `staging`.

```yaml
apiVersion: kompost.chuge.li/v1alpha1
kind: PostgresClusterInstance
metadata:
  name: staging-server
  namespace: default
  annotations:
    kompost.chuge.li/allowed-namespaces: "default, staging"
spec:
  hostname: postgres.svc
  port: 5432
  username: postgres
  passwordSecretRef:
    name: server-credentials
    key: password
```

The following resource can be referenced by `PostgresDatabase` resources in
namespace `staging`, any namespace starting with `test-` and any namespace
ending in `-alpha`.

```yaml
apiVersion: kompost.chuge.li/v1alpha1
kind: PostgresClusterInstance
metadata:
  name: staging-server
  namespace: default
  annotations:
    kompost.chuge.li/allowed-namespaces: "staging, test-.*, .*-alpha"
spec:
  hostname: postgres.svc
  port: 5432
  username: postgres
  passwordSecretRef:
    name: server-credentials
    key: password
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
