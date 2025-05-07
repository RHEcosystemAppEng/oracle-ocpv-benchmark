# Oracle Observability & Grafana Setup on OpenShift

This guide provides step-by-step instructions to set up [Oracle Observability exporter](https://github.com/oracle/oracle-db-appdev-monitoring) and Grafana on an OpenShift cluster for monitoring Oracle database metrics.

The Oracle Observability exporter collects metrics from an Oracle database and exposes them in a Prometheus-compatible format. Grafana, in turn, is used to visualize these metrics in a customizable dashboard.

This setup is ideal for platform engineers, DBAs, and developers who want to integrate Oracle database monitoring into their Kubernetes-native observability stack using Prometheus and Grafana.

## Prerequisites

- Access to an OpenShift cluster with cluster-admin or sufficient permissions.
- A running Oracle database (on-cluster or external).
- OpenShift CLI (`oc`) installed and authenticated.


## Setting up the Oracle Observability pod
An [open-source exporter](https://github.com/oracle/oracle-db-appdev-monitoring) that extracts Oracle database metrics and exposes them via an HTTP endpoint for Prometheus scraping.

Please find the instructions to set up the [Oracle Observability exporter](./setup-oracle-exporter.md).

## Setting up the grafana dashboards

Please find the instructions to set up the [Grafana instance and dashboards](./setup-grafana.md).

## Generating the AWR report

Please find the instructions to generate the [AWR report](./generating-awr-report) for oracle RAC. This document provides detailed explanation required to understand oracle rac snapshots.