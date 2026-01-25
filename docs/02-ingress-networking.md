# Ingress and Networking

Complete guide to Kubernetes Ingress for CKA preparation on macOS.

## Table of Contents

- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Ingress Controller Setup](#ingress-controller-setup)
- [Basic Ingress](#basic-ingress)
- [Advanced Ingress](#advanced-ingress)
- [Path-Based Routing](#path-based-routing)
- [Host-Based Routing](#host-based-routing)
- [TLS/SSL Configuration](#tlsssl-configuration)
- [Troubleshooting](#troubleshooting)
- [Exam Tips](#exam-tips)

## Overview

Ingress exposes HTTP and HTTPS routes from outside the cluster to services within the cluster. Traffic routing is controlled by rules defined on the Ingress resource.

### Key Concepts

- **Ingress**: API object that manages external access to services
- **Ingress Controller**: Implements the Ingress (e.g., nginx, traefik)
- **Rules**: Define routing based on host and path
- **Backend**: The service that receives the traffic

## Prerequisites

### Enable Ingress Addon

```bash
# Enable nginx ingress controller
minikube addons enable ingress

# Verify ingress controller is running
kubectl get pods -n ingress-nginx

# Expected output: ingress-nginx-controller pod running
```

### Verify Installation

```bash
# Check ingress class
kubectl get ingressclass

# Should see 'nginx' as default
NAME    CONTROLLER             PARAMETERS   AGE
nginx   k8s.io/ingress-nginx   <none>       1m
```

## Basic Ingress

### Step 1: Create Backend Application

```bash
# Create deployment
kubectl create deployment web --image=nginx:alpine --replicas=2

# Create service
kubectl expose deployment web --port=80 --name=web-service

# Verify
kubectl get deployment web
kubectl get svc web-service
```

### Step 2: Create Simple Ingress

```bash
cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: basic-ingress
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  ingressClassName: nginx
  rules:
  - host: example.local
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: web-service
            port:
              number: 80
EOF
```

### Step 3: Test Ingress

```bash
# Get minikube IP
MINIKUBE_IP=$(minikube ip)
echo $MINIKUBE_IP

# Add to /etc/hosts
echo "$MINIKUBE_IP example.local" | sudo tee -a /etc/hosts

# Test with curl
curl http://example.local

# Or test with Host header
curl -H "Host: example.local" http://$MINIKUBE_IP
```

### Understanding Ingress YAML

```yaml
apiVersion: networking.k8s.io/v1  # API version
kind: Ingress                      # Resource type
metadata:
  name: basic-ingress              # Ingress name
  annotations:                     # Controller-specific config
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  ingressClassName: nginx          # Which controller to use
  rules:                          # Routing rules
  - host: example.local           # Hostname
    http:
      paths:                      # Path-based routing
      - path: /                   # Match path
        pathType: Prefix          # Match type
        backend:
          service:
            name: web-service     # Target service
            port:
              number: 80          # Target port
```

## Path-Based Routing

Route traffic based on URL path.

### Create Multiple Services

```bash
# App 1
kubectl create deployment app1 --image=hashicorp/http-echo -- -text="App 1"
kubectl expose deployment app1 --port=5678 --name=app1-service

# App 2
kubectl create deployment app2 --image=hashicorp/http-echo -- -text="App 2"
kubectl expose deployment app2 --port=5678 --name=app2-service

# App 3
kubectl create deployment app3 --image=hashicorp/http-echo -- -text="App 3"
kubectl expose deployment app3 --port=5678 --name=app3-service
```

### Create Path-Based Ingress

```bash
cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: path-based-ingress
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  ingressClassName: nginx
  rules:
  - host: myapp.local
    http:
      paths:
      - path: /app1
        pathType: Prefix
        backend:
          service:
            name: app1-service
            port:
              number: 5678
      - path: /app2
        pathType: Prefix
        backend:
          service:
            name: app2-service
            port:
              number: 5678
      - path: /app3
        pathType: Prefix
        backend:
          service:
            name: app3-service
            port:
              number: 5678
EOF
```

### Test Path-Based Routing

```bash
# Add to /etc/hosts
echo "$(minikube ip) myapp.local" | sudo tee -a /etc/hosts

# Test different paths
curl http://myapp.local/app1
# Output: App 1

curl http://myapp.local/app2
# Output: App 2

curl http://myapp.local/app3
# Output: App 3
```

### PathType Options

```yaml
# Prefix: Matches based on URL path prefix
pathType: Prefix
path: /foo
# Matches: /foo, /foo/, /foo/bar

# Exact: Matches exact path only
pathType: Exact
path: /foo
# Matches: /foo only

# ImplementationSpecific: Depends on IngressClass
pathType: ImplementationSpecific
```

## Host-Based Routing

Route traffic based on hostname.

### Create Host-Based Ingress

```bash
cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: host-based-ingress
spec:
  ingressClassName: nginx
  rules:
  - host: app1.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: app1-service
            port:
              number: 5678
  - host: app2.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: app2-service
            port:
              number: 5678
  - host: app3.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: app3-service
            port:
              number: 5678
EOF
```

### Test Host-Based Routing

```bash
# Add all hosts to /etc/hosts
MINIKUBE_IP=$(minikube ip)
sudo bash -c "cat >> /etc/hosts << EOF
$MINIKUBE_IP app1.example.com
$MINIKUBE_IP app2.example.com
$MINIKUBE_IP app3.example.com
EOF"

# Test different hosts
curl http://app1.example.com
curl http://app2.example.com
curl http://app3.example.com
```

## Default Backend

Handle requests that don't match any rules.

```bash
# Create default backend
kubectl create deployment default-backend --image=nginx:alpine
kubectl expose deployment default-backend --port=80 --name=default-service

# Create ingress with default backend
cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: ingress-with-default
spec:
  ingressClassName: nginx
  defaultBackend:
    service:
      name: default-service
      port:
        number: 80
  rules:
  - host: myapp.local
    http:
      paths:
      - path: /app
        pathType: Prefix
        backend:
          service:
            name: app1-service
            port:
              number: 5678
EOF

# Test
curl http://myapp.local/app     # Goes to app1-service
curl http://myapp.local/other   # Goes to default-service
```

## TLS/SSL Configuration

Secure your ingress with HTTPS.

### Create Self-Signed Certificate

```bash
# Generate certificate
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout tls.key \
  -out tls.crt \
  -subj "/CN=myapp.local/O=myapp"

# Create secret
kubectl create secret tls myapp-tls \
  --cert=tls.crt \
  --key=tls.key

# Verify secret
kubectl get secret myapp-tls
```

### Create TLS Ingress

```bash
cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: tls-ingress
spec:
  ingressClassName: nginx
  tls:
  - hosts:
    - myapp.local
    secretName: myapp-tls
  rules:
  - host: myapp.local
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: web-service
            port:
              number: 80
EOF
```

### Test TLS

```bash
# Test HTTPS (ignore certificate warning)
curl -k https://myapp.local

# Or with certificate verification
curl --cacert tls.crt https://myapp.local
```

## Advanced Annotations

### Common nginx Annotations

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: annotated-ingress
  annotations:
    # Rewrite target
    nginx.ingress.kubernetes.io/rewrite-target: /
    
    # Enable SSL redirect
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
    
    # Backend protocol
    nginx.ingress.kubernetes.io/backend-protocol: "HTTPS"
    
    # Custom timeouts
    nginx.ingress.kubernetes.io/proxy-connect-timeout: "30"
    nginx.ingress.kubernetes.io/proxy-send-timeout: "30"
    
    # Rate limiting
    nginx.ingress.kubernetes.io/limit-rps: "10"
    
    # CORS
    nginx.ingress.kubernetes.io/enable-cors: "true"
    nginx.ingress.kubernetes.io/cors-allow-origin: "*"
    
    # Whitelist IPs
    nginx.ingress.kubernetes.io/whitelist-source-range: "10.0.0.0/24"
    
    # Custom headers
    nginx.ingress.kubernetes.io/configuration-snippet: |
      more_set_headers "X-Custom-Header: value";
```

### Rewrite Examples

```yaml
# Example 1: Remove path prefix
annotations:
  nginx.ingress.kubernetes.io/rewrite-target: /$2
spec:
  rules:
  - host: myapp.local
    http:
      paths:
      - path: /api(/|$)(.*)
        pathType: Prefix
# /api/users -> /users

# Example 2: Add path prefix
annotations:
  nginx.ingress.kubernetes.io/rewrite-target: /api/$2
spec:
  rules:
  - host: myapp.local
    http:
      paths:
      - path: /(/|$)(.*)
        pathType: Prefix
# /users -> /api/users
```

## Multiple Ingress Resources

You can have multiple Ingress resources.

```bash
# Ingress 1: Production apps
cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: prod-ingress
  namespace: production
spec:
  ingressClassName: nginx
  rules:
  - host: prod.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: prod-service
            port:
              number: 80
EOF

# Ingress 2: Staging apps
cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: staging-ingress
  namespace: staging
spec:
  ingressClassName: nginx
  rules:
  - host: staging.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: staging-service
            port:
              number: 80
EOF
```

## Troubleshooting

### Common Issues

#### 1. Ingress Not Working

```bash
# Check ingress controller
kubectl get pods -n ingress-nginx

# Check ingress resource
kubectl get ingress
kubectl describe ingress <ingress-name>

# Check events
kubectl get events --sort-by='.lastTimestamp'

# Check ingress controller logs
kubectl logs -n ingress-nginx -l app.kubernetes.io/name=ingress-nginx
```

#### 2. 404 Not Found

```bash
# Verify service exists
kubectl get svc <service-name>

# Verify service endpoints
kubectl get endpoints <service-name>

# Check if pods are running
kubectl get pods -l <service-selector>

# Verify ingress rules
kubectl get ingress <name> -o yaml
```

#### 3. DNS Not Resolving

```bash
# Check /etc/hosts
cat /etc/hosts | grep example.local

# Test with Host header instead
curl -H "Host: example.local" http://$(minikube ip)

# Verify minikube IP
minikube ip
```

#### 4. TLS Not Working

```bash
# Check secret exists
kubectl get secret myapp-tls

# Check secret data
kubectl get secret myapp-tls -o yaml

# Verify certificate
kubectl get secret myapp-tls -o jsonpath='{.data.tls\.crt}' | base64 -d | openssl x509 -text -noout
```

### Debugging Commands

```bash
# Get all ingresses
kubectl get ingress -A

# Describe ingress
kubectl describe ingress <name>

# Get ingress YAML
kubectl get ingress <name> -o yaml

# Check ingress class
kubectl get ingressclass

# View nginx config
kubectl exec -n ingress-nginx <ingress-controller-pod> -- cat /etc/nginx/nginx.conf

# Test from inside cluster
kubectl run test --image=curlimages/curl -it --rm -- curl http://web-service
```

## Exam Tips

### Quick Ingress Creation

```bash
# Method 1: Imperative (fastest for basic ingress)
kubectl create ingress simple \
  --rule="example.com/=web-service:80"

# Method 2: Generate YAML
kubectl create ingress simple \
  --rule="example.com/=web-service:80" \
  --dry-run=client -o yaml > ingress.yaml

# Method 3: From template
cat > ingress.yaml << EOF
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: example-ingress
spec:
  ingressClassName: nginx
  rules:
  - host: example.org
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: web-service
            port:
              number: 80
EOF
kubectl apply -f ingress.yaml
```

### Testing Pattern

```bash
# Pattern for exam:
# 1. Create ingress
kubectl create ingress exam-ingress --rule="example.org/=svc:80"

# 2. Test with curl
curl -H "Host: example.org" http://$(minikube ip)

# 3. Verify
kubectl get ingress exam-ingress
kubectl describe ingress exam-ingress
```

### Time-Saving Tips

1. **Use imperative commands** for simple ingress
2. **Know the rule format**: `host/path=service:port`
3. **Test with Host header**: No need to edit /etc/hosts
4. **Use kubectl explain**: `kubectl explain ingress.spec.rules`
5. **Remember ingressClassName**: Required in newer versions

### Common Exam Tasks

```bash
# Task: Create ingress for hostname
kubectl create ingress web-ingress \
  --rule="example.org/=web-service:80"

# Task: Add path-based routing
kubectl create ingress api-ingress \
  --rule="api.example.com/v1=api-v1:80" \
  --rule="api.example.com/v2=api-v2:80"

# Task: Enable TLS
# (Must use YAML, can't do imperatively)
```

## Practice Exercises

### Exercise 1: Basic Ingress

Create an ingress that routes `myapp.local` to service `web-service` on port 80.

<details>
<summary>Solution</summary>

```bash
kubectl create ingress myapp \
  --rule="myapp.local/=web-service:80"

# Test
curl -H "Host: myapp.local" http://$(minikube ip)
```
</details>

### Exercise 2: Path-Based Routing

Create an ingress with:
- `/api` -> `api-service:8080`
- `/web` -> `web-service:80`

<details>
<summary>Solution</summary>

```bash
kubectl create ingress multi-path \
  --rule="myapp.local/api=api-service:8080" \
  --rule="myapp.local/web=web-service:80"
```
</details>

### Exercise 3: Multiple Hosts

Create ingress routing:
- `app1.example.com` -> `app1-service:80`
- `app2.example.com` -> `app2-service:80`

<details>
<summary>Solution</summary>

```bash
kubectl create ingress multi-host \
  --rule="app1.example.com/=app1-service:80" \
  --rule="app2.example.com/=app2-service:80"
```
</details>

## Quick Reference

### Ingress Commands

```bash
# Create
kubectl create ingress <n> --rule="host/path=svc:port"

# Get
kubectl get ingress
kubectl get ing  # short form

# Describe
kubectl describe ingress <n>

# Delete
kubectl delete ingress <n>

# Edit
kubectl edit ingress <n>
```

### Ingress Template

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: NAME
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  ingressClassName: nginx
  rules:
  - host: HOSTNAME
    http:
      paths:
      - path: PATH
        pathType: Prefix
        backend:
          service:
            name: SERVICE
            port:
              number: PORT
```

---

**Back to**: [Main README](../README.md) | [Next: Resource Management](03-resource-management.md)
