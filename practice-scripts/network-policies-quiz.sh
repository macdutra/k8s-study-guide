#!/bin/bash

# Network Policies Interactive Practice Quiz
# Author: CKA Study Guide
# Description: Interactive practice questions with automatic validation

set -e

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Score tracking
SCORE=0
TOTAL=0

# Function to display question
show_question() {
    local question_num=$1
    local question_text=$2
    
    echo ""
    echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
    echo -e "${YELLOW}Question $question_num${NC}"
    echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "$question_text"
    echo ""
    echo -e "${YELLOW}Work on your solution, then press ENTER when ready to validate...${NC}"
}

# Function to validate and score
validate_answer() {
    local validation_cmd=$1
    local points=$2
    
    read -p ""
    
    echo ""
    echo -e "${BLUE}Validating your answer...${NC}"
    echo ""
    
    if eval "$validation_cmd"; then
        echo ""
        echo -e "${GREEN}✅ CORRECT! (+$points points)${NC}"
        SCORE=$((SCORE + points))
    else
        echo ""
        echo -e "${RED}❌ INCORRECT (0 points)${NC}"
    fi
    
    TOTAL=$((TOTAL + points))
    echo ""
    echo -e "${BLUE}Current Score: $SCORE/$TOTAL${NC}"
}

# Function to show solution
show_solution() {
    local solution=$1
    
    echo ""
    echo -e "${YELLOW}Press ENTER to see the solution...${NC}"
    read -p ""
    
    echo ""
    echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}SOLUTION:${NC}"
    echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "$solution"
    echo ""
}

# Function to cleanup
cleanup() {
    echo ""
    echo -e "${YELLOW}Cleaning up test resources...${NC}"
    kubectl delete networkpolicy --all 2>/dev/null || true
    kubectl delete pod frontend backend database 2>/dev/null || true
    kubectl delete svc frontend backend database 2>/dev/null || true
    kubectl delete namespace prod dev 2>/dev/null || true
    echo -e "${GREEN}Cleanup complete!${NC}"
}

# Main quiz
clear
echo -e "${BLUE}╔═══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║         NetworkPolicy Interactive Practice Quiz              ║${NC}"
echo -e "${BLUE}╔═══════════════════════════════════════════════════════════════╗${NC}"
echo ""
echo -e "This quiz will test your NetworkPolicy skills with real validation."
echo -e "You'll create resources, then the script will check your work."
echo ""
echo -e "${YELLOW}Prerequisites:${NC}"
echo -e "  ✓ Minikube running with Calico CNI"
echo -e "  ✓ kubectl configured"
echo ""
read -p "Press ENTER to start the quiz..."

# Cleanup before starting
cleanup

#═══════════════════════════════════════════════════════════════
# QUESTION 1
#═══════════════════════════════════════════════════════════════

show_question "1" "Create a NetworkPolicy named 'database-access' that:
  - Applies to pods with label: app=database
  - Allows ingress ONLY from pods with label: app=api
  - On port 5432 (TCP)
  
First, create the test environment:
  - Pod: database (image: postgres:alpine, label: app=database, env: POSTGRES_PASSWORD=secret)
  - Pod: api (image: nginx, label: app=api)
  - Pod: web (image: nginx, label: app=web)
  
Then create the NetworkPolicy named 'database-access'"

# Validation
validate_answer '
    # Check if NetworkPolicy exists
    if ! kubectl get networkpolicy database-access &>/dev/null; then
        echo "❌ NetworkPolicy database-access not found"
        exit 1
    fi
    
    # Check pod selector
    SELECTOR=$(kubectl get networkpolicy database-access -o jsonpath="{.spec.podSelector.matchLabels.app}")
    if [ "$SELECTOR" != "database" ]; then
        echo "❌ podSelector should be app=database, got: $SELECTOR"
        exit 1
    fi
    
    # Check ingress from selector
    FROM_SELECTOR=$(kubectl get networkpolicy database-access -o jsonpath="{.spec.ingress[0].from[0].podSelector.matchLabels.app}")
    if [ "$FROM_SELECTOR" != "api" ]; then
        echo "❌ Ingress from should be app=api, got: $FROM_SELECTOR"
        exit 1
    fi
    
    # Check port
    PORT=$(kubectl get networkpolicy database-access -o jsonpath="{.spec.ingress[0].ports[0].port}")
    if [ "$PORT" != "5432" ]; then
        echo "❌ Port should be 5432, got: $PORT"
        exit 1
    fi
    
    echo "✓ NetworkPolicy structure is correct"
    exit 0
' 10

show_solution 'kubectl run database --image=postgres:alpine --labels="app=database" --env="POSTGRES_PASSWORD=secret"
kubectl run api --image=nginx --labels="app=api"
kubectl run web --image=nginx --labels="app=web"

cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: database-access
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
          app: api
    ports:
    - protocol: TCP
      port: 5432
EOF'

#═══════════════════════════════════════════════════════════════
# QUESTION 2
#═══════════════════════════════════════════════════════════════

show_question "2" "Create a NetworkPolicy named 'deny-all-ingress' that:
  - Applies to ALL pods in the default namespace
  - Denies ALL incoming traffic
  
Hint: Use empty podSelector {} to select all pods"

validate_answer '
    # Check if NetworkPolicy exists
    if ! kubectl get networkpolicy deny-all-ingress &>/dev/null; then
        echo "❌ NetworkPolicy deny-all-ingress not found"
        exit 1
    fi
    
    # Check pod selector is empty (selects all)
    SELECTOR=$(kubectl get networkpolicy deny-all-ingress -o jsonpath="{.spec.podSelector}")
    if [ "$SELECTOR" != "{}" ]; then
        echo "❌ podSelector should be empty {}, got: $SELECTOR"
        exit 1
    fi
    
    # Check policy type
    POLICY_TYPE=$(kubectl get networkpolicy deny-all-ingress -o jsonpath="{.spec.policyTypes[0]}")
    if [ "$POLICY_TYPE" != "Ingress" ]; then
        echo "❌ policyTypes should include Ingress, got: $POLICY_TYPE"
        exit 1
    fi
    
    # Check that ingress rules are empty or not specified (deny all)
    INGRESS_RULES=$(kubectl get networkpolicy deny-all-ingress -o jsonpath="{.spec.ingress}")
    if [ ! -z "$INGRESS_RULES" ] && [ "$INGRESS_RULES" != "null" ]; then
        echo "❌ For deny-all, ingress rules should be empty"
        exit 1
    fi
    
    echo "✓ Deny-all NetworkPolicy is correct"
    exit 0
' 10

show_solution 'cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-all-ingress
spec:
  podSelector: {}
  policyTypes:
  - Ingress
EOF'

#═══════════════════════════════════════════════════════════════
# QUESTION 3
#═══════════════════════════════════════════════════════════════

show_question "3" "Create a NetworkPolicy named 'allow-dns-egress' that:
  - Applies to ALL pods
  - Allows egress to ALL pods on port 53 (UDP) for DNS
  - This is typically used with deny-all-egress policies
  
Note: DNS uses UDP port 53"

validate_answer '
    # Check if NetworkPolicy exists
    if ! kubectl get networkpolicy allow-dns-egress &>/dev/null; then
        echo "❌ NetworkPolicy allow-dns-egress not found"
        exit 1
    fi
    
    # Check policy type includes Egress
    POLICY_TYPE=$(kubectl get networkpolicy allow-dns-egress -o jsonpath="{.spec.policyTypes[0]}")
    if [ "$POLICY_TYPE" != "Egress" ]; then
        echo "❌ policyTypes should include Egress, got: $POLICY_TYPE"
        exit 1
    fi
    
    # Check port
    PORT=$(kubectl get networkpolicy allow-dns-egress -o jsonpath="{.spec.egress[0].ports[0].port}")
    if [ "$PORT" != "53" ]; then
        echo "❌ Port should be 53, got: $PORT"
        exit 1
    fi
    
    # Check protocol
    PROTOCOL=$(kubectl get networkpolicy allow-dns-egress -o jsonpath="{.spec.egress[0].ports[0].protocol}")
    if [ "$PROTOCOL" != "UDP" ]; then
        echo "❌ Protocol should be UDP, got: $PROTOCOL"
        exit 1
    fi
    
    echo "✓ DNS egress NetworkPolicy is correct"
    exit 0
' 10

show_solution 'cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-dns-egress
spec:
  podSelector: {}
  policyTypes:
  - Egress
  egress:
  - to:
    - namespaceSelector: {}
    ports:
    - protocol: UDP
      port: 53
EOF'

#═══════════════════════════════════════════════════════════════
# FINAL SCORE
#═══════════════════════════════════════════════════════════════

clear
echo ""
echo -e "${BLUE}╔═══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                    QUIZ COMPLETE!                             ║${NC}"
echo -e "${BLUE}╔═══════════════════════════════════════════════════════════════╗${NC}"
echo ""
echo -e "${YELLOW}Your Final Score: $SCORE / $TOTAL${NC}"
echo ""

PERCENTAGE=$((SCORE * 100 / TOTAL))

if [ $PERCENTAGE -ge 90 ]; then
    echo -e "${GREEN}🌟 EXCELLENT! You're ready for the CKA exam!${NC}"
elif [ $PERCENTAGE -ge 70 ]; then
    echo -e "${YELLOW}👍 GOOD! Review the solutions and try again.${NC}"
else
    echo -e "${RED}📚 NEEDS WORK! Study the solutions and practice more.${NC}"
fi

echo ""
echo -e "${BLUE}Grade: $PERCENTAGE%${NC}"
echo ""

# Ask to cleanup
read -p "Clean up all test resources? (y/n): " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
    cleanup
fi

echo ""
echo -e "${GREEN}Great job practicing! 🚀${NC}"
echo ""
