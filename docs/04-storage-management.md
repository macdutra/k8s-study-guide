# Storage Management

Complete guide to Kubernetes storage: PersistentVolumes, PersistentVolumeClaims, and StorageClasses.

## Table of Contents

- [Overview](#overview)
- [Storage Concepts](#storage-concepts)
- [PersistentVolumes](#persistentvolumes)
- [PersistentVolumeClaims](#persistentvolumeclaims)
- [StorageClasses](#storageclasses)
- [Volume Binding Modes](#volume-binding-modes)
- [Hands-On Practice](#hands-on-practice)
- [Troubleshooting](#troubleshooting)
- [Exam Tips](#exam-tips)

## Overview

Kubernetes storage abstracts the details of how storage is provided from how it is consumed.

### Key Concepts

- **Volume**: Directory accessible to containers in a pod
- **PersistentVolume (PV)**: Cluster-level storage resource
- **PersistentVolumeClaim (PVC)**: User's request for storage
- **StorageClass**: Dynamic provisioning template

## Storage Concepts

### Volume Lifecycle

```
StorageClass → PersistentVolume → PersistentVolumeClaim → Pod
     ↓              ↓                    ↓              ↓
 Template      Provisioned            Bound         Mounted
```

### Access Modes

- **ReadWriteOnce (RWO)**: Single node read-write
- **ReadOnlyMany (ROX)**: Multiple nodes read-only
- **ReadWriteMany (RWX)**: Multiple nodes read-write

### Reclaim Policies

- **Retain**: Keep volume after PVC deletion
- **Delete**: Delete volume after PVC deletion
- **Recycle**: Scrub data and reuse (deprecated)

## PersistentVolumes

### Create PersistentVolume Manually

```bash
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv-manual
spec:
  capacity:
    storage: 5Gi
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  storageClassName: manual
  hostPath:
    path: /mnt/data
EOF
```

### View PersistentVolumes

```bash
# List all PVs
kubectl get pv

# Describe PV
kubectl describe pv pv-manual

# Output shows:
# Name:            pv-manual
# Capacity:        5Gi
# Access Modes:    RWO
# Status:          Available
# Claim:           
# Reclaim Policy:  Retain
# Storage Class:   manual
```

### PV Status

- **Available**: Ready for use
- **Bound**: Bound to a PVC
- **Released**: PVC deleted, but not reclaimed
- **Failed**: Automatic reclamation failed

## PersistentVolumeClaims

### Create PersistentVolumeClaim

```bash
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: pvc-manual
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: manual
  resources:
    requests:
      storage: 3Gi
EOF
```

### View PersistentVolumeClaims

```bash
# List PVCs
kubectl get pvc

# Describe PVC
kubectl describe pvc pvc-manual

# Check binding
kubectl get pvc pvc-manual -o yaml | grep -A 3 status

# Output:
# status:
#   accessModes:
#   - ReadWriteOnce
#   capacity:
#     storage: 5Gi
#   phase: Bound
```

### PVC Status

- **Pending**: Waiting for suitable PV
- **Bound**: Bound to a PV
- **Lost**: PV no longer exists

## StorageClasses

### View Available StorageClasses

```bash
# List storage classes
kubectl get sc
kubectl get storageclass

# In minikube, default is:
# NAME                 PROVISIONER                RECLAIMPOLICY
# standard (default)   k8s.io/minikube-hostpath   Delete
```

### Create Custom StorageClass

```bash
cat <<EOF | kubectl apply -f -
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: fast-storage
provisioner: k8s.io/minikube-hostpath
volumeBindingMode: Immediate
reclaimPolicy: Delete
allowVolumeExpansion: true
EOF
```

### StorageClass with WaitForFirstConsumer

```bash
cat <<EOF | kubectl apply -f -
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: delayed-storage
provisioner: k8s.io/minikube-hostpath
volumeBindingMode: WaitForFirstConsumer
reclaimPolicy: Delete
allowVolumeExpansion: true
EOF
```

## Volume Binding Modes

### Immediate Binding

PV is provisioned and bound immediately when PVC is created.

```yaml
volumeBindingMode: Immediate
```

### WaitForFirstConsumer (Exam Important!)

PV provisioning delayed until pod using PVC is created.

```yaml
volumeBindingMode: WaitForFirstConsumer
```

### Test WaitForFirstConsumer

```bash
# Create StorageClass
cat <<EOF | kubectl apply -f -
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: wait-storage
provisioner: k8s.io/minikube-hostpath
volumeBindingMode: WaitForFirstConsumer
EOF

# Create PVC
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: wait-pvc
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: wait-storage
  resources:
    requests:
      storage: 1Gi
EOF

# Check PVC status - should be Pending
kubectl get pvc wait-pvc
# STATUS: Pending

# Create pod using PVC
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: pod-with-storage
spec:
  containers:
  - name: nginx
    image: nginx
    volumeMounts:
    - name: data
      mountPath: /data
  volumes:
  - name: data
    persistentVolumeClaim:
      claimName: wait-pvc
EOF

# Now PVC should be Bound
kubectl get pvc wait-pvc
# STATUS: Bound
```

## Hands-On Practice

### Exercise 1: Complete Storage Setup

Create StorageClass → PVC → Deployment using storage.

```bash
# Step 1: Create StorageClass
cat <<EOF | kubectl apply -f -
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: app-storage
provisioner: k8s.io/minikube-hostpath
volumeBindingMode: WaitForFirstConsumer
reclaimPolicy: Delete
EOF

# Step 2: Create PVC
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: app-pvc
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: app-storage
  resources:
    requests:
      storage: 2Gi
EOF

# Step 3: Create Deployment
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app-with-storage
spec:
  replicas: 1
  selector:
    matchLabels:
      app: myapp
  template:
    metadata:
      labels:
        app: myapp
    spec:
      containers:
      - name: nginx
        image: nginx
        volumeMounts:
        - name: data
          mountPath: /usr/share/nginx/html
      volumes:
      - name: data
        persistentVolumeClaim:
          claimName: app-pvc
EOF

# Step 4: Verify
kubectl get sc app-storage
kubectl get pvc app-pvc
kubectl get pods -l app=myapp
```

### Exercise 2: Test Data Persistence

```bash
# Write data to volume
POD=$(kubectl get pod -l app=myapp -o jsonpath='{.items[0].metadata.name}')
kubectl exec -it $POD -- bash -c "echo 'Hello from PVC' > /usr/share/nginx/html/index.html"

# Verify data
kubectl exec -it $POD -- cat /usr/share/nginx/html/index.html

# Delete pod
kubectl delete pod $POD

# Wait for new pod
kubectl get pods -l app=myapp --watch

# Check data persisted
POD=$(kubectl get pod -l app=myapp -o jsonpath='{.items[0].metadata.name}')
kubectl exec -it $POD -- cat /usr/share/nginx/html/index.html
# Should still show: Hello from PVC
```

### Exercise 3: Multiple Pods Sharing Storage

Only works with ReadWriteMany (not supported in minikube hostPath).

```bash
# Example for environments that support RWX
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: shared-pvc
spec:
  accessModes:
    - ReadWriteMany  # Multiple pods can mount
  resources:
    requests:
      storage: 5Gi
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: shared-app
spec:
  replicas: 3
  selector:
    matchLabels:
      app: shared
  template:
    metadata:
      labels:
        app: shared
    spec:
      containers:
      - name: nginx
        image: nginx
        volumeMounts:
        - name: shared
          mountPath: /shared
      volumes:
      - name: shared
        persistentVolumeClaim:
          claimName: shared-pvc
EOF
```

## Common Storage Patterns

### StatefulSet with Storage

```bash
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
  name: nginx-headless
spec:
  clusterIP: None
  selector:
    app: nginx-sts
  ports:
  - port: 80
---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: nginx-sts
spec:
  serviceName: nginx-headless
  replicas: 3
  selector:
    matchLabels:
      app: nginx-sts
  template:
    metadata:
      labels:
        app: nginx-sts
    spec:
      containers:
      - name: nginx
        image: nginx
        volumeMounts:
        - name: data
          mountPath: /data
  volumeClaimTemplates:
  - metadata:
      name: data
    spec:
      accessModes:
        - ReadWriteOnce
      resources:
        requests:
          storage: 1Gi
EOF

# Each pod gets its own PVC
kubectl get pvc
# data-nginx-sts-0
# data-nginx-sts-1
# data-nginx-sts-2
```

### ConfigMap as Volume

```bash
# Create ConfigMap
kubectl create configmap app-config \
  --from-literal=config.json='{"key":"value"}'

# Mount as volume
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: config-pod
spec:
  containers:
  - name: app
    image: nginx
    volumeMounts:
    - name: config
      mountPath: /etc/config
  volumes:
  - name: config
    configMap:
      name: app-config
EOF

# Verify
kubectl exec config-pod -- cat /etc/config/config.json
```

### Secret as Volume

```bash
# Create secret
kubectl create secret generic db-secret \
  --from-literal=password=secretpass123

# Mount as volume
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: secret-pod
spec:
  containers:
  - name: app
    image: nginx
    volumeMounts:
    - name: secret
      mountPath: /etc/secret
      readOnly: true
  volumes:
  - name: secret
    secret:
      secretName: db-secret
EOF

# Verify
kubectl exec secret-pod -- cat /etc/secret/password
```

### EmptyDir Volume

Temporary storage that exists for pod lifetime.

```bash
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: emptydir-pod
spec:
  containers:
  - name: writer
    image: busybox
    command: ['sh', '-c', 'while true; do date >> /cache/log; sleep 5; done']
    volumeMounts:
    - name: cache
      mountPath: /cache
  - name: reader
    image: busybox
    command: ['sh', '-c', 'tail -f /cache/log']
    volumeMounts:
    - name: cache
      mountPath: /cache
  volumes:
  - name: emptyDir
    emptyDir: {}
EOF
```

## Troubleshooting

### Issue 1: PVC Stuck in Pending

```bash
# Check PVC status
kubectl describe pvc <pvc-name>

# Common reasons:
# 1. No matching PV available
# 2. StorageClass doesn't exist
# 3. Insufficient storage
# 4. Access mode mismatch

# Solution 1: Create matching PV
# Solution 2: Check StorageClass exists
kubectl get sc <storage-class-name>

# Solution 3: Reduce storage request
kubectl edit pvc <pvc-name>
```

### Issue 2: Pod Can't Mount Volume

```bash
# Check pod events
kubectl describe pod <pod-name>

# Common errors:
# - VolumeMountFailed
# - Multi-Attach error (RWO volume already mounted)

# Solution: Check if volume is already mounted elsewhere
kubectl get pods -o wide | grep <pvc-name>
```

### Issue 3: Data Not Persisting

```bash
# Verify PVC is bound
kubectl get pvc

# Check volume mount in pod
kubectl describe pod <pod-name> | grep -A 5 Mounts

# Verify data location
kubectl exec <pod-name> -- ls -la /mount/path
```

### Issue 4: StorageClass Not Found

```bash
# List available StorageClasses
kubectl get sc

# If empty, create one
cat <<EOF | kubectl apply -f -
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: standard
provisioner: k8s.io/minikube-hostpath
EOF
```

## Exam Tips

### Quick PVC Creation

```bash
# Method 1: Imperative (limited options)
kubectl create pvc my-pvc \
  --storage-class=standard \
  --access-mode=ReadWriteOnce \
  --size=5Gi

# Method 2: Generate YAML (recommended)
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: exam-pvc
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: fast-storage
  resources:
    requests:
      storage: 2Gi
EOF
```

### Quick StorageClass Creation

```bash
cat <<EOF | kubectl apply -f -
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: exam-storage
provisioner: k8s.io/minikube-hostpath
volumeBindingMode: WaitForFirstConsumer
reclaimPolicy: Delete
EOF
```

### Common Exam Patterns

```bash
# Pattern 1: Create StorageClass with WaitForFirstConsumer
# This is frequently tested!

# Pattern 2: Create PVC, then use in deployment
kubectl apply -f storageclass.yaml
kubectl apply -f pvc.yaml
kubectl apply -f deployment.yaml

# Pattern 3: Verify PVC is bound
kubectl get pvc | grep Bound
```

### Time-Saving Commands

```bash
# View all storage resources
kubectl get pv,pvc,sc

# Check PVC status quickly
kubectl get pvc -o wide

# Get PV from PVC
kubectl get pvc <pvc-name> -o jsonpath='{.spec.volumeName}'
```

## Practice Exercises

### Exercise 1: Exam-Style Task

Create:
1. StorageClass named "fast" with WaitForFirstConsumer
2. PVC named "data-pvc" requesting 5Gi
3. Deployment using the PVC

<details>
<summary>Solution</summary>

```bash
# StorageClass
cat <<EOF | kubectl apply -f -
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: fast
provisioner: k8s.io/minikube-hostpath
volumeBindingMode: WaitForFirstConsumer
EOF

# PVC
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: data-pvc
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: fast
  resources:
    requests:
      storage: 5Gi
EOF

# Deployment
kubectl create deployment app --image=nginx
kubectl set volume deployment app \
  --add --name=data \
  --type=persistentVolumeClaim \
  --claim-name=data-pvc \
  --mount-path=/data
```
</details>

### Exercise 2: Edit Existing Deployment

Add PVC to existing deployment named "web".

<details>
<summary>Solution</summary>

```bash
kubectl edit deployment web

# Add under spec.template.spec:
volumes:
- name: data
  persistentVolumeClaim:
    claimName: existing-pvc

# Add under containers[0]:
volumeMounts:
- name: data
  mountPath: /data
```
</details>

## Quick Reference

### Storage Commands

```bash
# PersistentVolume
kubectl get pv
kubectl describe pv <pv-name>
kubectl delete pv <pv-name>

# PersistentVolumeClaim
kubectl get pvc
kubectl describe pvc <pvc-name>
kubectl delete pvc <pvc-name>

# StorageClass
kubectl get sc
kubectl describe sc <sc-name>
kubectl delete sc <sc-name>

# View all storage
kubectl get pv,pvc,sc
```

### Volume Types

```yaml
# emptyDir
volumes:
- name: cache
  emptyDir: {}

# hostPath (minikube)
volumes:
- name: data
  hostPath:
    path: /mnt/data

# PersistentVolumeClaim
volumes:
- name: data
  persistentVolumeClaim:
    claimName: my-pvc

# ConfigMap
volumes:
- name: config
  configMap:
    name: my-config

# Secret
volumes:
- name: secret
  secret:
    secretName: my-secret
```

---

**Back to**: [Main README](../README.md) | [Previous: Resources](03-resource-management.md) | [Next: Network Policies](05-network-policies.md)
