# The `PostgresDatabase` Resource

The `PostgresDatabase` resource defines a database on your Postgres server.
By creating this resource on the cluster, you're telling Kompost to ensure
such a database exists on the server.

## Usage

Once your [`PostgresInstance`](postgres_instance.md) or
[`PostgresClusterInstance`](postgres_cluster_instance.md) is set up and
connected, you can declare your database resources.
