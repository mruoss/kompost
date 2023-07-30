# The `PostgresDatabase` Resource

The `PostgresDatabase` resource defines a database on your Postgres server.
By creating this resource on the cluster, you're telling Kompost to ensure
such a database exists on the server.

## Basic Usage

Once your [`PostgresInstance`](postgres_instance.md) or
[`PostgresClusterInstance`](postgres_cluster_instance.md) is set up and
connected, you can declare your database resources.

```yaml
apiVersion: kompost.chuge.li/v1alpha1
kind: PostgresDatabase
metadata:
  name: some-database
  namespace: default
spec:
  instanceRef:
    name: staging-server
```

## Connection Details

Once applied to the cluster, Kompost creates a database and **two users**. One
is called `inspector` having read-only access to the database, a second is one
called `app` with read-write access to it. For each user, a secret is created
which can be used in your deployments to pass the connection details to your
application. Check the resource status to see the usernames created and the
names of their secrets.

The name of the users and the name of the secrets holding the information can be
taken from the `PostgresDatabase` resource's status:

```bash
kubectl get pgdb -n default some-database -o jsonpath="{.status.users}" |jq
[
  {
    "secret": "psql-some-database-inspector",
    "username": "default_some_database_inspector"
  },
  {
    "secret": "psql-some-database-app",
    "username": "default_some_database_app"
  }
]
```

The generated secrets hold all the information your apps require to connect to the database. They look something like this:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: psql-some-database-app
  namespace: default
type: Opaque
data:
  DB_HOST: cG9zdGdyZXMuc3Zj
  DB_NAME: ZGVmYXVsdF9zb21lX2RhdGFiYXNl
  DB_PASS: cGFzc3dvcmQ=
  DB_PORT: MzE0MzY=
  DB_SSL: ZmFsc2U=
  DB_SSL_VERIFY: ZmFsc2U=
  DB_USER: ZGVmYXVsdF9zb21lX2RhdGFiYXNlX2FwcA==
```

## Database Naming Strategy

The field `databaseNamingStrategy` controls how the database name is derived
from the resource name. Possible values are `resource_name` and
`prefix_namespace`. The default strategy is `prefix_namespace`.

### Strategies

- `resource_name`: Use the resource name as database name
- `prefix_namespace`: Prefix the resource name with the namespace to get a
  cluster-wide unique name.

### Example

Taking the [basic usage example](#basic-usage) from above, the resulting
database on the server is named `default_some_database`.

```yaml
apiVersion: kompost.chuge.li/v1alpha1
kind: PostgresDatabase
metadata:
  name: some-database
  namespace: default
spec:
  instanceRef:
    name: staging-server
  databaseNamingStrategy: resource_name
```

The resulting database on the server is named `some_database`.

!!! warning Strategy resource_name can lead to conflicts

    Using the `resource_name` strategy can lead to conflicts. If you define
    `PostgresDatabase` resources with the same name in different namespaces,
    both resources would control the same database on the server. Therefore the
    default strategy is `prefix_namespace`

## Deletion Policy - Abandoning Underlying Resources

When using Kompost on a live environment, you might want to protect the
underlying resources (i.e. the databases, users, etc.) from accidental deletion
if the Kubernetes resource gets deleted. That's the purpose of the
`kompost.chuge.li/deletion-policy` annotation. When set to `abandon`, it prevents
Kompost form adding the finalizers to your resource.

```yaml
apiVersion: kompost.chuge.li/v1alpha1
kind: PostgresDatabase
metadata:
  name: some-database
  namespace: default
  annotations:
    kompost.chuge.li/deletion-policy: abandon # <-- underlying resources are abandoned (not deleted) when this resource gets deleted
spec:
  instanceRef:
    name: staging-server
```

## Database Creation Parameters

Postgres takes [optional
parameters](https://www.postgresql.org/docs/current/sql-createdatabase.html)
when creating a database. Some of these parameters are supported by Kompost and
can be passed in `spec.params`.

!!! note Creation params cannot be changed

    These parameters are only used when the database is created. Kompost therefore denies requests to change them on an existing resource.

The currently supported parameters are:

- `template`
- `encoding`
- `locale`
- `lc_collate`
- `lc_ctype`
- `connection_limit`
- `is_template`

```yaml
apiVersion: kompost.chuge.li/v1alpha1
kind: PostgresDatabase
metadata:
  name: some-database
  namespace: default
spec:
  instanceRef:
    name: staging-server
  params:
    locale: en_US.UTF8
    connection_limit: 100
```
