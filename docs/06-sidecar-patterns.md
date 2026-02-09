# Multi-Container Pods & Sidecar Patterns

Complete guide to multi-container pods, sidecar patterns, and init containers for CKA preparation.

## Table of Contents

- [Overview](#overview)
- [Multi-Container Pod Basics](#multi-container-pod-basics)
- [Sidecar Pattern](#sidecar-pattern)
- [Init Containers](#init-containers)
- [Shared Volumes](#shared-volumes)
- [Ambassador Pattern](#ambassador-pattern)
- [Adapter Pattern](#adapter-pattern)
- [Hands-On Practice](#hands-on-practice)
- [Troubleshooting](#troubleshooting)
- [Exam Tips](#exam-tips)

## Overview

Multi-container pods run multiple containers in a single pod that share resources and work together.

### Key Concepts

- **Pod**: Smallest deployable unit (can have multiple containers)
- **Sidecar**: Helper container that enhances main container
- **Init Container**: Runs before main containers start
- **Shared Volume**: Storage accessible by all containers in pod
- **Shared Network**: All containers share same IP and ports

### Why Multiple Containers?

```
Single Container Pod:          Multi-Container Pod:
┌─────────────┐               ┌─────────────────────┐
│    Pod      │               │       Pod           │
│  ┌───────┐  │               │  ┌───────┬───────┐  │
│  │  App  │  │               │  │  App  │Sidecar│  │
│  └───────┘  │               │  └───┬───┴───┬───┘  │
└─────────────┘               │      └───────┘      │
                              │   Shared Volume     │
                              └─────────────────────┘
```

## Multi-Container Pod Basics

### Simple Multi-Container Pod

```bash
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: multi-container-pod
spec:
  containers:
  - name: nginx
    image: nginx
    ports:
    - containerPort: 80
  - name: busybox
    image: busybox
    command: ['sh', '-c', 'while true; do echo "Hello from busybox"; sleep 10; done']
EOF
```

### Verify Multiple Containers

```bash
# Get pod
kubectl get pod multi-container-pod

# Output shows 2/2 containers running
NAME                   READY   STATUS    RESTARTS   AGE
multi-container-pod    2/2     Running   0          1m

# Describe pod to see both containers
kubectl describe pod multi-container-pod

# View logs from specific container
kubectl logs multi-container-pod -c nginx
kubectl logs multi-container-pod -c busybox

# Execute command in specific container
kubectl exec -it multi-container-pod -c nginx -- /bin/bash
kubectl exec -it multi-container-pod -c busybox -- sh
```

## Sidecar Pattern

Sidecar container assists the main container (logging, monitoring, proxy).

### Example: Logging Sidecar

```bash
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: sidecar-logging
spec:
  volumes:
  - name: shared-logs
    emptyDir: {}
  
  containers:
  # Main application container
  - name: app
    image: nginx
    volumeMounts:
    - name: shared-logs
      mountPath: /var/log/nginx
  
  # Sidecar container for log processing
  - name: log-sidecar
    image: busybox
    command: ['sh', '-c', 'tail -f /logs/access.log']
    volumeMounts:
    - name: shared-logs
      mountPath: /logs
EOF
```

### How It Works

```
┌─────────────────────────────────┐
│           Pod                   │
│                                 │
│  ┌──────────┐    ┌──────────┐  │
│  │   Nginx  │    │   Log    │  │
│  │          │    │ Sidecar  │  │
│  │   writes │    │  reads   │  │
│  └────┬─────┘    └─────┬────┘  │
│       │                │        │
│       └────┬───────────┘        │
│            │                    │
│      ┌─────▼─────┐              │
│      │  Shared   │              │
│      │  Volume   │              │
│      │ /var/log  │              │
│      └───────────┘              │
└─────────────────────────────────┘
```

### Test Sidecar

```bash
# Generate some traffic to nginx
kubectl exec -it sidecar-logging -c app -- curl localhost

# Check sidecar logs (should show access.log entries)
kubectl logs sidecar-logging -c log-sidecar
```

### Real-World Sidecar Examples

```bash
# 1. Metrics exporter sidecar
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: app-with-metrics
spec:
  containers:
  - name: app
    image: myapp:1.0
  - name: metrics-exporter
    image: prometheus-exporter
    ports:
    - containerPort: 9090
EOF

# 2. Service mesh proxy (like Istio)
# Automatically injected by Istio
# - name: istio-proxy
#   image: istio/proxyv2

# 3. Configuration reloader
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: app-with-reloader
spec:
  volumes:
  - name: config
    configMap:
      name: app-config
  containers:
  - name: app
    image: myapp
    volumeMounts:
    - name: config
      mountPath: /config
  - name: config-reloader
    image: config-reloader
    volumeMounts:
    - name: config
      mountPath: /config
EOF
```

## Init Containers

Init containers run and complete before main containers start.

### Basic Init Container

```bash
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: init-container-demo
spec:
  # Init containers run first
  initContainers:
  - name: init-myservice
    image: busybox
    command: ['sh', '-c', 'echo "Initializing..." && sleep 5']
  
  - name: init-mydb
    image: busybox
    command: ['sh', '-c', 'echo "Waiting for DB..." && sleep 5']
  
  # Main container runs after all init containers succeed
  containers:
  - name: app
    image: nginx
EOF
```

### Watch Init Containers

```bash
# Watch pod startup
kubectl get pod init-container-demo --watch

# You'll see:
# NAME                   READY   STATUS     RESTARTS   AGE
# init-container-demo    0/1     Init:0/2   0          0s
# init-container-demo    0/1     Init:1/2   0          5s
# init-container-demo    0/1     PodInitializing   0   10s
# init-container-demo    1/1     Running    0          11s

# View init container logs
kubectl logs init-container-demo -c init-myservice
kubectl logs init-container-demo -c init-mydb
```

### Init Container Use Cases

#### 1. Wait for Service

```bash
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: wait-for-db
spec:
  initContainers:
  - name: wait-for-database
    image: busybox
    command: ['sh', '-c', 'until nslookup database-service; do echo waiting for db; sleep 2; done']
  
  containers:
  - name: app
    image: myapp
EOF
```

#### 2. Clone Git Repository

```bash
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: git-clone-pod
spec:
  volumes:
  - name: workdir
    emptyDir: {}
  
  initContainers:
  - name: git-clone
    image: alpine/git
    command: ['git', 'clone', 'https://github.com/user/repo.git', '/work']
    volumeMounts:
    - name: workdir
      mountPath: /work
  
  containers:
  - name: web
    image: nginx
    volumeMounts:
    - name: workdir
      mountPath: /usr/share/nginx/html
EOF
```

#### 3. Database Migration

```bash
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: app-with-migration
spec:
  initContainers:
  - name: db-migration
    image: myapp-migrations:latest
    command: ['./migrate', 'up']
    env:
    - name: DB_HOST
      value: "database-service"
  
  containers:
  - name: app
    image: myapp:latest
EOF
```

## Shared Volumes

Multiple containers sharing data via volumes.

### EmptyDir Volume

```bash
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: shared-volume-pod
spec:
  volumes:
  - name: shared-data
    emptyDir: {}
  
  containers:
  # Writer container
  - name: writer
    image: busybox
    command: ['sh', '-c', 'while true; do date >> /data/log.txt; sleep 5; done']
    volumeMounts:
    - name: shared-data
      mountPath: /data
  
  # Reader container
  - name: reader
    image: busybox
    command: ['sh', '-c', 'tail -f /data/log.txt']
    volumeMounts:
    - name: shared-data
      mountPath: /data
EOF
```

### Test Shared Volume

```bash
# Check writer logs
kubectl logs shared-volume-pod -c writer

# Check reader logs (should show same dates)
kubectl logs shared-volume-pod -c reader

# Exec into reader and verify file
kubectl exec -it shared-volume-pod -c reader -- cat /data/log.txt
```

### HostPath Volume (Shared with Node)

```bash
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: hostpath-pod
spec:
  volumes:
  - name: host-data
    hostPath:
      path: /tmp/data
      type: DirectoryOrCreate
  
  containers:
  - name: container1
    image: nginx
    volumeMounts:
    - name: host-data
      mountPath: /data
  
  - name: container2
    image: busybox
    command: ['sh', '-c', 'sleep 3600']
    volumeMounts:
    - name: host-data
      mountPath: /data
EOF
```

## Ambassador Pattern

Ambassador container proxies network connections for main container.

### Example: Database Proxy

```bash
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: ambassador-pod
spec:
  containers:
  # Main application
  - name: app
    image: myapp
    env:
    - name: DB_HOST
      value: "localhost"  # Connects to ambassador
    - name: DB_PORT
      value: "5432"
  
  # Ambassador proxy
  - name: db-proxy
    image: ambassador/ambassador:1.0
    ports:
    - containerPort: 5432
    env:
    - name: REAL_DB_HOST
      value: "production-db.example.com"
    - name: REAL_DB_PORT
      value: "5432"
EOF
```

### How Ambassador Works

```
┌────────────────────────────────┐
│          Pod                   │
│                                │
│  ┌──────────┐   ┌──────────┐  │
│  │   App    │──▶│Ambassador│──────▶ External
│  │          │   │  Proxy   │  │     Database
│  │localhost:│   │          │  │
│  │   5432   │   │5432→remote│ │
│  └──────────┘   └──────────┘  │
└────────────────────────────────┘
```

## Adapter Pattern

Adapter container transforms output from main container.

### Example: Log Adapter

```bash
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: adapter-pod
spec:
  volumes:
  - name: logs
    emptyDir: {}
  
  containers:
  # Application writes custom log format
  - name: app
    image: myapp
    volumeMounts:
    - name: logs
      mountPath: /var/log
  
  # Adapter converts to standard format
  - name: log-adapter
    image: log-formatter
    volumeMounts:
    - name: logs
      mountPath: /var/log
    command: ['sh', '-c', './format-logs.sh /var/log/app.log']
EOF
```

## Hands-On Practice

### Exercise 1: Create Sidecar Logging Pod

**Task:** Create a pod with nginx and a logging sidecar.

```bash
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: nginx-with-logger
spec:
  volumes:
  - name: logs
    emptyDir: {}
  
  containers:
  - name: nginx
    image: nginx
    volumeMounts:
    - name: logs
      mountPath: /var/log/nginx
  
  - name: logger
    image: busybox
    command: ['sh', '-c', 'tail -f /logs/access.log']
    volumeMounts:
    - name: logs
      mountPath: /logs
EOF

# Test it
kubectl exec nginx-with-logger -c nginx -- curl localhost
kubectl logs nginx-with-logger -c logger
```

### Exercise 2: Init Container Setup

**Task:** Create pod that waits for a service before starting.

```bash
# Create the service first (postgres requires password)
kubectl create deployment db --image=postgres:alpine --dry-run=client -o yaml > db-deployment.yaml

# Add the required POSTGRES_PASSWORD environment variable
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: db
spec:
  selector:
    matchLabels:
      app: db
  template:
    metadata:
      labels:
        app: db
    spec:
      containers:
      - name: postgres
        image: postgres:alpine
        env:
        - name: POSTGRES_PASSWORD
          value: "mysecretpassword"
        ports:
        - containerPort: 5432
EOF

# Expose the service
kubectl expose deployment db --port=5432

# Create pod with init container
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: app-with-init
spec:
  initContainers:
  - name: wait-for-db
    image: busybox
    command: ['sh', '-c', 'until nslookup db; do echo waiting; sleep 2; done']
  
  containers:
  - name: app
    image: nginx
EOF

# Watch it start
kubectl get pod app-with-init --watch
```

### Exercise 3: Shared Volume Communication

**Task:** Two containers communicating via shared file.

```bash
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: file-share
spec:
  volumes:
  - name: shared
    emptyDir: {}
  
  containers:
  - name: producer
    image: busybox
    command: ['sh', '-c', 'for i in $(seq 1 10); do echo "Message $i" >> /data/messages.txt; sleep 3; done']
    volumeMounts:
    - name: shared
      mountPath: /data
  
  - name: consumer
    image: busybox
    command: ['sh', '-c', 'tail -f /data/messages.txt']
    volumeMounts:
    - name: shared
      mountPath: /data
EOF

# Watch the messages
kubectl logs file-share -c consumer -f
```

## Troubleshooting

### Issue 1: Init Container Failing

```bash
# Check pod status
kubectl get pod <pod-name>

# Output might show:
# NAME      READY   STATUS                  RESTARTS   AGE
# my-pod    0/1     Init:CrashLoopBackOff   3          2m

# Check which init container failed
kubectl describe pod <pod-name>

# View init container logs
kubectl logs <pod-name> -c <init-container-name>

# Common issues:
# 1. Waiting for service that doesn't exist
# 2. Command syntax error
# 3. Missing dependencies
```

### Issue 2: Sidecar Not Seeing Files

```bash
# Verify volume is mounted in both containers
kubectl describe pod <pod-name>

# Check volume mounts section for each container
# Volumes:
#   shared-data:
#     Type:       EmptyDir
# Mounts:
#   /data from shared-data (rw)

# Exec into containers and check
kubectl exec -it <pod> -c container1 -- ls -la /data
kubectl exec -it <pod> -c container2 -- ls -la /data
```

### Issue 3: Wrong Container in Logs/Exec

```bash
# Always specify container name with -c
kubectl logs <pod> -c <container-name>
kubectl exec -it <pod> -c <container-name> -- sh

# List all containers in pod
kubectl get pod <pod> -o jsonpath='{.spec.containers[*].name}'
```

## Exam Tips

### Quick Multi-Container Pod Creation

```bash
# Generate base pod YAML
kubectl run multi --image=nginx --dry-run=client -o yaml > pod.yaml

# Edit to add second container
vim pod.yaml

# Add under spec.containers:
  - name: sidecar
    image: busybox
    command: ['sh', '-c', 'sleep 3600']

# Apply
kubectl apply -f pod.yaml
```

### Common Exam Patterns

**Pattern 1: Logging Sidecar**
```yaml
volumes:
- name: logs
  emptyDir: {}
containers:
- name: app
  volumeMounts:
  - name: logs
    mountPath: /var/log
- name: logger
  volumeMounts:
  - name: logs
    mountPath: /logs
```

**Pattern 2: Init Container Wait**
```yaml
initContainers:
- name: wait
  image: busybox
  command: ['sh', '-c', 'until nslookup service; do sleep 2; done']
```

**Pattern 3: Shared Data**
```yaml
volumes:
- name: data
  emptyDir: {}
containers:
- name: writer
  volumeMounts:
  - name: data
    mountPath: /data
- name: reader
  volumeMounts:
  - name: data
    mountPath: /data
    readOnly: true
```

### Time-Saving Commands

```bash
# View specific container logs
kubectl logs <pod> -c <container>

# Exec into specific container
kubectl exec -it <pod> -c <container> -- sh

# Get container names
kubectl get pod <pod> -o jsonpath='{.spec.containers[*].name}'

# Check init container status
kubectl describe pod <pod> | grep -A 10 "Init Containers"
```

## Practice Questions

### Question 1

Create a pod named "web-logger" with:
- nginx container
- busybox sidecar that tails nginx access logs
- Shared emptyDir volume

<details>
<summary>Solution</summary>

```bash
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: web-logger
spec:
  volumes:
  - name: logs
    emptyDir: {}
  containers:
  - name: nginx
    image: nginx
    volumeMounts:
    - name: logs
      mountPath: /var/log/nginx
  - name: sidecar
    image: busybox
    command: ['sh', '-c', 'tail -f /logs/access.log']
    volumeMounts:
    - name: logs
      mountPath: /logs
EOF
```
</details>

### Question 2

Create a pod with an init container that waits for service "database" before starting main container.

<details>
<summary>Solution</summary>

```bash
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: app-wait-db
spec:
  initContainers:
  - name: wait-db
    image: busybox
    command: ['sh', '-c', 'until nslookup database; do echo waiting; sleep 2; done']
  containers:
  - name: app
    image: nginx
EOF
```
</details>

## Quick Reference

### Multi-Container Pod Template

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: multi-pod
spec:
  volumes:
  - name: shared
    emptyDir: {}
  
  initContainers:
  - name: init
    image: busybox
    command: ['sh', '-c', 'echo init']
  
  containers:
  - name: main
    image: nginx
    volumeMounts:
    - name: shared
      mountPath: /data
  
  - name: sidecar
    image: busybox
    command: ['sh', '-c', 'sleep 3600']
    volumeMounts:
    - name: shared
      mountPath: /data
```

### Common Commands

```bash
# Create multi-container pod
kubectl apply -f pod.yaml

# Check container status
kubectl get pod <n> -o jsonpath='{.status.containerStatuses[*].name}'

# Logs from specific container
kubectl logs <pod> -c <container>

# Exec into specific container
kubectl exec -it <pod> -c <container> -- sh

# Describe (shows init containers separately)
kubectl describe pod <pod>
```

---

**Back to**: [Main README](../README.md) | [Previous: Network Policies](05-network-policies.md) | [Next: Pod Scheduling](07-pod-scheduling.md)
