# Pod Scheduling & Priority

Complete guide to controlling where and how pods are scheduled in Kubernetes.

## Table of Contents

- [Overview](#overview)
- [Node Selectors](#node-selectors)
- [Node Affinity](#node-affinity)
- [Taints and Tolerations](#taints-and-tolerations)
- [PriorityClass](#priorityclass)
- [Pod Affinity/Anti-Affinity](#pod-affinityanti-affinity)
- [Manual Scheduling](#manual-scheduling)

## Overview

Control **where** pods run and their **priority** when resources are scarce.

## Node Selectors

Simplest way to constrain pods to specific nodes.

```bash
# Label a node
kubectl label nodes node1 disktype=ssd

# Use in pod
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: nginx
spec:
  nodeSelector:
    disktype: ssd
  containers:
  - name: nginx
    image: nginx
EOF
```

## Node Affinity

More flexible than nodeSelector.

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: nginx
spec:
  affinity:
    nodeAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
        nodeSelectorTerms:
        - matchExpressions:
          - key: disktype
            operator: In
            values:
            - ssd
            - nvme
  containers:
  - name: nginx
    image: nginx
```

## Taints and Tolerations

Taints repel pods, tolerations allow pods to schedule on tainted nodes.

```bash
# Taint a node
kubectl taint nodes node1 key=value:NoSchedule

# Remove taint
kubectl taint nodes node1 key=value:NoSchedule-

# Pod with toleration
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: nginx
spec:
  tolerations:
  - key: "key"
    operator: "Equal"
    value: "value"
    effect: "NoSchedule"
  containers:
  - name: nginx
    image: nginx
EOF
```

## PriorityClass

Set pod priority for scheduling and preemption.

```bash
# Create PriorityClass
cat <<EOF | kubectl apply -f -
apiVersion: scheduling.k8s.io/v1
kind: PriorityClass
metadata:
  name: high-priority
value: 1000
globalDefault: false
description: "High priority class"
EOF

# Use in pod
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: nginx
spec:
  priorityClassName: high-priority
  containers:
  - name: nginx
    image: nginx
EOF
```

## Pod Affinity/Anti-Affinity

Schedule pods relative to other pods.

```yaml
# Pod affinity - schedule near other pods
apiVersion: v1
kind: Pod
metadata:
  name: with-pod-affinity
spec:
  affinity:
    podAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
      - labelSelector:
          matchExpressions:
          - key: app
            operator: In
            values:
            - database
        topologyKey: kubernetes.io/hostname
  containers:
  - name: nginx
    image: nginx
```

## Manual Scheduling

Schedule pod to specific node without scheduler.

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: nginx
spec:
  nodeName: node1  # Bypasses scheduler
  containers:
  - name: nginx
    image: nginx
```

## Quick Reference

```bash
# Label node
kubectl label nodes <node> key=value

# Taint node
kubectl taint nodes <node> key=value:NoSchedule

# Remove taint
kubectl taint nodes <node> key:NoSchedule-

# Create PriorityClass
kubectl create priorityclass high --value=1000

# View node labels
kubectl get nodes --show-labels

# View taints
kubectl describe node <node> | grep Taints
```

---

**Back to**: [Main README](../README.md) | [Previous: Sidecar Patterns](06-sidecar-patterns.md) | [Next: Gateway API](08-gateway-api.md)
