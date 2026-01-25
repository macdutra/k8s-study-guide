# Network Policies

Complete guide to Kubernetes NetworkPolicy for controlling pod-to-pod communication.

## Table of Contents

- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Basic NetworkPolicy](#basic-networkpolicy)
- [Ingress Rules](#ingress-rules)
- [Egress Rules](#egress-rules)
- [Selectors](#selectors)
- [Common Patterns](#common-patterns)
- [Hands-On Practice](#hands-on-practice)
- [Troubleshooting](#troubleshooting)
- [Exam Tips](#exam-tips)

## Overview

NetworkPolicy allows you to control traffic flow at the IP address or port level.

### Key Concepts

- **Pod Selector**: Which pods the policy applies to
- **Ingress**: Incoming traffic rules
- **Egress**: Outgoing traffic rules
- **Selectors**: podSelector, namespaceSelector, ipBlock

### Default Behavior

- **Without NetworkPolicy**: All pods can communicate with all pods
- **With NetworkPolicy**: Only explicitly allowed traffic is permitted

## Prerequisites

### Verify Network Plugin Supports NetworkPolicy

```bash
# In minikube, the default CNI supports NetworkPolicy
minikube ssh "cat /etc/cni/net.d/*" | grep -i network

# Most CNIs support it: Calico, Cilium, Weave, Flannel (with modifications)
```

### Create Test Environment

```bash
# Create namespace for testing
kubectl create namespace netpol-test
kubectl config set-context --current --namespace=netpol-test

# Create frontend pod
kubectl run frontend --image=nginx --labels="tier=frontend"

# Create backend pod
kubectl run backend --image=nginx --labels="tier=backend"

# Create database pod
kubectl run database --image=postgres --labels="tier=database" \
  --env="POSTGRES_PASSWORD=secret"

# Expose services
kubectl expose pod frontend --port=80
kubectl expose pod backend --port=80
kubectl expose pod database --port=5432
```

## Basic NetworkPolicy

### Deny All Ingress

```bash
cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-all-ingress
  namespace: netpol-test
spec:
  podSelector: {}  # Applies to all pods
  policyTypes:
  - Ingress
EOF
```

### Test Deny All

```bash
# Before NetworkPolicy
kubectl exec frontend -- wget -qO- --timeout=2 backend
# Works

# Apply deny-all
kubectl apply -f deny-all.yaml

# After NetworkPolicy
kubectl exec frontend -- wget -qO- --timeout=2 backend
# Fails (timeout)
```

### Allow All Ingress

```bash
cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-all-ingress
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  ingress:
  - {}  # Empty rule allows all
EOF
```

## Ingress Rules

### Allow from Specific Pod

```bash
cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-frontend-to-backend
spec:
  podSelector:
    matchLabels:
      tier: backend
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          tier: frontend
    ports:
    - protocol: TCP
      port: 80
EOF
```

### Test Specific Pod Access

```bash
# Frontend to backend - should work
kubectl exec frontend -- wget -qO- --timeout=2 backend

# Database to backend - should fail
kubectl exec database -- wget -qO- --timeout=2 backend
```

### Allow from Specific Namespace

```bash
cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-from-prod-namespace
spec:
  podSelector:
    matchLabels:
      app: api
  policyTypes:
  - Ingress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          name: production
    ports:
    - protocol: TCP
      port: 8080
EOF
```

### Allow from IP Block

```bash
cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-from-cidr
spec:
  podSelector:
    matchLabels:
      app: public-api
  policyTypes:
  - Ingress
  ingress:
  - from:
    - ipBlock:
        cidr: 192.168.1.0/24
        except:
        - 192.168.1.5/32
    ports:
    - protocol: TCP
      port: 443
EOF
```

## Egress Rules

### Deny All Egress

```bash
cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-all-egress
spec:
  podSelector: {}
  policyTypes:
  - Egress
EOF
```

### Allow Egress to Specific Pod

```bash
cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: backend-to-database
spec:
  podSelector:
    matchLabels:
      tier: backend
  policyTypes:
  - Egress
  egress:
  - to:
    - podSelector:
        matchLabels:
          tier: database
    ports:
    - protocol: TCP
      port: 5432
EOF
```

### Allow DNS (Essential!)

```bash
cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-dns
spec:
  podSelector: {}
  policyTypes:
  - Egress
  egress:
  - to:
    - namespaceSelector:
        matchLabels:
          name: kube-system
    ports:
    - protocol: UDP
      port: 53
EOF
```

## Selectors

### Pod Selector

Match pods by labels.

```yaml
podSelector:
  matchLabels:
    app: frontend
    version: v1
```

### Namespace Selector

Match entire namespace.

```yaml
namespaceSelector:
  matchLabels:
    environment: production
```

### Combined Selectors (AND)

Both conditions must match.

```yaml
ingress:
- from:
  - namespaceSelector:
      matchLabels:
        environment: prod
    podSelector:
      matchLabels:
        app: api
```

### Multiple Selectors (OR)

Any condition matches.

```yaml
ingress:
- from:
  - namespaceSelector:
      matchLabels:
        environment: prod
  - podSelector:
      matchLabels:
        app: admin
```

## Common Patterns

### 3-Tier Application

```bash
cat <<EOF | kubectl apply -f -
# Frontend: Allow from anywhere
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: frontend-policy
spec:
  podSelector:
    matchLabels:
      tier: frontend
  policyTypes:
  - Ingress
  ingress:
  - {}  # Allow all ingress
---
# Backend: Allow only from frontend
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: backend-policy
spec:
  podSelector:
    matchLabels:
      tier: backend
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          tier: frontend
  egress:
  - to:
    - podSelector:
        matchLabels:
          tier: database
    ports:
    - protocol: TCP
      port: 5432
  - to:
    - namespaceSelector: {}
    ports:
    - protocol: UDP
      port: 53
---
# Database: Allow only from backend
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: database-policy
spec:
  podSelector:
    matchLabels:
      tier: database
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          tier: backend
    ports:
    - protocol: TCP
      port: 5432
EOF
```

### Default Deny with Exceptions

```bash
cat <<EOF | kubectl apply -f -
# Default deny all
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
---
# Allow DNS
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-dns
spec:
  podSelector: {}
  policyTypes:
  - Egress
  egress:
  - to:
    - namespaceSelector: {}
    ports:
    - protocol: UDP
      port: 53
---
# Allow specific connections
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-app-traffic
spec:
  podSelector:
    matchLabels:
      app: myapp
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: frontend
  egress:
  - to:
    - podSelector:
        matchLabels:
          app: database
EOF
```

### Isolate Namespace

```bash
cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: isolate-namespace
  namespace: production
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          name: production
  egress:
  - to:
    - namespaceSelector:
        matchLabels:
          name: production
  - to:
    - namespaceSelector: {}
    ports:
    - protocol: UDP
      port: 53
EOF
```

## Hands-On Practice

### Exercise 1: Three-Tier App Security

Setup a 3-tier app with proper network isolation.

```bash
# Create pods
kubectl run frontend --image=nginx --labels="tier=frontend"
kubectl run backend --image=nginx --labels="tier=backend"
kubectl run database --image=postgres --labels="tier=database" \
  --env="POSTGRES_PASSWORD=secret"

# Create services
kubectl expose pod frontend --port=80
kubectl expose pod backend --port=80
kubectl expose pod database --port=5432

# Test connectivity (should all work)
kubectl exec frontend -- wget -qO- --timeout=2 backend
kubectl exec frontend -- nc -zv database 5432
kubectl exec backend -- nc -zv database 5432

# Apply network policies
cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: database-policy
spec:
  podSelector:
    matchLabels:
      tier: database
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          tier: backend
    ports:
    - protocol: TCP
      port: 5432
EOF

# Test again
kubectl exec frontend -- nc -zv database 5432  # Should FAIL
kubectl exec backend -- nc -zv database 5432   # Should WORK
```

### Exercise 2: Namespace Isolation

```bash
# Create namespaces
kubectl create namespace prod
kubectl create namespace dev

# Label namespaces
kubectl label namespace prod environment=production
kubectl label namespace dev environment=development

# Create pods in both namespaces
kubectl run app --image=nginx -n prod
kubectl run app --image=nginx -n dev

# Apply isolation
cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: isolate-prod
  namespace: prod
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          environment: production
EOF

# Test
kubectl exec -n dev app -- wget -qO- --timeout=2 app.prod  # FAIL
kubectl exec -n prod app -- wget -qO- --timeout=2 app.prod # WORK
```

## Troubleshooting

### Issue 1: Policy Not Working

```bash
# Check if NetworkPolicy was created
kubectl get networkpolicy

# Describe policy
kubectl describe networkpolicy <policy-name>

# Check pod labels match
kubectl get pods --show-labels

# Verify CNI supports NetworkPolicy
kubectl get pods -n kube-system
```

### Issue 2: DNS Not Working

```bash
# Always allow DNS egress
cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-dns
spec:
  podSelector: {}
  egress:
  - to:
    - namespaceSelector: {}
    ports:
    - protocol: UDP
      port: 53
EOF
```

### Issue 3: Can't Test Connectivity

```bash
# Install network tools in pod
kubectl run test --image=nicolaka/netshoot -it --rm

# Test connectivity
wget -qO- --timeout=2 http://backend
nc -zv backend 80
nslookup backend
```

### Debugging Commands

```bash
# List all NetworkPolicies
kubectl get networkpolicy -A

# Describe policy
kubectl describe networkpolicy <n>

# Check pod connectivity
kubectl exec <pod> -- wget -qO- --timeout=2 <target>
kubectl exec <pod> -- nc -zv <target> <port>

# View policy YAML
kubectl get networkpolicy <n> -o yaml
```

## Exam Tips

### Quick NetworkPolicy Creation

```bash
# Basic template
cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: <policy-name>
spec:
  podSelector:
    matchLabels:
      app: <app-name>
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: <source-app>
    ports:
    - protocol: TCP
      port: <port>
EOF
```

### Common Exam Patterns

```bash
# Pattern 1: Allow only specific pod to database
podSelector:
  matchLabels:
    tier: database
ingress:
- from:
  - podSelector:
      matchLabels:
        tier: backend

# Pattern 2: Deny all, then allow specific
# First apply deny-all, then allow policies

# Pattern 3: Always remember DNS
egress:
- to:
  - namespaceSelector: {}
  ports:
  - protocol: UDP
    port: 53
```

### Time-Saving Tips

1. **Start with deny-all**: Apply default deny, then add exceptions
2. **Test before and after**: Verify connectivity before/after policy
3. **Use kubectl explain**: `kubectl explain networkpolicy.spec`
4. **Remember DNS**: Always allow port 53 UDP for egress
5. **Check labels**: Verify pod labels match selectors

## Practice Questions

### Question 1

Create NetworkPolicy allowing only pods labeled `app=api` to access pods labeled `app=database` on port 5432.

<details>
<summary>Solution</summary>

```bash
cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: database-access
spec:
  podSelector:
    matchLabels:
      app: database
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: api
    ports:
    - protocol: TCP
      port: 5432
EOF
```
</details>

### Question 2

Create NetworkPolicy denying all egress except DNS.

<details>
<summary>Solution</summary>

```bash
cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-egress-except-dns
spec:
  podSelector: {}
  policyTypes:
  - Egress
  egress:
  - to:
    - namespaceSelector: {}
    ports:
    - protocol: UDP
      port: 53
EOF
```
</details>

## Quick Reference

### NetworkPolicy Template

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: POLICY_NAME
spec:
  podSelector:
    matchLabels:
      KEY: VALUE
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          KEY: VALUE
    ports:
    - protocol: TCP
      port: PORT
  egress:
  - to:
    - podSelector:
        matchLabels:
          KEY: VALUE
    ports:
    - protocol: TCP
      port: PORT
```

### Common Commands

```bash
# Create policy
kubectl apply -f policy.yaml

# List policies
kubectl get networkpolicy
kubectl get netpol  # short form

# Describe
kubectl describe networkpolicy <n>

# Delete
kubectl delete networkpolicy <n>

# Test connectivity
kubectl exec <pod> -- wget -qO- <target>
kubectl exec <pod> -- nc -zv <target> <port>
```

---

**Back to**: [Main README](../README.md) | [Previous: Storage](04-storage-management.md) | [Next: Sidecar Patterns](06-sidecar-patterns.md)
