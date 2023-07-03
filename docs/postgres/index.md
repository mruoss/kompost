# Postgres Kompo

The Postgres Kompo manages databases inside your Postgres servers.

## Example

After installing Kompost, you need to tell it where to find your PostgreSQL
instance. You do this by applying a resource of kind `PostgresInstance` to
your cluster:

```yaml
apiVersion: kompost.chuge.li/v1alpha1
kind: PostgresInstance
metadata:
  name: app-database
  namespace: awesome-application
spec:
  hostname: postgres.svc
  port: 5432
  username: postgres
  passwordSecretRef:
    name: app-database-password
    key: DB_PASS
```
