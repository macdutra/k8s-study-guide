# Minikube vs kubectl Command Reference

Quick reference showing Minikube commands (for local practice) and their kubectl equivalents (for the exam).

## 🎯 Critical: Exam vs Local Practice

| Command Type | Available in Exam? | Use For |
|--------------|-------------------|---------|
| `kubectl` | ✅ YES | Everything - master these! |
| `minikube` | ❌ NO | Local practice only |
| `vim` / `nano` | ✅ YES | Editing files |
| `jq` / `yq` | ❌ NO | Nice to have locally |

## 📋 Command Equivalents

### Cluster Information

| Task | ⚠️ Minikube (Local Only) | ✅ kubectl (Exam-Safe) |
|------|-------------------------|----------------------|
| Cluster status | `minikube status` | `kubectl cluster-info`<br>`kubectl get nodes` |
| Cluster IP | `minikube ip` | `kubectl get nodes -o wide`<br>(see INTERNAL-IP column) |
| Cluster version | `minikube version` | `kubectl version` |

### Service Access

| Task | ⚠️ Minikube (Local Only) | ✅ kubectl (Exam-Safe) |
|------|-------------------------|----------------------|
| Get service URL | `minikube service <n> --url` | `kubectl get svc <n>`<br>`kubectl get nodes -o wide`<br>Combine NodePort + Node IP |
| Open in browser | `minikube service <n>` | `kubectl port-forward svc/<n> 8080:80`<br>Then open http://localhost:8080 |
| List services | `minikube service list` | `kubectl get svc -A` |

**Example:**
```bash
# ⚠️ Minikube way (local only):
minikube service nginx --url
# Output: http://192.168.49.2:30123

# ✅ kubectl way (exam-safe):
kubectl get svc nginx
# NAME    TYPE       CLUSTER-IP      EXTERNAL-IP   PORT(S)        AGE
# nginx   NodePort   10.96.100.50    <none>        80:30123/TCP   1m

kubectl get nodes -o wide
# NAME       STATUS   ROLES    AGE   INTERNAL-IP    ...
# minikube   Ready    master   10m   192.168.49.2   ...

# Construct URL: http://192.168.49.2:30123

# Or use port-forward:
kubectl port-forward svc/nginx 8080:80
# Access: http://localhost:8080
```

### Node Access

| Task | ⚠️ Minikube (Local Only) | ✅ kubectl (Exam-Safe) |
|------|-------------------------|----------------------|
| SSH to node | `minikube ssh` | `ssh user@<node-ip>`<br>(using cluster credentials) |
| Execute command | `minikube ssh "command"` | `kubectl debug node/<n> -it --image=ubuntu` |
| Copy files to node | `minikube cp local:/path remote:/path` | `kubectl cp <file> <pod>:/path`<br>(via pod) |

### Dashboard & UI

| Task | ⚠️ Minikube (Local Only) | ✅ kubectl (Exam-Safe) |
|------|-------------------------|----------------------|
| Open dashboard | `minikube dashboard` | `kubectl get all -A`<br>`kubectl top nodes`<br>`kubectl top pods` |
| View resources | `minikube dashboard` | `kubectl get all`<br>`kubectl describe <resource>` |

### Add-ons & Features

| Task | ⚠️ Minikube (Local Only) | ✅ kubectl (Exam-Safe) |
|------|-------------------------|----------------------|
| Enable ingress | `minikube addons enable ingress` | Already installed in exam cluster |
| Enable metrics | `minikube addons enable metrics-server` | Already installed in exam cluster |
| List add-ons | `minikube addons list` | `kubectl get pods -n kube-system` |

### Logs & Troubleshooting

| Task | ⚠️ Minikube (Local Only) | ✅ kubectl (Exam-Safe) |
|------|-------------------------|----------------------|
| Cluster logs | `minikube logs` | `kubectl logs -n kube-system <pod>`<br>`journalctl -u kubelet` (on node) |
| View events | `minikube logs` | `kubectl get events -A --sort-by='.lastTimestamp'` |
| Debug pod | `minikube ssh` then docker | `kubectl logs <pod>`<br>`kubectl describe pod <pod>`<br>`kubectl exec -it <pod> -- sh` |

## 🔧 Common Scenarios

### Scenario 1: Test a Deployment

```bash
# Create deployment
kubectl create deployment nginx --image=nginx --replicas=3

# Expose as NodePort
kubectl expose deployment nginx --port=80 --type=NodePort

# ⚠️ MINIKUBE WAY (local):
minikube service nginx --url
curl $(minikube service nginx --url)

# ✅ KUBECTL WAY (exam):
# Method 1: Port-forward (easiest)
kubectl port-forward svc/nginx 8080:80 &
curl http://localhost:8080
pkill -f "port-forward"

# Method 2: NodePort (if you need external access)
NODE_PORT=$(kubectl get svc nginx -o jsonpath='{.spec.ports[0].nodePort}')
NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[0].address}')
curl http://$NODE_IP:$NODE_PORT

# Method 3: From inside cluster
kubectl run test --image=curlimages/curl -it --rm -- curl http://nginx
```

### Scenario 2: Check Cluster Health

```bash
# ⚠️ MINIKUBE WAY (local):
minikube status
minikube ip

# ✅ KUBECTL WAY (exam):
kubectl cluster-info
kubectl get nodes
kubectl get nodes -o wide
kubectl get componentstatuses  # deprecated but may work
kubectl get --raw /healthz
```

### Scenario 3: Access etcd

```bash
# ⚠️ MINIKUBE WAY (local):
minikube ssh
# Then access etcd

# ✅ KUBECTL WAY (exam):
kubectl get pods -n kube-system | grep etcd
kubectl exec -it -n kube-system etcd-<node> -- sh
# Or SSH to control plane node if given access
```

### Scenario 4: Debugging Network Issues

```bash
# ⚠️ MINIKUBE WAY (local):
minikube ssh
docker ps
docker logs <container>

# ✅ KUBECTL WAY (exam):
kubectl get pods -o wide
kubectl describe pod <pod>
kubectl logs <pod>
kubectl exec -it <pod> -- sh

# Network debug pod:
kubectl run netshoot --image=nicolaka/netshoot -it --rm -- bash
# Inside pod: ping, curl, nslookup, etc.
```

## 💡 Pro Tips for Exam

### 1. Always Use kubectl

If you find yourself thinking "I wish I had minikube command", there's always a kubectl way:

```bash
# Want to: minikube service <n> --url
# Use instead: kubectl port-forward svc/<n> 8080:80

# Want to: minikube dashboard
# Use instead: kubectl get all -A

# Want to: minikube ssh
# Use instead: kubectl debug node/<n> -it --image=ubuntu
```

### 2. Master Port-Forward

This is your best friend for testing services:

```bash
# Forward service
kubectl port-forward svc/my-service 8080:80

# Forward pod
kubectl port-forward pod/my-pod 8080:80

# Forward deployment
kubectl port-forward deployment/my-deploy 8080:80

# Background mode
kubectl port-forward svc/my-service 8080:80 &

# Kill port-forward
pkill -f "port-forward"
```

### 3. Use JSONPath Instead of jq

```bash
# Want to: kubectl get pods -o json | jq '.items[].metadata.name'
# Use instead: kubectl get pods -o jsonpath='{.items[*].metadata.name}'

# Get specific field
kubectl get svc nginx -o jsonpath='{.spec.ports[0].nodePort}'

# Get node IP
kubectl get nodes -o jsonpath='{.items[0].status.addresses[0].address}'

# Multiple fields
kubectl get pods -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.status.podIP}{"\n"}{end}'
```

### 4. Quick Service Testing

```bash
# Don't waste time with NodePort if you just need to test
# Use port-forward instead:

kubectl port-forward svc/my-service 8080:80 &
curl http://localhost:8080
# Test complete
pkill -f "port-forward"

# Or use a test pod:
kubectl run test --image=curlimages/curl -it --rm -- curl http://my-service
```

## 📊 Summary Table

| You Want To... | Don't Use (Minikube) | Use Instead (kubectl) |
|----------------|---------------------|---------------------|
| Get service URL | `minikube service --url` | `kubectl port-forward` or get NodePort |
| See dashboard | `minikube dashboard` | `kubectl get all -A` |
| Get cluster IP | `minikube ip` | `kubectl get nodes -o wide` |
| SSH to node | `minikube ssh` | `kubectl debug node` or `ssh` |
| View logs | `minikube logs` | `kubectl logs` |
| Test service | `minikube service` | `kubectl port-forward` |

## 🎯 Practice Exercise

Replace these minikube commands with kubectl equivalents:

1. `minikube service my-app --url`
2. `minikube ip`
3. `minikube ssh "cat /var/log/pods/..."`
4. `minikube dashboard`
5. `minikube addons list`

<details>
<summary>Solutions</summary>

1. ```bash
   kubectl port-forward svc/my-app 8080:80
   # Or:
   kubectl get svc my-app
   kubectl get nodes -o wide
   ```

2. ```bash
   kubectl get nodes -o jsonpath='{.items[0].status.addresses[0].address}'
   ```

3. ```bash
   kubectl logs <pod-name>
   # Or:
   kubectl exec -it <pod-name> -- cat /var/log/...
   ```

4. ```bash
   kubectl get all -A
   kubectl top nodes
   kubectl top pods -A
   ```

5. ```bash
   kubectl get pods -n kube-system
   kubectl get all -n kube-system
   ```
</details>

## 🔖 Bookmark This Page

During your study:
- Use minikube commands for convenience
- Always learn the kubectl equivalent
- Practice with kubectl-only when doing mock exams

During the exam:
- Only kubectl commands available
- Use port-forward liberally
- Remember JSONPath for complex queries

---

**Remember**: Minikube is a tool to RUN Kubernetes locally. kubectl is the tool to MANAGE Kubernetes. In the exam, the cluster is already running - you just need kubectl!

**Back to**: [Main README](README.md) | [Exam Environment](EXAM-ENVIRONMENT.md)
