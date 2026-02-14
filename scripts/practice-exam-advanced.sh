#!/bin/bash

# Kubernetes CKA Study Guide - Advanced Practice Exam
# 16 tasks, 120 minutes
# Interactive version - No spoilers!

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Score tracking
SCORE=0
TOTAL=16

# Timer function - shows live clock and elapsed time
show_timer() {
    local start_time=$1
    while true; do
        local current_time=$(date +%s)
        local elapsed=$((current_time - start_time))
        local hours=$((elapsed / 3600))
        local minutes=$(((elapsed % 3600) / 60))
        local seconds=$((elapsed % 60))
        local clock=$(date +"%H:%M:%S")
        
        # Move cursor to top right corner and display
        tput sc  # Save cursor position
        tput cup 0 $(($(tput cols) - 45))  # Move to top right
        printf "${CYAN}⏱ Elapsed: %02d:%02d:%02d | 🕐 Clock: %s${NC}" $hours $minutes $seconds "$clock"
        tput rc  # Restore cursor position
        
        sleep 1
    done
}

# Start timer in background
start_timer() {
    START_TIME=$(date +%s)
    show_timer $START_TIME &
    TIMER_PID=$!
    # Ensure timer stops on script exit
    trap "kill $TIMER_PID 2>/dev/null" EXIT
}

# Stop timer
stop_timer() {
    if [ ! -z "$TIMER_PID" ]; then
        kill $TIMER_PID 2>/dev/null
        wait $TIMER_PID 2>/dev/null
    fi
}

# Print functions
print_header() {
    echo -e "\n${BLUE}══════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}══════════════════════════════════════════════════════════${NC}\n"
}

print_task() {
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║ Task $1 of $TOTAL${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${YELLOW}$2${NC}"
    echo ""
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

validate_and_score() {
    local validation_cmd=$1
    local solution=$2
    
    echo -e "${BLUE}Validating your answer...${NC}"
    sleep 1
    
    if eval "$validation_cmd" &>/dev/null; then
        print_success "CORRECT! Task completed successfully"
        SCORE=$((SCORE + 1))
    else
        print_error "Task not completed correctly"
    fi
    
    echo ""
    echo -e "${GREEN}═══ Solution ═══${NC}"
    echo -e "${CYAN}$solution${NC}"
    echo ""
    
    echo -e "${BLUE}Current Score: $SCORE/$TOTAL${NC}"
    echo ""
    read -p "Press ENTER to continue to next task..."
}

# Check prerequisites
check_prerequisites() {
    print_header "Checking Prerequisites"
    
    if ! command -v kubectl &> /dev/null; then
        echo -e "${RED}kubectl not found. Please install it first.${NC}"
        exit 1
    fi
    
    if ! kubectl cluster-info &> /dev/null; then
        echo -e "${RED}Kubernetes cluster not accessible. Please start minikube.${NC}"
        exit 1
    fi
    
    print_success "kubectl installed"
    print_success "Cluster accessible"
}

# Cleanup function
cleanup() {
    echo ""
    echo -e "${YELLOW}Cleaning up exam resources...${NC}"
    kubectl delete namespace exam-advanced production monitoring --ignore-not-found=true
    kubectl delete clusterrole deploy-manager --ignore-not-found=true
    kubectl delete clusterrolebinding deploy-binding --ignore-not-found=true
    kubectl delete pv exam-pv --ignore-not-found=true
    kubectl config set-context --current --namespace=default
    print_success "Cleanup complete"
}

# Main exam
clear
print_header "CKA ADVANCED PRACTICE EXAM"
echo -e "${YELLOW}Time Limit:${NC} 120 minutes"
echo -e "${YELLOW}Passing Score:${NC} 11/16 tasks (69%)"
echo -e "${YELLOW}Format:${NC} Complete tasks, validation after each"
echo ""
echo -e "${CYAN}Instructions:${NC}"
echo "• Read each task carefully"
echo "• Complete the task using kubectl"
echo "• Press ENTER when done to validate"
echo "• Solution shown after each task"
echo ""
echo -e "${RED}⚠ WARNING: This is the ADVANCED exam!${NC}"
echo "• Covers ETCD, RBAC, troubleshooting, upgrades"
echo "• Requires strong Kubernetes knowledge"
echo "• Recommended: Complete Beginner & Intermediate first"
echo ""
read -p "Press ENTER to start the exam..."

check_prerequisites

# Create exam namespace
print_header "Setting Up Exam Environment"
kubectl create namespace exam-advanced --dry-run=client -o yaml | kubectl apply -f - &>/dev/null
kubectl config set-context --current --namespace=exam-advanced &>/dev/null
print_success "Namespace 'exam-advanced' created and set"
sleep 1

# Start timer and chronometer
clear
start_timer
echo ""
echo ""
echo -e "${GREEN}Timer started! Good luck!${NC}"
sleep 2

#═══════════════════════════════════════════════════════════════
# TASK 1: ETCD Snapshot Backup
#═══════════════════════════════════════════════════════════════
clear
print_task "1" "ETCD Backup - Create a snapshot of ETCD database

Requirements:
  • Create ETCD snapshot at: /tmp/etcd-backup.db
  • Use etcdctl to create the backup
  
Note: This simulates ETCD backup (validation checks file exists)"

echo -e "${YELLOW}Complete this task, then press ENTER to validate...${NC}"
read -p ""

validate_and_score \
    "[ -f /tmp/etcd-backup.db ] || kubectl get pods -n kube-system | grep -q etcd" \
    "# On a real cluster with access to etcd:
ETCDCTL_API=3 etcdctl snapshot save /tmp/etcd-backup.db \\
  --endpoints=https://127.0.0.1:2379 \\
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \\
  --cert=/etc/kubernetes/pki/etcd/server.crt \\
  --key=/etc/kubernetes/pki/etcd/server.key

# For this practice (Minikube), create dummy file:
touch /tmp/etcd-backup.db"

#═══════════════════════════════════════════════════════════════
# TASK 2: ClusterRole and ClusterRoleBinding
#═══════════════════════════════════════════════════════════════
clear
print_task "2" "RBAC - Create ClusterRole for deployment management

Requirements:
  • ClusterRole name: deploy-manager
  • Permissions: get, list, create, update, delete on deployments
  • ClusterRoleBinding name: deploy-binding
  • Bind to user: john"

echo -e "${YELLOW}Complete this task, then press ENTER to validate...${NC}"
read -p ""

validate_and_score \
    "kubectl get clusterrole deploy-manager && kubectl get clusterrolebinding deploy-binding" \
    "kubectl create clusterrole deploy-manager \\
  --verb=get,list,create,update,delete \\
  --resource=deployments

kubectl create clusterrolebinding deploy-binding \\
  --clusterrole=deploy-manager \\
  --user=john"

#═══════════════════════════════════════════════════════════════
# TASK 3: Network Policy - Multiple Rules
#═══════════════════════════════════════════════════════════════
clear
print_task "3" "NetworkPolicy - Complex ingress and egress rules

Requirements:
  • Create pods: frontend (app=frontend), backend (app=backend), db (app=db)
  • NetworkPolicy name: db-network-policy
  • Allow ingress to db ONLY from backend on port 5432
  • Allow egress from db ONLY to DNS (port 53 UDP)
  • Use labels to select pods"

echo -e "${YELLOW}Complete this task, then press ENTER to validate...${NC}"
read -p ""

validate_and_score \
    "kubectl get networkpolicy db-network-policy -n exam-advanced" \
    "kubectl run frontend --image=nginx --labels=app=frontend
kubectl run backend --image=nginx --labels=app=backend  
kubectl run db --image=postgres:alpine --labels=app=db --env='POSTGRES_PASSWORD=secret'

cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: db-network-policy
spec:
  podSelector:
    matchLabels:
      app: db
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: backend
    ports:
    - protocol: TCP
      port: 5432
  egress:
  - to:
    - namespaceSelector: {}
    ports:
    - protocol: UDP
      port: 53
EOF"

#═══════════════════════════════════════════════════════════════
# TASK 4: Troubleshooting - Fix Broken Pod
#═══════════════════════════════════════════════════════════════
clear
print_task "4" "Troubleshooting - Fix a CrashLoopBackOff pod

Requirements:
  • A broken pod 'broken-app' has been created with wrong image
  • Current image: ngnix:latest (typo!)
  • Fix the pod to use correct image: nginx:latest
  • Pod should be in Running state"

# Create broken pod
kubectl run broken-app --image=ngnix:latest &>/dev/null || true

echo -e "${YELLOW}Complete this task, then press ENTER to validate...${NC}"
read -p ""

validate_and_score \
    "kubectl get pod broken-app -n exam-advanced -o jsonpath='{.status.phase}' | grep -q Running" \
    "# Method 1: Delete and recreate
kubectl delete pod broken-app
kubectl run broken-app --image=nginx:latest

# Method 2: Edit the pod
kubectl edit pod broken-app
# Change image from 'ngnix' to 'nginx'

# Method 3: Replace
kubectl get pod broken-app -o yaml > broken-app.yaml
# Edit broken-app.yaml to fix image
kubectl replace -f broken-app.yaml --force"

#═══════════════════════════════════════════════════════════════
# TASK 5: Multi-container Pod with Shared Volume
#═══════════════════════════════════════════════════════════════
clear
print_task "5" "Sidecar Pattern - Pod with shared volume between containers

Requirements:
  • Pod name: log-processor
  • Container 1 'app': nginx, writes logs to /var/log/nginx
  • Container 2 'sidecar': busybox, reads from /logs
  • Shared emptyDir volume mounted to both containers"

echo -e "${YELLOW}Complete this task, then press ENTER to validate...${NC}"
read -p ""

validate_and_score \
    "kubectl get pod log-processor -n exam-advanced && [ \$(kubectl get pod log-processor -n exam-advanced -o jsonpath='{.spec.containers[*].name}' | wc -w) -eq 2 ]" \
    "cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: log-processor
spec:
  volumes:
  - name: logs
    emptyDir: {}
  containers:
  - name: app
    image: nginx
    volumeMounts:
    - name: logs
      mountPath: /var/log/nginx
  - name: sidecar
    image: busybox
    command: ['sh', '-c', 'tail -f /logs/access.log 2>/dev/null || sleep 3600']
    volumeMounts:
    - name: logs
      mountPath: /logs
EOF"

#═══════════════════════════════════════════════════════════════
# TASK 6: Node Affinity
#═══════════════════════════════════════════════════════════════
clear
print_task "6" "Scheduling - Pod with node affinity

Requirements:
  • Pod name: affinity-pod
  • Image: nginx
  • Node affinity: requiredDuringSchedulingIgnoredDuringExecution
  • Match node with label: disktype=ssd"

echo -e "${YELLOW}Complete this task, then press ENTER to validate...${NC}"
read -p ""

validate_and_score \
    "kubectl get pod affinity-pod -n exam-advanced" \
    "cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: affinity-pod
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
  containers:
  - name: nginx
    image: nginx
EOF

# Note: Pod may be Pending if no node has disktype=ssd label
# To test: kubectl label nodes <node-name> disktype=ssd"

#═══════════════════════════════════════════════════════════════
# TASK 7: Taints and Tolerations
#═══════════════════════════════════════════════════════════════
clear
print_task "7" "Scheduling - Pod with toleration

Requirements:
  • First, taint a node: kubectl taint nodes <node> gpu=true:NoSchedule
  • Pod name: gpu-pod
  • Image: nginx
  • Add toleration for taint: gpu=true:NoSchedule"

echo -e "${YELLOW}Complete this task, then press ENTER to validate...${NC}"
read -p ""

validate_and_score \
    "kubectl get pod gpu-pod -n exam-advanced" \
    "# First, taint a node (get node name first)
NODE=\$(kubectl get nodes -o jsonpath='{.items[0].metadata.name}')
kubectl taint nodes \$NODE gpu=true:NoSchedule

# Create pod with toleration
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: gpu-pod
spec:
  tolerations:
  - key: gpu
    operator: Equal
    value: \"true\"
    effect: NoSchedule
  containers:
  - name: nginx
    image: nginx
EOF

# Remove taint after (optional):
# kubectl taint nodes \$NODE gpu=true:NoSchedule-"

#═══════════════════════════════════════════════════════════════
# TASK 8: PersistentVolume with Specific Storage Class
#═══════════════════════════════════════════════════════════════
clear
print_task "8" "Storage - Create PV, PVC with StorageClass

Requirements:
  • PersistentVolume name: advanced-pv
  • Storage: 2Gi, AccessMode: ReadWriteOnce
  • StorageClass: manual
  • hostPath: /mnt/advanced-data
  • PVC name: advanced-pvc requesting 1Gi"

echo -e "${YELLOW}Complete this task, then press ENTER to validate...${NC}"
read -p ""

validate_and_score \
    "kubectl get pv advanced-pv && kubectl get pvc advanced-pvc -n exam-advanced" \
    "cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: PersistentVolume
metadata:
  name: advanced-pv
spec:
  storageClassName: manual
  capacity:
    storage: 2Gi
  accessModes:
  - ReadWriteOnce
  hostPath:
    path: /mnt/advanced-data
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: advanced-pvc
spec:
  storageClassName: manual
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
EOF"

#═══════════════════════════════════════════════════════════════
# TASK 9: Service Account with Secret
#═══════════════════════════════════════════════════════════════
clear
print_task "9" "Security - ServiceAccount with mounted secret

Requirements:
  • ServiceAccount name: secure-sa
  • Secret name: api-token with key: token, value: abc123xyz
  • Pod name: secure-pod using secure-sa
  • Mount secret as volume at /etc/api-token"

echo -e "${YELLOW}Complete this task, then press ENTER to validate...${NC}"
read -p ""

validate_and_score \
    "kubectl get serviceaccount secure-sa -n exam-advanced && kubectl get pod secure-pod -n exam-advanced" \
    "kubectl create serviceaccount secure-sa

kubectl create secret generic api-token --from-literal=token=abc123xyz

cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: secure-pod
spec:
  serviceAccountName: secure-sa
  volumes:
  - name: token-volume
    secret:
      secretName: api-token
  containers:
  - name: app
    image: nginx
    volumeMounts:
    - name: token-volume
      mountPath: /etc/api-token
      readOnly: true
EOF"

#═══════════════════════════════════════════════════════════════
# TASK 10: Resource Quota and LimitRange
#═══════════════════════════════════════════════════════════════
clear
print_task "10" "Resource Management - Quota and Limits

Requirements:
  • Create namespace: production
  • ResourceQuota name: prod-quota
    - Max CPU: 4 cores
    - Max Memory: 8Gi
    - Max Pods: 20
  • LimitRange name: prod-limits
    - Default CPU request: 100m
    - Default Memory request: 128Mi"

echo -e "${YELLOW}Complete this task, then press ENTER to validate...${NC}"
read -p ""

validate_and_score \
    "kubectl get resourcequota prod-quota -n production && kubectl get limitrange prod-limits -n production" \
    "kubectl create namespace production

cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ResourceQuota
metadata:
  name: prod-quota
  namespace: production
spec:
  hard:
    requests.cpu: \"4\"
    requests.memory: 8Gi
    pods: \"20\"
---
apiVersion: v1
kind: LimitRange
metadata:
  name: prod-limits
  namespace: production
spec:
  limits:
  - default:
      cpu: 200m
      memory: 256Mi
    defaultRequest:
      cpu: 100m
      memory: 128Mi
    type: Container
EOF"

#═══════════════════════════════════════════════════════════════
# TASK 11: Upgrade Deployment with Rolling Update
#═══════════════════════════════════════════════════════════════
clear
print_task "11" "Deployment Strategy - Rolling update with controls

Requirements:
  • Deployment name: rolling-app
  • Image: nginx:1.19 (initial), replicas: 5
  • Update strategy: maxSurge: 1, maxUnavailable: 1
  • Then perform rolling update to nginx:1.21"

echo -e "${YELLOW}Complete this task, then press ENTER to validate...${NC}"
read -p ""

validate_and_score \
    "kubectl get deployment rolling-app -n exam-advanced" \
    "kubectl create deployment rolling-app --image=nginx:1.19 --replicas=5

kubectl patch deployment rolling-app -p '{\"spec\":{\"strategy\":{\"type\":\"RollingUpdate\",\"rollingUpdate\":{\"maxSurge\":1,\"maxUnavailable\":1}}}}'

# Perform rolling update
kubectl set image deployment/rolling-app nginx=nginx:1.21

# Watch the rollout
kubectl rollout status deployment/rolling-app"

#═══════════════════════════════════════════════════════════════
# TASK 12: Pod Security - securityContext
#═══════════════════════════════════════════════════════════════
clear
print_task "12" "Security - Pod with security context

Requirements:
  • Pod name: secure-nginx
  • Image: nginx
  • Run as non-root user (runAsUser: 1000)
  • Read-only root filesystem
  • Drop all capabilities"

echo -e "${YELLOW}Complete this task, then press ENTER to validate...${NC}"
read -p ""

validate_and_score \
    "kubectl get pod secure-nginx -n exam-advanced" \
    "cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: secure-nginx
spec:
  securityContext:
    runAsUser: 1000
    runAsNonRoot: true
  containers:
  - name: nginx
    image: nginx
    securityContext:
      readOnlyRootFilesystem: true
      capabilities:
        drop:
        - ALL
    volumeMounts:
    - name: cache
      mountPath: /var/cache/nginx
    - name: run
      mountPath: /var/run
  volumes:
  - name: cache
    emptyDir: {}
  - name: run
    emptyDir: {}
EOF"

#═══════════════════════════════════════════════════════════════
# TASK 13: ConfigMap and Secret in Pod
#═══════════════════════════════════════════════════════════════
clear
print_task "13" "Configuration - Use ConfigMap and Secret together

Requirements:
  • ConfigMap name: app-config with: app.env=production, log.level=info
  • Secret name: app-secret with: db.password=secretpass
  • Pod name: config-app (image: nginx)
  • Mount ConfigMap as volume at /etc/config
  • Use Secret as environment variable DB_PASSWORD"

echo -e "${YELLOW}Complete this task, then press ENTER to validate...${NC}"
read -p ""

validate_and_score \
    "kubectl get pod config-app -n exam-advanced" \
    "kubectl create configmap app-config \\
  --from-literal=app.env=production \\
  --from-literal=log.level=info

kubectl create secret generic app-secret \\
  --from-literal=db.password=secretpass

cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: config-app
spec:
  volumes:
  - name: config-volume
    configMap:
      name: app-config
  containers:
  - name: nginx
    image: nginx
    env:
    - name: DB_PASSWORD
      valueFrom:
        secretKeyRef:
          name: app-secret
          key: db.password
    volumeMounts:
    - name: config-volume
      mountPath: /etc/config
EOF"

#═══════════════════════════════════════════════════════════════
# TASK 14: Monitoring - Create metrics collection setup
#═══════════════════════════════════════════════════════════════
clear
print_task "14" "Monitoring - Setup namespace with labels for monitoring

Requirements:
  • Create namespace: monitoring
  • Add label: team=ops, environment=production
  • Create pod: monitor-agent (image: nginx)
  • Add labels: app=monitor, version=v1
  • Add annotation: prometheus.io/scrape=true"

echo -e "${YELLOW}Complete this task, then press ENTER to validate...${NC}"
read -p ""

validate_and_score \
    "kubectl get namespace monitoring && kubectl get pod monitor-agent -n monitoring" \
    "kubectl create namespace monitoring

kubectl label namespace monitoring team=ops environment=production

kubectl run monitor-agent --image=nginx -n monitoring \\
  --labels=app=monitor,version=v1

kubectl annotate pod monitor-agent -n monitoring \\
  prometheus.io/scrape=true"

#═══════════════════════════════════════════════════════════════
# TASK 15: Advanced Service - Headless Service
#═══════════════════════════════════════════════════════════════
clear
print_task "15" "Networking - Create headless service for StatefulSet

Requirements:
  • Service name: headless-svc (ClusterIP: None)
  • Selector: app=stateful
  • Port: 80
  • StatefulSet name: stateful-app
  • Replicas: 3, using service: headless-svc"

echo -e "${YELLOW}Complete this task, then press ENTER to validate...${NC}"
read -p ""

validate_and_score \
    "kubectl get service headless-svc -n exam-advanced && kubectl get statefulset stateful-app -n exam-advanced" \
    "# Create headless service
kubectl create service clusterip headless-svc \\
  --tcp=80:80 \\
  --clusterip=None

kubectl patch service headless-svc -p '{\"spec\":{\"selector\":{\"app\":\"stateful\"}}}'

# Create StatefulSet
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: stateful-app
spec:
  serviceName: headless-svc
  replicas: 3
  selector:
    matchLabels:
      app: stateful
  template:
    metadata:
      labels:
        app: stateful
    spec:
      containers:
      - name: nginx
        image: nginx
        ports:
        - containerPort: 80
EOF"

#═══════════════════════════════════════════════════════════════
# TASK 16: Troubleshooting - Debug cluster issue
#═══════════════════════════════════════════════════════════════
clear
print_task "16" "Final Challenge - Multi-step troubleshooting

Requirements:
  • Create a deployment: debug-app (image: nginx, replicas: 3)
  • The deployment has issues (missing resource requests)
  • Add resource requests: cpu=50m, memory=64Mi
  • Verify all 3 pods are Running
  • Expose as service on port 80"

echo -e "${YELLOW}Complete this task, then press ENTER to validate...${NC}"
read -p ""

validate_and_score \
    "kubectl get deployment debug-app -n exam-advanced && kubectl get service debug-app -n exam-advanced && [ \$(kubectl get pods -l app=debug-app -n exam-advanced --field-selector=status.phase=Running --no-headers | wc -l) -eq 3 ]" \
    "# Create deployment
kubectl create deployment debug-app --image=nginx --replicas=3

# Add resource requests
kubectl set resources deployment debug-app \\
  --requests=cpu=50m,memory=64Mi

# Wait for rollout
kubectl rollout status deployment debug-app

# Expose service
kubectl expose deployment debug-app --port=80

# Verify
kubectl get pods -l app=debug-app
kubectl get svc debug-app"

#═══════════════════════════════════════════════════════════════
# FINAL SCORE
#═══════════════════════════════════════════════════════════════

# Stop timer
stop_timer

END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))
HOURS=$((DURATION / 3600))
MINUTES=$(((DURATION % 3600) / 60))
SECONDS=$((DURATION % 60))

clear
print_header "EXAM COMPLETE!"

echo -e "${CYAN}Final Score: $SCORE / $TOTAL${NC}"
if [ $HOURS -gt 0 ]; then
    echo -e "${CYAN}Time Taken: ${HOURS}h ${MINUTES}m ${SECONDS}s${NC}"
else
    echo -e "${CYAN}Time Taken: ${MINUTES}m ${SECONDS}s${NC}"
fi
echo ""

PERCENTAGE=$((SCORE * 100 / TOTAL))

if [ $PERCENTAGE -ge 69 ]; then
    echo -e "${GREEN}╔══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║                      PASSED! ✓                           ║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${GREEN}Congratulations! You passed the ADVANCED exam!${NC}"
else
    echo -e "${YELLOW}╔══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}║                   NEEDS IMPROVEMENT                      ║${NC}"
    echo -e "${YELLOW}╚══════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${YELLOW}Keep practicing! You need 11/16 to pass.${NC}"
fi

echo ""
echo -e "${BLUE}Grade: $PERCENTAGE%${NC}"
echo ""

if [ $PERCENTAGE -ge 90 ]; then
    echo -e "${GREEN}🌟 OUTSTANDING! You're READY for the CKA exam!${NC}"
elif [ $PERCENTAGE -ge 80 ]; then
    echo -e "${GREEN}🎯 EXCELLENT! Almost exam-ready!${NC}"
elif [ $PERCENTAGE -ge 69 ]; then
    echo -e "${YELLOW}👍 GOOD! Practice more complex scenarios.${NC}"
else
    echo -e "${RED}📚 STUDY MORE! Review advanced topics.${NC}"
fi

echo ""
echo -e "${CYAN}Recommended next steps:${NC}"
if [ $PERCENTAGE -ge 80 ]; then
    echo -e "  ✅ Practice on killer.sh"
    echo -e "  ✅ Schedule your CKA exam"
    echo -e "  ✅ Review any topics you missed"
elif [ $PERCENTAGE -ge 69 ]; then
    echo -e "  📖 Review ETCD, RBAC, and troubleshooting"
    echo -e "  🔄 Retake this exam for better score"
    echo -e "  ⏱️  Practice speed - aim for < 100 min"
else
    echo -e "  📚 Study the documentation thoroughly"
    echo -e "  🔄 Redo intermediate exam first"
    echo -e "  💪 Practice more hands-on scenarios"
fi

echo ""
read -p "Would you like to clean up exam resources? (y/n): " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
    cleanup
else
    echo -e "${YELLOW}Resources left in namespaces${NC}"
    echo -e "Clean up later with the following commands:"
    echo -e "  kubectl delete namespace exam-advanced production monitoring"
    echo -e "  kubectl delete clusterrole deploy-manager"
    echo -e "  kubectl delete clusterrolebinding deploy-binding"
fi

echo ""
echo -e "${GREEN}Congratulations on completing the Advanced exam! 🚀${NC}"
echo -e "${CYAN}You're well on your way to CKA certification!${NC}"
echo ""
