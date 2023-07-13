# Kompost

https://kompost.chuge.li

Kompost is a Kubernetes operator providing self-service management for
developers to install infrastructure resources.

It is meant to be installed by operators running their applications on
Kubernetes to give their development teams a way to create certain
infrastructure resources by applying Kubernetes resources to their clusters or
committing to their infra repo when using ArgoCD.

Kompost was written in Elixir, using [`bonny`](https://hexdocs.pm/bonny), a Kubernetes development
framework written in Elixir.

## Usage Example

If you're in charge of managing infrastructure like setting up and maintaining
postgres instances you can install **Kompost** to give your developer teams a
way to install databases on those instances on their own.

## Installing Kompost

To install Kompost, just download the manifest from the [release
page](https://github.com/mruoss/kompost/releases) and apply it to your cluster.

## Documentation

Find the documentation on https://kompost.chuge.li
