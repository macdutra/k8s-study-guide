# Full CKA Practice Exam

**Time Limit**: 120 minutes  
**Passing Score**: 66% (11 out of 16 tasks)  
**Environment**: Minikube cluster

## Exam Rules

- ✅ You may use kubectl documentation (`kubectl explain`)
- ✅ You may use Kubernetes documentation (kubernetes.io/docs)
- ❌ No external help or collaboration
- ⏰ Set a timer for 120 minutes
- 📝 Track your answers for self-grading

## Before You Start

```bash
# Verify cluster is running
minikube status

# If not running, start it
minikube start --cpus=4 --memory=8192

# Verify cluster
kubectl cluster-info
kubectl get nodes

# Set context
kubectl config use-context minikube

# Create exam namespace
kubectl create namespace exam

# Set default namespace
kubectl config set-context --current --namespace=exam
```

---

## Task 1: Horizontal Pod Autoscaler with ScaleDown (8 points)

**Objective**: Create an HPA for a deployment with custom scaleDown behavior.

### Requirements:
- Create a deployment named `web-app` with image `nginx:alpine`
- Initial replicas: 1
- Set resource requests: CPU 100m, Memory 128Mi
- Create HPA named `web-app-hpa`
- Minimum replicas: 1
- Maximum replicas: 4
- Target CPU utilization: 50%
- ScaleDown stabilization window: 60 seconds
- ScaleDown policy: Max 50% pods per 15 seconds

### Solution Space:

```bash
# Your commands here:




```

<details>
<summary>Show Solution</summary>

```bash
# Create deployment
kubectl create deployment web-app --image=nginx:alpine --replicas=1

# Set resources
kubectl set resources deployment web-app --requests=cpu=100m,memory=128Mi --limits=cpu=500m,memory=256Mi

# Create HPA with custom behavior
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
```
</details>

---

## Task 2: Ingress Configuration (6 points)

**Objective**: Create an Ingress resource for hostname-based routing.

### Requirements:
- Ingress name: `example-ingress`
- Hostname: `example.org`
- Backend service: `web-app` (from Task 1)
- Port: 80
- Path: `/` (Prefix)
- Test with curl

### Solution Space:

```bash
# Your commands here:




```

<details>
<summary>Show Solution</summary>

```bash
# Expose deployment as service first
kubectl expose deployment web-app --port=80 --name=web-app

# Create Ingress
cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: example-ingress
spec:
  ingressClassName: nginx
  rules:
  - host: example.org
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: web-app
            port:
              number: 80
EOF

# Test
MINIKUBE_IP=$(minikube ip)
curl -H "Host: example.org" http://$MINIKUBE_IP

# Or add to /etc/hosts
echo "$MINIKUBE_IP example.org" | sudo tee -a /etc/hosts
curl http://example.org
```
</details>

---

## Task 3: Fix Memory Issues (5 points)

**Objective**: Fix a WordPress deployment with insufficient memory.

### Scenario:
A WordPress deployment exists but pods are failing due to OOMKilled.

### Setup:

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
            memory: "32Mi"
            cpu: "100m"
          limits:
            memory: "64Mi"
            cpu: "200m"
EOF
```

### Requirements:
- Fix the deployment to use appropriate memory resources
- Requests: memory 256Mi, cpu 100m
- Limits: memory 512Mi, cpu 500m
- Use `kubectl edit` command

### Solution Space:

```bash
# Your commands here:




```

<details>
<summary>Show Solution</summary>

```bash
# Method 1: kubectl edit
kubectl edit deployment wordpress
# Change:
# requests:
#   memory: "256Mi"
#   cpu: "100m"
# limits:
#   memory: "512Mi"
#   cpu: "500m"

# Method 2: kubectl patch
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

# Verify
kubectl get pods
kubectl describe pod -l app=wordpress | grep -A 5 Resources
```
</details>

---

## Task 4: Sidecar Pattern (7 points)

**Objective**: Create a deployment with a sidecar container sharing a volume.

### Requirements:
- Deployment name: `app-with-sidecar`
- Main container: `busybox`, writes logs to `/var/log/app.log` every 5 seconds
- Sidecar container: `busybox`, reads from `/var/log/app.log`
- Shared volume: `emptyDir` named `shared-logs`
- Both containers mount at `/var/log`
- Verify sidecar can read main container's logs

### Solution Space:

```bash
# Your commands here:




```

<details>
<summary>Show Solution</summary>

```bash
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app-with-sidecar
spec:
  replicas: 1
  selector:
    matchLabels:
      app: sidecar-demo
  template:
    metadata:
      labels:
        app: sidecar-demo
    spec:
      volumes:
      - name: shared-logs
        emptyDir: {}
      containers:
      - name: main-app
        image: busybox
        command: ['sh', '-c']
        args:
        - while true; do echo "$(date) - Log entry" >> /var/log/app.log; sleep 5; done
        volumeMounts:
        - name: shared-logs
          mountPath: /var/log
      - name: log-sidecar
        image: busybox
        command: ['sh', '-c']
        args:
        - tail -f /var/log/app.log
        volumeMounts:
        - name: shared-logs
          mountPath: /var/log
          readOnly: true
EOF

# Verify
kubectl get pods -l app=sidecar-demo
POD=$(kubectl get pod -l app=sidecar-demo -o jsonpath='{.items[0].metadata.name}')
kubectl logs $POD -c log-sidecar
```
</details>

---

## Task 5: Storage Class with WaitForFirstConsumer (7 points)

**Objective**: Create a StorageClass with delayed binding.

### Requirements:
- StorageClass name: `delayed-storage`
- Provisioner: `k8s.io/minikube-hostpath`
- Volume binding mode: `WaitForFirstConsumer`
- Reclaim policy: `Delete`
- Create a PVC using this storage class

### Solution Space:

```bash
# Your commands here:




```

<details>
<summary>Show Solution</summary>

```bash
# Create StorageClass
cat <<EOF | kubectl apply -f -
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: delayed-storage
provisioner: k8s.io/minikube-hostpath
volumeBindingMode: WaitForFirstConsumer
reclaimPolicy: Delete
EOF

# Create PVC
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: delayed-pvc
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: delayed-storage
  resources:
    requests:
      storage: 1Gi
EOF

# Verify (should be Pending until used by pod)
kubectl get pvc delayed-pvc
kubectl get sc delayed-storage
```
</details>

---

## Task 6: Service Type Conversion (5 points)

**Objective**: Convert an existing ClusterIP service to NodePort.

### Requirements:
- Convert `web-app` service from Task 1 to NodePort
- Specify nodePort: 30080
- Verify you can access it via minikube IP

### Solution Space:

```bash
# Your commands here:




```

<details>
<summary>Show Solution</summary>

```bash
# Method 1: kubectl edit
kubectl edit svc web-app
# Change type: NodePort and add nodePort: 30080

# Method 2: kubectl patch
kubectl patch svc web-app -p '{"spec":{"type":"NodePort","ports":[{"port":80,"targetPort":80,"nodePort":30080}]}}'

# Verify and test
kubectl get svc web-app
MINIKUBE_IP=$(minikube ip)
curl http://$MINIKUBE_IP:30080
```
</details>

---

## Task 7: Priority Class (6 points)

**Objective**: Create a PriorityClass and use it in a pod.

### Requirements:
- PriorityClass name: `high-priority`
- Value: 1000
- Global default: false
- Create a pod named `critical-pod` using this priority
- Image: `nginx:alpine`

### Solution Space:

```bash
# Your commands here:




```

<details>
<summary>Show Solution</summary>

```bash
# Create PriorityClass
cat <<EOF | kubectl apply -f -
apiVersion: scheduling.k8s.io/v1
kind: PriorityClass
metadata:
  name: high-priority
value: 1000
globalDefault: false
description: "High priority for critical pods"
EOF

# Create pod with priority
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: critical-pod
spec:
  priorityClassName: high-priority
  containers:
  - name: nginx
    image: nginx:alpine
EOF

# Verify
kubectl get priorityclass
kubectl describe pod critical-pod | grep -i priority
```
</details>

---

## Task 8: PVC Creation and Usage (7 points)

**Objective**: Create a PVC and use it in a deployment.

### Requirements:
- Create PVC named `app-data`
- Storage: 2Gi
- Access mode: ReadWriteOnce
- Use the `delayed-storage` StorageClass from Task 5
- Create deployment `data-app` using this PVC
- Mount at `/data` in the container

### Solution Space:

```bash
# Your commands here:




```

<details>
<summary>Show Solution</summary>

```bash
# Create PVC
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: app-data
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: delayed-storage
  resources:
    requests:
      storage: 2Gi
EOF

# Create deployment
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: data-app
spec:
  replicas: 1
  selector:
    matchLabels:
      app: data-app
  template:
    metadata:
      labels:
        app: data-app
    spec:
      containers:
      - name: nginx
        image: nginx:alpine
        volumeMounts:
        - name: data
          mountPath: /data
      volumes:
      - name: data
        persistentVolumeClaim:
          claimName: app-data
EOF

# Verify
kubectl get pvc app-data
kubectl get pods -l app=data-app
```
</details>

---

## Task 9: Gateway API (8 points)

**Objective**: Create a Gateway and HTTPRoute, then delete old Ingress.

### Requirements:
- Create Gateway named `api-gateway`
- Listener on port 80 for hostname `*.api.example.org`
- Create HTTPRoute named `api-route` for `api.example.org`
- Route `/v1` to `web-app` service
- Delete the `example-ingress` from Task 2
- Test with curl

### Solution Space:

```bash
# Your commands here:




```

<details>
<summary>Show Solution</summary>

```bash
# Note: Gateway API requires additional setup in minikube
# For exam purposes, show knowledge of the manifests

# Install Gateway API CRDs (if not already)
kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.0.0/standard-install.yaml

# Create Gateway
cat <<EOF | kubectl apply -f -
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: api-gateway
spec:
  gatewayClassName: nginx
  listeners:
  - name: http
    protocol: HTTP
    port: 80
    hostname: "*.api.example.org"
EOF

# Create HTTPRoute
cat <<EOF | kubectl apply -f -
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: api-route
spec:
  parentRefs:
  - name: api-gateway
  hostnames:
  - "api.example.org"
  rules:
  - matches:
    - path:
        type: PathPrefix
        value: /v1
    backendRefs:
    - name: web-app
      port: 80
EOF

# Delete old ingress
kubectl delete ingress example-ingress

# Verify
kubectl get gateway api-gateway
kubectl get httproute api-route
```
</details>

---

## Task 10: Network Policy (8 points)

**Objective**: Create a NetworkPolicy to restrict pod communication.

### Requirements:
- Create three pods: `frontend`, `backend`, `database`
- NetworkPolicy name: `db-network-policy`
- Allow only `backend` pods to communicate with `database` on port 5432
- Deny all other ingress to `database`

### Solution Space:

```bash
# Your commands here:




```

<details>
<summary>Show Solution</summary>

```bash
# Create pods
kubectl run frontend --image=nginx --labels="tier=frontend"
kubectl run backend --image=nginx --labels="tier=backend"
kubectl run database --image=postgres --labels="tier=database" --env="POSTGRES_PASSWORD=secret"

# Create NetworkPolicy
cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: db-network-policy
spec:
  podSelector:
    matchLabels:
      tier: database
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          tier: backend
    ports:
    - protocol: TCP
      port: 5432
EOF

# Verify
kubectl get networkpolicy
kubectl describe networkpolicy db-network-policy
```
</details>

---

## Task 11: CRD Export (5 points)

**Objective**: Export Custom Resource Definitions and use kubectl explain.

### Requirements:
- Export all CRDs to file `all-crds.yaml`
- Use `kubectl explain` on any CRD and save output to `crd-explain.txt`

### Solution Space:

```bash
# Your commands here:




```

<details>
<summary>Show Solution</summary>

```bash
# Export all CRDs
kubectl get crd -o yaml > all-crds.yaml

# Pick a CRD and explain it
# Example with gateways (from Gateway API)
kubectl explain gateways > crd-explain.txt
kubectl explain gateways.spec >> crd-explain.txt

# Verify
ls -lh all-crds.yaml crd-explain.txt
cat crd-explain.txt
```
</details>

---

## Task 12: Immutable ConfigMap (5 points)

**Objective**: Create an immutable ConfigMap with TLS configuration.

### Requirements:
- ConfigMap name: `tls-config`
- Data key: `min-tls-version` with value `1.2`
- Must be immutable
- Create a pod that uses this ConfigMap

### Solution Space:

```bash
# Your commands here:




```

<details>
<summary>Show Solution</summary>

```bash
# Create immutable ConfigMap
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: tls-config
data:
  min-tls-version: "1.2"
  tls.conf: |
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_prefer_server_ciphers on;
immutable: true
EOF

# Create pod using ConfigMap
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: tls-pod
spec:
  containers:
  - name: nginx
    image: nginx:alpine
    volumeMounts:
    - name: config
      mountPath: /etc/tls
  volumes:
  - name: config
    configMap:
      name: tls-config
EOF

# Verify immutability
kubectl edit cm tls-config  # Should fail
kubectl get cm tls-config -o yaml | grep immutable
```
</details>

---

## Task 13: Helm Installation (7 points)

**Objective**: Install ArgoCD using Helm (template first, then install).

### Requirements:
- Add ArgoCD Helm repository
- Generate template to `argocd-template.yaml`
- Install in namespace `argocd`
- Service type: NodePort
- Verify installation

### Solution Space:

```bash
# Your commands here:




```

<details>
<summary>Show Solution</summary>

```bash
# Add Helm repo
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update

# Create namespace
kubectl create namespace argocd

# Generate template
helm template argocd argo/argo-cd \
  --namespace argocd \
  --set server.service.type=NodePort \
  > argocd-template.yaml

# Install
kubectl apply -f argocd-template.yaml -n argocd

# Or install directly
helm install argocd argo/argo-cd \
  --namespace argocd \
  --set server.service.type=NodePort

# Verify
kubectl get pods -n argocd
kubectl get svc -n argocd
```
</details>

---

## Task 14: ETCD Troubleshooting (8 points)

**Objective**: Diagnose and fix ETCD connectivity issue.

### Scenario:
The API server cannot connect to ETCD. Fix the configuration.

### Setup:
```bash
# This task requires SSH to minikube node
# Simulate by viewing manifests
minikube ssh
sudo cat /etc/kubernetes/manifests/kube-apiserver.yaml | grep etcd
exit
```

### Requirements:
- Identify the ETCD server configuration in kube-apiserver
- Verify ETCD is running correctly
- Document the correct ETCD endpoint

### Solution Space:

```bash
# Your commands here:




```

<details>
<summary>Show Solution</summary>

```bash
# SSH into minikube
minikube ssh

# Check ETCD configuration
sudo cat /etc/kubernetes/manifests/kube-apiserver.yaml | grep etcd-servers
# Should see: --etcd-servers=https://127.0.0.1:2379

# Check ETCD pod
sudo crictl ps | grep etcd

# Verify ETCD health
ETCD_ID=$(sudo crictl ps | grep etcd | awk '{print $1}')
sudo crictl exec $ETCD_ID etcdctl \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/var/lib/minikube/certs/etcd/ca.crt \
  --cert=/var/lib/minikube/certs/etcd/server.crt \
  --key=/var/lib/minikube/certs/etcd/server.key \
  endpoint health

# Exit
exit

# If there was a wrong IP, correct it in:
# /etc/kubernetes/manifests/kube-apiserver.yaml
# Change --etcd-servers to correct endpoint: https://127.0.0.1:2379
```
</details>

---

## Task 15: Linux Network Configuration (5 points)

**Objective**: Configure network parameters using sysctl.

### Requirements:
- Enable IP forwarding
- Set net.ipv4.tcp_syncookies to 1
- Make changes persistent
- Verify configuration

### Solution Space:

```bash
# Your commands here (inside minikube ssh):




```

<details>
<summary>Show Solution</summary>

```bash
# SSH into minikube
minikube ssh

# Enable IP forwarding temporarily
sudo sysctl -w net.ipv4.ip_forward=1
sudo sysctl -w net.ipv4.tcp_syncookies=1

# Make persistent
sudo bash -c 'cat >> /etc/sysctl.conf << EOF
net.ipv4.ip_forward = 1
net.ipv4.tcp_syncookies = 1
EOF'

# Apply changes
sudo sysctl -p

# Verify
sysctl net.ipv4.ip_forward
sysctl net.ipv4.tcp_syncookies

exit
```
</details>

---

## Task 16: Package Management (4 points)

**Objective**: Install a package using dpkg.

### Requirements:
- Download and install `tree` package
- Verify installation
- List files from the package

### Solution Space:

```bash
# Your commands here (inside minikube ssh):




```

<details>
<summary>Show Solution</summary>

```bash
# SSH into minikube
minikube ssh

# Using apt (easier)
sudo apt-get update
sudo apt-get install -y tree

# Or using dpkg (if you have .deb file)
# wget http://ftp.us.debian.org/debian/pool/main/t/tree/tree_2.0.2-1_amd64.deb
# sudo dpkg -i tree_2.0.2-1_amd64.deb

# Verify
which tree
tree --version

# List package files
dpkg -L tree

exit
```
</details>

---

## Scoring

| Task | Points | Your Score |
|------|--------|------------|
| 1. HPA with ScaleDown | 8 | |
| 2. Ingress | 6 | |
| 3. Memory Fix | 5 | |
| 4. Sidecar | 7 | |
| 5. StorageClass | 7 | |
| 6. NodePort | 5 | |
| 7. PriorityClass | 6 | |
| 8. PVC Usage | 7 | |
| 9. Gateway API | 8 | |
| 10. NetworkPolicy | 8 | |
| 11. CRD Export | 5 | |
| 12. Immutable ConfigMap | 5 | |
| 13. Helm/ArgoCD | 7 | |
| 14. ETCD Troubleshooting | 8 | |
| 15. Network Config | 5 | |
| 16. Package Management | 4 | |
| **Total** | **100** | |

**Passing Score**: 66/100

## Cleanup

After the exam:

```bash
# Delete exam namespace
kubectl delete namespace exam

# Or delete all resources
kubectl delete all --all -n exam
kubectl delete pvc --all -n exam
kubectl delete networkpolicy --all -n exam

# Delete ArgoCD
helm uninstall argocd -n argocd
kubectl delete namespace argocd
```

## Time Management Tips

- ⏱️ **Average 7.5 minutes per task**
- 🎯 **Do easy tasks first** (2, 3, 6, 11, 12, 16)
- 🚀 **Use imperative commands** when possible
- 📋 **Flag and skip** difficult tasks, return later
- ✅ **Verify each task** before moving on

## Good Luck! 🚀

Remember:
- Read questions carefully
- Verify your work
- Watch the clock
- Stay calm and focused

---

**Back to**: [Main README](../README.md) | [Practice Exams](../examples/)
