#!/bin/bash

# Kubernetes CKA Study Guide - Advanced Practice Exam
# 16 tasks, 120 minutes - Full CKA simulation

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_header() {
    echo -e "\n${BLUE}=====================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}=====================================${NC}\n"
}

print_task() {
    echo -e "${YELLOW}Task $1: $2${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_header "Advanced Practice Exam - Full CKA Simulation"
echo "Tasks: 16"
echo "Time Limit: 120 minutes"
echo "Passing Score: 11/16 (66%)"
echo ""
echo "This exam simulates the actual CKA certification exam."
echo ""
read -p "Press Enter to start..."

kubectl create namespace exam-advanced --dry-run=client -o yaml | kubectl apply -f -
kubectl config set-context --current --namespace=exam-advanced
print_success "Environment ready"

START_TIME=$(date +%s)

print_header "Exam Started - Good Luck!"
echo "Work through tasks at your own pace."
echo "Press Enter after completing each task."
echo ""

# Task 1: HPA
print_task "1" "Create deployment 'web' (nginx), then HPA min=1 max=4, CPU target=50%"
echo "Hint: kubectl create deployment, then kubectl autoscale"
read -p "Press Enter when done..."

# Task 2: Ingress
print_task "2" "Create ingress 'web-ingress' routing example.org to service 'web-svc' port 80"
echo "Hint: kubectl create ingress --rule"
read -p "Press Enter when done..."

# Task 3: Resource Fix
print_task "3" "Fix deployment 'broken-app' that's OOMKilled - increase memory to 256Mi"
cat << 'EOF'
# First create the broken app:
kubectl create deployment broken-app --image=nginx --replicas=3
kubectl set resources deployment broken-app --requests=memory=32Mi --limits=memory=64Mi

# Now fix it:
kubectl set resources deployment broken-app --requests=memory=128Mi --limits=memory=256Mi
EOF
read -p "Press Enter when done..."

# Task 4: Sidecar
print_task "4" "Create pod 'sidecar-pod' with nginx + busybox sharing emptyDir volume at /data"
echo "Hint: Multi-container pod with volumes and volumeMounts"
read -p "Press Enter when done..."

# Task 5: StorageClass
print_task "5" "Create StorageClass 'fast' with WaitForFirstConsumer binding mode"
cat << 'EOF'
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: fast
provisioner: k8s.io/minikube-hostpath
volumeBindingMode: WaitForFirstConsumer
EOF
read -p "Press Enter when done..."

# Task 6: Service Type
print_task "6" "Change service 'web-svc' from ClusterIP to NodePort"
echo "Hint: kubectl patch or kubectl edit"
read -p "Press Enter when done..."

# Task 7: PriorityClass
print_task "7" "Create PriorityClass 'high-priority' with value 1000"
cat << 'EOF'
apiVersion: scheduling.k8s.io/v1
kind: PriorityClass
metadata:
  name: high-priority
value: 1000
globalDefault: false
EOF
read -p "Press Enter when done..."

# Task 8: PVC
print_task "8" "Create PVC 'data-pvc' requesting 2Gi using StorageClass 'fast'"
cat << 'EOF'
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
      storage: 2Gi
EOF
read -p "Press Enter when done..."

# Task 9: NetworkPolicy
print_task "9" "Create NetworkPolicy allowing only 'frontend' pods to access 'backend' pods on port 80"
cat << 'EOF'
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
EOF
read -p "Press Enter when done..."

# Task 10: ResourceQuota
print_task "10" "Create ResourceQuota 'compute-quota' limiting pods=10, cpu=4, memory=8Gi"
cat << 'EOF'
apiVersion: v1
kind: ResourceQuota
metadata:
  name: compute-quota
spec:
  hard:
    pods: "10"
    requests.cpu: "4"
    requests.memory: "8Gi"
EOF
read -p "Press Enter when done..."

# Task 11: ConfigMap
print_task "11" "Create immutable ConfigMap 'app-config' with data: version=1.0"
cat << 'EOF'
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
data:
  version: "1.0"
immutable: true
EOF
read -p "Press Enter when done..."

# Task 12: Secret
print_task "12" "Create TLS secret 'tls-secret' from cert.crt and cert.key files"
echo "Hint: kubectl create secret tls tls-secret --cert=cert.crt --key=cert.key"
echo "(Create dummy files for practice)"
read -p "Press Enter when done..."

# Task 13: ServiceAccount
print_task "13" "Create ServiceAccount 'app-sa' and use it in deployment 'web'"
cat << 'EOF'
kubectl create serviceaccount app-sa
kubectl set serviceaccount deployment web app-sa
EOF
read -p "Press Enter when done..."

# Task 14: Labels
print_task "14" "Label all pods with app=web to also have tier=frontend"
echo "Hint: kubectl label pods -l app=web tier=frontend"
read -p "Press Enter when done..."

# Task 15: Troubleshooting
print_task "15" "Find pods in CrashLoopBackOff state and describe them"
echo "Hint: kubectl get pods --field-selector=status.phase=Failed"
echo "      kubectl describe pod <pod-name>"
read -p "Press Enter when done..."

# Task 16: Backup
print_task "16" "Export all resources in namespace to backup.yaml"
echo "Hint: kubectl get all -o yaml > backup.yaml"
read -p "Press Enter when done..."

END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))
MINUTES=$((DURATION / 60))
SECONDS=$((DURATION % 60))

print_header "Verification"
SCORE=0

# Verify each task
echo "Checking your solutions..."
echo ""

# Task 1
echo -n "Task 1 (HPA): "
if kubectl get hpa &> /dev/null; then
    print_success "Pass"
    ((SCORE++))
else
    echo -e "${RED}Fail${NC}"
fi

# Task 2
echo -n "Task 2 (Ingress): "
if kubectl get ingress web-ingress &> /dev/null; then
    print_success "Pass"
    ((SCORE++))
else
    echo -e "${RED}Fail${NC}"
fi

# Task 3
echo -n "Task 3 (Resource Fix): "
if kubectl get deployment broken-app &> /dev/null; then
    MEM=$(kubectl get deployment broken-app -o jsonpath='{.spec.template.spec.containers[0].resources.limits.memory}')
    if [ "$MEM" == "256Mi" ]; then
        print_success "Pass"
        ((SCORE++))
    else
        echo -e "${RED}Fail${NC}"
    fi
else
    echo -e "${RED}Fail${NC}"
fi

# Task 4
echo -n "Task 4 (Sidecar): "
if kubectl get pod sidecar-pod &> /dev/null; then
    CONTAINERS=$(kubectl get pod sidecar-pod -o jsonpath='{.spec.containers[*].name}' | wc -w)
    if [ "$CONTAINERS" -ge 2 ]; then
        print_success "Pass"
        ((SCORE++))
    else
        echo -e "${RED}Fail${NC}"
    fi
else
    echo -e "${RED}Fail${NC}"
fi

# Task 5
echo -n "Task 5 (StorageClass): "
if kubectl get sc fast &> /dev/null; then
    print_success "Pass"
    ((SCORE++))
else
    echo -e "${RED}Fail${NC}"
fi

# Task 6
echo -n "Task 6 (NodePort): "
if kubectl get svc web-svc -o jsonpath='{.spec.type}' 2>/dev/null | grep -q NodePort; then
    print_success "Pass"
    ((SCORE++))
else
    echo -e "${RED}Fail${NC}"
fi

# Task 7
echo -n "Task 7 (PriorityClass): "
if kubectl get priorityclass high-priority &> /dev/null; then
    print_success "Pass"
    ((SCORE++))
else
    echo -e "${RED}Fail${NC}"
fi

# Task 8
echo -n "Task 8 (PVC): "
if kubectl get pvc data-pvc &> /dev/null; then
    print_success "Pass"
    ((SCORE++))
else
    echo -e "${RED}Fail${NC}"
fi

# Task 9
echo -n "Task 9 (NetworkPolicy): "
if kubectl get networkpolicy backend-policy &> /dev/null; then
    print_success "Pass"
    ((SCORE++))
else
    echo -e "${RED}Fail${NC}"
fi

# Task 10
echo -n "Task 10 (ResourceQuota): "
if kubectl get resourcequota compute-quota &> /dev/null; then
    print_success "Pass"
    ((SCORE++))
else
    echo -e "${RED}Fail${NC}"
fi

# Task 11
echo -n "Task 11 (ConfigMap): "
if kubectl get configmap app-config &> /dev/null; then
    print_success "Pass"
    ((SCORE++))
else
    echo -e "${RED}Fail${NC}"
fi

# Task 12
echo -n "Task 12 (Secret): "
if kubectl get secret tls-secret &> /dev/null; then
    print_success "Pass"
    ((SCORE++))
else
    echo -e "${RED}Fail${NC}"
fi

# Task 13
echo -n "Task 13 (ServiceAccount): "
if kubectl get sa app-sa &> /dev/null; then
    print_success "Pass"
    ((SCORE++))
else
    echo -e "${RED}Fail${NC}"
fi

# Task 14
echo -n "Task 14 (Labels): "
LABELED=$(kubectl get pods -l app=web,tier=frontend --no-headers 2>/dev/null | wc -l)
if [ "$LABELED" -gt 0 ]; then
    print_success "Pass"
    ((SCORE++))
else
    echo -e "${RED}Fail${NC}"
fi

# Task 15
echo -n "Task 15 (Troubleshooting): "
print_success "Manual check - did you identify and describe pods?"
echo "(Award yourself 1 point if yes)"

# Task 16
echo -n "Task 16 (Backup): "
if [ -f backup.yaml ]; then
    print_success "Pass"
    ((SCORE++))
else
    echo -e "${RED}Fail (backup.yaml not found)${NC}"
fi

print_header "Final Results"
echo "Score: $SCORE/16 ($(($SCORE * 100 / 16))%)"
echo "Time: ${MINUTES}m ${SECONDS}s / 120m"
echo ""

if [ $SCORE -ge 11 ]; then
    print_success "PASSED! You would pass the CKA exam!"
    echo ""
    echo "Congratulations! You demonstrated strong Kubernetes skills."
else
    echo -e "${YELLOW}Not quite there yet. Keep practicing!${NC}"
    echo ""
    echo "Recommended: Review the topics where you struggled"
fi

echo ""
echo "Time management: "
if [ $MINUTES -le 120 ]; then
    print_success "Finished within time limit"
else
    echo -e "${YELLOW}Over time - practice speed${NC}"
fi

read -p "Clean up exam resources? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    kubectl delete namespace exam-advanced
    rm -f backup.yaml
    print_success "Cleanup complete"
fi

print_header "Next Steps"
echo "1. Review topics where you scored low"
echo "2. Study the documentation for those topics"
echo "3. Practice with kubectl commands"
echo "4. Take the exam again in a few days"
echo ""
print_success "Keep practicing! You've got this!"
