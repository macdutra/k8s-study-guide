# Quick Start Guide

Get started with your CKA preparation in 5 minutes!

## Prerequisites

- macOS 11 (Big Sur) or later
- 8GB RAM minimum
- 20GB free disk space
- Terminal access

## Step 1: Download

```bash
# Clone or download this repository
git clone https://github.com/yourusername/k8s-cka-study-guide.git
cd k8s-cka-study-guide
```

## Step 2: Run Setup

```bash
# Make setup script executable
chmod +x scripts/setup-macos.sh

# Run the automated setup
./scripts/setup-macos.sh
```

This script will install:
- ✅ Homebrew
- ✅ Docker Desktop
- ✅ kubectl
- ✅ Minikube
- ✅ Helm
- ✅ Additional tools (k9s, kubectx, jq, yq)

## Step 3: Start Minikube

```bash
# Start your Kubernetes cluster
minikube start --cpus=4 --memory=8192

# Verify it's running
kubectl cluster-info
kubectl get nodes
```

## Step 4: Enable Add-ons

```bash
# Enable essential add-ons
minikube addons enable metrics-server
minikube addons enable ingress
minikube addons enable dashboard
```

## Step 5: Test Your Setup

```bash
# Create a test deployment
kubectl create deployment hello --image=nginx

# Expose it
kubectl expose deployment hello --port=80 --type=NodePort

# Get the URL
minikube service hello --url

# Test it
curl $(minikube service hello --url)

# Clean up
kubectl delete deployment hello
kubectl delete service hello
```

## Step 6: Start Learning

### Option 1: Follow the Study Path

```bash
# Open the main README
open README.md

# Follow Week 1, Day 1 topics
# Start with: docs/00-setup-macos.md
```

### Option 2: Jump to Practice

```bash
# Try the full practice exam
open examples/practice-exam-full.md

# Set a timer for 120 minutes
# Work through all 16 tasks
```

### Option 3: Use Cheat Sheets

```bash
# kubectl commands
open cheat-sheets/kubectl-cheatsheet.md

# macOS tips
open cheat-sheets/macos-tips.md
```

## Daily Study Routine

### Morning (30 minutes)
1. Review theory in docs/
2. Practice kubectl commands
3. Read cheat sheets

### Afternoon (1-2 hours)
1. Hands-on lab exercises
2. Create resources
3. Practice troubleshooting

### Evening (30 minutes)
1. Review what you learned
2. Practice exam questions
3. Note weak areas

## Keyboard Shortcuts (Save Time!)

Add to `~/.zshrc`:

```bash
# Kubectl aliases
alias k='kubectl'
alias kgp='kubectl get pods'
alias kgs='kubectl get svc'
alias kaf='kubectl apply -f'
alias kdel='kubectl delete'

# Reload
source ~/.zshrc
```

## Your First Day Checklist

- [ ] Install all tools (use setup script)
- [ ] Start minikube successfully
- [ ] Create and delete a pod
- [ ] Use kubectl get, describe, logs
- [ ] Set up shell aliases
- [ ] Read docs/00-setup-macos.md
- [ ] Complete 3 kubectl exercises

## Common First-Day Issues

### Docker not starting
```bash
# Solution: Open Docker Desktop app manually
open -a Docker
# Wait for whale icon in menu bar
```

### Minikube won't start
```bash
# Solution: Delete and recreate
minikube delete
minikube start --driver=docker
```

### kubectl not found
```bash
# Solution: Ensure Homebrew is in PATH
echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
source ~/.zprofile
```

## Next Steps

1. ✅ Complete setup (you're here!)
2. 📖 Read [Main README](README.md)
3. 🎓 Start [Week 1 Study Plan](README.md#-week-1-foundations)
4. 💻 Practice with [HPA Tutorial](docs/01-hpa-autoscaling.md)
5. 📝 Try [Practice Exam](examples/practice-exam-full.md)

## Get Help

- 📚 Check [Troubleshooting](cheat-sheets/macos-tips.md#troubleshooting)
- 💬 Open an issue on GitHub
- 📖 Read Kubernetes docs: https://kubernetes.io/docs/

## Quick Commands Reference

```bash
# Cluster
minikube start
minikube stop
minikube status
minikube dashboard

# kubectl
kubectl get pods
kubectl describe pod <name>
kubectl logs <pod>
kubectl exec -it <pod> -- /bin/sh
kubectl apply -f <file>
kubectl delete -f <file>

# Help
kubectl --help
kubectl explain pod
minikube --help
```

---

**You're ready to start! Good luck with your CKA preparation! 🚀**

Return to: [Main README](README.md) | [Setup Guide](docs/00-setup-macos.md)
