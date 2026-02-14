#!/bin/bash

# Kubernetes CKA Study Guide - Beginner Practice Exam
# 8 tasks, 60 minutes
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
TOTAL=8

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
    kubectl delete namespace exam-beginner --ignore-not-found=true
    kubectl config set-context --current --namespace=default
    print_success "Cleanup complete"
}

# Main exam
clear
print_header "CKA BEGINNER PRACTICE EXAM"
echo -e "${YELLOW}Time Limit:${NC} 60 minutes"
echo -e "${YELLOW}Passing Score:${NC} 5/8 tasks (63%)"
echo -e "${YELLOW}Format:${NC} Complete tasks, validation after each"
echo ""
echo -e "${CYAN}Instructions:${NC}"
echo "• Read each task carefully"
echo "• Complete the task using kubectl"
echo "• Press ENTER when done to validate"
echo "• Solutions shown only if you want them"
echo ""
read -p "Press ENTER to start the exam..."

check_prerequisites

# Create exam namespace
print_header "Setting Up Exam Environment"
kubectl create namespace exam-beginner --dry-run=client -o yaml | kubectl apply -f - &>/dev/null
kubectl config set-context --current --namespace=exam-beginner &>/dev/null
print_success "Namespace 'exam-beginner' created and set"
sleep 1

# Start timer
START_TIME=$(date +%s)

#═══════════════════════════════════════════════════════════════
# TASK 1
#═══════════════════════════════════════════════════════════════
clear
print_task "1" "Create a pod named 'nginx-pod' using the image 'nginx:alpine'

Requirements:
  • Pod name: nginx-pod
  • Image: nginx:alpine
  • Namespace: exam-beginner (already set)"

echo -e "${YELLOW}Complete this task, then press ENTER to validate...${NC}"
read -p ""

validate_and_score \
    "kubectl get pod nginx-pod -n exam-beginner" \
    "kubectl run nginx-pod --image=nginx:alpine"

#═══════════════════════════════════════════════════════════════
# TASK 2
#═══════════════════════════════════════════════════════════════
clear
print_task "2" "Create a deployment named 'web-app' with 3 replicas

Requirements:
  • Deployment name: web-app
  • Image: nginx:alpine
  • Replicas: 3"

echo -e "${YELLOW}Complete this task, then press ENTER to validate...${NC}"
read -p ""

validate_and_score \
    "kubectl get deployment web-app -n exam-beginner && [ \$(kubectl get deployment web-app -n exam-beginner -o jsonpath='{.spec.replicas}') -eq 3 ]" \
    "kubectl create deployment web-app --image=nginx:alpine --replicas=3"

#═══════════════════════════════════════════════════════════════
# TASK 3
#═══════════════════════════════════════════════════════════════
clear
print_task "3" "Expose the 'web-app' deployment as a service

Requirements:
  • Service name: web-service
  • Port: 80
  • Target: web-app deployment"

echo -e "${YELLOW}Complete this task, then press ENTER to validate...${NC}"
read -p ""

validate_and_score \
    "kubectl get service web-service -n exam-beginner && [ \$(kubectl get service web-service -n exam-beginner -o jsonpath='{.spec.ports[0].port}') -eq 80 ]" \
    "kubectl expose deployment web-app --port=80 --name=web-service"

#═══════════════════════════════════════════════════════════════
# TASK 4
#═══════════════════════════════════════════════════════════════
clear
print_task "4" "Scale the 'web-app' deployment to 5 replicas

Requirements:
  • Deployment: web-app
  • New replica count: 5"

echo -e "${YELLOW}Complete this task, then press ENTER to validate...${NC}"
read -p ""

validate_and_score \
    "[ \$(kubectl get deployment web-app -n exam-beginner -o jsonpath='{.spec.replicas}') -eq 5 ]" \
    "kubectl scale deployment web-app --replicas=5"

#═══════════════════════════════════════════════════════════════
# TASK 5
#═══════════════════════════════════════════════════════════════
clear
print_task "5" "Create a ConfigMap with application configuration

Requirements:
  • ConfigMap name: app-config
  • Key: environment
  • Value: development"

echo -e "${YELLOW}Complete this task, then press ENTER to validate...${NC}"
read -p ""

validate_and_score \
    "kubectl get configmap app-config -n exam-beginner && [ \"\$(kubectl get configmap app-config -n exam-beginner -o jsonpath='{.data.environment}')\" = \"development\" ]" \
    "kubectl create configmap app-config --from-literal=environment=development"

#═══════════════════════════════════════════════════════════════
# TASK 6
#═══════════════════════════════════════════════════════════════
clear
print_task "6" "Create a pod that runs a long-running process

Requirements:
  • Pod name: busybox-test
  • Image: busybox
  • Command: sleep 3600"

echo -e "${YELLOW}Complete this task, then press ENTER to validate...${NC}"
read -p ""

validate_and_score \
    "kubectl get pod busybox-test -n exam-beginner" \
    "kubectl run busybox-test --image=busybox -- sleep 3600"

#═══════════════════════════════════════════════════════════════
# TASK 7
#═══════════════════════════════════════════════════════════════
clear
print_task "7" "Set resource requests for the 'web-app' deployment

Requirements:
  • Deployment: web-app
  • CPU request: 100m
  • Memory request: 128Mi"

echo -e "${YELLOW}Complete this task, then press ENTER to validate...${NC}"
read -p ""

validate_and_score \
    "kubectl get deployment web-app -n exam-beginner -o yaml | grep -q 'cpu: 100m' && kubectl get deployment web-app -n exam-beginner -o yaml | grep -q 'memory: 128Mi'" \
    "kubectl set resources deployment web-app --requests=cpu=100m,memory=128Mi"

#═══════════════════════════════════════════════════════════════
# TASK 8
#═══════════════════════════════════════════════════════════════
clear
print_task "8" "Create a new namespace

Requirements:
  • Namespace name: production"

echo -e "${YELLOW}Complete this task, then press ENTER to validate...${NC}"
read -p ""

validate_and_score \
    "kubectl get namespace production" \
    "kubectl create namespace production"

#═══════════════════════════════════════════════════════════════
# FINAL SCORE
#═══════════════════════════════════════════════════════════════

END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))
MINUTES=$((DURATION / 60))
SECONDS=$((DURATION % 60))

clear
print_header "EXAM COMPLETE!"

echo -e "${CYAN}Final Score: $SCORE / $TOTAL${NC}"
echo -e "${CYAN}Time Taken: ${MINUTES}m ${SECONDS}s${NC}"
echo ""

PERCENTAGE=$((SCORE * 100 / TOTAL))

if [ $PERCENTAGE -ge 63 ]; then
    echo -e "${GREEN}╔══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║                      PASSED! ✓                           ║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${GREEN}Congratulations! You passed the beginner exam!${NC}"
else
    echo -e "${YELLOW}╔══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}║                   NEEDS IMPROVEMENT                      ║${NC}"
    echo -e "${YELLOW}╚══════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${YELLOW}Keep practicing! You need 5/8 to pass.${NC}"
fi

echo ""
echo -e "${BLUE}Grade: $PERCENTAGE%${NC}"
echo ""

if [ $PERCENTAGE -ge 90 ]; then
    echo -e "${GREEN}🌟 Outstanding! Ready for intermediate level!${NC}"
elif [ $PERCENTAGE -ge 75 ]; then
    echo -e "${GREEN}Great job! Consider trying intermediate level.${NC}"
elif [ $PERCENTAGE -ge 63 ]; then
    echo -e "${YELLOW}Good! Practice more then try again.${NC}"
else
    echo -e "${RED}Review the documentation and try again.${NC}"
fi

echo ""
read -p "Would you like to clean up exam resources? (y/n): " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
    cleanup
else
    echo -e "${YELLOW}Resources left in namespace 'exam-beginner'${NC}"
    echo -e "Clean up later with: kubectl delete namespace exam-beginner"
fi

echo ""
echo -e "${GREEN}Keep practicing! 🚀${NC}"
echo ""
