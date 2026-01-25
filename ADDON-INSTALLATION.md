# Installing Kubernetes Add-ons with kubectl

Complete guide for installing common Kubernetes add-ons using kubectl instead of minikube commands.

## 🎯 Overview

In the CKA exam, you **cannot use minikube addons**. This guide shows you how to install common add-ons using only kubectl.

## 📊 Quick Reference

| Add-on | Minikube Command | kubectl Command |
|--------|------------------|-----------------|
| metrics-server | `minikube addons enable metrics-server` | `kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml` |
| ingress-nginx | `minikube addons enable ingress` | `kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.1/deploy/static/provider/cloud/deploy.yaml` |
| dashboard | `minikube addons enable dashboard` | `kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.7.0/aio/deploy/recommended.yaml` |

## 🔧 Detailed Installation Guides

### 1. Metrics Server

Metrics Server collects resource metrics for HPA and `kubectl top`.

**Installation:**

```bash
# Install latest version
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

# Or specific version (more reliable)
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/download/v0.7.0/components.yaml
```

**Verification:**

```bash
# Check deployment
kubectl get deployment metrics-server -n kube-system

# Check pods
kubectl get pods -n kube-system -l k8s-app=metrics-server

# Wait for ready state
kubectl wait --for=condition=ready pod -l k8s-app=metrics-server -n kube-system --timeout=60s

# Test (wait 1-2 minutes for data collection)
kubectl top nodes
kubectl top pods -A
```

**Troubleshooting (Minikube/Dev):**

```bash
# If you get TLS errors, add insecure flag:
kubectl patch deployment metrics-server -n kube-system --type='json' \
  -p='[{"op": "add", "path": "/spec/template/spec/containers/0/args/-", "value": "--kubelet-insecure-tls"}]'

# Restart deployment
kubectl rollout restart deployment metrics-server -n kube-system
```

**Removal:**

```bash
kubectl delete -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
```

### 2. Ingress Nginx Controller

Ingress controller for routing HTTP/HTTPS traffic.

**Installation:**

```bash
# For cloud environments
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.1/deploy/static/provider/cloud/deploy.yaml

# For bare metal (minikube, kind, etc.)
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.1/deploy/static/provider/baremetal/deploy.yaml
```

**Verification:**

```bash
# Check namespace created
kubectl get namespace ingress-nginx

# Check pods
kubectl get pods -n ingress-nginx

# Wait for controller to be ready
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=120s

# Check ingress class
kubectl get ingressclass
```

**Test with Sample Ingress:**

```bash
# Create test deployment and service
kubectl create deployment web --image=nginx
kubectl expose deployment web --port=80

# Create ingress
cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: test-ingress
spec:
  ingressClassName: nginx
  rules:
  - host: test.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: web
            port:
              number: 80
EOF

# Verify
kubectl get ingress test-ingress
```

**Removal:**

```bash
kubectl delete -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.1/deploy/static/provider/cloud/deploy.yaml
```

### 3. Kubernetes Dashboard

Web UI for managing Kubernetes cluster.

**Installation:**

```bash
# Install dashboard
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.7.0/aio/deploy/recommended.yaml
```

**Verification:**

```bash
# Check namespace
kubectl get namespace kubernetes-dashboard

# Check pods
kubectl get pods -n kubernetes-dashboard

# Check services
kubectl get svc -n kubernetes-dashboard
```

**Access Dashboard:**

```bash
# Method 1: Port-forward (recommended)
kubectl port-forward -n kubernetes-dashboard service/kubernetes-dashboard 8443:443
# Open: https://localhost:8443

# Method 2: Create NodePort service
kubectl patch svc kubernetes-dashboard -n kubernetes-dashboard -p '{"spec":{"type":"NodePort"}}'
kubectl get svc kubernetes-dashboard -n kubernetes-dashboard
```

**Get Access Token:**

```bash
# Create service account
kubectl create serviceaccount dashboard-admin -n kubernetes-dashboard

# Create cluster role binding
kubectl create clusterrolebinding dashboard-admin \
  --clusterrole=cluster-admin \
  --serviceaccount=kubernetes-dashboard:dashboard-admin

# Get token
kubectl -n kubernetes-dashboard create token dashboard-admin

# Or for persistent token (create secret):
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Secret
metadata:
  name: dashboard-admin-token
  namespace: kubernetes-dashboard
  annotations:
    kubernetes.io/service-account.name: dashboard-admin
type: kubernetes.io/service-account-token
EOF

kubectl get secret dashboard-admin-token -n kubernetes-dashboard -o jsonpath='{.data.token}' | base64 -d
```

**Removal:**

```bash
kubectl delete -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.7.0/aio/deploy/recommended.yaml
```

### 4. Storage Provisioner

**Note:** In exam clusters, a StorageClass is usually pre-configured.

**Check Existing:**

```bash
# List storage classes
kubectl get storageclass

# Describe default
kubectl describe storageclass
```

**Create Custom StorageClass:**

```bash
# Example for local storage
cat <<EOF | kubectl apply -f -
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: fast-storage
provisioner: kubernetes.io/no-provisioner
volumeBindingMode: WaitForFirstConsumer
EOF
```

### 5. CoreDNS

Usually pre-installed, but here's how to manage it:

**Check Status:**

```bash
# Check CoreDNS deployment
kubectl get deployment coredns -n kube-system

# Check pods
kubectl get pods -n kube-system -l k8s-app=kube-dns

# View configuration
kubectl get configmap coredns -n kube-system -o yaml
```

**Restart CoreDNS:**

```bash
kubectl rollout restart deployment coredns -n kube-system
```

**Scale CoreDNS:**

```bash
kubectl scale deployment coredns -n kube-system --replicas=3
```

## 🎓 Exam-Specific Tips

### Check What's Already Installed

```bash
# List all system components
kubectl get all -n kube-system

# Check for specific components
kubectl get deployment -n kube-system | grep -E "metrics|coredns"
kubectl get pods -n ingress-nginx 2>/dev/null || echo "Ingress not installed"

# Check API resources available
kubectl api-resources | grep metrics
```

### Common Exam Scenarios

**Scenario 1: "Enable metrics for HPA"**

```bash
# Check if metrics-server exists
kubectl get deployment metrics-server -n kube-system

# If not, install it:
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

# Wait and verify
kubectl top nodes
```

**Scenario 2: "Create an Ingress"**

```bash
# Check if ingress controller exists
kubectl get ingressclass

# If not, you may need to install it (or it may be installed differently)
kubectl get pods -A | grep ingress

# Create your ingress (controller should be pre-installed)
kubectl create ingress my-ingress --rule="host/path=service:port"
```

**Scenario 3: "Troubleshoot DNS"**

```bash
# Check CoreDNS
kubectl get pods -n kube-system -l k8s-app=kube-dns

# Restart if needed
kubectl rollout restart deployment coredns -n kube-system

# Test DNS
kubectl run test --image=busybox -it --rm -- nslookup kubernetes.default
```

## 🔍 Troubleshooting Add-ons

### Metrics Server Not Working

```bash
# Check logs
kubectl logs -n kube-system -l k8s-app=metrics-server

# Common issues:
# 1. Certificate errors (add --kubelet-insecure-tls)
# 2. Network policies blocking access
# 3. Not enough time passed (wait 1-2 minutes)

# Fix certificate issue:
kubectl edit deployment metrics-server -n kube-system
# Add under args: - --kubelet-insecure-tls
```

### Ingress Controller Not Working

```bash
# Check controller logs
kubectl logs -n ingress-nginx -l app.kubernetes.io/component=controller

# Check if webhook is ready
kubectl get validatingwebhookconfigurations
kubectl get pods -n ingress-nginx

# Common issues:
# 1. Webhook not ready
# 2. IngressClass not set
# 3. Service type incorrect
```

### Dashboard Not Accessible

```bash
# Check all dashboard resources
kubectl get all -n kubernetes-dashboard

# Check service type
kubectl get svc -n kubernetes-dashboard

# Use port-forward as fallback
kubectl port-forward -n kubernetes-dashboard svc/kubernetes-dashboard 8443:443
```

## 📋 Quick Install Script

```bash
#!/bin/bash

# Install common add-ons with kubectl

echo "Installing metrics-server..."
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

echo "Installing ingress-nginx..."
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.1/deploy/static/provider/cloud/deploy.yaml

echo "Waiting for components to be ready..."
kubectl wait --for=condition=ready pod -l k8s-app=metrics-server -n kube-system --timeout=60s
kubectl wait --for=condition=ready pod -l app.kubernetes.io/component=controller -n ingress-nginx --timeout=120s

echo "Verifying installations..."
kubectl get deployment metrics-server -n kube-system
kubectl get pods -n ingress-nginx
kubectl top nodes

echo "Add-ons installed successfully!"
```

## 💡 Remember

1. **In the exam**: Most add-ons are pre-installed
2. **Always check first**: `kubectl get all -n kube-system`
3. **Metrics-server**: Required for HPA and `kubectl top`
4. **Ingress**: Usually pre-installed, just use it
5. **Use kubectl apply**: Not minikube commands

---

**Back to**: [Main README](README.md) | [Minikube vs kubectl](MINIKUBE-VS-KUBECTL.md)
