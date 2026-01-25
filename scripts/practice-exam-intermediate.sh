#!/bin/bash

# Kubernetes CKA Study Guide - Intermediate Practice Exam
# 12 tasks, 90 minutes

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

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

# Main exam
print_header "Intermediate Practice Exam - 12 Tasks"
echo "Time Limit: 90 minutes"
echo "Passing Score: 8/12 tasks (67%)"
echo ""
read -p "Press Enter to start the exam..."

# Create exam namespace
kubectl create namespace exam-intermediate --dry-run=client -o yaml | kubectl apply -f -
kubectl config set-context --current --namespace=exam-intermediate
print_success "Namespace created"

START_TIME=$(date +%s)

print_header "Exam Tasks"

# Task 1
print_task "1" "Create a deployment 'nginx-deploy' with 3 replicas, image nginx:1.20"
cat << 'EOF'
kubectl create deployment nginx-deploy --image=nginx:1.20 --replicas=3
EOF
echo ""
read -p "Complete and press Enter..."

# Task 2
print_task "2" "Create a service 'nginx-svc' exposing the deployment as NodePort on port 80"
cat << 'EOF'
kubectl expose deployment nginx-deploy --name=nginx-svc --port=80 --type=NodePort
EOF
echo ""
read -p "Complete and press Enter..."

# Task 3
print_task "3" "Create a PVC named 'app-pvc' requesting 1Gi storage, accessMode ReadWriteOnce"
cat << 'EOF'
kubectl create -f - << YAML
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: app-pvc
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
YAML
EOF
echo ""
read -p "Complete and press Enter..."

# Task 4
print_task "4" "Set resource limits on nginx-deploy: cpu=500m, memory=256Mi"
cat << 'EOF'
kubectl set resources deployment nginx-deploy --limits=cpu=500m,memory=256Mi
EOF
echo ""
read -p "Complete and press Enter..."

# Task 5
print_task "5" "Create a ConfigMap 'app-config' from literal: app.properties='key=value'"
cat << 'EOF'
kubectl create configmap app-config --from-literal=app.properties='key=value'
EOF
echo ""
read -p "Complete and press Enter..."

# Task 6
print_task "6" "Create a pod 'multi-container' with nginx and busybox containers sharing an emptyDir volume"
cat << 'EOF'
kubectl apply -f - << YAML
apiVersion: v1
kind: Pod
metadata:
  name: multi-container
spec:
  volumes:
  - name: shared
    emptyDir: {}
  containers:
  - name: nginx
    image: nginx
    volumeMounts:
    - name: shared
      mountPath: /data
  - name: busybox
    image: busybox
    command: ['sh', '-c', 'sleep 3600']
    volumeMounts:
    - name: shared
      mountPath: /data
YAML
EOF
echo ""
read -p "Complete and press Enter..."

# Task 7
print_task "7" "Create an Ingress 'app-ingress' routing app.example.com to nginx-svc on port 80"
cat << 'EOF'
kubectl create ingress app-ingress --rule="app.example.com/=nginx-svc:80"
EOF
echo ""
read -p "Complete and press Enter..."

# Task 8
print_task "8" "Create a NetworkPolicy 'deny-all' that denies all ingress traffic"
cat << 'EOF'
kubectl apply -f - << YAML
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-all
spec:
  podSelector: {}
  policyTypes:
  - Ingress
YAML
EOF
echo ""
read -p "Complete and press Enter..."

# Task 9
print_task "9" "Create a Secret 'db-secret' with username=admin and password=secret123"
cat << 'EOF'
kubectl create secret generic db-secret --from-literal=username=admin --from-literal=password=secret123
EOF
echo ""
read -p "Complete and press Enter..."

# Task 10
print_task "10" "Update nginx-deploy to use the app-pvc, mounting at /data"
cat << 'EOF'
kubectl set volume deployment nginx-deploy --add --name=data --type=persistentVolumeClaim --claim-name=app-pvc --mount-path=/data
EOF
echo ""
read -p "Complete and press Enter..."

# Task 11
print_task "11" "Create a Job 'pi-job' that calculates pi using perl image"
cat << 'EOF'
kubectl create job pi-job --image=perl -- perl -Mbignum=bpi -wle 'print bpi(2000)'
EOF
echo ""
read -p "Complete and press Enter..."

# Task 12
print_task "12" "Create a CronJob 'hello-cron' that runs 'echo Hello' every minute"
cat << 'EOF'
kubectl create cronjob hello-cron --image=busybox --schedule="*/1 * * * *" -- echo Hello
EOF
echo ""
read -p "Complete and press Enter..."

# End timer
END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))
MINUTES=$((DURATION / 60))
SECONDS=$((DURATION % 60))

print_header "Verification"
SCORE=0

echo -n "Task 1: "
kubectl get deployment nginx-deploy &> /dev/null && { print_success "Pass"; ((SCORE++)); } || echo -e "${RED}Fail${NC}"

echo -n "Task 2: "
kubectl get service nginx-svc &> /dev/null && { print_success "Pass"; ((SCORE++)); } || echo -e "${RED}Fail${NC}"

echo -n "Task 3: "
kubectl get pvc app-pvc &> /dev/null && { print_success "Pass"; ((SCORE++)); } || echo -e "${RED}Fail${NC}"

echo -n "Task 4: "
LIMIT=$(kubectl get deployment nginx-deploy -o jsonpath='{.spec.template.spec.containers[0].resources.limits.cpu}')
[ "$LIMIT" == "500m" ] && { print_success "Pass"; ((SCORE++)); } || echo -e "${RED}Fail${NC}"

echo -n "Task 5: "
kubectl get configmap app-config &> /dev/null && { print_success "Pass"; ((SCORE++)); } || echo -e "${RED}Fail${NC}"

echo -n "Task 6: "
kubectl get pod multi-container &> /dev/null && { print_success "Pass"; ((SCORE++)); } || echo -e "${RED}Fail${NC}"

echo -n "Task 7: "
kubectl get ingress app-ingress &> /dev/null && { print_success "Pass"; ((SCORE++)); } || echo -e "${RED}Fail${NC}"

echo -n "Task 8: "
kubectl get networkpolicy deny-all &> /dev/null && { print_success "Pass"; ((SCORE++)); } || echo -e "${RED}Fail${NC}"

echo -n "Task 9: "
kubectl get secret db-secret &> /dev/null && { print_success "Pass"; ((SCORE++)); } || echo -e "${RED}Fail${NC}"

echo -n "Task 10: "
VOL=$(kubectl get deployment nginx-deploy -o jsonpath='{.spec.template.spec.volumes[0].persistentVolumeClaim.claimName}')
[ "$VOL" == "app-pvc" ] && { print_success "Pass"; ((SCORE++)); } || echo -e "${RED}Fail${NC}"

echo -n "Task 11: "
kubectl get job pi-job &> /dev/null && { print_success "Pass"; ((SCORE++)); } || echo -e "${RED}Fail${NC}"

echo -n "Task 12: "
kubectl get cronjob hello-cron &> /dev/null && { print_success "Pass"; ((SCORE++)); } || echo -e "${RED}Fail${NC}"

print_header "Final Score"
echo "Score: $SCORE/12 ($(($SCORE * 100 / 12))%)"
echo "Time: ${MINUTES}m ${SECONDS}s / 90m"
echo ""

if [ $SCORE -ge 8 ]; then
    print_success "PASSED!"
else
    echo -e "${RED}Not passed. Need 8/12.${NC}"
fi

read -p "Clean up resources? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    kubectl delete namespace exam-intermediate
    print_success "Cleanup complete"
fi
