#!/bin/bash

# RBAC Interactive Practice Quiz
# Author: CKA Study Guide

set -e

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SCORE=0
TOTAL=0

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

cleanup() {
    echo ""
    echo -e "${YELLOW}Cleaning up test resources...${NC}"
    kubectl delete role pod-reader 2>/dev/null || true
    kubectl delete rolebinding read-pods 2>/dev/null || true
    kubectl delete serviceaccount pod-viewer 2>/dev/null || true
    kubectl delete clusterrole deployment-manager 2>/dev/null || true
    kubectl delete clusterrolebinding manage-deployments 2>/dev/null || true
    echo -e "${GREEN}Cleanup complete!${NC}"
}

clear
echo -e "${BLUE}╔═══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║              RBAC Interactive Practice Quiz                   ║${NC}"
echo -e "${BLUE}╔═══════════════════════════════════════════════════════════════╗${NC}"
echo ""
read -p "Press ENTER to start the quiz..."

cleanup

#═══════════════════════════════════════════════════════════════
# QUESTION 1
#═══════════════════════════════════════════════════════════════

show_question "1" "Create a Role named 'pod-reader' that allows:
  - Verbs: get, list, watch
  - Resources: pods
  - In the default namespace
  
Then create a RoleBinding named 'read-pods' that:
  - Binds the 'pod-reader' role
  - To a ServiceAccount named 'pod-viewer' (you need to create this too)"

validate_answer '
    # Check ServiceAccount
    if ! kubectl get serviceaccount pod-viewer &>/dev/null; then
        echo "❌ ServiceAccount pod-viewer not found"
        exit 1
    fi
    
    # Check Role
    if ! kubectl get role pod-reader &>/dev/null; then
        echo "❌ Role pod-reader not found"
        exit 1
    fi
    
    # Check verbs
    VERBS=$(kubectl get role pod-reader -o jsonpath="{.rules[0].verbs[*]}")
    if [[ ! "$VERBS" =~ "get" ]] || [[ ! "$VERBS" =~ "list" ]] || [[ ! "$VERBS" =~ "watch" ]]; then
        echo "❌ Role should have verbs: get, list, watch. Got: $VERBS"
        exit 1
    fi
    
    # Check resources
    RESOURCES=$(kubectl get role pod-reader -o jsonpath="{.rules[0].resources[*]}")
    if [[ ! "$RESOURCES" =~ "pods" ]]; then
        echo "❌ Role should have resource: pods. Got: $RESOURCES"
        exit 1
    fi
    
    # Check RoleBinding
    if ! kubectl get rolebinding read-pods &>/dev/null; then
        echo "❌ RoleBinding read-pods not found"
        exit 1
    fi
    
    # Check RoleBinding references correct Role
    ROLE_REF=$(kubectl get rolebinding read-pods -o jsonpath="{.roleRef.name}")
    if [ "$ROLE_REF" != "pod-reader" ]; then
        echo "❌ RoleBinding should reference role pod-reader, got: $ROLE_REF"
        exit 1
    fi
    
    # Check RoleBinding references correct ServiceAccount
    SA_NAME=$(kubectl get rolebinding read-pods -o jsonpath="{.subjects[0].name}")
    if [ "$SA_NAME" != "pod-viewer" ]; then
        echo "❌ RoleBinding should reference ServiceAccount pod-viewer, got: $SA_NAME"
        exit 1
    fi
    
    echo "✓ RBAC configuration is correct"
    exit 0
' 15

show_solution 'kubectl create serviceaccount pod-viewer

kubectl create role pod-reader --verb=get,list,watch --resource=pods

kubectl create rolebinding read-pods --role=pod-reader --serviceaccount=default:pod-viewer'

#═══════════════════════════════════════════════════════════════
# QUESTION 2
#═══════════════════════════════════════════════════════════════

show_question "2" "Create a ClusterRole named 'deployment-manager' that allows:
  - Verbs: get, list, create, update, delete
  - Resources: deployments
  - Across ALL namespaces
  
Create a ClusterRoleBinding named 'manage-deployments' that:
  - Binds this ClusterRole
  - To the user 'jane' (kind: User)"

validate_answer '
    # Check ClusterRole
    if ! kubectl get clusterrole deployment-manager &>/dev/null; then
        echo "❌ ClusterRole deployment-manager not found"
        exit 1
    fi
    
    # Check verbs
    VERBS=$(kubectl get clusterrole deployment-manager -o jsonpath="{.rules[0].verbs[*]}")
    for verb in get list create update delete; do
        if [[ ! "$VERBS" =~ "$verb" ]]; then
            echo "❌ ClusterRole missing verb: $verb"
            exit 1
        fi
    done
    
    # Check resources
    RESOURCES=$(kubectl get clusterrole deployment-manager -o jsonpath="{.rules[0].resources[*]}")
    if [[ ! "$RESOURCES" =~ "deployments" ]]; then
        echo "❌ ClusterRole should have resource: deployments"
        exit 1
    fi
    
    # Check ClusterRoleBinding
    if ! kubectl get clusterrolebinding manage-deployments &>/dev/null; then
        echo "❌ ClusterRoleBinding manage-deployments not found"
        exit 1
    fi
    
    # Check subject
    USER_NAME=$(kubectl get clusterrolebinding manage-deployments -o jsonpath="{.subjects[0].name}")
    USER_KIND=$(kubectl get clusterrolebinding manage-deployments -o jsonpath="{.subjects[0].kind}")
    
    if [ "$USER_NAME" != "jane" ] || [ "$USER_KIND" != "User" ]; then
        echo "❌ ClusterRoleBinding should bind to User jane"
        exit 1
    fi
    
    echo "✓ ClusterRole and ClusterRoleBinding are correct"
    exit 0
' 15

show_solution 'kubectl create clusterrole deployment-manager --verb=get,list,create,update,delete --resource=deployments

kubectl create clusterrolebinding manage-deployments --clusterrole=deployment-manager --user=jane'

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

read -p "Clean up all test resources? (y/n): " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
    cleanup
fi

echo ""
echo -e "${GREEN}Great job practicing! 🚀${NC}"
echo ""
