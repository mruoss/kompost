# Kompost

Kompost is a Kubernetes operator providing self-service management for
developers ton install infrastructure resources.

It is meant to be installed by operators running their applications on
Kubernetes to give their development teams a way to create certain
infrastructure resources by applying Kubernetes resources to their clusters or
committing to their infra repo when using ArgoCD.

## Usage Example

If you're in charge of managing infrastructure like setting up and maintaining
postgres instances you can install **Kompost** to give your developer teams a
way to install databases on those instances on their own.

## Installing Kompost

To install Kompost, just download the manifest from the release page and apply
it to your cluster.

## Kompos

Kompos are the compontens that can be managed through Kompost. At the moment
only a single Kompo is implemented:

- **Postgres** - Allows to create PostgreSQL databases with their users on
  existing instances

### Postgres - Usage

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
  plainPassword: password
```

Once created, Kompost will try to connect to it. Check the conditions in the
resource status.

```sh
$ kubectl describe pginst app-database

[...]
Status:
  Conditions:
    Last Heartbeat Time:   2023-02-26T18:21:35.683152Z
    Last Transition Time:  2023-02-26T18:21:16.417437Z
    Message:               Connection to database was established
    Status:                True
    Type:                  Connected
    Last Heartbeat Time:   2023-02-26T18:21:35.683135Z
    Last Transition Time:  2023-02-26T18:21:16.343485Z
    Status:                True
    Type:                  Credentials
    Last Heartbeat Time:   2023-02-26T18:21:35.696358Z
    Last Transition Time:  2023-02-26T18:21:16.434984Z
    Message:               The conneted user has the required privileges
    Status:                True
    Type:                  Privileged
  Observed Generation:     1
Events:
  Type     Reason      Age   From     Message
  ----     ------      ----  ----     -------
  Warning  Failed Add  24s   kompost  tcp connect (postgres.svc:5432): connection refused - :econnrefused

```

#### Passing the password in a secret

It is recommended to pass the connection password in a secret. Assuming you have
a secret `app-database-password` holding the password in `.data.PW_PASS`, you
can pass it to Kompost by replacing `plainPassword` with `passwordSecretRef`:

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

#### Creating a database

Now your developers can create databases by applying a resource of kind
`PostgresDatabase` to the cluster:

```yaml
apiVersion: kompost.chuge.li/v1alpha1
kind: PostgresDatabase
metadata:
  name: staging
  namespace: awesome-application
spec:
  instanceRef:
    name: app-database
    namespace: awesome-application # optional if in the same namespace
```

Once applied to the cluster, Kompost creates a database and two users, one
called `inspector` having read-only access to the database, a second one called
`app` with read-write access to it. For each user, a secret is created which can
be used in your deployments to pass the connection details to your application.
Check the resource status to see the usernames created and the names of their
secrets.

```sh
$ kubectl describe pgdb staging

[...]
Status:
  Conditions:
    Last Heartbeat Time:   2023-02-26T19:23:43.302340Z
    Last Transition Time:  2023-02-26T18:52:53.132978Z
    Message:               Application user was created successfully.
    Status:                True
    Type:                  AppUser
    Last Heartbeat Time:   2023-02-26T19:23:43.253022Z
    Last Transition Time:  2023-02-26T19:23:43.253022Z
    Message:               Connected to the referenced PostgreSQL instance.
    Status:                True
    Type:                  Connection
    Last Heartbeat Time:   2023-02-26T19:23:43.262621Z
    Last Transition Time:  2023-02-26T18:52:53.089959Z
    Message:               The database "default_test" was created on the PostgreSQL instance
    Status:                True
    Type:                  Database
    Last Heartbeat Time:   2023-02-26T19:23:43.317226Z
    Last Transition Time:  2023-02-26T18:52:53.149431Z
    Message:               Inspector user was created successfully.
    Status:                True
    Type:                  InspectorUser
  Observed Generation:     1
  sql_db_name:             default_test
  Users:
    Secret:    psql-test-inspector
    Username:  default_test_inspector
    Secret:    psql-test-app
    Username:  default_test_app
```
