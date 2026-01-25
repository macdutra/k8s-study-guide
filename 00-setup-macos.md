# macOS Setup Guide for Kubernetes CKA Study

Complete environment setup guide for macOS users preparing for the CKA certification.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Installation Steps](#installation-steps)
- [Verification](#verification)
- [macOS-Specific Configuration](#macos-specific-configuration)
- [Troubleshooting](#troubleshooting)

## Prerequisites

### System Requirements

- **macOS**: 11 (Big Sur) or later (macOS 13+ recommended)
- **RAM**: 8GB minimum, 16GB recommended
- **Disk Space**: 20GB free minimum
- **CPU**: Multi-core processor (4+ cores recommended)
- **Architecture**: Intel or Apple Silicon (M1/M2/M3)

### Before You Start

1. Update macOS to the latest version
2. Install Xcode Command Line Tools (if not installed):
   ```bash
   xcode-select --install
   ```

## Installation Steps

### 1. Install Homebrew

Homebrew is the package manager for macOS.

```bash
# Install Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# For Apple Silicon Macs, add Homebrew to PATH
echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
eval "$(/opt/homebrew/bin/brew shellenv)"

# Verify installation
brew --version
```

### 2. Install Docker Desktop

Docker Desktop is required for running Minikube with the Docker driver.

```bash
# Install Docker Desktop via Homebrew
brew install --cask docker

# Or download from: https://www.docker.com/products/docker-desktop/

# Start Docker Desktop from Applications folder
# Wait for Docker to fully start (whale icon in menu bar)

# Verify Docker installation
docker --version
docker ps
```

**Alternative: Use Colima (Lightweight Docker Alternative)**

```bash
# Install Colima
brew install colima

# Start Colima
colima start --cpu 4 --memory 8

# Verify
docker ps
```

### 3. Install kubectl

kubectl is the Kubernetes command-line tool.

```bash
# Install kubectl
brew install kubectl

# Verify installation
kubectl version --client

# Expected output:
# Client Version: v1.28.x
```

### 4. Install Minikube

Minikube runs a local Kubernetes cluster.

```bash
# Install Minikube
brew install minikube

# Verify installation
minikube version

# Expected output:
# minikube version: v1.32.x
```

### 5. Install Helm

Helm is the package manager for Kubernetes.

```bash
# Install Helm
brew install helm

# Verify installation
helm version

# Expected output:
# version.BuildInfo{Version:"v3.13.x", ...}
```

### 6. Install Additional Tools

```bash
# Install k9s (Kubernetes TUI)
brew install k9s

# Install kubectx and kubens (context switching)
brew install kubectx

# Install jq (JSON processor)
brew install jq

# Install yq (YAML processor)
brew install yq

# Install watch (for watching kubectl commands)
brew install watch

# Install tree (directory structure viewer)
brew install tree
```

## Start Your First Cluster

### Using Docker Driver (Recommended)

```bash
# Start minikube with Docker driver
minikube start \
  --driver=docker \
  --cpus=4 \
  --memory=8192 \
  --disk-size=20g \
  --kubernetes-version=v1.28.0

# Set Docker as default driver
minikube config set driver docker
```

### Using Hyperkit Driver (Intel Macs)

```bash
# Install Hyperkit
brew install hyperkit

# Start minikube with Hyperkit driver
minikube start \
  --driver=hyperkit \
  --cpus=4 \
  --memory=8192 \
  --disk-size=20g

# Set Hyperkit as default driver
minikube config set driver hyperkit
```

### Using QEMU Driver (Apple Silicon)

```bash
# Install QEMU
brew install qemu

# Start minikube with QEMU driver
minikube start \
  --driver=qemu \
  --cpus=4 \
  --memory=8192 \
  --disk-size=20g

# Note: QEMU is experimental on Apple Silicon
```

## Verification

### Verify Cluster is Running

```bash
# Check minikube status
minikube status

# Expected output:
# minikube
# type: Control Plane
# host: Running
# kubelet: Running
# apiserver: Running
# kubeconfig: Configured

# Check cluster info
kubectl cluster-info

# Check nodes
kubectl get nodes

# Expected output:
# NAME       STATUS   ROLES           AGE   VERSION
# minikube   Ready    control-plane   1m    v1.28.0
```

### Enable Minikube Addons

```bash
# Enable metrics-server (required for HPA)
minikube addons enable metrics-server

# Enable ingress controller
minikube addons enable ingress

# Enable dashboard
minikube addons enable dashboard

# Enable storage provisioner (default)
minikube addons enable storage-provisioner

# Enable registry (optional)
minikube addons enable registry

# List all enabled addons
minikube addons list
```

### Test Your Setup

```bash
# Create a test deployment
kubectl create deployment hello-minikube --image=kicbase/echo-server:1.0

# Expose the deployment
kubectl expose deployment hello-minikube --type=NodePort --port=8080

# Get the service URL
minikube service hello-minikube --url

# Access the service
curl $(minikube service hello-minikube --url)

# Clean up
kubectl delete deployment hello-minikube
kubectl delete service hello-minikube
```

## macOS-Specific Configuration

### Configure Shell (zsh)

macOS uses zsh by default. Add these to your `~/.zshrc`:

```bash
# Open .zshrc
nano ~/.zshrc

# Add the following:

# Kubectl aliases
alias k='kubectl'
alias kgp='kubectl get pods'
alias kgs='kubectl get svc'
alias kgd='kubectl get deployments'
alias kdp='kubectl describe pod'
alias kds='kubectl describe svc'
alias kl='kubectl logs'
alias kex='kubectl exec -it'
alias kaf='kubectl apply -f'
alias kdel='kubectl delete'

# Kubectl completion
source <(kubectl completion zsh)
alias kubectl=k
complete -F __start_kubectl k

# Minikube aliases
alias mk='minikube'
alias mks='minikube start'
alias mkstop='minikube stop'
alias mkdel='minikube delete'
alias mkssh='minikube ssh'

# Helm aliases
alias h='helm'
alias hi='helm install'
alias hls='helm list'

# Reload the configuration
source ~/.zshrc
```

### Configure VS Code (Optional)

```bash
# Install VS Code
brew install --cask visual-studio-code

# Install Kubernetes extension
code --install-extension ms-kubernetes-tools.vscode-kubernetes-tools

# Install YAML extension
code --install-extension redhat.vscode-yaml
```

### Resource Limits Configuration

Set default resource limits for minikube:

```bash
# Configure default settings
minikube config set cpus 4
minikube config set memory 8192
minikube config set disk-size 20g

# View current config
minikube config view
```

### Docker Desktop Settings

If using Docker Desktop, configure:

1. Open Docker Desktop
2. Go to Preferences → Resources
3. Set:
   - **CPUs**: 4 or more
   - **Memory**: 8GB or more
   - **Disk**: 20GB or more
4. Apply & Restart

## macOS Performance Tips

### 1. Use Docker Driver for Best Performance

```bash
# Docker driver is fastest on macOS
minikube start --driver=docker
```

### 2. Allocate Sufficient Resources

```bash
# Don't be stingy with resources
minikube start --cpus=4 --memory=8192
```

### 3. Enable macOS-Specific Optimizations

```bash
# Increase file descriptor limit
sudo launchctl limit maxfiles 65536 200000

# Add to ~/.zshrc for persistence
ulimit -n 65536
```

### 4. Use SSD for Better I/O

Ensure minikube is using SSD storage (it should be by default on modern Macs).

### 5. Close Unnecessary Applications

During practice, close resource-intensive applications to free up CPU and memory.

## Troubleshooting

### Common Issues and Solutions

#### Issue: "minikube start" fails

```bash
# Solution 1: Delete and restart
minikube delete
minikube start

# Solution 2: Try different driver
minikube start --driver=hyperkit

# Solution 3: Check Docker
docker ps
# If Docker isn't running, start Docker Desktop
```

#### Issue: Docker Desktop not starting

```bash
# Solution 1: Reset Docker Desktop
# Docker Desktop → Troubleshoot → Reset to factory defaults

# Solution 2: Reinstall Docker Desktop
brew uninstall --cask docker
brew install --cask docker

# Solution 3: Use Colima instead
brew install colima
colima start
```

#### Issue: kubectl connection refused

```bash
# Check minikube status
minikube status

# If not running, start it
minikube start

# Update kubeconfig
minikube update-context

# Verify context
kubectl config current-context
# Should show: minikube
```

#### Issue: Insufficient resources

```bash
# Error: "Requested memory allocation (8192MB) exceeds the available memory"

# Solution 1: Reduce allocation
minikube start --memory=4096 --cpus=2

# Solution 2: Close other applications

# Solution 3: Increase Docker Desktop resources
# Docker Desktop → Preferences → Resources → Adjust sliders
```

#### Issue: VPN conflicts

```bash
# Some corporate VPNs interfere with minikube

# Solution 1: Disconnect VPN temporarily

# Solution 2: Configure minikube to use host network
minikube start --network=host

# Solution 3: Use static IP
minikube start --static-ip=192.168.99.99
```

#### Issue: Apple Silicon (M1/M2/M3) specific issues

```bash
# Use Docker driver (best compatibility)
minikube start --driver=docker

# If Docker driver fails, try QEMU
brew install qemu
minikube start --driver=qemu

# For older Kubernetes versions, specify arch
minikube start --driver=docker --kubernetes-version=v1.28.0
```

#### Issue: Port already in use

```bash
# Find and kill process using port 8443 (API server)
lsof -ti:8443 | xargs kill -9

# Or use a different port
minikube start --apiserver-port=8444
```

#### Issue: DNS resolution problems

```bash
# Restart CoreDNS
kubectl rollout restart deployment coredns -n kube-system

# Or restart minikube
minikube stop
minikube start
```

### Getting Help

If you encounter issues not covered here:

1. Check minikube logs:
   ```bash
   minikube logs
   ```

2. Check kubectl logs:
   ```bash
   kubectl get events --all-namespaces --sort-by='.lastTimestamp'
   ```

3. Describe failed resources:
   ```bash
   kubectl describe pod <pod-name>
   ```

4. Visit the troubleshooting guide:
   - [Minikube Troubleshooting](https://minikube.sigs.k8s.io/docs/handbook/troubleshooting/)
   - [kubectl Troubleshooting](https://kubernetes.io/docs/tasks/debug/)

## Next Steps

Now that your environment is set up:

1. ✅ [Complete the HPA Tutorial](01-hpa-autoscaling.md)
2. ✅ [Learn Ingress Configuration](02-ingress-networking.md)
3. ✅ [Practice Resource Management](03-resource-management.md)
4. ✅ [Master Storage Concepts](04-storage-management.md)

## Quick Reference

### Start/Stop Commands

```bash
# Start cluster
minikube start

# Stop cluster (preserves state)
minikube stop

# Pause cluster (preserves resources)
minikube pause

# Unpause cluster
minikube unpause

# Delete cluster
minikube delete

# Delete all clusters and data
minikube delete --all --purge
```

### Useful Commands

```bash
# Get minikube IP
minikube ip

# SSH into minikube
minikube ssh

# Open Kubernetes dashboard
minikube dashboard

# Access service in browser
minikube service <service-name>

# Mount local directory
minikube mount /local/path:/minikube/path

# View logs
minikube logs

# Update minikube
brew upgrade minikube
```

---

**Ready to start learning? Head back to the [main README](../README.md) to begin your study path!**
