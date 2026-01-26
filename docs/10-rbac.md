# RBAC - Role-Based Access Control

Complete guide to RBAC for controlling access to Kubernetes resources.

## Table of Contents

- [Overview](#overview)
- [RBAC Components](#rbac-components)
- [Creating Roles](#creating-roles)
- [Creating RoleBindings](#creating-rolebindings)
- [ServiceAccounts](#serviceaccounts)
- [ClusterRoles vs Roles](#clusterroles-vs-roles)
- [Testing Permissions](#testing-permissions)
- [Common Patterns](#common-patterns)
- [Troubleshooting](#troubleshooting)
- [Exam Tips](#exam-tips)

## Overview

RBAC controls **who** can do **what** in your Kubernetes cluster.

### Key Concepts

```
┌─────────────────────────────────────┐
│   RBAC Components                   │
│                                     │
│  ServiceAccount  ──────────┐        │
│  (who)                     │        │
│                            ▼        │
│  Role            ───▶  RoleBinding  │
│  (what)                (connects)   │
│                                     │
└─────────────────────────────────────┘
```

**4 Main Components:**
1. **Role** - What actions are allowed
2. **RoleBinding** - Who gets the Role
3. **ClusterRole** - Cluster-wide Role
4. **ClusterRoleBinding** - Cluster-wide binding

## RBAC Components

### 1. ServiceAccount (Who)

```bash
# Create ServiceAccount
kubectl create serviceaccount my-sa

# View ServiceAccounts
kubectl get serviceaccounts
kubectl get sa

# Describe
kubectl describe sa my-sa
```

### 2. Role (What)

```bash
# Create Role
kubectl create role pod-reader \
  --verb=get,list,watch \
  --resource=pods

# View Roles
kubectl get roles

# Describe Role
kubectl describe role pod-reader
```

### 3. RoleBinding (Connect Who to What)

```bash
# Create RoleBinding
kubectl create rolebinding read-pods \
  --role=pod-reader \
  --serviceaccount=default:my-sa

# View RoleBindings
kubectl get rolebindings

# Describe
kubectl describe rolebinding read-pods
```

## Creating Roles

### Basic Role Creation

```bash
# Role: Can list and get pods
kubectl create role pod-reader \
  --verb=get,list \
  --resource=pods

# Role: Can create, update, delete deployments
kubectl create role deploy-manager \
  --verb=create,update,delete,patch \
  --resource=deployments

# Role: Full access to services
kubectl create role service-admin \
  --verb=* \
  --resource=services
```

### Role with Multiple Resources

```bash
# Role: Can read pods and services
kubectl create role app-reader \
  --verb=get,list,watch \
  --resource=pods,services,configmaps
```

### Role YAML Example

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: pod-reader
  namespace: default
rules:
- apiGroups: [""]  # "" = core API group
  resources: ["pods"]
  verbs: ["get", "list", "watch"]
```

### Common Verbs

| Verb | Description |
|------|-------------|
| `get` | Read a single resource |
| `list` | List all resources |
| `watch` | Watch for changes |
| `create` | Create new resources |
| `update` | Update existing resources |
| `patch` | Partial update |
| `delete` | Delete resources |
| `*` | All verbs |

### Common Resources

```bash
# Core resources (apiGroups: [""])
pods, services, configmaps, secrets, persistentvolumeclaims, events

# Apps (apiGroups: ["apps"])
deployments, replicasets, statefulsets, daemonsets

# Batch (apiGroups: ["batch"])
jobs, cronjobs

# Networking (apiGroups: ["networking.k8s.io"])
ingresses, networkpolicies
```

## Creating RoleBindings

### Bind Role to ServiceAccount

```bash
# Create ServiceAccount
kubectl create serviceaccount app-sa

# Create Role
kubectl create role pod-reader --verb=get,list --resource=pods

# Bind them together
kubectl create rolebinding app-sa-can-read-pods \
  --role=pod-reader \
  --serviceaccount=default:app-sa
```

### Bind Role to User

```bash
# Bind to user
kubectl create rolebinding john-pod-reader \
  --role=pod-reader \
  --user=john
```

### Bind Role to Group

```bash
# Bind to group
kubectl create rolebinding devs-pod-reader \
  --role=pod-reader \
  --group=developers
```

### RoleBinding YAML

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: read-pods
  namespace: default
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: pod-reader
subjects:
- kind: ServiceAccount
  name: my-sa
  namespace: default
```

## ServiceAccounts

### Create ServiceAccount

```bash
# Create
kubectl create serviceaccount my-app-sa

# View
kubectl get sa
kubectl describe sa my-app-sa
```

### Use ServiceAccount in Pod

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: my-app
spec:
  serviceAccountName: my-app-sa  # Use this SA
  containers:
  - name: app
    image: nginx
```

### ServiceAccount Tokens

```bash
# Get token (Kubernetes 1.24+)
kubectl create token my-app-sa

# Create long-lived token secret (older method)
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Secret
metadata:
  name: my-app-sa-token
  annotations:
    kubernetes.io/service-account.name: my-app-sa
type: kubernetes.io/service-account-token
EOF

# Get the token
kubectl get secret my-app-sa-token -o jsonpath='{.data.token}' | base64 -d
```

## ClusterRoles vs Roles

### Role (Namespace-scoped)

```bash
# Role only works in one namespace
kubectl create role pod-reader \
  --verb=get,list \
  --resource=pods \
  --namespace=production

# Can only read pods in 'production' namespace
```

### ClusterRole (Cluster-wide)

```bash
# ClusterRole works across all namespaces
kubectl create clusterrole pod-reader-all \
  --verb=get,list \
  --resource=pods

# Can read pods in any namespace
```

### When to Use Each

**Use Role when:**
- Limited to one namespace
- Managing app-specific permissions

**Use ClusterRole when:**
- Need access across namespaces
- Managing cluster resources (nodes, PVs)
- Need to grant same permissions in multiple namespaces

### ClusterRoleBinding

```bash
# Create ClusterRole
kubectl create clusterrole secret-reader \
  --verb=get,list \
  --resource=secrets

# Bind cluster-wide
kubectl create clusterrolebinding all-secret-readers \
  --clusterrole=secret-reader \
  --serviceaccount=default:my-sa

# Now my-sa can read secrets in ALL namespaces
```

## Testing Permissions

### Check Your Own Permissions

```bash
# Can I create pods?
kubectl auth can-i create pods

# Can I delete deployments?
kubectl auth can-i delete deployments

# Can I do everything?
kubectl auth can-i '*' '*'
```

### Check Another User's Permissions

```bash
# Can john create pods?
kubectl auth can-i create pods --as=john

# Can my-sa list secrets?
kubectl auth can-i list secrets \
  --as=system:serviceaccount:default:my-sa

# Can developers group delete pods?
kubectl auth can-i delete pods --as-group=developers
```

### Check in Specific Namespace

```bash
# Can I create pods in production?
kubectl auth can-i create pods --namespace=production

# Can my-sa list services in dev?
kubectl auth can-i list services \
  --as=system:serviceaccount:default:my-sa \
  --namespace=dev
```

## Common Patterns

### Pattern 1: Read-Only Access

```bash
# Create read-only role
kubectl create role pod-reader \
  --verb=get,list,watch \
  --resource=pods,services,configmaps

# Bind to ServiceAccount
kubectl create rolebinding reader-binding \
  --role=pod-reader \
  --serviceaccount=default:reader-sa
```

### Pattern 2: Deployment Manager

```bash
# Can manage deployments
kubectl create role deploy-manager \
  --verb=create,update,delete,patch,get,list \
  --resource=deployments

kubectl create rolebinding deploy-mgr-binding \
  --role=deploy-manager \
  --serviceaccount=default:deploy-sa
```

### Pattern 3: Namespace Admin

```bash
# Full access to namespace
kubectl create role namespace-admin \
  --verb=* \
  --resource=*

kubectl create rolebinding ns-admin-binding \
  --role=namespace-admin \
  --serviceaccount=default:admin-sa
```

### Pattern 4: Secret Reader (Cluster-wide)

```bash
# Read secrets everywhere
kubectl create clusterrole secret-reader \
  --verb=get,list \
  --resource=secrets

kubectl create clusterrolebinding secret-reader-binding \
  --clusterrole=secret-reader \
  --serviceaccount=default:app-sa
```

## Troubleshooting

### Issue 1: Permission Denied

```bash
# Error: pods is forbidden: User "system:serviceaccount:default:my-sa" 
#        cannot list resource "pods"

# Check what permissions the SA has
kubectl auth can-i list pods --as=system:serviceaccount:default:my-sa

# Output: no

# Solution: Create Role and RoleBinding
kubectl create role pod-lister --verb=list --resource=pods
kubectl create rolebinding my-sa-list-pods \
  --role=pod-lister \
  --serviceaccount=default:my-sa

# Verify
kubectl auth can-i list pods --as=system:serviceaccount:default:my-sa
# Output: yes
```

### Issue 2: RoleBinding in Wrong Namespace

```bash
# RoleBinding in 'default' but pods in 'production'

# Check binding
kubectl get rolebinding -n default

# Create binding in correct namespace
kubectl create rolebinding my-binding \
  --role=pod-reader \
  --serviceaccount=default:my-sa \
  --namespace=production
```

### Issue 3: Using ClusterRole in Namespace

```bash
# ClusterRole exists but RoleBinding needed in namespace

# Create ClusterRole (if not exists)
kubectl create clusterrole pod-reader --verb=get,list --resource=pods

# Bind in specific namespace
kubectl create rolebinding prod-pod-reader \
  --clusterrole=pod-reader \
  --serviceaccount=default:my-sa \
  --namespace=production
```

## Exam Tips

### Quick Commands

```bash
# Create SA, Role, RoleBinding in one go
kubectl create serviceaccount my-sa
kubectl create role pod-reader --verb=get,list --resource=pods
kubectl create rolebinding my-binding \
  --role=pod-reader \
  --serviceaccount=default:my-sa

# Test it
kubectl auth can-i list pods --as=system:serviceaccount:default:my-sa
```

### Time-Saving Patterns

```bash
# One-liner: SA + Role + Binding
kubectl create sa app-sa && \
kubectl create role app-role --verb=get,list --resource=pods,services && \
kubectl create rolebinding app-binding --role=app-role --serviceaccount=default:app-sa
```

### Common Exam Questions

**Q1: Create a ServiceAccount that can read pods**
```bash
kubectl create sa pod-reader-sa
kubectl create role pod-reader --verb=get,list --resource=pods
kubectl create rolebinding pod-reader-binding \
  --role=pod-reader \
  --serviceaccount=default:pod-reader-sa
```

**Q2: Grant cluster-wide secret access**
```bash
kubectl create clusterrole secret-reader --verb=get,list --resource=secrets
kubectl create clusterrolebinding secret-reader-binding \
  --clusterrole=secret-reader \
  --serviceaccount=default:app-sa
```

**Q3: Check if user can delete pods**
```bash
kubectl auth can-i delete pods --as=john
```

## Practice Questions

### Question 1
Create a ServiceAccount named "deploy-sa" that can create, update, and delete deployments.

<details>
<summary>Solution</summary>

```bash
kubectl create serviceaccount deploy-sa
kubectl create role deploy-manager \
  --verb=create,update,delete \
  --resource=deployments
kubectl create rolebinding deploy-sa-binding \
  --role=deploy-manager \
  --serviceaccount=default:deploy-sa

# Verify
kubectl auth can-i create deployments --as=system:serviceaccount:default:deploy-sa
```
</details>

### Question 2
Create a ClusterRole that can read all pods in all namespaces.

<details>
<summary>Solution</summary>

```bash
kubectl create clusterrole pod-reader-all \
  --verb=get,list,watch \
  --resource=pods
kubectl create clusterrolebinding pod-reader-all-binding \
  --clusterrole=pod-reader-all \
  --serviceaccount=default:reader-sa
```
</details>

## Quick Reference

```bash
# Create ServiceAccount
kubectl create serviceaccount <name>

# Create Role
kubectl create role <name> --verb=<verbs> --resource=<resources>

# Create RoleBinding
kubectl create rolebinding <name> \
  --role=<role> \
  --serviceaccount=<namespace>:<sa-name>

# Create ClusterRole
kubectl create clusterrole <name> --verb=<verbs> --resource=<resources>

# Create ClusterRoleBinding
kubectl create clusterrolebinding <name> \
  --clusterrole=<role> \
  --serviceaccount=<namespace>:<sa-name>

# Test permissions
kubectl auth can-i <verb> <resource> --as=<user/sa>
```

---

**Back to**: [Main README](../README.md) | [Next: Troubleshooting](11-cluster-troubleshooting.md)
