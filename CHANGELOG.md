# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.2.0] - 2023-02-27

### Added

- Temporal Kompo was added. Used to create resources in a [Temporal](https://temporal.io) Cluster.

## [0.1.5] - 2023-02-27

### Fixed

- `PostgresInstance`, `PostgresDatabase` - Misconfigured RBAC rules prevented user secrets from being created.

## [0.1.4] - 2023-02-26

### Fixed

- `PostgresDatabase` - duplicate users were added to resource status infinitely

### Added

- `PostgresDatabase` - Added printer columns to resource
- `PostgresInstance`, `PostgresDatabase` - Warning logs

### Changed

- Upgreaded `bonny` to v1.1.1

## [0.1.3] - 2023-02-25

- Remove defaults from CRD manifests (stop fighting ArgoCD)

## [0.1.2] - 2023-02-25

### Fixed

- Disable TLS peer verification as most likely we're connecting to an IP address.

## [0.1.1] - 2023-02-25

### Changed

- Watching all namespaces now

## [0.1.0] - 2023-02-25

Initial release with Postgres Kompo.

##
