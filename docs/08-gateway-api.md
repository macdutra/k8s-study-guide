# Gateway API - Modern Ingress Alternative

Complete guide to Kubernetes Gateway API for advanced traffic routing.

## Table of Contents

- [Overview](#overview)
- [Gateway API vs Ingress](#gateway-api-vs-ingress)
- [Installation](#installation)
- [Basic Gateway](#basic-gateway)
- [HTTPRoute](#httproute)
- [Advanced Routing](#advanced-routing)
- [Exam Tips](#exam-tips)

## Overview

Gateway API is the next-generation Ingress API for Kubernetes, providing more advanced traffic routing capabilities.

### Key Concepts

- **GatewayClass**: Defines the gateway controller (like IngressClass)
- **Gateway**: Infrastructure configuration (like load balancer)
- **HTTPRoute**: Routes HTTP traffic (like Ingress rules)
- **TLSRoute**: Routes TLS traffic
- **TCPRoute**: Routes TCP traffic

### Why Gateway API?

- ✅ **Role-oriented**: Separates infrastructure from application routing
- ✅ **Expressive**: Header-based routing, traffic splitting, mirroring
- ✅ **Extensible**: Custom filters and policies
- ✅ **Typed**: Proper CRDs instead of annotations

## Gateway API vs Ingress

| Feature | Ingress | Gateway API |
|---------|---------|-------------|
| **API Design** | Single resource | Multiple resources (Gateway, Route) |
| **Role Separation** | Mixed | Separated (infra vs app) |
| **Header Routing** | Via annotations | Native support |
| **Traffic Splitting** | Via annotations | Native support |
| **Protocol Support** | HTTP/HTTPS | HTTP, HTTPS, TCP, UDP, gRPC |
| **Cross-namespace** | Limited | Built-in |

## Installation

### Prerequisites

```bash
# Gateway API is NOT included in CKA exam by default
# This is for reference only

# Install Gateway API CRDs
kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.0.0/standard-install.yaml

# Verify installation
kubectl get crd | grep gateway
# Should show:
# gatewayclasses.gateway.networking.k8s.io
# gateways.gateway.networking.k8s.io
# httproutes.gateway.networking.k8s.io
```

### Install nginx Gateway

```bash
# For testing purposes (not on CKA exam)
kubectl apply -f https://raw.githubusercontent.com/nginxinc/nginx-gateway-fabric/main/deploy/manifests/nginx-gateway.yaml

# Wait for gateway controller
kubectl wait --for=condition=ready pod -l app=nginx-gateway -n nginx-gateway --timeout=120s
```

## Basic Gateway

### Step 1: Create GatewayClass

```bash
cat <<EOF | kubectl apply -f -
apiVersion: gateway.networking.k8s.io/v1
kind: GatewayClass
metadata:
  name: nginx
spec:
  controllerName: nginx.org/gateway-controller
EOF
```

### Step 2: Create Gateway

```bash
cat <<EOF | kubectl apply -f -
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: my-gateway
  namespace: default
spec:
  gatewayClassName: nginx
  listeners:
  - name: http
    protocol: HTTP
    port: 80
EOF
```

### Step 3: Verify Gateway

```bash
# Check gateway status
kubectl get gateway

# Describe gateway
kubectl describe gateway my-gateway
```

## HTTPRoute

### Basic HTTPRoute

```bash
# Create backend service
kubectl create deployment web --image=nginx
kubectl expose deployment web --port=80

# Create HTTPRoute
cat <<EOF | kubectl apply -f -
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: web-route
  namespace: default
spec:
  parentRefs:
  - name: my-gateway
  hostnames:
  - "example.com"
  rules:
  - matches:
    - path:
        type: PathPrefix
        value: /
    backendRefs:
    - name: web
      port: 80
EOF
```

### Multiple Backends

```bash
# Create multiple services
kubectl create deployment app1 --image=nginx
kubectl create deployment app2 --image=httpd
kubectl expose deployment app1 --port=80
kubectl expose deployment app2 --port=80

# Route based on path
cat <<EOF | kubectl apply -f -
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: multi-route
spec:
  parentRefs:
  - name: my-gateway
  rules:
  - matches:
    - path:
        type: PathPrefix
        value: /app1
    backendRefs:
    - name: app1
      port: 80
  - matches:
    - path:
        type: PathPrefix
        value: /app2
    backendRefs:
    - name: app2
      port: 80
EOF
```

## Advanced Routing

### Header-Based Routing

```bash
cat <<EOF | kubectl apply -f -
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: header-route
spec:
  parentRefs:
  - name: my-gateway
  rules:
  - matches:
    - headers:
      - name: version
        value: v1
    backendRefs:
    - name: app-v1
      port: 80
  - matches:
    - headers:
      - name: version
        value: v2
    backendRefs:
    - name: app-v2
      port: 80
EOF
```

### Traffic Splitting (Canary)

```bash
cat <<EOF | kubectl apply -f -
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: canary-route
spec:
  parentRefs:
  - name: my-gateway
  rules:
  - backendRefs:
    - name: app-v1
      port: 80
      weight: 90  # 90% traffic
    - name: app-v2
      port: 80
      weight: 10  # 10% traffic (canary)
EOF
```

### Request Mirroring

```bash
cat <<EOF | kubectl apply -f -
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: mirror-route
spec:
  parentRefs:
  - name: my-gateway
  rules:
  - backendRefs:
    - name: production
      port: 80
    filters:
    - type: RequestMirror
      requestMirror:
        backendRef:
          name: test
          port: 80
EOF
```

### Cross-Namespace Routing

```bash
# Create namespace
kubectl create namespace backend

# Create service in backend namespace
kubectl create deployment api --image=nginx -n backend
kubectl expose deployment api --port=80 -n backend

# Allow route from default to backend
cat <<EOF | kubectl apply -f -
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: cross-ns-route
  namespace: default
spec:
  parentRefs:
  - name: my-gateway
  rules:
  - backendRefs:
    - name: api
      namespace: backend  # Cross-namespace reference
      port: 80
EOF
```

## Gateway API vs Ingress Comparison

### Same Task - Different Approaches

**With Ingress:**

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: my-ingress
  annotations:
    nginx.ingress.kubernetes.io/canary: "true"
    nginx.ingress.kubernetes.io/canary-weight: "10"
spec:
  rules:
  - host: example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: app-v2
            port:
              number: 80
```

**With Gateway API:**

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: my-route
spec:
  parentRefs:
  - name: my-gateway
  hostnames:
  - "example.com"
  rules:
  - backendRefs:
    - name: app-v1
      port: 80
      weight: 90
    - name: app-v2
      port: 80
      weight: 10
```

## Troubleshooting

### Gateway Not Ready

```bash
# Check gateway status
kubectl get gateway my-gateway

# Check events
kubectl describe gateway my-gateway

# Check gateway controller
kubectl get pods -n nginx-gateway
kubectl logs -n nginx-gateway -l app=nginx-gateway
```

### HTTPRoute Not Working

```bash
# Check route status
kubectl get httproute

# Describe route
kubectl describe httproute web-route

# Check parent reference
kubectl get httproute web-route -o jsonpath='{.spec.parentRefs}'

# Verify backend service exists
kubectl get svc
```

## Exam Tips

### Gateway API NOT on CKA Exam

**Important:** As of 2024, Gateway API is **NOT** part of the CKA exam. The exam focuses on:
- ✅ Ingress (traditional)
- ✅ NetworkPolicy
- ✅ Services (ClusterIP, NodePort, LoadBalancer)

### When You Might See It

Gateway API **may appear** in:
- **CKS (Security)**: For advanced security policies
- **CKAD (Developer)**: For application routing
- **Future CKA versions**: As it becomes standard

### Focus on Ingress Instead

For CKA exam, master **Ingress**:

```bash
# This IS on the exam
kubectl create ingress my-ingress \
  --rule="example.com/=web:80"

# This is NOT on the exam (yet)
kubectl create httproute my-route ...
```

## Quick Reference

### Resource Hierarchy

```
GatewayClass (infrastructure owner)
    ↓
Gateway (infrastructure owner)
    ↓
HTTPRoute (application developer)
    ↓
Service → Pods
```

### Common Commands

```bash
# List resources
kubectl get gatewayclass
kubectl get gateway
kubectl get httproute

# Describe
kubectl describe gateway <name>
kubectl describe httproute <name>

# Delete
kubectl delete httproute <name>
kubectl delete gateway <name>
```

### Key Differences from Ingress

| Aspect | Ingress | Gateway API |
|--------|---------|-------------|
| **Ownership** | Mixed | Separated |
| **Configuration** | Annotations | Native fields |
| **Protocols** | HTTP/HTTPS | HTTP, HTTPS, TCP, UDP, gRPC |
| **Flexibility** | Limited | Extensive |
| **Maturity** | Stable | Stable (v1.0+) |

## Summary

**Gateway API** is the future of Kubernetes traffic routing, but **Ingress** is still the standard for CKA.

**For the exam:**
- ✅ Focus on Ingress
- ✅ Understand Services
- ✅ Master NetworkPolicy
- ℹ️ Know Gateway API exists (conceptually)

**After the exam:**
- Consider Gateway API for production
- More expressive routing
- Better role separation
- Future-proof architecture

---

**Back to**: [Main README](../README.md) | [Previous: Pod Scheduling](07-pod-scheduling.md) | [Next: ETCD Backup & Restore](09-etcd-backup-restore.md)
