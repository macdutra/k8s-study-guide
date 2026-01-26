# ETCD Backup & Restore

Complete guide to backing up and restoring ETCD - the cluster's database. This is a **guaranteed exam question**.

## Table of Contents

- [Overview](#overview)
- [ETCD Basics](#etcd-basics)
- [Backup ETCD](#backup-etcd)
- [Restore ETCD](#restore-etcd)
- [Certificate Locations](#certificate-locations)
- [Verification](#verification)
- [Troubleshooting](#troubleshooting)
- [Exam Tips](#exam-tips)

## Overview

**ETCD** is Kubernetes' key-value store that holds all cluster data (pods, services, secrets, etc.).

### Why Backup ETCD?

- Disaster recovery
- Cluster migration
- Before major upgrades
- **Exam requirement!**

### Exam Likelihood

🔴 **CRITICAL**: 90% chance of appearing (1-2 questions worth 4-8 points)

## ETCD Basics

### What is ETCD?

```
┌─────────────────────────────────┐
│    Kubernetes Cluster           │
│                                 │
│  ┌──────────────────┐           │
│  │  Control Plane   │           │
│  │                  │           │
│  │  ┌────────────┐  │           │
│  │  │   ETCD     │◄─┼───── Stores ALL cluster data
│  │  │ (Database) │  │           │
│  │  └────────────┘  │           │
│  │                  │           │
│  │  API Server      │           │
│  │  Scheduler       │           │
│  │  Controller Mgr  │           │
│  └──────────────────┘           │
└─────────────────────────────────┘
```

### ETCD Stores:

- All pods, deployments, services
- ConfigMaps and Secrets
- Namespaces
- RBAC rules
- Network policies
- **Everything about your cluster**

### Check ETCD Status

```bash
# Check if ETCD pod is running
kubectl get pods -n kube-system | grep etcd

# Output:
# etcd-controlplane    1/1     Running   0          10m

# Get ETCD pod details
kubectl describe pod etcd-controlplane -n kube-system

# Check ETCD version
kubectl exec -n kube-system etcd-controlplane -- etcd --version
```

## Backup ETCD

### Method 1: Using etcdctl (Recommended for Exam)

**Full Backup Command:**

```bash
ETCDCTL_API=3 etcdctl snapshot save /backup/etcd-snapshot.db \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key
```

**Step-by-Step:**

```bash
# 1. Create backup directory
mkdir -p /backup

# 2. Run backup
ETCDCTL_API=3 etcdctl snapshot save /backup/etcd-snapshot-$(date +%Y%m%d).db \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key

# Output:
# Snapshot saved at /backup/etcd-snapshot-20260126.db

# 3. Verify backup
ETCDCTL_API=3 etcdctl snapshot status /backup/etcd-snapshot-20260126.db

# Output shows:
# HASH        REVISION    TOTAL KEYS    SIZE
# 1234abcd    1000        50            2.5 MB
```

### Understanding the Command

```bash
ETCDCTL_API=3              # Use API version 3 (required)
etcdctl snapshot save      # Backup command
/backup/etcd-snapshot.db   # Where to save backup

--endpoints=https://127.0.0.1:2379  # ETCD server address
--cacert=/etc/kubernetes/pki/etcd/ca.crt      # CA certificate
--cert=/etc/kubernetes/pki/etcd/server.crt    # Client certificate
--key=/etc/kubernetes/pki/etcd/server.key     # Client key
```

### Method 2: Get Info from ETCD Pod

```bash
# Get all parameters from running ETCD pod
kubectl describe pod etcd-controlplane -n kube-system

# Look for these in the command section:
# --advertise-client-urls=https://10.0.0.1:2379
# --cert-file=/etc/kubernetes/pki/etcd/server.crt
# --key-file=/etc/kubernetes/pki/etcd/server.key
# --trusted-ca-file=/etc/kubernetes/pki/etcd/ca.crt

# Use these values in your backup command
```

### Quick Backup Script

```bash
#!/bin/bash
# save as: backup-etcd.sh

BACKUP_DIR="/backup"
DATE=$(date +%Y%m%d-%H%M%S)
BACKUP_FILE="${BACKUP_DIR}/etcd-snapshot-${DATE}.db"

mkdir -p ${BACKUP_DIR}

ETCDCTL_API=3 etcdctl snapshot save ${BACKUP_FILE} \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key

echo "Backup saved to: ${BACKUP_FILE}"

# Verify
ETCDCTL_API=3 etcdctl snapshot status ${BACKUP_FILE}
```

## Restore ETCD

### Full Restore Process

**⚠️ WARNING**: Restore will replace ALL current cluster data!

```bash
# 1. Stop API server (on control plane node)
mv /etc/kubernetes/manifests/kube-apiserver.yaml /tmp/

# 2. Restore snapshot
ETCDCTL_API=3 etcdctl snapshot restore /backup/etcd-snapshot.db \
  --data-dir=/var/lib/etcd-from-backup

# 3. Update ETCD pod to use new data directory
# Edit: /etc/kubernetes/manifests/etcd.yaml
# Change: --data-dir=/var/lib/etcd
# To:     --data-dir=/var/lib/etcd-from-backup

# Also update volume mount:
# volumes:
# - hostPath:
#     path: /var/lib/etcd-from-backup
#     type: DirectoryOrCreate
#   name: etcd-data

# 4. Restore API server
mv /tmp/kube-apiserver.yaml /etc/kubernetes/manifests/

# 5. Wait for cluster to come back up
watch kubectl get pods -n kube-system
```

### Detailed Restore Steps

```bash
# Step 1: Stop the API server
# Move the manifest file to stop the static pod
mv /etc/kubernetes/manifests/kube-apiserver.yaml /tmp/kube-apiserver.yaml.bak

# Wait for API server to stop
docker ps | grep kube-apiserver  # Should show nothing

# Step 2: Restore the snapshot
ETCDCTL_API=3 etcdctl snapshot restore /backup/etcd-snapshot.db \
  --data-dir=/var/lib/etcd-from-backup \
  --name=master \
  --initial-cluster=master=https://127.0.0.1:2380 \
  --initial-advertise-peer-urls=https://127.0.0.1:2380

# Output:
# 2024-01-26 10:00:00.000000 I | mvcc: restore compact to 1000
# 2024-01-26 10:00:00.000000 I | etcdserver/membership: added member...

# Step 3: Update ETCD manifest
vim /etc/kubernetes/manifests/etcd.yaml

# Find and change:
spec:
  containers:
  - command:
    - etcd
    - --data-dir=/var/lib/etcd-from-backup  # Changed from /var/lib/etcd
    
  volumes:
  - hostPath:
      path: /var/lib/etcd-from-backup  # Changed from /var/lib/etcd
      type: DirectoryOrCreate
    name: etcd-data

# Step 4: Restore API server
mv /tmp/kube-apiserver.yaml.bak /etc/kubernetes/manifests/kube-apiserver.yaml

# Step 5: Verify cluster
kubectl get nodes
kubectl get pods -A
```

### Alternative: Restore with Original Data Dir

```bash
# 1. Stop API server
mv /etc/kubernetes/manifests/kube-apiserver.yaml /tmp/

# 2. Remove old ETCD data
rm -rf /var/lib/etcd/*

# 3. Restore to original location
ETCDCTL_API=3 etcdctl snapshot restore /backup/etcd-snapshot.db \
  --data-dir=/var/lib/etcd

# 4. Set correct ownership
chown -R etcd:etcd /var/lib/etcd

# 5. Restore API server
mv /tmp/kube-apiserver.yaml /etc/kubernetes/manifests/

# 6. Wait and verify
sleep 30
kubectl get nodes
```

## Certificate Locations

### Standard Certificate Paths

```bash
# CA Certificate
/etc/kubernetes/pki/etcd/ca.crt

# Server Certificate
/etc/kubernetes/pki/etcd/server.crt

# Server Key
/etc/kubernetes/pki/etcd/server.key

# Peer Certificate (for restore)
/etc/kubernetes/pki/etcd/peer.crt

# Peer Key (for restore)
/etc/kubernetes/pki/etcd/peer.key
```

### Find Certificate Paths

```bash
# Method 1: Check ETCD pod
kubectl describe pod etcd-controlplane -n kube-system | grep -A 10 "Command"

# Method 2: Check ETCD manifest
cat /etc/kubernetes/manifests/etcd.yaml | grep -E "cert|key"

# Method 3: Check process
ps aux | grep etcd | grep -oE "\--(cert|key|cacert|trusted-ca)[^ ]*"
```

### Verify Certificates

```bash
# Check certificate details
openssl x509 -in /etc/kubernetes/pki/etcd/server.crt -text -noout

# Verify certificate chain
openssl verify -CAfile /etc/kubernetes/pki/etcd/ca.crt \
  /etc/kubernetes/pki/etcd/server.crt
```

## Verification

### Verify Backup

```bash
# Check snapshot status
ETCDCTL_API=3 etcdctl snapshot status /backup/etcd-snapshot.db

# Output shows:
# HASH        REVISION    TOTAL KEYS    TOTAL SIZE
# a1b2c3d4    5000        250           5.2 MB

# More detailed check
ETCDCTL_API=3 etcdctl snapshot status /backup/etcd-snapshot.db --write-out=table

# Output:
# +----------+----------+------------+------------+
# |   HASH   | REVISION | TOTAL KEYS | TOTAL SIZE |
# +----------+----------+------------+------------+
# | a1b2c3d4 |     5000 |        250 |     5.2 MB |
# +----------+----------+------------+------------+
```

### Verify Restore

```bash
# After restore, check cluster health
kubectl get nodes

# Check all system pods
kubectl get pods -n kube-system

# Verify your workloads
kubectl get pods -A

# Check ETCD cluster status
ETCDCTL_API=3 etcdctl --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key \
  member list

# Check endpoint health
ETCDCTL_API=3 etcdctl --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key \
  endpoint health
```

## Troubleshooting

### Issue 1: "permission denied" Error

```bash
# Problem: Cannot write backup file
# Error: Error: open /backup/etcd-snapshot.db: permission denied

# Solution 1: Use sudo
sudo ETCDCTL_API=3 etcdctl snapshot save /backup/etcd-snapshot.db ...

# Solution 2: Change directory permissions
sudo mkdir -p /backup
sudo chmod 777 /backup

# Solution 3: Use /tmp instead
ETCDCTL_API=3 etcdctl snapshot save /tmp/etcd-snapshot.db ...
```

### Issue 2: "connection refused" Error

```bash
# Problem: Cannot connect to ETCD
# Error: Error: context deadline exceeded

# Solution 1: Check ETCD is running
kubectl get pods -n kube-system | grep etcd

# Solution 2: Verify endpoint
kubectl describe pod etcd-controlplane -n kube-system | grep listen-client-urls

# Solution 3: Use correct endpoint
# Change: --endpoints=https://127.0.0.1:2379
# To:     --endpoints=https://<actual-ip>:2379
```

### Issue 3: Certificate Errors

```bash
# Problem: TLS handshake failed
# Error: Error: x509: certificate signed by unknown authority

# Solution 1: Verify certificate paths
ls -la /etc/kubernetes/pki/etcd/

# Solution 2: Get paths from ETCD pod
kubectl describe pod etcd-controlplane -n kube-system | grep -E "cert|key"

# Solution 3: Use exact paths from manifest
cat /etc/kubernetes/manifests/etcd.yaml | grep -E "cert-file|key-file|trusted-ca"
```

### Issue 4: Restore Not Working

```bash
# Problem: Cluster doesn't come back after restore

# Check 1: ETCD pod status
kubectl get pods -n kube-system | grep etcd

# Check 2: ETCD pod logs
kubectl logs -n kube-system etcd-controlplane

# Check 3: Data directory permissions
ls -la /var/lib/etcd-from-backup
sudo chown -R etcd:etcd /var/lib/etcd-from-backup

# Check 4: Static pod manifest
cat /etc/kubernetes/manifests/etcd.yaml | grep data-dir

# Check 5: Restart kubelet
systemctl restart kubelet
```

## Exam Tips

### Memorize This Command

```bash
# BACKUP (memorize this!)
ETCDCTL_API=3 etcdctl snapshot save /backup/etcd.db \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key

# RESTORE (memorize this!)
ETCDCTL_API=3 etcdctl snapshot restore /backup/etcd.db \
  --data-dir=/var/lib/etcd-from-backup
```

### Quick Reference Card

```bash
# Backup
ETCDCTL_API=3 etcdctl snapshot save <file> \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key

# Verify backup
ETCDCTL_API=3 etcdctl snapshot status <file>

# Restore
ETCDCTL_API=3 etcdctl snapshot restore <file> \
  --data-dir=<new-dir>

# Update etcd.yaml
vim /etc/kubernetes/manifests/etcd.yaml
# Change --data-dir and volume hostPath

# Restart (static pods restart automatically)
```

### Exam Shortcuts

```bash
# Get certificate paths quickly
grep -E "cert|key|ca" /etc/kubernetes/manifests/etcd.yaml

# Or from pod description
kubectl describe pod -n kube-system etcd-controlplane | grep -E "cert|key"

# Create backup with timestamp
ETCDCTL_API=3 etcdctl snapshot save /backup/etcd-$(date +%F).db \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key
```

### Common Exam Scenarios

**Scenario 1: Simple Backup**
```bash
# Task: Create a backup of ETCD to /backup/etcd.db

# Solution:
mkdir -p /backup
ETCDCTL_API=3 etcdctl snapshot save /backup/etcd.db \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key

# Verify
ETCDCTL_API=3 etcdctl snapshot status /backup/etcd.db
```

**Scenario 2: Backup and Restore**
```bash
# Task: Backup ETCD, delete a pod, then restore

# Step 1: Backup
ETCDCTL_API=3 etcdctl snapshot save /backup/etcd.db \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key

# Step 2: Delete a pod (to simulate data loss)
kubectl delete pod test-pod

# Step 3: Restore
mv /etc/kubernetes/manifests/kube-apiserver.yaml /tmp/
ETCDCTL_API=3 etcdctl snapshot restore /backup/etcd.db \
  --data-dir=/var/lib/etcd-from-backup

# Step 4: Update ETCD manifest
vim /etc/kubernetes/manifests/etcd.yaml
# Update --data-dir and volume path

# Step 5: Bring cluster back
mv /tmp/kube-apiserver.yaml /etc/kubernetes/manifests/

# Step 6: Verify pod is back
kubectl get pod test-pod
```

### Time Management

- **Backup only**: 2-3 minutes
- **Backup + verify**: 3-4 minutes
- **Full restore**: 5-7 minutes

**Practice until you can do backup in under 2 minutes!**

## Practice Questions

### Question 1: Basic Backup

Create an ETCD backup at `/opt/etcd-backup.db`

<details>
<summary>Solution</summary>

```bash
ETCDCTL_API=3 etcdctl snapshot save /opt/etcd-backup.db \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key

# Verify
ETCDCTL_API=3 etcdctl snapshot status /opt/etcd-backup.db
```
</details>

### Question 2: Find Certificate Paths

The ETCD certificates are not in the standard location. Find them and create a backup.

<details>
<summary>Solution</summary>

```bash
# Find paths from ETCD pod
kubectl describe pod -n kube-system etcd-controlplane | grep -E "cert-file|key-file|trusted-ca"

# Or from manifest
cat /etc/kubernetes/manifests/etcd.yaml | grep -E "cert-file|key-file|trusted-ca"

# Use found paths in backup command
ETCDCTL_API=3 etcdctl snapshot save /backup/etcd.db \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=<found-ca-path> \
  --cert=<found-cert-path> \
  --key=<found-key-path>
```
</details>

### Question 3: Restore from Backup

Restore the cluster from `/backup/etcd-snapshot.db` to a new data directory `/var/lib/etcd-restored`

<details>
<summary>Solution</summary>

```bash
# 1. Stop API server
mv /etc/kubernetes/manifests/kube-apiserver.yaml /tmp/

# 2. Restore
ETCDCTL_API=3 etcdctl snapshot restore /backup/etcd-snapshot.db \
  --data-dir=/var/lib/etcd-restored

# 3. Edit ETCD manifest
vim /etc/kubernetes/manifests/etcd.yaml
# Change: --data-dir=/var/lib/etcd-restored
# Change volume hostPath to: /var/lib/etcd-restored

# 4. Restart API server
mv /tmp/kube-apiserver.yaml /etc/kubernetes/manifests/

# 5. Verify
sleep 30
kubectl get nodes
```
</details>

## Quick Reference

```bash
# BACKUP
ETCDCTL_API=3 etcdctl snapshot save /backup/etcd.db \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key

# VERIFY BACKUP
ETCDCTL_API=3 etcdctl snapshot status /backup/etcd.db

# RESTORE
ETCDCTL_API=3 etcdctl snapshot restore /backup/etcd.db \
  --data-dir=/var/lib/etcd-from-backup

# GET CERT PATHS
grep -E "cert|key" /etc/kubernetes/manifests/etcd.yaml

# CHECK ETCD POD
kubectl get pod -n kube-system etcd-controlplane
kubectl describe pod -n kube-system etcd-controlplane
```

---

**This is a guaranteed exam question. Practice until you can do it in your sleep!**

**Back to**: [Main README](../README.md) | [Next: RBAC](10-rbac.md)
