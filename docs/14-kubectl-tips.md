# kubectl Tips & Tricks - CKA Exam Efficiency

Complete guide to kubectl productivity for CKA exam success.

## Table of Contents

- [Overview](#overview)
- [Imperative Commands](#imperative-commands)
- [Dry Run & Generate YAML](#dry-run--generate-yaml)
- [Shortcuts & Aliases](#shortcuts--aliases)
- [Powerful Queries](#powerful-queries)
- [Exam Speed Tips](#exam-speed-tips)
- [Common Patterns](#common-patterns)

## Overview

In the CKA exam, **speed matters**. Mastering kubectl imperative commands and shortcuts can save you 30-40% of your time.

### Why This Matters

- ⏱️ **Time Pressure**: 2 hours for 15-20 tasks
- ⚡ **Efficiency**: Imperative > YAML for simple tasks
- 🎯 **Accuracy**: Less typing = fewer errors
- 💡 **Strategy**: Know when to use imperative vs declarative

## Imperative Commands

### Pod Creation

```bash
# Basic pod
kubectl run nginx --image=nginx

# With port
kubectl run nginx --image=nginx --port=80

# With labels
kubectl run nginx --image=nginx --labels="app=web,env=prod"

# With command
kubectl run busybox --image=busybox -- sleep 3600

# With args
kubectl run busybox --image=busybox -- echo "hello world"

# In specific namespace
kubectl run nginx --image=nginx -n production

# With restart policy
kubectl run nginx --image=nginx --restart=Never  # Pod (not deployment)

# With resource limits
kubectl run nginx --image=nginx --requests='cpu=100m,memory=256Mi' --limits='cpu=200m,memory=512Mi'
```

### Deployment Creation

```bash
# Basic deployment
kubectl create deployment nginx --image=nginx

# With replicas
kubectl create deployment nginx --image=nginx --replicas=3

# With port
kubectl create deployment nginx --image=nginx --port=80

# Scale existing
kubectl scale deployment nginx --replicas=5

# Set image (update)
kubectl set image deployment/nginx nginx=nginx:1.21
```

### Service Creation

```bash
# Expose deployment
kubectl expose deployment nginx --port=80

# Expose with type
kubectl expose deployment nginx --port=80 --type=NodePort

# Expose with target port
kubectl expose deployment nginx --port=80 --target-port=8080

# Expose pod
kubectl expose pod nginx --port=80

# Create service directly
kubectl create service clusterip nginx --tcp=80:80
kubectl create service nodeport nginx --tcp=80:80
kubectl create service loadbalancer nginx --tcp=80:80
```

### ConfigMap & Secret

```bash
# ConfigMap from literal
kubectl create configmap app-config --from-literal=key=value --from-literal=foo=bar

# ConfigMap from file
kubectl create configmap app-config --from-file=config.properties

# ConfigMap from directory
kubectl create configmap app-config --from-file=config/

# Secret from literal
kubectl create secret generic db-secret --from-literal=username=admin --from-literal=password=pass123

# TLS secret
kubectl create secret tls my-tls --cert=tls.crt --key=tls.key

# Docker registry secret
kubectl create secret docker-registry my-reg --docker-server=server --docker-username=user --docker-password=pass
```

### Namespace

```bash
# Create namespace
kubectl create namespace production

# Set default namespace
kubectl config set-context --current --namespace=production

# Run in specific namespace
kubectl run nginx --image=nginx -n production
```

## Dry Run & Generate YAML

### Dry Run Modes

```bash
# Client-side dry run (fast, local validation)
kubectl run nginx --image=nginx --dry-run=client

# Server-side dry run (validates against API server)
kubectl run nginx --image=nginx --dry-run=server

# Generate YAML without creating
kubectl run nginx --image=nginx --dry-run=client -o yaml

# Generate and save to file
kubectl run nginx --image=nginx --dry-run=client -o yaml > pod.yaml
```

### Common YAML Generation Patterns

```bash
# Pod YAML
kubectl run nginx --image=nginx --dry-run=client -o yaml > pod.yaml

# Deployment YAML
kubectl create deployment nginx --image=nginx --dry-run=client -o yaml > deployment.yaml

# Service YAML
kubectl create service clusterip nginx --tcp=80:80 --dry-run=client -o yaml > service.yaml

# ConfigMap YAML
kubectl create configmap app-config --from-literal=key=value --dry-run=client -o yaml > configmap.yaml

# Secret YAML
kubectl create secret generic db-secret --from-literal=password=pass123 --dry-run=client -o yaml > secret.yaml
```

### Generate, Edit, Apply Pattern

```bash
# Generate template
kubectl create deployment nginx --image=nginx --dry-run=client -o yaml > deploy.yaml

# Edit file
vim deploy.yaml
# (modify replicas, add resources, etc.)

# Apply
kubectl apply -f deploy.yaml

# Or one-liner
kubectl create deployment nginx --image=nginx --dry-run=client -o yaml | \
  sed 's/replicas: 1/replicas: 3/' | kubectl apply -f -
```

## Shortcuts & Aliases

### Built-in Short Names

```bash
# Resource short names
kubectl get po          # pods
kubectl get deploy      # deployments
kubectl get svc         # services
kubectl get ns          # namespaces
kubectl get cm          # configmaps
kubectl get sa          # serviceaccounts
kubectl get pv          # persistentvolumes
kubectl get pvc         # persistentvolumeclaims
kubectl get ing         # ingresses
kubectl get netpol      # networkpolicies
kubectl get ds          # daemonsets
kubectl get sts         # statefulsets
kubectl get rs          # replicasets
kubectl get cj          # cronjobs
kubectl get no          # nodes
```

### Essential Aliases (Add to ~/.bashrc)

```bash
# Basic shortcuts
alias k='kubectl'
alias kgp='kubectl get pods'
alias kgs='kubectl get svc'
alias kgd='kubectl get deployments'
alias kgn='kubectl get nodes'

# With watch
alias kgpw='kubectl get pods -w'

# All namespaces
alias kgpa='kubectl get pods -A'

# Describe
alias kdp='kubectl describe pod'
alias kds='kubectl describe svc'
alias kdd='kubectl describe deployment'

# Delete
alias kdelp='kubectl delete pod'
alias kdeld='kubectl delete deployment'

# Logs
alias kl='kubectl logs'
alias klf='kubectl logs -f'

# Exec
alias kex='kubectl exec -it'

# Apply/Delete
alias ka='kubectl apply -f'
alias kdel='kubectl delete -f'

# Context and namespace
alias kcc='kubectl config current-context'
alias kcn='kubectl config set-context --current --namespace'
```

### Enable kubectl Autocompletion

```bash
# For bash (add to ~/.bashrc)
source <(kubectl completion bash)
complete -o default -F __start_kubectl k  # autocomplete for 'k' alias

# For zsh (add to ~/.zshrc)
source <(kubectl completion zsh)

# Test autocomplete
kubectl get po<TAB>  # completes to 'pods'
kubectl get pods nginx-<TAB>  # completes pod name
```

## Powerful Queries

### JSONPath Queries

```bash
# Get pod IP
kubectl get pod nginx -o jsonpath='{.status.podIP}'

# Get node names
kubectl get nodes -o jsonpath='{.items[*].metadata.name}'

# Get image name
kubectl get pod nginx -o jsonpath='{.spec.containers[0].image}'

# Get container names
kubectl get pod nginx -o jsonpath='{.spec.containers[*].name}'

# Get pod name and status
kubectl get pods -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.status.phase}{"\n"}{end}'

# Get resource requests
kubectl get pod nginx -o jsonpath='{.spec.containers[*].resources.requests.memory}'
```

### Custom Columns

```bash
# Custom output format
kubectl get pods -o custom-columns=NAME:.metadata.name,STATUS:.status.phase,IP:.status.podIP

# With namespace
kubectl get pods -A -o custom-columns=NAMESPACE:.metadata.namespace,NAME:.metadata.name,STATUS:.status.phase

# Nodes with capacity
kubectl get nodes -o custom-columns=NAME:.metadata.name,CPU:.status.capacity.cpu,MEMORY:.status.capacity.memory
```

### Field Selectors

```bash
# By status
kubectl get pods --field-selector status.phase=Running
kubectl get pods --field-selector status.phase!=Running

# By node
kubectl get pods --field-selector spec.nodeName=node01

# Multiple conditions
kubectl get pods --field-selector status.phase=Running,spec.restartPolicy=Always
```

### Label Selectors

```bash
# Equality-based
kubectl get pods -l app=nginx
kubectl get pods -l app=nginx,env=prod
kubectl get pods -l 'app in (nginx,apache)'

# Set-based
kubectl get pods -l 'env=prod,tier in (frontend,backend)'
kubectl get pods -l 'env!=dev'

# Show labels
kubectl get pods --show-labels

# Label column
kubectl get pods -L app,env
```

## Exam Speed Tips

### Time-Saving Techniques

```bash
# 1. Use imperative commands for simple tasks
kubectl run nginx --image=nginx
# Faster than writing YAML

# 2. Use dry-run to generate complex YAML
kubectl create deployment nginx --image=nginx --dry-run=client -o yaml > deploy.yaml
vim deploy.yaml
kubectl apply -f deploy.yaml

# 3. Use kubectl replace --force for quick updates
kubectl replace --force -f pod.yaml

# 4. Use kubectl edit for one-off changes
kubectl edit pod nginx

# 5. Use -o yaml for debugging
kubectl get pod nginx -o yaml | less

# 6. Copy-paste from kubectl explain
kubectl explain pod.spec.containers
# Copy the YAML example
```

### Exam Workflow Patterns

**Pattern 1: Simple Pod**
```bash
# ⚡ FAST (10 seconds)
kubectl run test --image=nginx --labels="app=test"

# ❌ SLOW (2 minutes)
vim pod.yaml  # write entire YAML manually
kubectl apply -f pod.yaml
```

**Pattern 2: Complex Deployment**
```bash
# ⚡ FAST (30 seconds)
kubectl create deployment app --image=nginx --dry-run=client -o yaml > deploy.yaml
vim deploy.yaml  # add resources, probes, etc.
kubectl apply -f deploy.yaml

# ❌ SLOW (5 minutes)
vim deploy.yaml  # write entire YAML from scratch
```

**Pattern 3: Service Exposure**
```bash
# ⚡ FAST (5 seconds)
kubectl expose deployment nginx --port=80 --type=NodePort

# ❌ SLOW (1 minute)
vim service.yaml
kubectl apply -f service.yaml
```

## Common Patterns

### Debugging Workflow

```bash
# 1. Check pod status
kubectl get pods

# 2. Describe pod (look for events)
kubectl describe pod nginx

# 3. Check logs
kubectl logs nginx

# 4. Check previous container logs (if crashed)
kubectl logs nginx --previous

# 5. Exec into pod
kubectl exec -it nginx -- bash

# 6. Check resource usage
kubectl top pod nginx
```

### Quick Fixes

```bash
# Restart pod (delete and recreate)
kubectl delete pod nginx
# If managed by deployment, it auto-recreates

# Force delete stuck pod
kubectl delete pod nginx --grace-period=0 --force

# Restart deployment
kubectl rollout restart deployment nginx

# Scale to zero and back
kubectl scale deployment nginx --replicas=0
kubectl scale deployment nginx --replicas=3

# Update image
kubectl set image deployment/nginx nginx=nginx:1.21

# Undo last rollout
kubectl rollout undo deployment nginx
```

### Resource Management

```bash
# Get all resources
kubectl get all

# Get all in namespace
kubectl get all -n production

# Delete all pods (dangerous!)
kubectl delete pods --all

# Delete all in namespace
kubectl delete all --all -n test

# Force delete namespace
kubectl delete namespace test --force --grace-period=0
```

## Exam Cheat Sheet

### Must-Know Commands

```bash
# Run pod
kubectl run nginx --image=nginx

# Create deployment
kubectl create deployment nginx --image=nginx --replicas=3

# Expose service
kubectl expose deployment nginx --port=80 --type=NodePort

# Scale
kubectl scale deployment nginx --replicas=5

# Update image
kubectl set image deployment/nginx nginx=nginx:1.21

# Create from YAML
kubectl apply -f file.yaml

# Generate YAML
kubectl create deployment nginx --image=nginx --dry-run=client -o yaml > deploy.yaml

# Edit resource
kubectl edit deployment nginx

# Delete
kubectl delete pod nginx
kubectl delete deployment nginx

# Logs
kubectl logs nginx
kubectl logs -f nginx

# Exec
kubectl exec -it nginx -- bash

# Describe
kubectl describe pod nginx
```

### Common Task Times

| Task | Time | Command |
|------|------|---------|
| Create pod | 10s | `kubectl run nginx --image=nginx` |
| Create deployment | 15s | `kubectl create deployment nginx --image=nginx` |
| Expose service | 10s | `kubectl expose deployment nginx --port=80` |
| Scale deployment | 5s | `kubectl scale deployment nginx --replicas=3` |
| Generate YAML | 20s | `kubectl create ... --dry-run=client -o yaml > file.yaml` |
| Edit resource | 30s | `kubectl edit deployment nginx` |
| Check logs | 5s | `kubectl logs nginx` |
| Debug pod | 15s | `kubectl describe pod nginx` |

## Summary

**Master kubectl** to save time in the CKA exam:
- Use imperative commands for simple tasks
- Use dry-run to generate YAML for complex tasks
- Learn shortcuts and aliases
- Practice JSONPath for quick queries
- Know when to use imperative vs declarative

**Time-Saving Hierarchy:**
1. ⚡⚡⚡ Imperative one-liners (10-30s)
2. ⚡⚡ Generate + Edit YAML (30-60s)
3. ⚡ Write YAML from scratch (2-5min)

**Exam Strategy:**
- Simple pod/service? → Imperative
- Complex deployment? → Generate + Edit
- Multi-resource? → YAML file
- Debugging? → describe, logs, exec

**Practice until:**
- You can create a pod in < 15 seconds
- You can expose a service in < 10 seconds
- You can generate deployment YAML in < 20 seconds
- You know all major resource short names

---

**Back to**: [Main README](../README.md) | [Previous: ConfigMap & Secrets](13-configmap-secrets.md)
