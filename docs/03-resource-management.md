# Resource Management

Complete guide to Kubernetes resource requests, limits, and quotas for CKA preparation.

## Table of Contents

- [Overview](#overview)
- [Resource Requests](#resource-requests)
- [Resource Limits](#resource-limits)
- [Quality of Service](#quality-of-service)
- [ResourceQuota](#resourcequota)
- [LimitRange](#limitrange)
- [Troubleshooting OOMKilled](#troubleshooting-oomkilled)
- [Exam Tips](#exam-tips)

## Overview

Resource management ensures pods get the resources they need while preventing any single pod from consuming all cluster resources.

### Key Concepts

- **Requests**: Minimum resources guaranteed to a pod
- **Limits**: Maximum resources a pod can use
- **QoS Classes**: Guaranteed, Burstable, BestEffort
- **ResourceQuota**: Limits total resources in a namespace
- **LimitRange**: Default and min/max for pods/containers

## Resource Requests

Requests define the minimum amount of resources that must be available for a pod to be scheduled.

### CPU and Memory Requests

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: resource-demo
spec:
  containers:
  - name: app
    image: nginx
    resources:
      requests:
        memory: "64Mi"    # Minimum 64 MiB RAM
        cpu: "250m"       # Minimum 0.25 CPU cores
```

### Resource Units

**CPU**:
- `1` = 1 CPU core
- `1000m` = 1 CPU core (millicore)
- `500m` = 0.5 CPU core
- `100m` = 0.1 CPU core

**Memory**:
- `128974848` = bytes
- `129M` = 129 megabytes
- `123Mi` = 123 mebibytes
- `1Gi` = 1 gibibyte

### Set Requests Imperatively

```bash
# Create deployment
kubectl create deployment web --image=nginx

# Set resources
kubectl set resources deployment web \
  --requests=cpu=100m,memory=128Mi
```

## Resource Limits

Limits define the maximum amount of resources a pod can consume.

### CPU and Memory Limits

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: limited-pod
spec:
  containers:
  - name: app
    image: nginx
    resources:
      requests:
        memory: "64Mi"
        cpu: "250m"
      limits:
        memory: "128Mi"   # Maximum 128 MiB RAM
        cpu: "500m"       # Maximum 0.5 CPU cores
```

### What Happens When Limits Are Exceeded?

**CPU**:
- Pod is throttled (capped at limit)
- Never killed for exceeding CPU limit

**Memory**:
- Pod is OOMKilled (Out of Memory Killed)
- Pod restarts automatically

### Set Limits Imperatively

```bash
# Set both requests and limits
kubectl set resources deployment web \
  --requests=cpu=100m,memory=128Mi \
  --limits=cpu=500m,memory=256Mi
```

## Hands-On: Fix OOMKilled Pods

### Scenario 1: WordPress with Insufficient Memory

```bash
# Create problematic deployment
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: wordpress
spec:
  replicas: 3
  selector:
    matchLabels:
      app: wordpress
  template:
    metadata:
      labels:
        app: wordpress
    spec:
      containers:
      - name: wordpress
        image: wordpress:latest
        resources:
          requests:
            memory: "32Mi"   # Too low!
            cpu: "100m"
          limits:
            memory: "64Mi"   # Too low!
            cpu: "200m"
EOF
```

### Diagnose the Issue

```bash
# Check pod status
kubectl get pods -l app=wordpress

# Output shows CrashLoopBackOff or OOMKilled
NAME                         READY   STATUS              RESTARTS
wordpress-xxx                0/1     CrashLoopBackOff    3

# Describe pod to see reason
kubectl describe pod -l app=wordpress

# Look for:
# Last State: Terminated
# Reason: OOMKilled

# Check events
kubectl get events --sort-by='.lastTimestamp' | grep -i oom
```

### Fix with kubectl edit

```bash
# Method 1: Edit deployment
kubectl edit deployment wordpress

# Change in the editor:
resources:
  requests:
    memory: "256Mi"  # Increased
    cpu: "100m"
  limits:
    memory: "512Mi"  # Increased
    cpu: "500m"

# Save and exit (:wq in vim)
```

### Fix with kubectl patch

```bash
# Method 2: Patch deployment
kubectl patch deployment wordpress -p '
{
  "spec": {
    "template": {
      "spec": {
        "containers": [
          {
            "name": "wordpress",
            "resources": {
              "requests": {
                "memory": "256Mi",
                "cpu": "100m"
              },
              "limits": {
                "memory": "512Mi",
                "cpu": "500m"
              }
            }
          }
        ]
      }
    }
  }
}'
```

### Fix with kubectl set resources

```bash
# Method 3: Use set resources (fastest)
kubectl set resources deployment wordpress \
  --requests=cpu=100m,memory=256Mi \
  --limits=cpu=500m,memory=512Mi
```

### Verify Fix

```bash
# Watch pods restart
kubectl get pods -l app=wordpress --watch

# Pods should become Running
NAME                         READY   STATUS    RESTARTS   AGE
wordpress-xxx                1/1     Running   0          30s

# Verify resources
kubectl get pod -l app=wordpress -o yaml | grep -A 10 resources
```

## Quality of Service (QoS) Classes

Kubernetes assigns QoS classes based on requests and limits.

### 1. Guaranteed (Highest Priority)

Requests == Limits for all resources.

```yaml
resources:
  requests:
    memory: "200Mi"
    cpu: "500m"
  limits:
    memory: "200Mi"  # Same as request
    cpu: "500m"      # Same as request
```

### 2. Burstable (Medium Priority)

Requests < Limits (or only requests specified).

```yaml
resources:
  requests:
    memory: "100Mi"
    cpu: "250m"
  limits:
    memory: "200Mi"  # Higher than request
    cpu: "500m"      # Higher than request
```

### 3. BestEffort (Lowest Priority)

No requests or limits specified.

```yaml
# No resources section at all
containers:
- name: app
  image: nginx
  # No resources
```

### Check QoS Class

```bash
# Create pods with different QoS
kubectl run guaranteed --image=nginx \
  --dry-run=client -o yaml | \
  kubectl set resources -f - \
  --requests=cpu=100m,memory=128Mi \
  --limits=cpu=100m,memory=128Mi \
  --local -o yaml | kubectl apply -f -

kubectl run burstable --image=nginx \
  --dry-run=client -o yaml | \
  kubectl set resources -f - \
  --requests=cpu=100m,memory=128Mi \
  --limits=cpu=200m,memory=256Mi \
  --local -o yaml | kubectl apply -f -

kubectl run besteffort --image=nginx

# Check QoS class
kubectl get pod guaranteed -o jsonpath='{.status.qosClass}'
# Output: Guaranteed

kubectl get pod burstable -o jsonpath='{.status.qosClass}'
# Output: Burstable

kubectl get pod besteffort -o jsonpath='{.status.qosClass}'
# Output: BestEffort
```

### QoS and Eviction

When a node runs out of resources, pods are evicted in this order:
1. BestEffort pods first
2. Burstable pods exceeding requests
3. Guaranteed pods last (almost never evicted)

## ResourceQuota

Limit total resources in a namespace.

### Create ResourceQuota

```bash
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ResourceQuota
metadata:
  name: compute-quota
  namespace: default
spec:
  hard:
    requests.cpu: "4"          # Total CPU requests
    requests.memory: "8Gi"     # Total memory requests
    limits.cpu: "8"            # Total CPU limits
    limits.memory: "16Gi"      # Total memory limits
    pods: "10"                 # Max number of pods
EOF
```

### Object Count Quotas

```bash
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ResourceQuota
metadata:
  name: object-quota
spec:
  hard:
    persistentvolumeclaims: "5"
    services: "10"
    services.loadbalancers: "2"
    services.nodeports: "5"
    secrets: "10"
    configmaps: "10"
EOF
```

### Check ResourceQuota

```bash
# View quota
kubectl get resourcequota

# Describe quota
kubectl describe resourcequota compute-quota

# Output shows:
# Resource           Used  Hard
# --------           ----  ----
# limits.cpu         2     8
# limits.memory      4Gi   16Gi
# pods               3     10
# requests.cpu       1     4
# requests.memory    2Gi   8Gi
```

### Test ResourceQuota

```bash
# Try to exceed quota
kubectl create deployment big-app --image=nginx --replicas=20

# Some pods will be Pending
kubectl get pods

# Check events
kubectl get events | grep -i quota
# Error: exceeded quota: compute-quota
```

## LimitRange

Set default requests/limits and min/max values.

### Create LimitRange

```bash
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: LimitRange
metadata:
  name: limit-range
spec:
  limits:
  - max:                        # Maximum allowed
      cpu: "2"
      memory: "2Gi"
    min:                        # Minimum required
      cpu: "100m"
      memory: "64Mi"
    default:                    # Default limit if not specified
      cpu: "500m"
      memory: "512Mi"
    defaultRequest:             # Default request if not specified
      cpu: "250m"
      memory: "256Mi"
    type: Container
EOF
```

### Test LimitRange

```bash
# Create pod without resources
kubectl run test-limits --image=nginx

# Check assigned resources
kubectl get pod test-limits -o yaml | grep -A 10 resources

# Should see default values applied:
# requests:
#   cpu: 250m
#   memory: 256Mi
# limits:
#   cpu: 500m
#   memory: 512Mi
```

### LimitRange for Pods

```bash
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: LimitRange
metadata:
  name: pod-limit-range
spec:
  limits:
  - max:
      cpu: "4"
      memory: "4Gi"
    min:
      cpu: "200m"
      memory: "128Mi"
    type: Pod
EOF
```

## Monitoring Resource Usage

### Check Node Resources

```bash
# View node capacity
kubectl get nodes -o yaml | grep -A 10 capacity

# View node allocatable
kubectl get nodes -o yaml | grep -A 10 allocatable

# Describe node
kubectl describe node minikube
```

### Check Pod Resource Usage

```bash
# Requires metrics-server
minikube addons enable metrics-server

# View pod resource usage
kubectl top pods

# View node resource usage
kubectl top nodes

# Sort by CPU
kubectl top pods --sort-by=cpu

# Sort by memory
kubectl top pods --sort-by=memory

# Specific namespace
kubectl top pods -n kube-system

# All namespaces
kubectl top pods -A
```

### Resource Usage Examples

```bash
# Create pod with known load
kubectl run stress --image=polinux/stress \
  -- stress --cpu 2 --vm 1 --vm-bytes 256M

# Watch resource usage
kubectl top pod stress --watch

# Check if pod is being throttled
kubectl describe pod stress | grep -i throttl
```

## Troubleshooting

### Issue 1: Pod Stuck in Pending

```bash
# Check pod status
kubectl get pods

# Describe pod
kubectl describe pod <pod-name>

# Look for:
# Events:
#   Warning  FailedScheduling  ... Insufficient cpu
#   Warning  FailedScheduling  ... Insufficient memory

# Solution: Reduce requests or add more nodes
kubectl set resources deployment <n> --requests=cpu=50m,memory=64Mi
```

### Issue 2: OOMKilled Pods

```bash
# Identify OOMKilled pods
kubectl get pods --field-selector=status.phase=Failed

kubectl describe pod <pod-name>
# Last State: Terminated
# Reason: OOMKilled

# Solution: Increase memory limits
kubectl set resources deployment <n> --limits=memory=512Mi
```

### Issue 3: CPU Throttling

```bash
# Check if pod is CPU throttled
kubectl describe pod <pod-name> | grep -i throttl

# Check CPU usage
kubectl top pod <pod-name>

# Solution: Increase CPU limits
kubectl set resources deployment <n> --limits=cpu=1000m
```

### Issue 4: ResourceQuota Exceeded

```bash
# Check quota usage
kubectl describe resourcequota

# Solution 1: Increase quota
kubectl edit resourcequota <quota-name>

# Solution 2: Delete unused resources
kubectl delete pod <unused-pod>
```

## Exam Tips

### Quick Resource Management

```bash
# Set resources on existing deployment (FASTEST)
kubectl set resources deployment <n> \
  --requests=cpu=100m,memory=128Mi \
  --limits=cpu=500m,memory=256Mi

# Create deployment with resources
kubectl create deployment app --image=nginx
kubectl set resources deployment app --requests=cpu=100m,memory=128Mi
```

### Common Patterns

```bash
# Pattern 1: Fix OOMKilled deployment
kubectl get pods  # Identify OOMKilled
kubectl describe pod <n>  # Confirm OOMKilled
kubectl edit deployment <n>  # Increase memory
# or
kubectl set resources deployment <n> --limits=memory=512Mi

# Pattern 2: Set default resources
kubectl create limitrange defaults --default=cpu=500m,memory=512Mi \
  --default-request=cpu=250m,memory=256Mi

# Pattern 3: Create quota
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ResourceQuota
metadata:
  name: quota
spec:
  hard:
    requests.cpu: "4"
    requests.memory: "8Gi"
EOF
```

### Time-Saving Commands

```bash
# View resources quickly
kubectl top nodes
kubectl top pods

# Check QoS
kubectl get pod <n> -o jsonpath='{.status.qosClass}'

# Get pod resources
kubectl get pod <n> -o yaml | grep -A 10 resources
```

## Practice Exercises

### Exercise 1: Fix OOMKilled WordPress

WordPress deployment is crashing. Fix it.

```bash
# Create problem
kubectl create deployment wordpress --image=wordpress --replicas=3
kubectl set resources deployment wordpress --requests=memory=32Mi --limits=memory=64Mi

# Wait for OOMKilled
kubectl get pods --watch

# Your task: Fix it
```

<details>
<summary>Solution</summary>

```bash
kubectl set resources deployment wordpress \
  --requests=cpu=100m,memory=256Mi \
  --limits=cpu=500m,memory=512Mi
```
</details>

### Exercise 2: Create ResourceQuota

Create a ResourceQuota limiting:
- Max 10 pods
- Total CPU requests: 4 cores
- Total memory requests: 8Gi

<details>
<summary>Solution</summary>

```bash
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ResourceQuota
metadata:
  name: my-quota
spec:
  hard:
    pods: "10"
    requests.cpu: "4"
    requests.memory: "8Gi"
EOF
```
</details>

### Exercise 3: Create LimitRange

Create LimitRange with defaults:
- CPU request: 100m, limit: 500m
- Memory request: 128Mi, limit: 256Mi

<details>
<summary>Solution</summary>

```bash
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: LimitRange
metadata:
  name: defaults
spec:
  limits:
  - default:
      cpu: "500m"
      memory: "256Mi"
    defaultRequest:
      cpu: "100m"
      memory: "128Mi"
    type: Container
EOF
```
</details>

## Quick Reference

### Resource Commands

```bash
# Set resources
kubectl set resources deployment <n> \
  --requests=cpu=100m,memory=128Mi \
  --limits=cpu=500m,memory=256Mi

# View usage
kubectl top nodes
kubectl top pods

# Create quota
kubectl create quota <n> --hard=pods=10,cpu=4,memory=8Gi

# View quota
kubectl get resourcequota
kubectl describe resourcequota <n>

# Create limitrange
kubectl create limitrange <n> \
  --default=cpu=500m,memory=512Mi \
  --default-request=cpu=250m,memory=256Mi
```

### Resource Units Cheat Sheet

```bash
# CPU
1 = 1 core
1000m = 1 core
500m = 0.5 core
100m = 0.1 core

# Memory
1Ki = 1024 bytes
1Mi = 1024 Ki
1Gi = 1024 Mi
1Ti = 1024 Gi
```

---

**Back to**: [Main README](../README.md) | [Previous: Ingress](02-ingress-networking.md) | [Next: Storage](04-storage-management.md)
