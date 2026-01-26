# Using Kubernetes Documentation During CKA Exam

Complete guide on how to efficiently find YAML examples and reference materials during the exam.

## 🎯 What You Can Access

### ✅ Allowed Documentation

During the CKA exam, you can access:
- **kubernetes.io/docs** - Official Kubernetes documentation
- **kubernetes.io/blog** - Kubernetes blog
- **github.com/kubernetes** - Kubernetes GitHub repositories (limited)
- **helm.sh/docs** - Helm documentation (if applicable)

### ❌ NOT Allowed

- Google, StackOverflow, ChatGPT
- Your own notes (unless from allowed sites)
- Any other websites

## 🚀 Three Methods to Find YAML Examples

### Method 1: kubectl explain (Fastest! ⚡)

**Built into kubectl - works without internet!**

```bash
# Basic structure
kubectl explain <resource>

# Detailed spec
kubectl explain <resource>.spec

# Specific field
kubectl explain <resource>.spec.<field>

# Recursive (all fields)
kubectl explain <resource> --recursive
```

**Examples:**

```bash
# HPA
kubectl explain hpa
kubectl explain hpa.spec
kubectl explain hpa.spec.behavior
kubectl explain hpa.spec.behavior.scaleDown

# Ingress
kubectl explain ingress
kubectl explain ingress.spec.rules

# NetworkPolicy
kubectl explain networkpolicy
kubectl explain networkpolicy.spec.ingress

# Pod
kubectl explain pod.spec.containers
kubectl explain pod.spec.volumes
```

**Why this is best:**
- ✅ Instant (no searching)
- ✅ Shows field types and descriptions
- ✅ Works offline
- ✅ Shows exactly what's valid

### Method 2: Generate with kubectl (Fast!)

**Use --dry-run to create templates**

```bash
# General pattern
kubectl create <resource> <name> [options] --dry-run=client -o yaml

# Save to file
kubectl create <resource> <name> [options] --dry-run=client -o yaml > file.yaml

# Edit and apply
vim file.yaml
kubectl apply -f file.yaml
```

**Common Examples:**

```bash
# Pod
kubectl run nginx --image=nginx --dry-run=client -o yaml > pod.yaml

# Deployment
kubectl create deployment web --image=nginx --replicas=3 \
  --dry-run=client -o yaml > deploy.yaml

# Service
kubectl expose deployment web --port=80 --type=NodePort \
  --dry-run=client -o yaml > svc.yaml

# ConfigMap
kubectl create configmap app-config \
  --from-literal=key=value \
  --dry-run=client -o yaml > cm.yaml

# Secret
kubectl create secret generic app-secret \
  --from-literal=password=secret123 \
  --dry-run=client -o yaml > secret.yaml

# Job
kubectl create job pi --image=perl \
  -- perl -Mbignum=bpi -wle 'print bpi(2000)' \
  --dry-run=client -o yaml > job.yaml

# CronJob
kubectl create cronjob hello --image=busybox \
  --schedule="*/1 * * * *" -- echo Hello \
  --dry-run=client -o yaml > cronjob.yaml

# Ingress
kubectl create ingress web --rule="example.com/=web:80" \
  --dry-run=client -o yaml > ingress.yaml

# Namespace
kubectl create namespace prod --dry-run=client -o yaml > ns.yaml

# Service Account
kubectl create serviceaccount app-sa \
  --dry-run=client -o yaml > sa.yaml

# Role
kubectl create role pod-reader \
  --verb=get --verb=list --verb=watch \
  --resource=pods \
  --dry-run=client -o yaml > role.yaml

# RoleBinding
kubectl create rolebinding pod-reader-binding \
  --role=pod-reader \
  --serviceaccount=default:app-sa \
  --dry-run=client -o yaml > rb.yaml
```

### Method 3: Kubernetes Documentation (For Complex Scenarios)

**When you need examples of advanced features**

#### Quick Navigation

**URL Patterns:**

```
# Tasks (practical examples)
https://kubernetes.io/docs/tasks/

# Concepts (explanations)
https://kubernetes.io/docs/concepts/

# API Reference (complete spec)
https://kubernetes.io/docs/reference/kubernetes-api/

# kubectl Reference
https://kubernetes.io/docs/reference/kubectl/
```

#### Common Resource Pages

| Resource | Quick Search | Direct Path |
|----------|--------------|-------------|
| HPA | "horizontal pod autoscaler" | Tasks → Run Applications → HPA Walkthrough |
| Ingress | "ingress" | Concepts → Services, Load Balancing → Ingress |
| NetworkPolicy | "network policy" | Concepts → Services, Load Balancing → Network Policies |
| PV/PVC | "persistent volumes" | Concepts → Storage → Persistent Volumes |
| ConfigMap | "configmap" | Concepts → Configuration → ConfigMaps |
| Secret | "secrets" | Concepts → Configuration → Secrets |
| RBAC | "rbac" | Reference → API Access Control → RBAC |

#### Search Tips

**Good Searches:**
- "horizontal pod autoscaler walkthrough" ✅
- "ingress example" ✅
- "network policy examples" ✅
- "statefulset basic" ✅

**Bad Searches:**
- "how to create HPA" ❌
- "kubernetes autoscaling tutorial" ❌

## 📚 Resource-Specific Quick Reference

### HorizontalPodAutoscaler (HPA)

**kubectl explain:**
```bash
kubectl explain hpa.spec
kubectl explain hpa.spec.metrics
kubectl explain hpa.spec.behavior.scaleDown
```

**Generate template:**
```bash
kubectl autoscale deployment web --cpu-percent=50 --min=1 --max=10 \
  --dry-run=client -o yaml > hpa.yaml
```

**Docs page:**
- Search: "horizontal pod autoscaler"
- URL: https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/

**What to copy from docs:**
- `spec.behavior` section (not in imperative command)
- Multiple metrics examples
- Custom metrics configuration

### NetworkPolicy

**kubectl explain:**
```bash
kubectl explain networkpolicy.spec
kubectl explain networkpolicy.spec.ingress
kubectl explain networkpolicy.spec.egress
```

**No imperative command - must write YAML**

**Docs page:**
- Search: "network policy"
- URL: https://kubernetes.io/docs/concepts/services-networking/network-policies/

**Common patterns in docs:**
- Deny all ingress/egress
- Allow specific pods
- Allow specific namespaces
- Allow specific ports

### PersistentVolumeClaim

**kubectl explain:**
```bash
kubectl explain pvc.spec
kubectl explain pvc.spec.resources
kubectl explain pvc.spec.accessModes
```

**No good imperative command - write YAML**

**Docs page:**
- Search: "persistent volume claims"
- URL: https://kubernetes.io/docs/concepts/storage/persistent-volumes/

### StorageClass

**kubectl explain:**
```bash
kubectl explain storageclass
kubectl explain storageclass.provisioner
kubectl explain storageclass.volumeBindingMode
```

**Docs page:**
- Search: "storage classes"
- URL: https://kubernetes.io/docs/concepts/storage/storage-classes/

**What to copy:**
- `volumeBindingMode: WaitForFirstConsumer` examples
- Different provisioner configurations

### Ingress

**kubectl explain:**
```bash
kubectl explain ingress.spec
kubectl explain ingress.spec.rules
kubectl explain ingress.spec.tls
```

**Generate template:**
```bash
kubectl create ingress web --rule="example.com/path=service:80" \
  --dry-run=client -o yaml > ingress.yaml
```

**Docs page:**
- Search: "ingress"
- URL: https://kubernetes.io/docs/concepts/services-networking/ingress/

**What to copy:**
- Path-based routing examples
- Host-based routing examples
- TLS configuration

## 🎓 Exam Workflow Examples

### Example 1: Create HPA with Custom Behavior

**Time: 3-4 minutes**

```bash
# Step 1: Generate base (30 seconds)
kubectl autoscale deployment web --cpu-percent=50 --min=1 --max=4 \
  --dry-run=client -o yaml > hpa.yaml

# Step 2: Check structure (30 seconds)
kubectl explain hpa.spec.behavior.scaleDown

# Step 3: Open docs (1 minute)
# Search: "HPA behavior"
# Find example of behavior.scaleDown

# Step 4: Edit file (1 minute)
vim hpa.yaml
# Add behavior section from docs

# Step 5: Apply (10 seconds)
kubectl apply -f hpa.yaml

# Step 6: Verify (10 seconds)
kubectl get hpa web
kubectl describe hpa web
```

### Example 2: Create NetworkPolicy

**Time: 2-3 minutes**

```bash
# Step 1: Check structure (30 seconds)
kubectl explain networkpolicy.spec

# Step 2: Search docs (1 minute)
# Search: "network policy examples"
# Find: deny all, allow from specific pods

# Step 3: Copy and modify (1 minute)
cat > netpol.yaml << EOF
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: db-policy
spec:
  podSelector:
    matchLabels:
      app: database
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: backend
    ports:
    - protocol: TCP
      port: 5432
EOF

# Step 4: Apply (10 seconds)
kubectl apply -f netpol.yaml

# Step 5: Verify (10 seconds)
kubectl get networkpolicy
kubectl describe networkpolicy db-policy
```

### Example 3: Create Ingress with TLS

**Time: 2-3 minutes**

```bash
# Step 1: Generate base (30 seconds)
kubectl create ingress web --rule="example.com/=web:80" \
  --dry-run=client -o yaml > ingress.yaml

# Step 2: Search docs (1 minute)
# Search: "ingress tls"
# Find TLS configuration example

# Step 3: Edit (1 minute)
vim ingress.yaml
# Add TLS section from docs example

# Step 4: Create secret first (30 seconds)
kubectl create secret tls web-tls --cert=tls.crt --key=tls.key

# Step 5: Apply ingress (10 seconds)
kubectl apply -f ingress.yaml
```

## 💡 Pro Tips

### 1. Bookmark Key Pages Before Exam

Open these in tabs:

```
Tab 1: https://kubernetes.io/docs/reference/kubectl/cheatsheet/
Tab 2: https://kubernetes.io/docs/reference/kubernetes-api/
Tab 3: https://kubernetes.io/docs/tasks/
Tab 4: https://kubernetes.io/docs/concepts/
```

### 2. Use Browser Search (Ctrl+F)

Once on a docs page:
- Press Ctrl+F
- Search for specific field name
- Jump directly to example

### 3. Know When to Use Each Method

**Use kubectl explain when:**
- You need field names
- You want valid options
- You're unsure of structure

**Use kubectl create --dry-run when:**
- Resource has imperative command
- You need basic template
- Speed is critical

**Use docs when:**
- You need complex examples
- Feature not in imperative commands
- You want to understand behavior

### 4. Copy Smart, Not Everything

From docs, copy only:
- The specific section you need
- Not the entire YAML example
- Modify for your use case

### 5. Verify Your YAML

```bash
# Check syntax before applying
kubectl apply -f file.yaml --dry-run=client

# If syntax is good, apply for real
kubectl apply -f file.yaml
```

## 🔖 Quick Command Reference

### Check What Exists

```bash
# Before creating, check if it exists
kubectl get <resource-type>

# Check in all namespaces
kubectl get <resource-type> -A

# Get YAML of existing resource (for reference)
kubectl get <resource> <name> -o yaml
```

### Get Examples from Cluster

```bash
# Export existing resource as template
kubectl get deployment nginx -o yaml > template.yaml

# Clean it up (remove status, uid, etc.)
# Then modify for your needs
```

### Validate Syntax

```bash
# Client-side validation
kubectl apply -f file.yaml --dry-run=client

# Server-side validation (more thorough)
kubectl apply -f file.yaml --dry-run=server
```

## 📊 Time Budget

| Task | Method | Time |
|------|--------|------|
| Simple resource | kubectl create --dry-run | 30 sec |
| Check field | kubectl explain | 30 sec |
| Find docs page | Search | 1 min |
| Copy from docs | Browser | 1 min |
| Edit YAML | vim | 1-2 min |
| Apply and verify | kubectl | 30 sec |
| **Total** | | **4-5 min** |

## 🎯 Remember

1. **Try imperative first** - Saves time
2. **kubectl explain is your friend** - Fast reference
3. **Docs for complex features** - Behavior, advanced config
4. **Don't reinvent the wheel** - Copy and modify
5. **Verify before applying** - Use --dry-run

---

**Practice using only these three methods. You'll be much faster in the exam!**

**Back to**: [Main README](../README.md) | [Exam Environment](EXAM-ENVIRONMENT.md)
