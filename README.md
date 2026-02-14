# Kubernetes CKA Study Guide (macOS Edition)

<div align="center">

![Kubernetes](https://img.shields.io/badge/kubernetes-%23326ce5.svg?style=for-the-badge&logo=kubernetes&logoColor=white)
![macOS](https://img.shields.io/badge/macOS-000000?style=for-the-badge&logo=apple&logoColor=white)
![Helm](https://img.shields.io/badge/Helm-0F1689?style=for-the-badge&logo=helm&logoColor=white)

**Complete CKA Certification Study Guide for macOS Users**

[Getting Started](#-quick-start) • [Documentation](#-documentation) • [Practice Exams](#-practice-exams) • [Cheat Sheets](#-cheat-sheets)

</div>

---

## 📚 Table of Contents

- [Overview](#-overview)
- [Prerequisites](#-prerequisites)
- [Quick Start](#-quick-start)
- [Study Path](#-study-path)
- [Documentation](#-documentation)
- [Practice Exams](#-practice-exams)
- [Cheat Sheets](#-cheat-sheets)
- [Contributing](#-contributing)
- [License](#-license)

## 🎯 Overview

This repository contains a comprehensive study guide covering all essential Kubernetes topics for CKA certification, specifically optimized for **macOS** users with Minikube.

### Topics Covered

| Category | Topics | Status |
|----------|--------|--------|
| **Autoscaling** | HPA with ScaleDown behavior | ✅ |
| **Networking** | Ingress, Gateway API, NetworkPolicy | ✅ |
| **Resources** | Requests, Limits, ResourceQuota | ✅ |
| **Storage** | PV, PVC, StorageClass | ✅ |
| **Security** | NetworkPolicy, RBAC, TLS | ✅ |
| **Patterns** | Sidecar, Init Containers | ✅ |
| **Scheduling** | PriorityClass, Node Affinity | ✅ |
| **Troubleshooting** | ETCD, Control Plane | ✅ |
| **Advanced** | CRDs, Custom Controllers | ✅ |
| **DevOps** | Helm, ArgoCD | ✅ |

## 💻 Prerequisites

### System Requirements (macOS)

- **macOS**: 11 (Big Sur) or later
- **RAM**: 8GB minimum (16GB recommended)
- **Disk Space**: 20GB free
- **CPU**: Multi-core processor (4+ cores recommended)

### Required Software

- [Homebrew](https://brew.sh/) - Package manager for macOS
- Terminal or iTerm2
- Basic command line knowledge

## 🚀 Quick Start

### 1. Install Homebrew (if not installed)

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

### 2. Run the Setup Script

```bash
# Clone the repository
git clone https://github.com/yourusername/k8s-cka-study-guide.git
cd k8s-cka-study-guide

# Make setup script executable
chmod +x scripts/setup-macos.sh

# Run setup
./scripts/setup-macos.sh
```

### 3. Verify Installation

```bash
# Check versions
kubectl version --client
minikube version
helm version

# Start your first cluster
minikube start --cpus=4 --memory=4096

# Verify cluster
kubectl cluster-info
kubectl get nodes
```

## 📊 Study Materials

### Comprehensive Study Path

- **[COVERAGE-ANALYSIS.md](COVERAGE-ANALYSIS.md)** - 🎯 What you have vs. what you need for 100% exam coverage
- **[Week 1 Study Plan](README.md#-week-1-foundations)** - Foundations (HPA, Ingress, Resources, Storage)

**Objective**: Master core Kubernetes concepts and resource management

| Day | Focus Area | Topics | Practice Time |
|-----|------------|--------|---------------|
| 1-2 | Setup & Basics | Environment setup, kubectl basics | 4 hours |
| 3-4 | High Priority | HPA, Ingress, Resource Management | 6 hours |
| 5-6 | Storage | PV, PVC, StorageClass | 6 hours |
| 7 | Review | Practice exercises, troubleshooting | 4 hours |

**Resources**: 
- [Setup Guide](docs/00-setup-macos.md)
- [HPA Deep Dive](docs/01-hpa-autoscaling.md)
- [Ingress Tutorial](docs/02-ingress-networking.md)
- [Resource Management](docs/03-resource-management.md)
- [Storage Guide](docs/04-storage-management.md)

### 🟡 Week 2: Advanced Topics

**Objective**: Advanced networking, security, and multi-container patterns

| Day | Focus Area | Topics | Practice Time |
|-----|------------|--------|---------------|
| 1-2 | Security | NetworkPolicy, RBAC | 6 hours |
| 3-4 | Patterns | Sidecar, PriorityClass, Gateway API | 6 hours |
| 5-6 | Troubleshooting | ETCD, CRDs, Control Plane | 6 hours |
| 7 | Review | Practice exercises, troubleshooting | 4 hours |

**Resources**:
- [Network Policies](docs/05-network-policies.md)
- [Sidecar Patterns](docs/06-sidecar-patterns.md)
- [Pod Scheduling](docs/07-pod-scheduling.md)
- [Gateway API](docs/08-gateway-api.md)
- [ETCD Backup & Restore](docs/09-etcd-backup-restore.md)
- [RBAC](docs/10-rbac.md)
- [Cluster Troubleshooting](docs/11-cluster-troubleshooting.md)

### 🔴 Week 3: Integration & Mastery

**Objective**: DevOps tools integration and exam readiness

| Day | Focus Area | Topics | Practice Time |
|-----|------------|--------|---------------|
| 1-2 | DevOps Tools | Helm, ArgoCD | 6 hours |
| 3-4 | Practice Exams | Full exam simulations | 8 hours |
| 5-6 | Weak Areas | Focus on challenging topics | 6 hours |
| 7 | Final Review | Complete practice exam | 4 hours |

**Resources**:
- [Helm Basics](docs/12-helm-basics.md)
- [ConfigMap & Secrets](docs/13-configmap-secrets.md)
- [kubectl Tips & Tricks](docs/14-kubectl-tips.md)
- [Practice Exercises](examples/)
- Review all core documentation

## 📚 Documentation

### Core Topics

1. **[macOS Setup Guide](docs/00-setup-macos.md)** - Complete environment setup for macOS
2. **[HPA with ScaleDown](docs/01-hpa-autoscaling.md)** - Horizontal Pod Autoscaling
3. **[Ingress & Networking](docs/02-ingress-networking.md)** - Ingress controllers and rules
4. **[Resource Management](docs/03-resource-management.md)** - Requests, limits, quotas
5. **[Storage Management](docs/04-storage-management.md)** - PV, PVC, StorageClass
6. **[Network Policies](docs/05-network-policies.md)** - Pod-to-pod communication control
7. **[Sidecar Patterns](docs/06-sidecar-patterns.md)** - Multi-container pod patterns
8. **[Pod Scheduling](docs/07-pod-scheduling.md)** - Node affinity, taints, tolerations
9. **[Gateway API](docs/08-gateway-api.md)** - Modern ingress alternative
10. **[ETCD Backup & Restore](docs/09-etcd-backup-restore.md)** - Control plane backup and recovery
11. **[RBAC](docs/10-rbac.md)** - Role-Based Access Control
12. **[Cluster Troubleshooting](docs/11-cluster-troubleshooting.md)** - Debugging cluster issues
13. **[Helm Basics](docs/12-helm-basics.md)** - Kubernetes package manager
14. **[ConfigMap & Secrets](docs/13-configmap-secrets.md)** - Configuration management
15. **[kubectl Tips & Tricks](docs/14-kubectl-tips.md)** - Exam efficiency guide

### Quick References

- **[USING-DOCUMENTATION.md](USING-DOCUMENTATION.md)** - 📖 How to find YAML examples during the exam (kubectl explain, docs, etc.)
- **[MINIKUBE-VS-KUBECTL.md](MINIKUBE-VS-KUBECTL.md)** - ⚠️ Minikube commands vs kubectl equivalents
- **[ADDON-INSTALLATION.md](ADDON-INSTALLATION.md)** - Installing metrics-server, ingress, and other add-ons
- **[EXAM-ENVIRONMENT.md](EXAM-ENVIRONMENT.md)** - What tools are available during the exam
- **[kubectl Cheat Sheet](cheat-sheets/kubectl-cheatsheet.md)** - Essential kubectl commands
- **[YAML Templates](cheat-sheets/yaml-templates.md)** - Common resource templates
- **[Troubleshooting Guide](cheat-sheets/troubleshooting.md)** - Common issues and solutions
- **[macOS Tips](cheat-sheets/macos-tips.md)** - macOS-specific tips and tricks

## 🧪 Practice Exams

### Interactive Practice Quizzes ⭐ NEW!

**Exam-style quizzes with automatic validation and scoring!**

```bash
cd practice-scripts

# NetworkPolicy Quiz (3 questions, 15 min)
./network-policies-quiz.sh

# RBAC Quiz (2 questions, 10 min)
./rbac-quiz.sh
```

**Features:**
- ✅ See question ONLY (no spoilers!)
- ✅ Create your solution with kubectl
- ✅ Automatic validation of your work
- ✅ Instant scoring and feedback
- ✅ See correct solution after each question
- ✅ Final grade at the end

See [practice-scripts/README.md](practice-scripts/README.md) for details.

### Available Practice Tests

1. **[Beginner Practice Exam](examples/practice-exam-beginner.md)** - 8 tasks, 60 minutes
2. **[Intermediate Practice Exam](examples/practice-exam-intermediate.md)** - 12 tasks, 90 minutes
3. **[Advanced Practice Exam](examples/practice-exam-advanced.md)** - 16 tasks, 120 minutes
4. **[Full CKA Simulation](examples/practice-exam-full.md)** - 17 tasks, 120 minutes

### Practice Scripts

```bash
# Run beginner practice exam
./scripts/practice-exam-beginner.sh

# Run intermediate practice exam
./scripts/practice-exam-intermediate.sh

# Run advanced practice exam
./scripts/practice-exam-advanced.sh

# Run full CKA simulation
./scripts/practice-exam-full.sh
```

## 📋 Cheat Sheets

### Quick Command Reference

```bash
# Cluster Management
minikube start --cpus=4 --memory=8192
minikube status
minikube dashboard

# Resource Management
kubectl get all -A
kubectl describe pod <pod-name>
kubectl logs <pod-name> -f
kubectl exec -it <pod-name> -- /bin/sh

# Configuration
kubectl apply -f manifest.yaml
kubectl delete -f manifest.yaml
kubectl edit deployment <name>
kubectl scale deployment <name> --replicas=3

# Debugging
kubectl get events --sort-by='.lastTimestamp'
kubectl top nodes
kubectl top pods
```

### Useful Aliases (Add to ~/.zshrc or ~/.bash_profile)

```bash
alias k='kubectl'
alias kgp='kubectl get pods'
alias kgs='kubectl get svc'
alias kgd='kubectl get deployments'
alias kdp='kubectl describe pod'
alias kl='kubectl logs'
alias kex='kubectl exec -it'
alias kaf='kubectl apply -f'
alias kdel='kubectl delete'
alias kc='kubectl config'
alias kcc='kubectl config current-context'
alias kns='kubectl config set-context --current --namespace'
```

## 🏆 Study Tips

### Best Practices

1. **Hands-On Practice**: Don't just read - practice every command
2. **Time Management**: Use a timer during practice exams
3. **Documentation**: Get comfortable with `kubectl explain` and `--help`
4. **Aliases**: Use aliases to save time during the exam
5. **Imperative Commands**: Master `kubectl create`, `expose`, `run` for speed
6. **YAML Skills**: Learn to write and edit YAML quickly
7. **Troubleshooting**: Practice debugging failed pods and services
8. **Regular Practice**: Study consistently rather than cramming

### Exam Day Tips

- ✅ Arrive early and test your equipment
- ✅ Have ID ready and workspace clear
- ✅ Use imperative commands when possible
- ✅ Read questions carefully
- ✅ Flag difficult questions and return later
- ✅ Verify your work before moving on
- ✅ Watch the clock but don't panic
- ✅ Use `kubectl explain` for syntax help

## 🛠️ Troubleshooting

### Common Issues on macOS

#### Minikube won't start

```bash
# Reset minikube
minikube delete
minikube start --driver=docker --cpus=4 --memory=8192

# Or try hyperkit driver
minikube start --driver=hyperkit --cpus=4 --memory=8192
```

#### Docker issues

```bash
# Restart Docker Desktop
# Docker Desktop → Preferences → Reset → Restart

# Verify Docker
docker ps
docker version
```

#### kubectl not connecting

```bash
# Check context
kubectl config current-context

# Switch to minikube
kubectl config use-context minikube

# Verify connection
kubectl cluster-info
```

#### Resource constraints

```bash
# Increase minikube resources
minikube config set memory 8192
minikube config set cpus 4
minikube delete
minikube start
```

## 📝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request. For major changes, please open an issue first to discuss what you would like to change.

### How to Contribute

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Kubernetes Documentation
- CKA Curriculum
- Cloud Native Computing Foundation (CNCF)
- The Kubernetes Community

## 📞 Support

- **Issues**: [GitHub Issues](https://github.com/yourusername/k8s-cka-study-guide/issues)
- **Discussions**: [GitHub Discussions](https://github.com/yourusername/k8s-cka-study-guide/discussions)
- **Email**: your.email@example.com

---

<div align="center">

**Good luck with your CKA certification! 🚀**

Made with ❤️ by Kubernetes enthusiasts

</div>
