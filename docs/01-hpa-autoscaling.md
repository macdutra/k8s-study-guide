# Horizontal Pod Autoscaler (HPA) Deep Dive

Complete guide to Kubernetes HPA with ScaleDown behavior for CKA preparation.

## Table of Contents

- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Basic HPA](#basic-hpa)
- [Advanced HPA with Behavior](#advanced-hpa-with-behavior)
- [ScaleDown Configuration](#scaledown-configuration)
- [Hands-On Practice](#hands-on-practice)
- [Troubleshooting](#troubleshooting)
- [Exam Tips](#exam-tips)

## Overview

The Horizontal Pod Autoscaler (HPA) automatically scales the number of pods in a deployment, replica set, or stateful set based on observed metrics.

### Key Concepts

- **Metrics**: CPU, memory, or custom metrics
- **Target**: Desired metric value (e.g., 50% CPU)
- **Scale Range**: Minimum and maximum replicas
- **Behavior**: Controls scaling velocity and stability

## Prerequisites

### Enable Metrics Server

```bash
# Check if metrics-server is running
kubectl get deployment metrics-server -n kube-system

# If not, enable it
minikube addons enable metrics-server

# Verify metrics are available
kubectl top nodes
kubectl top pods -A
```

### Verify Metrics Server

```bash
# Check metrics-server pods
kubectl get pods -n kube-system -l k8s-app=metrics-server

# View metrics-server logs
kubectl logs -n kube-system -l k8s-app=metrics-server

# Test metrics
kubectl top node
```

## Basic HPA

### Creating a Simple HPA

#### Step 1: Create Deployment

```bash
# Create deployment with resource limits
kubectl create deployment php-apache \
  --image=registry.k8s.io/hpa-example \
  --replicas=1

# Add resource requests and limits
kubectl set resources deployment php-apache \
  --requests=cpu=200m,memory=128Mi \
  --limits=cpu=500m,memory=256Mi
```

#### Step 2: Expose as Service

```bash
# Create service
kubectl expose deployment php-apache --port=80
```

#### Step 3: Create Basic HPA

```bash
# Create HPA using imperative command
kubectl autoscale deployment php-apache \
  --cpu-percent=50 \
  --min=1 \
  --max=10

# Verify HPA
kubectl get hpa php-apache
kubectl describe hpa php-apache
```

#### Step 4: Generate Load

```bash
# In one terminal, watch HPA
kubectl get hpa php-apache --watch

# In another terminal, generate load
kubectl run load-generator \
  --image=busybox \
  --restart=Never \
  -it --rm \
  -- /bin/sh -c "while sleep 0.01; do wget -q -O- http://php-apache; done"

# Watch pods scaling
kubectl get pods --watch
```

### Understanding HPA Output

```bash
NAME         REFERENCE               TARGETS   MINPODS   MAXPODS   REPLICAS   AGE
php-apache   Deployment/php-apache   0%/50%    1         10        1          5m

# TARGETS: current/target
# 0%/50% means current CPU is 0%, target is 50%
```

## Advanced HPA with Behavior

### HPA v2 API

The v2 API provides advanced features:
- Multiple metrics
- Custom metrics
- Scaling behavior control

### Complete HPA Manifest

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: advanced-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: php-apache
  
  minReplicas: 1
  maxReplicas: 10
  
  metrics:
  # CPU metric
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 50
  
  # Memory metric (optional)
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 70
  
  behavior:
    scaleDown:
      stabilizationWindowSeconds: 300
      policies:
      - type: Percent
        value: 50
        periodSeconds: 15
      - type: Pods
        value: 2
        periodSeconds: 60
      selectPolicy: Min
    
    scaleUp:
      stabilizationWindowSeconds: 0
      policies:
      - type: Percent
        value: 100
        periodSeconds: 15
      - type: Pods
        value: 4
        periodSeconds: 60
      selectPolicy: Max
```

### Apply Advanced HPA

```bash
# Save manifest to file
cat > advanced-hpa.yaml << 'EOF'
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: advanced-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: php-apache
  minReplicas: 1
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 50
  behavior:
    scaleDown:
      stabilizationWindowSeconds: 300
      policies:
      - type: Percent
        value: 50
        periodSeconds: 15
      selectPolicy: Min
EOF

# Apply
kubectl apply -f advanced-hpa.yaml

# View
kubectl get hpa advanced-hpa -o yaml
```

## ScaleDown Configuration

### Understanding ScaleDown Behavior

The ScaleDown behavior controls how fast pods are removed when load decreases.

#### Key Parameters

1. **stabilizationWindowSeconds**: 
   - How long to wait before scaling down
   - Prevents flapping
   - Default: 300 seconds (5 minutes)

2. **policies**: 
   - Rules that limit scaling velocity
   - Can specify percentage or absolute number
   - Multiple policies can be defined

3. **selectPolicy**:
   - `Min`: Use the policy that scales down the least
   - `Max`: Use the policy that scales down the most
   - `Disabled`: Disable scaleDown

### ScaleDown Examples

#### Conservative ScaleDown (Slow)

```yaml
behavior:
  scaleDown:
    stabilizationWindowSeconds: 600  # Wait 10 minutes
    policies:
    - type: Percent
      value: 25                      # Max 25% per period
      periodSeconds: 60              # Every minute
    selectPolicy: Min
```

#### Aggressive ScaleDown (Fast)

```yaml
behavior:
  scaleDown:
    stabilizationWindowSeconds: 60   # Wait 1 minute
    policies:
    - type: Percent
      value: 100                     # Can remove all at once
      periodSeconds: 15              # Every 15 seconds
    selectPolicy: Max
```

#### Balanced ScaleDown (Recommended)

```yaml
behavior:
  scaleDown:
    stabilizationWindowSeconds: 300  # Wait 5 minutes
    policies:
    - type: Percent
      value: 50                      # Max 50% per period
      periodSeconds: 15              # Every 15 seconds
    - type: Pods
      value: 2                       # Or max 2 pods per period
      periodSeconds: 60              # Every minute
    selectPolicy: Min                # Use more conservative
```

### Disable ScaleDown

```yaml
behavior:
  scaleDown:
    selectPolicy: Disabled
```

## Hands-On Practice

### Exercise 1: Basic HPA (Exam Style)

**Task**: Create an HPA with min=1, max=4, and ScaleDown parameter.

```bash
# Step 1: Create deployment
kubectl create deployment web-app --image=nginx:alpine

# Step 2: Set resources
kubectl set resources deployment web-app \
  --requests=cpu=100m,memory=128Mi \
  --limits=cpu=500m,memory=256Mi

# Step 3: Create HPA with behavior
cat <<EOF | kubectl apply -f -
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: web-app-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: web-app
  minReplicas: 1
  maxReplicas: 4
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 50
  behavior:
    scaleDown:
      stabilizationWindowSeconds: 60
      policies:
      - type: Percent
        value: 50
        periodSeconds: 15
EOF

# Verify
kubectl get hpa web-app-hpa
kubectl describe hpa web-app-hpa
```

### Exercise 2: Test Scaling

```bash
# Generate load
kubectl run load-generator \
  --image=busybox \
  --restart=Never \
  --rm -it \
  -- /bin/sh -c "while true; do wget -q -O- http://web-app; done"

# Watch in another terminal
kubectl get hpa web-app-hpa --watch
kubectl get pods -l app=web-app --watch
```

### Exercise 3: Memory-Based Scaling

```bash
cat <<EOF | kubectl apply -f -
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: memory-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: web-app
  minReplicas: 2
  maxReplicas: 8
  metrics:
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 70
  behavior:
    scaleDown:
      stabilizationWindowSeconds: 180
      policies:
      - type: Pods
        value: 1
        periodSeconds: 30
EOF
```

### Exercise 4: Multiple Metrics

```bash
cat <<EOF | kubectl apply -f -
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: multi-metric-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: web-app
  minReplicas: 1
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 50
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 80
  behavior:
    scaleDown:
      stabilizationWindowSeconds: 300
      policies:
      - type: Percent
        value: 50
        periodSeconds: 15
    scaleUp:
      stabilizationWindowSeconds: 0
      policies:
      - type: Percent
        value: 100
        periodSeconds: 15
      - type: Pods
        value: 4
        periodSeconds: 60
      selectPolicy: Max
EOF
```

## Troubleshooting

### Common Issues

#### 1. HPA shows "unknown" for metrics

```bash
# Check if metrics-server is running
kubectl get pods -n kube-system -l k8s-app=metrics-server

# Check HPA status
kubectl describe hpa <hpa-name>

# Check if pods have resource requests
kubectl get pod <pod-name> -o yaml | grep -A 5 resources

# Solution: Ensure resource requests are set
kubectl set resources deployment <n> --requests=cpu=100m
```

#### 2. HPA not scaling

```bash
# Check current metrics
kubectl top pods -l app=<app>

# Check HPA events
kubectl describe hpa <hpa-name>

# Check target percentage
kubectl get hpa <hpa-name>

# View detailed status
kubectl get hpa <hpa-name> -o yaml
```

#### 3. Pods scaling too aggressively

```bash
# Increase stabilizationWindowSeconds
kubectl patch hpa <hpa-name> -p '
{
  "spec": {
    "behavior": {
      "scaleDown": {
        "stabilizationWindowSeconds": 600
      }
    }
  }
}'
```

#### 4. ScaleDown not working

```bash
# Check behavior configuration
kubectl get hpa <hpa-name> -o yaml | grep -A 20 behavior

# Ensure selectPolicy is not Disabled
# Verify stabilization window has passed
```

### Debugging Commands

```bash
# View HPA in detail
kubectl get hpa <hpa-name> -o yaml

# Watch HPA status
kubectl get hpa --watch

# Check metrics
kubectl top pods
kubectl top nodes

# View events
kubectl get events --field-selector involvedObject.name=<hpa-name>

# Describe HPA
kubectl describe hpa <hpa-name>
```

## Exam Tips

### Quick HPA Creation

```bash
# Imperative command (fastest)
kubectl autoscale deployment <n> --cpu-percent=50 --min=1 --max=10

# Generate YAML
kubectl autoscale deployment <n> \
  --cpu-percent=50 --min=1 --max=10 \
  --dry-run=client -o yaml > hpa.yaml
```

### Adding ScaleDown Behavior

```bash
# You'll need to edit the YAML to add behavior
kubectl autoscale deployment web-app --cpu-percent=50 --min=1 --max=4 \
  --dry-run=client -o yaml | kubectl apply -f -

# Then edit to add behavior
kubectl edit hpa web-app

# Add under spec:
behavior:
  scaleDown:
    stabilizationWindowSeconds: 60
    policies:
    - type: Percent
      value: 50
      periodSeconds: 15
```

### Time-Saving Tips

1. **Use imperative for basic HPA**: `kubectl autoscale`
2. **Use YAML for behavior**: Can't add behavior imperatively
3. **Remember to set resource requests**: HPA won't work without them
4. **Check metrics-server first**: Common failure point
5. **Use kubectl explain**: `kubectl explain hpa.spec.behavior`

### Common Exam Patterns

```bash
# Pattern 1: Create deployment + HPA
kubectl create deployment app --image=nginx
kubectl set resources deployment app --requests=cpu=100m
kubectl autoscale deployment app --cpu-percent=50 --min=1 --max=4

# Pattern 2: Add ScaleDown to existing HPA
kubectl get hpa app -o yaml > hpa.yaml
# Edit hpa.yaml to add behavior
kubectl apply -f hpa.yaml

# Pattern 3: Quick verification
kubectl get hpa
kubectl describe hpa <name>
kubectl top pods
```

## Practice Questions

### Question 1
Create an HPA named `api-hpa` for deployment `api-server` with:
- Min replicas: 2
- Max replicas: 6
- CPU target: 60%
- ScaleDown: 30% every 30 seconds

<details>
<summary>Solution</summary>

```bash
kubectl set resources deployment api-server --requests=cpu=200m

cat <<EOF | kubectl apply -f -
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: api-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: api-server
  minReplicas: 2
  maxReplicas: 6
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 60
  behavior:
    scaleDown:
      policies:
      - type: Percent
        value: 30
        periodSeconds: 30
EOF
```
</details>

### Question 2
Modify existing HPA to prevent any scaleDown for 10 minutes after scaleUp.

<details>
<summary>Solution</summary>

```bash
kubectl patch hpa <hpa-name> -p '
{
  "spec": {
    "behavior": {
      "scaleDown": {
        "stabilizationWindowSeconds": 600
      }
    }
  }
}'
```
</details>

## Reference

### HPA API Versions

- `autoscaling/v1`: Basic CPU-based scaling
- `autoscaling/v2beta2`: Deprecated, use v2
- `autoscaling/v2`: Current, supports behavior and multiple metrics

### Key kubectl Commands

```bash
# Create HPA
kubectl autoscale deployment <n> --cpu-percent=50 --min=1 --max=10

# Get HPA
kubectl get hpa
kubectl get hpa <name> -o yaml

# Describe HPA
kubectl describe hpa <name>

# Delete HPA
kubectl delete hpa <name>

# Edit HPA
kubectl edit hpa <name>

# Patch HPA
kubectl patch hpa <name> -p '{...}'
```

---

**Back to**: [Main README](../README.md) | [Practice Exercises](../examples/)
