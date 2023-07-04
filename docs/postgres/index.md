# Postgres Kompo

The Postgres Kompo manages databases inside your Postgres servers.

In order to use it, you need a running Postgres server and the information about
how to connect to it using a superadmin account. You then declare databases to
be created on that server by this operator.

## How it Works

The Postgres Kompo comes with [`PostgresInstance`](postgres_instance.md) and
[`PostgresClusterInstance`](postgres_cluster_instance.md) CRDs which serve as
connectors to your Postgres server.

The `PostgresDatabase` CRD defines a database to be created inside the instance
referenced by `.spec.instanceRef` or `.spec.clusterInstanceRef` respectively.

The operator uses the information from the instance resource to connect to
the server in order to create the requested database.

## Reconciliation

In case the state in the target (the Postgres server) diverges, Kompost tries to
reconcile it. E.g. if a database gets deleted on the cluster, Kompost recreates
it. However, Kompost does not backup and restore schemas and/or data.
