# CKA Exam Environment Guide

What to expect in the actual CKA exam environment and how to prepare.

## 🎯 Exam Environment Overview

The CKA exam is:
- **Performance-based**: You work in real Kubernetes clusters
- **Remote proctored**: Monitored via webcam
- **Browser-based**: Uses a remote desktop in your browser
- **Time-limited**: 2 hours (120 minutes)
- **Open documentation**: You can access kubernetes.io/docs

## 🛠️ Available Tools

### ✅ What You WILL Have

**Text Editors:**
- `vim` (primary)
- `nano` (alternative)

**Kubernetes Tools:**
- `kubectl` (all versions and features)
- `crictl` (container runtime interface)
- `kubeadm` (for cluster operations)

**Linux Commands:**
- `grep`, `awk`, `sed` (text processing)
- `cat`, `less`, `more` (file viewing)
- `ls`, `find`, `tree` (maybe - directory listing)
- `cp`, `mv`, `rm` (file operations)
- `systemctl` (service management)
- `journalctl` (system logs)
- `ssh` (to access cluster nodes)
- `scp` (file transfer between nodes)

**Shell:**
- `bash` shell
- Standard bash features (pipes, redirects, variables)

### ❌ What You WON'T Have

**Nice-to-have tools (NOT in exam):**
- `jq` - JSON processor
- `yq` - YAML processor
- `k9s` - Terminal UI for Kubernetes
- `kubectx` / `kubens` - Context switching helpers
- `helm` (unless question specifically requires it)
- Most other third-party tools

**Your local conveniences:**
- Your custom aliases (unless you recreate them)
- Your .bashrc / .zshrc settings
- Auto-completion (unless you enable it)
- Syntax highlighting in vim (unless configured)

## 📚 Documentation Access

### ✅ Allowed Sites

During the exam, you can access:
- **kubernetes.io/docs** - Official Kubernetes documentation
- **kubernetes.io/blog** - Kubernetes blog
- **github.com/kubernetes** - Kubernetes GitHub (limited)
- **helm.sh/docs** - Helm documentation (if needed)

### ❌ Not Allowed

- Google, StackOverflow, ChatGPT, or any other sites
- Your own notes (must be from allowed sites)
- Communication with anyone

## 💪 How to Prepare

### Practice Without Helper Tools

```bash
# Instead of jq:
kubectl get pods -o jsonpath='{.items[*].metadata.name}'

# Instead of yq:
grep "replicas:" deployment.yaml
kubectl get deployment -o yaml | grep replicas:

# Instead of kubectx:
kubectl config use-context <context-name>

# Instead of kubens:
kubectl config set-context --current --namespace=<namespace>
```

### Master kubectl Native Features

```bash
# JSONPath (replaces jq)
kubectl get pods -o jsonpath='{.items[*].metadata.name}'
kubectl get nodes -o jsonpath='{.items[*].status.addresses[?(@.type=="InternalIP")].address}'

# Custom columns
kubectl get pods -o custom-columns=NAME:.metadata.name,STATUS:.status.phase

# Field selectors
kubectl get pods --field-selector status.phase=Running

# Label selectors
kubectl get pods -l app=nginx,env=prod

# Output formats
kubectl get pods -o wide
kubectl get pods -o yaml
kubectl get pods -o json
kubectl get pods -o name
```

### Enable kubectl Auto-completion

You'll want to enable this in the exam:

```bash
# In the exam, run this first thing:
source <(kubectl completion bash)
alias k=kubectl
complete -F __start_kubectl k

# Now you can use:
k get po<TAB>
k get pods -n <TAB>
```

### Learn vim Basics

You WILL need to edit YAML files:

```bash
# Essential vim commands:
i          # Enter insert mode
ESC        # Exit insert mode
:w         # Save
:q         # Quit
:wq        # Save and quit
:q!        # Quit without saving
dd         # Delete line
yy         # Copy line
p          # Paste
/search    # Search
n          # Next search result
:set nu    # Show line numbers
```

Or use `nano` if you prefer:
```bash
nano file.yaml
# Ctrl+O to save
# Ctrl+X to exit
```

## 🎓 Exam-Style Practice

### Set Up Exam-Like Environment

```bash
# Practice with minimal environment
# Don't use: jq, yq, k9s, kubectx

# Create practice session
alias practice-mode='unalias jq yq k9s kubectx 2>/dev/null; echo "Practice mode: Only kubectl and basic tools"'

# Run practice exams without helper tools
practice-mode
./scripts/practice-exam-advanced.sh
```

### Time Management Practice

```bash
# Use a timer
time ./scripts/practice-exam-full.sh

# Or manually time yourself
start=$(date +%s)
# Do tasks...
end=$(date +%s)
echo "Time: $((end - start)) seconds"
```

## 📝 Exam Day Checklist

### Before the Exam

- [ ] Test your webcam and microphone
- [ ] Clear your desk (only water allowed)
- [ ] Close all applications except browser
- [ ] Have government ID ready
- [ ] Test your internet connection
- [ ] Read exam rules carefully

### First 5 Minutes of Exam

1. **Enable kubectl completion:**
   ```bash
   source <(kubectl completion bash)
   alias k=kubectl
   complete -F __start_kubectl k
   ```

2. **Verify cluster access:**
   ```bash
   kubectl cluster-info
   kubectl get nodes
   ```

3. **Check available contexts:**
   ```bash
   kubectl config get-contexts
   ```

4. **Bookmark important docs:**
   - Open kubernetes.io/docs in a tab
   - Keep kubectl cheatsheet page ready

### During the Exam

**DO:**
- ✅ Use imperative commands when possible (faster)
- ✅ Use `kubectl explain` for syntax help
- ✅ Use `--dry-run=client -o yaml` to generate templates
- ✅ Verify your work before moving on
- ✅ Flag difficult questions and return later
- ✅ Watch the timer but don't panic
- ✅ Use kubectl auto-completion extensively

**DON'T:**
- ❌ Spend too much time on one question
- ❌ Try to memorize everything (use docs)
- ❌ Forget to switch contexts when required
- ❌ Forget to switch namespaces when required
- ❌ Leave questions blank (try something!)

## 🔧 Essential kubectl Patterns for Exam

### Quick Resource Creation

```bash
# Pod
kubectl run nginx --image=nginx

# Deployment
kubectl create deployment web --image=nginx --replicas=3

# Service
kubectl expose deployment web --port=80 --type=NodePort

# ConfigMap
kubectl create configmap app-config --from-literal=key=value

# Secret
kubectl create secret generic app-secret --from-literal=password=secret

# Namespace
kubectl create namespace production

# Job
kubectl create job pi --image=perl -- perl -Mbignum=bpi -wle 'print bpi(2000)'

# CronJob
kubectl create cronjob hello --image=busybox --schedule="*/1 * * * *" -- echo Hello
```

### Resource Modification

```bash
# Scale
kubectl scale deployment web --replicas=5

# Set image
kubectl set image deployment web nginx=nginx:1.20

# Set resources
kubectl set resources deployment web --requests=cpu=100m,memory=128Mi

# Edit resource
kubectl edit deployment web

# Patch resource
kubectl patch deployment web -p '{"spec":{"replicas":3}}'
```

### Quick Verification

```bash
# Get all resources
kubectl get all

# Describe for details
kubectl describe pod <pod-name>

# Check logs
kubectl logs <pod-name>

# Check events
kubectl get events --sort-by='.lastTimestamp'

# Execute command
kubectl exec -it <pod-name> -- /bin/sh
```

## 💡 Pro Tips

### 1. Speed Techniques

```bash
# Use aliases
alias k=kubectl
alias kgp='kubectl get pods'
alias kd='kubectl describe'
alias kdel='kubectl delete'

# Use short names
kubectl get po     # instead of pods
kubectl get svc    # instead of services
kubectl get deploy # instead of deployments
kubectl get ns     # instead of namespaces
```

### 2. Template Generation

```bash
# Generate YAML without creating
kubectl run nginx --image=nginx --dry-run=client -o yaml > pod.yaml

# Modify and apply
vim pod.yaml
kubectl apply -f pod.yaml
```

### 3. Quick Edits

```bash
# For simple changes, use kubectl edit
kubectl edit deployment web

# For complex changes, export -> edit -> replace
kubectl get deployment web -o yaml > deploy.yaml
vim deploy.yaml
kubectl replace -f deploy.yaml --force
```

### 4. Error Recovery

```bash
# If you mess up, don't panic
kubectl delete -f badfile.yaml
kubectl get all # verify what's left
# Start over

# Check what went wrong
kubectl describe pod <pod-name>
kubectl logs <pod-name>
kubectl get events
```

## 📊 Summary

| Category | Exam Has | You Need to Learn |
|----------|----------|-------------------|
| Tools | kubectl, vim, basic Linux | kubectl extensively, vim basics |
| Helpers | None | Practice without jq/yq/k9s |
| Docs | kubernetes.io | Navigate docs quickly |
| Time | 2 hours | Speed and accuracy |
| Questions | ~15-20 tasks | All CKA topics |

## 🎯 Action Items

1. **This Week:**
   - Practice without jq/yq/k9s
   - Master kubectl JSONPath
   - Learn essential vim commands

2. **Before Exam:**
   - Take timed practice exams
   - Practice with only kubernetes.io/docs
   - Set up exam environment at home

3. **Exam Day:**
   - Enable kubectl completion first
   - Use imperative commands
   - Manage your time wisely

---

**Remember**: The exam tests your ability to work with Kubernetes in a **real production environment** using **standard tools**. Practice the way you'll be tested!

**Good luck! 🚀**

---

**Back to**: [Main README](../README.md) | [Setup Guide](docs/00-setup-macos.md)
