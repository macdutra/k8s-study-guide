#!/bin/bash

# Kubernetes CKA Study Guide - Beginner Practice Exam
# 8 tasks, 60 minutes

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Print functions
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

# Main exam
print_header "Beginner Practice Exam - 8 Tasks"
echo "Time Limit: 60 minutes"
echo "Passing Score: 5/8 tasks (63%)"
echo ""
read -p "Press Enter to start the exam..."

check_prerequisites

# Create exam namespace
print_header "Setting Up Exam Environment"
kubectl create namespace exam-beginner --dry-run=client -o yaml | kubectl apply -f -
kubectl config set-context --current --namespace=exam-beginner
print_success "Namespace created and set"

# Start timer
START_TIME=$(date +%s)

print_header "Exam Tasks"
echo "Complete the following 8 tasks. Solutions are at the end."
echo ""

# Task 1
print_task "1" "Create a pod named 'nginx-pod' with image nginx:alpine"
echo "Command: kubectl run nginx-pod --image=nginx:alpine"
echo ""
read -p "Press Enter when complete..."

# Task 2
print_task "2" "Create a deployment named 'web-app' with 3 replicas using nginx:alpine"
echo "Command: kubectl create deployment web-app --image=nginx:alpine --replicas=3"
echo ""
read -p "Press Enter when complete..."

# Task 3
print_task "3" "Expose deployment 'web-app' as a service on port 80"
echo "Command: kubectl expose deployment web-app --port=80 --name=web-service"
echo ""
read -p "Press Enter when complete..."

# Task 4
print_task "4" "Scale deployment 'web-app' to 5 replicas"
echo "Command: kubectl scale deployment web-app --replicas=5"
echo ""
read -p "Press Enter when complete..."

# Task 5
print_task "5" "Create a ConfigMap named 'app-config' with key=value data: environment=development"
echo "Command: kubectl create configmap app-config --from-literal=environment=development"
echo ""
read -p "Press Enter when complete..."

# Task 6
print_task "6" "Create a pod named 'busybox-test' with image busybox that runs 'sleep 3600'"
echo "Command: kubectl run busybox-test --image=busybox -- sleep 3600"
echo ""
read -p "Press Enter when complete..."

# Task 7
print_task "7" "Set resource requests for deployment 'web-app': cpu=100m, memory=128Mi"
echo "Command: kubectl set resources deployment web-app --requests=cpu=100m,memory=128Mi"
echo ""
read -p "Press Enter when complete..."

# Task 8
print_task "8" "Create a namespace named 'production'"
echo "Command: kubectl create namespace production"
echo ""
read -p "Press Enter when complete..."

# End timer
END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))
MINUTES=$((DURATION / 60))
SECONDS=$((DURATION % 60))

print_header "Exam Complete!"
echo "Time taken: ${MINUTES}m ${SECONDS}s"
echo ""

# Verification
print_header "Verifying Your Work"
echo "Checking your solutions..."
echo ""

SCORE=0

# Check Task 1
echo -n "Task 1: "
if kubectl get pod nginx-pod &> /dev/null; then
    print_success "nginx-pod exists"
    ((SCORE++))
else
    echo -e "${RED}✗ nginx-pod not found${NC}"
fi

# Check Task 2
echo -n "Task 2: "
if kubectl get deployment web-app &> /dev/null; then
    print_success "web-app deployment exists"
    ((SCORE++))
else
    echo -e "${RED}✗ web-app deployment not found${NC}"
fi

# Check Task 3
echo -n "Task 3: "
if kubectl get service web-service &> /dev/null; then
    print_success "web-service exists"
    ((SCORE++))
else
    echo -e "${RED}✗ web-service not found${NC}"
fi

# Check Task 4
echo -n "Task 4: "
REPLICAS=$(kubectl get deployment web-app -o jsonpath='{.spec.replicas}')
if [ "$REPLICAS" == "5" ]; then
    print_success "web-app scaled to 5 replicas"
    ((SCORE++))
else
    echo -e "${RED}✗ web-app has $REPLICAS replicas (expected 5)${NC}"
fi

# Check Task 5
echo -n "Task 5: "
if kubectl get configmap app-config &> /dev/null; then
    print_success "app-config ConfigMap exists"
    ((SCORE++))
else
    echo -e "${RED}✗ app-config ConfigMap not found${NC}"
fi

# Check Task 6
echo -n "Task 6: "
if kubectl get pod busybox-test &> /dev/null; then
    print_success "busybox-test pod exists"
    ((SCORE++))
else
    echo -e "${RED}✗ busybox-test pod not found${NC}"
fi

# Check Task 7
echo -n "Task 7: "
CPU_REQ=$(kubectl get deployment web-app -o jsonpath='{.spec.template.spec.containers[0].resources.requests.cpu}')
if [ "$CPU_REQ" == "100m" ]; then
    print_success "Resource requests set correctly"
    ((SCORE++))
else
    echo -e "${RED}✗ Resource requests not set correctly${NC}"
fi

# Check Task 8
echo -n "Task 8: "
if kubectl get namespace production &> /dev/null; then
    print_success "production namespace exists"
    ((SCORE++))
else
    echo -e "${RED}✗ production namespace not found${NC}"
fi

# Final score
print_header "Final Score"
echo "Score: $SCORE/8 ($(($SCORE * 100 / 8))%)"
echo ""

if [ $SCORE -ge 5 ]; then
    print_success "PASSED! (Passing score: 5/8)"
else
    echo -e "${RED}Not passed. Passing score is 5/8.${NC}"
fi

echo ""
echo "Time taken: ${MINUTES}m ${SECONDS}s"
echo "Target time: 60 minutes"
echo ""

# Cleanup option
read -p "Do you want to clean up the exam resources? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    print_info "Cleaning up..."
    kubectl delete namespace exam-beginner
    kubectl delete namespace production 2>/dev/null || true
    print_success "Cleanup complete"
fi

print_header "Solutions Reference"
cat << 'EOF'
Task 1: kubectl run nginx-pod --image=nginx:alpine
Task 2: kubectl create deployment web-app --image=nginx:alpine --replicas=3
Task 3: kubectl expose deployment web-app --port=80 --name=web-service
Task 4: kubectl scale deployment web-app --replicas=5
Task 5: kubectl create configmap app-config --from-literal=environment=development
Task 6: kubectl run busybox-test --image=busybox -- sleep 3600
Task 7: kubectl set resources deployment web-app --requests=cpu=100m,memory=128Mi
Task 8: kubectl create namespace production

For detailed explanations, see the documentation in docs/
EOF

echo ""
print_success "Exam complete! Good luck with your studies!"
