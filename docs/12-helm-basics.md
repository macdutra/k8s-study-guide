# Helm - Kubernetes Package Manager

Complete guide to Helm for CKA preparation.

## Table of Contents

- [Overview](#overview)
- [Installation](#installation)
- [Basic Commands](#basic-commands)
- [Charts](#charts)
- [Repositories](#repositories)
- [Values & Templating](#values--templating)
- [Exam Tips](#exam-tips)

## Overview

Helm is the package manager for Kubernetes, allowing you to define, install, and upgrade complex Kubernetes applications.

### Key Concepts

- **Chart**: Package of Kubernetes resources
- **Release**: Instance of a chart running in a cluster
- **Repository**: Collection of charts
- **Values**: Configuration parameters for a chart

### Why Helm?

- ✅ **Package Management**: Install complete applications with one command
- ✅ **Versioning**: Track and rollback releases
- ✅ **Templating**: Dynamic manifest generation
- ✅ **Dependency Management**: Handle complex applications

## Installation

### Install Helm on macOS

```bash
# Using Homebrew (recommended)
brew install helm

# Verify installation
helm version

# Initialize (Helm 3 doesn't need Tiller)
helm repo add stable https://charts.helm.sh/stable
helm repo update
```

### Verify Helm is Working

```bash
# List repositories
helm repo list

# Search for charts
helm search repo nginx

# Check installed releases
helm list
```

## Basic Commands

### Install a Chart

```bash
# Install nginx from bitnami repo
helm repo add bitnami https://charts.bitnami.com/bitnami

# Install with default values
helm install my-nginx bitnami/nginx

# Install with custom release name
helm install web-server bitnami/nginx

# Install in specific namespace
helm install my-nginx bitnami/nginx --namespace production --create-namespace

# Install with custom values
helm install my-nginx bitnami/nginx --set service.type=NodePort
```

### List Releases

```bash
# List all releases
helm list

# List in all namespaces
helm list --all-namespaces

# List in specific namespace
helm list -n production

# Show all releases (including failed)
helm list --all
```

### Upgrade Release

```bash
# Upgrade with new values
helm upgrade my-nginx bitnami/nginx --set replicaCount=3

# Upgrade to specific version
helm upgrade my-nginx bitnami/nginx --version 15.0.0

# Upgrade with values file
helm upgrade my-nginx bitnami/nginx -f custom-values.yaml
```

### Rollback Release

```bash
# List release history
helm history my-nginx

# Rollback to previous version
helm rollback my-nginx

# Rollback to specific revision
helm rollback my-nginx 2

# Rollback and wait
helm rollback my-nginx --wait
```

### Uninstall Release

```bash
# Uninstall release
helm uninstall my-nginx

# Uninstall and keep history
helm uninstall my-nginx --keep-history

# Uninstall from specific namespace
helm uninstall my-nginx -n production
```

## Charts

### Chart Structure

```
mychart/
  Chart.yaml          # Chart metadata
  values.yaml         # Default configuration
  templates/          # Kubernetes manifests
    deployment.yaml
    service.yaml
    _helpers.tpl      # Template helpers
  charts/             # Dependency charts
  README.md
```

### Create a Chart

```bash
# Create new chart
helm create mychart

# Check chart structure
tree mychart

# Validate chart
helm lint mychart

# Package chart
helm package mychart

# Install local chart
helm install my-release ./mychart
```

### Chart.yaml Example

```yaml
apiVersion: v2
name: myapp
description: A Helm chart for my application
type: application
version: 1.0.0
appVersion: "1.0"
keywords:
  - web
  - nginx
maintainers:
  - name: Your Name
    email: you@example.com
```

## Repositories

### Manage Repositories

```bash
# Add repository
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo add stable https://charts.helm.sh/stable

# List repositories
helm repo list

# Update repositories
helm repo update

# Remove repository
helm repo remove stable

# Search in repository
helm search repo nginx

# Search Hub (Artifact Hub)
helm search hub wordpress
```

### Popular Repositories

```bash
# Bitnami (most popular)
helm repo add bitnami https://charts.bitnami.com/bitnami

# Prometheus
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts

# Grafana
helm repo add grafana https://grafana.github.io/helm-charts

# Ingress NGINX
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx

# Update all repos
helm repo update
```

## Values & Templating

### Using Values

```bash
# Show default values
helm show values bitnami/nginx

# Install with custom values
helm install my-nginx bitnami/nginx \
  --set service.type=NodePort \
  --set replicaCount=3

# Install with values file
cat > custom-values.yaml <<EOF
replicaCount: 2
service:
  type: LoadBalancer
  port: 8080
resources:
  limits:
    cpu: 200m
    memory: 256Mi
EOF

helm install my-nginx bitnami/nginx -f custom-values.yaml
```

### Template Functions

```yaml
# values.yaml
replicaCount: 2
image:
  repository: nginx
  tag: "1.21"

# templates/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ .Release.Name }}-nginx
spec:
  replicas: {{ .Values.replicaCount }}
  template:
    spec:
      containers:
      - name: nginx
        image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
```

### Dry Run (Template Preview)

```bash
# Render templates without installing
helm template my-nginx bitnami/nginx

# Render with custom values
helm template my-nginx bitnami/nginx --set replicaCount=5

# Debug installation
helm install my-nginx bitnami/nginx --dry-run --debug

# Show manifest that would be applied
helm get manifest my-nginx
```

## Practical Examples

### Example 1: Install WordPress

```bash
# Add bitnami repo
helm repo add bitnami https://charts.bitnami.com/bitnami

# Install WordPress
helm install my-blog bitnami/wordpress \
  --set wordpressUsername=admin \
  --set wordpressPassword=password123 \
  --set service.type=NodePort

# Get WordPress URL
kubectl get svc my-blog-wordpress
```

### Example 2: Install Prometheus

```bash
# Add repo
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts

# Install Prometheus
helm install prometheus prometheus-community/prometheus \
  --namespace monitoring \
  --create-namespace

# Check installation
kubectl get pods -n monitoring
helm list -n monitoring
```

### Example 3: Upgrade with New Values

```bash
# Current installation
helm install myapp bitnami/nginx --set replicaCount=2

# Upgrade to 3 replicas
helm upgrade myapp bitnami/nginx --set replicaCount=3

# Verify upgrade
kubectl get deployments
helm history myapp
```

## Helm vs kubectl

### Same Task - Different Approaches

**With kubectl:**

```bash
# Create deployment
kubectl create deployment nginx --image=nginx

# Expose service
kubectl expose deployment nginx --port=80 --type=LoadBalancer

# Scale
kubectl scale deployment nginx --replicas=3

# Delete
kubectl delete deployment nginx
kubectl delete service nginx
```

**With Helm:**

```bash
# Install (deployment + service)
helm install nginx bitnami/nginx

# Upgrade (scale to 3)
helm upgrade nginx bitnami/nginx --set replicaCount=3

# Uninstall (removes everything)
helm uninstall nginx
```

## Troubleshooting

### Release Failed

```bash
# Check status
helm status my-release

# Get manifest
helm get manifest my-release

# Check values used
helm get values my-release

# View history
helm history my-release

# Rollback failed release
helm rollback my-release
```

### Chart Issues

```bash
# Validate chart syntax
helm lint mychart

# Debug template rendering
helm template mychart --debug

# Dry run installation
helm install test mychart --dry-run --debug

# Check hooks
helm get hooks my-release
```

## Exam Tips

### Helm on CKA Exam

**Important:** Helm knowledge for CKA is **basic**. Focus on:
- ✅ Installing charts (`helm install`)
- ✅ Listing releases (`helm list`)
- ✅ Upgrading releases (`helm upgrade`)
- ✅ Uninstalling releases (`helm uninstall`)
- ❌ Creating charts (not required)
- ❌ Advanced templating (not required)

### Essential Commands for Exam

```bash
# Install
helm install <release> <chart>

# List
helm list

# Upgrade
helm upgrade <release> <chart>

# Rollback
helm rollback <release>

# Uninstall
helm uninstall <release>

# Get values
helm show values <chart>
```

### Quick Installation

```bash
# One-liner: repo add, update, install
helm repo add bitnami https://charts.bitnami.com/bitnami && \
helm repo update && \
helm install myapp bitnami/nginx
```

## Quick Reference

### Common Commands

```bash
# Repository management
helm repo add <name> <url>
helm repo list
helm repo update
helm repo remove <name>

# Release management
helm install <release> <chart>
helm list
helm upgrade <release> <chart>
helm rollback <release>
helm uninstall <release>
helm status <release>

# Chart operations
helm create <chart>
helm package <chart>
helm lint <chart>

# Information
helm show chart <chart>
helm show values <chart>
helm show readme <chart>

# Advanced
helm template <chart>
helm get manifest <release>
helm get values <release>
helm history <release>
```

### Helm 2 vs Helm 3

| Feature | Helm 2 | Helm 3 |
|---------|--------|--------|
| **Tiller** | Required | Not needed ✅ |
| **Security** | Less secure | More secure ✅ |
| **Namespaces** | Optional | Required ✅ |
| **Installation** | Complex | Simple ✅ |

**For CKA:** Only Helm 3 is relevant (Tiller-free).

## Summary

**Helm** simplifies Kubernetes application management through:
- Package management (charts)
- Version control (releases)
- Configuration management (values)
- Easy rollbacks

**For the exam:**
- ✅ Know basic installation and management
- ✅ Understand repositories
- ✅ Use `--dry-run` for testing
- ❌ Don't worry about chart creation

**Practice these:**
```bash
helm install myapp bitnami/nginx
helm list
helm upgrade myapp bitnami/nginx --set replicaCount=3
helm rollback myapp
helm uninstall myapp
```

---

**Back to**: [Main README](../README.md) | [Previous: Cluster Troubleshooting](11-cluster-troubleshooting.md) | [Next: ConfigMap & Secrets](13-configmap-secrets.md)
