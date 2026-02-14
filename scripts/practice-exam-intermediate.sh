#!/bin/bash

# Kubernetes CKA Study Guide - Intermediate Practice Exam
# 12 tasks, 90 minutes
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
TOTAL=12

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
    kubectl delete namespace exam-intermediate --ignore-not-found=true
    kubectl delete namespace production --ignore-not-found=true
    kubectl delete pv exam-pv --ignore-not-found=true
    kubectl config set-context --current --namespace=default
    print_success "Cleanup complete"
}

# Main exam
clear
print_header "CKA INTERMEDIATE PRACTICE EXAM"
echo -e "${YELLOW}Time Limit:${NC} 90 minutes"
echo -e "${YELLOW}Passing Score:${NC} 8/12 tasks (67%)"
echo -e "${YELLOW}Format:${NC} Complete tasks, validation after each"
echo ""
echo -e "${CYAN}Instructions:${NC}"
echo "• Read each task carefully"
echo "• Complete the task using kubectl"
echo "• Press ENTER when done to validate"
echo "• Solution shown after each task"
echo ""
read -p "Press ENTER to start the exam..."

check_prerequisites

# Create exam namespace
print_header "Setting Up Exam Environment"
kubectl create namespace exam-intermediate --dry-run=client -o yaml | kubectl apply -f - &>/dev/null
kubectl config set-context --current --namespace=exam-intermediate &>/dev/null
print_success "Namespace 'exam-intermediate' created and set"
sleep 1

# Start timer and chronometer
clear
start_timer
echo ""
echo ""
echo -e "${GREEN}Timer started! Good luck!${NC}"
sleep 2

#═══════════════════════════════════════════════════════════════
# TASK 1
#═══════════════════════════════════════════════════════════════
clear
print_task "1" "Create a pod with multiple containers (sidecar pattern)

Requirements:
  • Pod name: multi-container
  • Container 1: nginx (image: nginx)
  • Container 2: logger (image: busybox, command: sleep 3600)"

echo -e "${YELLOW}Complete this task, then press ENTER to validate...${NC}"
read -p ""

validate_and_score \
    "kubectl get pod multi-container -n exam-intermediate && [ \$(kubectl get pod multi-container -n exam-intermediate -o jsonpath='{.spec.containers[*].name}' | wc -w) -eq 2 ]" \
    "kubectl run multi-container --image=nginx --dry-run=client -o yaml > multi.yaml
# Edit to add second container:
# spec:
#   containers:
#   - name: nginx
#     image: nginx
#   - name: logger
#     image: busybox
#     command: ['sleep', '3600']
kubectl apply -f multi.yaml"

#═══════════════════════════════════════════════════════════════
# TASK 2
#═══════════════════════════════════════════════════════════════
clear
print_task "2" "Create a Secret and use it in a pod

Requirements:
  • Secret name: db-secret
  • Key: password, Value: mysecretpass
  • Pod name: secret-pod (image: nginx)
  • Mount secret as environment variable DB_PASSWORD"

echo -e "${YELLOW}Complete this task, then press ENTER to validate...${NC}"
read -p ""

validate_and_score \
    "kubectl get secret db-secret -n exam-intermediate && kubectl get pod secret-pod -n exam-intermediate" \
    "kubectl create secret generic db-secret --from-literal=password=mysecretpass

kubectl run secret-pod --image=nginx --dry-run=client -o yaml > secret-pod.yaml
# Edit to add env:
#   env:
#   - name: DB_PASSWORD
#     valueFrom:
#       secretKeyRef:
#         name: db-secret
#         key: password
kubectl apply -f secret-pod.yaml"

#═══════════════════════════════════════════════════════════════
# TASK 3
#═══════════════════════════════════════════════════════════════
clear
print_task "3" "Create a PersistentVolume and PersistentVolumeClaim

Requirements:
  • PV name: exam-pv
  • Storage: 1Gi
  • Access mode: ReadWriteOnce
  • hostPath: /mnt/data
  • PVC name: exam-pvc
  • Request: 500Mi"

echo -e "${YELLOW}Complete this task, then press ENTER to validate...${NC}"
read -p ""

validate_and_score \
    "kubectl get pv exam-pv && kubectl get pvc exam-pvc -n exam-intermediate" \
    "cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: PersistentVolume
metadata:
  name: exam-pv
spec:
  capacity:
    storage: 1Gi
  accessModes:
  - ReadWriteOnce
  hostPath:
    path: /mnt/data
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: exam-pvc
spec:
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 500Mi
EOF"

#═══════════════════════════════════════════════════════════════
# TASK 4
#═══════════════════════════════════════════════════════════════
clear
print_task "4" "Create a NetworkPolicy to restrict access

Requirements:
  • Create pod: backend (label: app=backend, image: nginx)
  • Create pod: frontend (label: app=frontend, image: nginx)
  • NetworkPolicy name: backend-policy
  • Allow ONLY frontend to access backend on port 80"

echo -e "${YELLOW}Complete this task, then press ENTER to validate...${NC}"
read -p ""

validate_and_score \
    "kubectl get networkpolicy backend-policy -n exam-intermediate" \
    "kubectl run backend --image=nginx --labels=app=backend
kubectl run frontend --image=nginx --labels=app=frontend

cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: backend-policy
spec:
  podSelector:
    matchLabels:
      app: backend
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: frontend
    ports:
    - protocol: TCP
      port: 80
EOF"

#═══════════════════════════════════════════════════════════════
# TASK 5
#═══════════════════════════════════════════════════════════════
clear
print_task "5" "Create a ServiceAccount and use it in a pod

Requirements:
  • ServiceAccount name: app-sa
  • Pod name: sa-pod (image: nginx)
  • Use the app-sa ServiceAccount"

echo -e "${YELLOW}Complete this task, then press ENTER to validate...${NC}"
read -p ""

validate_and_score \
    "kubectl get serviceaccount app-sa -n exam-intermediate && kubectl get pod sa-pod -n exam-intermediate" \
    "kubectl create serviceaccount app-sa

kubectl run sa-pod --image=nginx --serviceaccount=app-sa
# Or edit YAML:
# spec:
#   serviceAccountName: app-sa"

#═══════════════════════════════════════════════════════════════
# TASK 6
#═══════════════════════════════════════════════════════════════
clear
print_task "6" "Create a Job that runs to completion

Requirements:
  • Job name: batch-job
  • Image: busybox
  • Command: echo 'Hello from job'
  • Completions: 3"

echo -e "${YELLOW}Complete this task, then press ENTER to validate...${NC}"
read -p ""

validate_and_score \
    "kubectl get job batch-job -n exam-intermediate" \
    "kubectl create job batch-job --image=busybox --dry-run=client -o yaml -- echo 'Hello from job' > job.yaml
# Edit to add completions: 3
# spec:
#   completions: 3
kubectl apply -f job.yaml"

#═══════════════════════════════════════════════════════════════
# TASK 7
#═══════════════════════════════════════════════════════════════
clear
print_task "7" "Create a CronJob

Requirements:
  • CronJob name: hourly-job
  • Schedule: Every hour (0 * * * *)
  • Image: busybox
  • Command: date"

echo -e "${YELLOW}Complete this task, then press ENTER to validate...${NC}"
read -p ""

validate_and_score \
    "kubectl get cronjob hourly-job -n exam-intermediate" \
    "kubectl create cronjob hourly-job --image=busybox --schedule='0 * * * *' -- date"

#═══════════════════════════════════════════════════════════════
# TASK 8
#═══════════════════════════════════════════════════════════════
clear
print_task "8" "Create a ResourceQuota

Requirements:
  • ResourceQuota name: compute-quota
  • Max pods: 10
  • Max CPU requests: 4 cores
  • Max memory requests: 8Gi"

echo -e "${YELLOW}Complete this task, then press ENTER to validate...${NC}"
read -p ""

validate_and_score \
    "kubectl get resourcequota compute-quota -n exam-intermediate" \
    "cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ResourceQuota
metadata:
  name: compute-quota
spec:
  hard:
    pods: '10'
    requests.cpu: '4'
    requests.memory: 8Gi
EOF"

#═══════════════════════════════════════════════════════════════
# TASK 9
#═══════════════════════════════════════════════════════════════
clear
print_task "9" "Create a DaemonSet

Requirements:
  • DaemonSet name: log-collector
  • Image: fluentd
  • Should run on all nodes"

echo -e "${YELLOW}Complete this task, then press ENTER to validate...${NC}"
read -p ""

validate_and_score \
    "kubectl get daemonset log-collector -n exam-intermediate" \
    "kubectl create deployment log-collector --image=fluentd --dry-run=client -o yaml > ds.yaml
# Change kind to DaemonSet and remove replicas
# kind: DaemonSet
# Remove: replicas, strategy
kubectl apply -f ds.yaml"

#═══════════════════════════════════════════════════════════════
# TASK 10
#═══════════════════════════════════════════════════════════════
clear
print_task "10" "Create a pod with init container

Requirements:
  • Pod name: init-demo
  • Init container: wait-service (image: busybox, command: sleep 10)
  • Main container: app (image: nginx)"

echo -e "${YELLOW}Complete this task, then press ENTER to validate...${NC}"
read -p ""

validate_and_score \
    "kubectl get pod init-demo -n exam-intermediate" \
    "cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: init-demo
spec:
  initContainers:
  - name: wait-service
    image: busybox
    command: ['sleep', '10']
  containers:
  - name: app
    image: nginx
EOF"

#═══════════════════════════════════════════════════════════════
# TASK 11
#═══════════════════════════════════════════════════════════════
clear
print_task "11" "Create a StatefulSet

Requirements:
  • StatefulSet name: web
  • Replicas: 3
  • Image: nginx
  • Service name: nginx (headless service)"

echo -e "${YELLOW}Complete this task, then press ENTER to validate...${NC}"
read -p ""

validate_and_score \
    "kubectl get statefulset web -n exam-intermediate && kubectl get service nginx -n exam-intermediate" \
    "kubectl create service clusterip nginx --tcp=80:80 --clusterip=None

cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: web
spec:
  serviceName: nginx
  replicas: 3
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx
        ports:
        - containerPort: 80
EOF"

#═══════════════════════════════════════════════════════════════
# TASK 12
#═══════════════════════════════════════════════════════════════
clear
print_task "12" "Create a HorizontalPodAutoscaler

Requirements:
  • Target deployment: web-app (create if not exists)
  • Min replicas: 2
  • Max replicas: 10
  • CPU target: 50%"

echo -e "${YELLOW}Complete this task, then press ENTER to validate...${NC}"
read -p ""

validate_and_score \
    "kubectl get hpa -n exam-intermediate" \
    "# Ensure deployment exists with resource requests
kubectl create deployment web-app --image=nginx --replicas=2 2>/dev/null || true
kubectl set resources deployment web-app --requests=cpu=100m

kubectl autoscale deployment web-app --min=2 --max=10 --cpu-percent=50"

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

if [ $PERCENTAGE -ge 67 ]; then
    echo -e "${GREEN}╔══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║                      PASSED! ✓                           ║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${GREEN}Congratulations! You passed the intermediate exam!${NC}"
else
    echo -e "${YELLOW}╔══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}║                   NEEDS IMPROVEMENT                      ║${NC}"
    echo -e "${YELLOW}╚══════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${YELLOW}Keep practicing! You need 8/12 to pass.${NC}"
fi

echo ""
echo -e "${BLUE}Grade: $PERCENTAGE%${NC}"
echo ""

if [ $PERCENTAGE -ge 90 ]; then
    echo -e "${GREEN}🌟 Outstanding! Ready for advanced level!${NC}"
elif [ $PERCENTAGE -ge 80 ]; then
    echo -e "${GREEN}Great job! Consider trying advanced level.${NC}"
elif [ $PERCENTAGE -ge 67 ]; then
    echo -e "${YELLOW}Good! Practice more then try advanced.${NC}"
else
    echo -e "${RED}Review the documentation and try again.${NC}"
fi

echo ""
read -p "Would you like to clean up exam resources? (y/n): " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
    cleanup
else
    echo -e "${YELLOW}Resources left in namespace 'exam-intermediate'${NC}"
    echo -e "Clean up later with: kubectl delete namespace exam-intermediate"
fi

echo ""
echo -e "${GREEN}Keep practicing! 🚀${NC}"
echo ""
