#!/bin/bash

# Kubernetes CKA Study Guide - macOS Setup Script
# This script automates the installation of all required tools for CKA preparation

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Print functions
print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_info() {
    echo -e "${YELLOW}ℹ $1${NC}"
}

print_header() {
    echo -e "\n${YELLOW}=====================================${NC}"
    echo -e "${YELLOW}$1${NC}"
    echo -e "${YELLOW}=====================================${NC}\n"
}

# Check if running on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    print_error "This script is designed for macOS only"
    exit 1
fi

print_header "Kubernetes CKA Study Guide - macOS Setup"

# Check for Xcode Command Line Tools
print_info "Checking for Xcode Command Line Tools..."
if ! xcode-select -p &>/dev/null; then
    print_info "Installing Xcode Command Line Tools..."
    xcode-select --install
    print_info "Please complete the Xcode Command Line Tools installation and re-run this script"
    exit 0
else
    print_success "Xcode Command Line Tools already installed"
fi

# Install Homebrew
print_header "Installing Homebrew"
if ! command -v brew &>/dev/null; then
    print_info "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    
    # Add Homebrew to PATH for Apple Silicon
    if [[ $(uname -m) == "arm64" ]]; then
        echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
        eval "$(/opt/homebrew/bin/brew shellenv)"
    fi
    
    print_success "Homebrew installed successfully"
else
    print_success "Homebrew already installed"
    print_info "Updating Homebrew..."
    brew update
fi

# Install Docker Desktop
print_header "Installing Docker Desktop"
if ! command -v docker &>/dev/null; then
    print_info "Installing Docker Desktop..."
    brew install --cask docker
    print_info "Please start Docker Desktop from Applications and wait for it to fully start"
    print_info "Look for the whale icon in your menu bar"
    read -p "Press Enter when Docker Desktop is running..."
    print_success "Docker Desktop installed"
else
    print_success "Docker already installed"
fi

# Verify Docker is running
print_info "Verifying Docker..."
if docker ps &>/dev/null; then
    print_success "Docker is running"
else
    print_error "Docker is not running. Please start Docker Desktop and try again"
    exit 1
fi

# Install kubectl
print_header "Installing kubectl"
if ! command -v kubectl &>/dev/null; then
    print_info "Installing kubectl..."
    brew install kubectl
    print_success "kubectl installed successfully"
else
    print_success "kubectl already installed"
    kubectl version --client --short
fi

# Install Minikube
print_header "Installing Minikube"
if ! command -v minikube &>/dev/null; then
    print_info "Installing Minikube..."
    brew install minikube
    print_success "Minikube installed successfully"
else
    print_success "Minikube already installed"
    minikube version
fi

# Install Helm
print_header "Installing Helm"
if ! command -v helm &>/dev/null; then
    print_info "Installing Helm..."
    brew install helm
    print_success "Helm installed successfully"
else
    print_success "Helm already installed"
    helm version --short
fi

# Install additional tools
print_header "Installing Additional Tools"

print_info "NOTE: Some tools (jq, yq, tree, k9s) are NOT available in the CKA exam"
print_info "They're useful for learning, but practice exam tasks without them too!"
echo ""

tools=("k9s" "kubectx" "jq" "yq" "watch" "tree")
for tool in "${tools[@]}"; do
    if ! command -v "$tool" &>/dev/null; then
        print_info "Installing $tool..."
        brew install "$tool"
        print_success "$tool installed (for study only)"
    else
        print_success "$tool already installed"
    fi
done

print_info ""
print_info "Remember: During the exam, you'll only have kubectl, vim, and basic Linux tools"

# Configure Minikube
print_header "Configuring Minikube"
print_info "Setting default Minikube configuration..."

minikube config set driver docker
minikube config set cpus 4
minikube config set memory 8192
minikube config set disk-size 20g

print_success "Minikube configuration set"
print_info "Configuration:"
minikube config view

# Setup shell configuration
print_header "Setting up Shell Configuration"

SHELL_RC=""
if [ -f ~/.zshrc ]; then
    SHELL_RC=~/.zshrc
elif [ -f ~/.bash_profile ]; then
    SHELL_RC=~/.bash_profile
fi

if [ -n "$SHELL_RC" ]; then
    print_info "Adding kubectl aliases to $SHELL_RC..."
    
    # Check if aliases already exist
    if ! grep -q "# Kubernetes CKA aliases" "$SHELL_RC"; then
        cat >> "$SHELL_RC" << 'EOF'

# Kubernetes CKA aliases
alias k='kubectl'
alias kgp='kubectl get pods'
alias kgs='kubectl get svc'
alias kgd='kubectl get deployments'
alias kgn='kubectl get nodes'
alias kdp='kubectl describe pod'
alias kds='kubectl describe svc'
alias kl='kubectl logs'
alias kex='kubectl exec -it'
alias kaf='kubectl apply -f'
alias kdel='kubectl delete'

# Minikube aliases
alias mk='minikube'
alias mks='minikube start'
alias mkstop='minikube stop'
alias mkdel='minikube delete'

# Helm aliases
alias h='helm'
alias hi='helm install'
alias hls='helm list'

# Enable kubectl completion
source <(kubectl completion zsh) 2>/dev/null || source <(kubectl completion bash) 2>/dev/null
EOF
        print_success "Aliases added to $SHELL_RC"
        print_info "Run 'source $SHELL_RC' to load aliases"
    else
        print_success "Aliases already exist in $SHELL_RC"
    fi
fi

# Start Minikube
print_header "Starting Minikube Cluster"
read -p "Do you want to start a Minikube cluster now? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    print_info "Starting Minikube cluster..."
    minikube start --cpus=4 --memory=8192 --disk-size=20g
    
    print_info "Enabling addons..."
    minikube addons enable metrics-server
    minikube addons enable ingress
    minikube addons enable dashboard
    
    print_success "Minikube cluster started successfully"
    
    # Verify cluster
    print_info "Verifying cluster..."
    kubectl cluster-info
    kubectl get nodes
    
    print_success "Cluster is ready!"
else
    print_info "Skipping Minikube start. You can start it later with: minikube start"
fi

# Final verification
print_header "Installation Summary"
print_success "Installation complete! Installed tools:"
echo ""
echo "  ✓ Homebrew: $(brew --version | head -1)"
echo "  ✓ Docker: $(docker --version)"
echo "  ✓ kubectl: $(kubectl version --client --short 2>/dev/null | head -1)"
echo "  ✓ Minikube: $(minikube version --short)"
echo "  ✓ Helm: $(helm version --short)"
echo "  ✓ k9s: $(k9s version --short 2>/dev/null | head -1 || echo 'installed')"
echo ""

print_header "Next Steps"
echo "1. Source your shell configuration:"
echo "   source $SHELL_RC"
echo ""
echo "2. If you didn't start Minikube, start it now:"
echo "   minikube start --cpus=4 --memory=8192"
echo ""
echo "3. Verify your setup:"
echo "   kubectl cluster-info"
echo "   kubectl get nodes"
echo ""
echo "4. Start learning! Open the study guide:"
echo "   open README.md"
echo ""
echo "5. Try the Kubernetes dashboard:"
echo "   minikube dashboard"
echo ""

print_success "Setup complete! Happy learning! 🚀"
