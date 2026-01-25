# macOS Tips for Kubernetes CKA Study

macOS-specific tips, tricks, and optimizations for CKA preparation.

## Terminal Configuration

### Use iTerm2 (Recommended)

```bash
# Install iTerm2
brew install --cask iterm2

# Benefits:
# - Split panes (Cmd+D horizontal, Cmd+Shift+D vertical)
# - Search (Cmd+F)
# - Better color schemes
# - Tmux integration
```

### Configure zsh (Default on macOS)

Add to `~/.zshrc`:

```bash
# Kubernetes aliases
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

# Context switching
alias kctx='kubectl config use-context'
alias kns='kubectl config set-context --current --namespace'

# Minikube aliases
alias mk='minikube'
alias mks='minikube start'
alias mkstop='minikube stop'
alias mkssh='minikube ssh'
alias mkip='minikube ip'

# Helm aliases
alias h='helm'
alias hi='helm install'
alias hls='helm list'
alias hdel='helm delete'

# Enable kubectl completion
source <(kubectl completion zsh)
complete -F __start_kubectl k

# Enable helm completion
source <(helm completion zsh)

# Reload config
source ~/.zshrc
```

### Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| `Cmd+T` | New tab |
| `Cmd+W` | Close tab |
| `Cmd+K` | Clear screen |
| `Cmd+F` | Search |
| `Cmd+D` | Split pane horizontally (iTerm2) |
| `Cmd+Shift+D` | Split pane vertically (iTerm2) |
| `Cmd+[` / `Cmd+]` | Switch between panes |
| `Ctrl+A` | Move to beginning of line |
| `Ctrl+E` | Move to end of line |
| `Ctrl+U` | Delete from cursor to beginning |
| `Ctrl+K` | Delete from cursor to end |
| `Ctrl+R` | Search command history |
| `Option+Click` | Move cursor (iTerm2) |

## Docker Desktop Optimization

### Recommended Settings

1. **Open Docker Desktop → Preferences**

2. **Resources**:
   ```
   CPUs: 4 (or more if available)
   Memory: 8 GB (minimum)
   Swap: 2 GB
   Disk image size: 64 GB
   ```

3. **Advanced**:
   ```
   ✅ Enable VirtioFS accelerated directory sharing
   ✅ Use Rosetta for x86/amd64 emulation (Apple Silicon)
   ```

4. **Kubernetes** (Optional - we use Minikube):
   ```
   ❌ Disable built-in Kubernetes (conflicts with Minikube)
   ```

### Docker Performance Tips

```bash
# Clean up unused containers, images, volumes
docker system prune -a

# Check Docker disk usage
docker system df

# Remove specific items
docker container prune
docker image prune -a
docker volume prune
```

## Minikube Optimization

### Best Driver for macOS

```bash
# Intel Macs: Use hyperkit or docker
minikube start --driver=hyperkit  # Best performance
minikube start --driver=docker    # Most compatible

# Apple Silicon (M1/M2/M3): Use docker
minikube start --driver=docker    # Only reliable option

# Set as default
minikube config set driver docker
```

### Performance Tuning

```bash
# Increase resources
minikube config set cpus 4
minikube config set memory 8192
minikube config set disk-size 20g

# View configuration
minikube config view

# Start with specific settings
minikube start \
  --cpus=4 \
  --memory=8192 \
  --disk-size=20g \
  --driver=docker
```

### Quick Commands

```bash
# Start/Stop without deleting
minikube start
minikube stop

# Pause/Unpause (saves resources)
minikube pause
minikube unpause

# Quick restart
minikube delete && minikube start

# Multiple profiles
minikube start -p profile1
minikube start -p profile2
minikube profile list
minikube profile profile1
```

## Apple Silicon (M1/M2/M3) Specific

### Architecture Considerations

```bash
# Some images may need platform specification
docker pull --platform linux/amd64 <image>

# Or in Kubernetes manifests, most images work fine
# but if you encounter issues:
kubectl run test --image=nginx:alpine  # Usually works
kubectl run test --image=amd64/nginx:alpine  # If needed
```

### Rosetta 2 (for x86 compatibility)

```bash
# Install Rosetta 2 if not already
softwareupdate --install-rosetta

# Enable in Docker Desktop:
# Preferences → General → Use Rosetta for x86/amd64 emulation
```

### Known Issues and Workarounds

```bash
# Issue: Some images crash on ARM
# Solution: Use multi-arch images or specify platform

# Issue: VPN interference
# Solution: Disconnect VPN or configure split tunneling

# Issue: Resource limits
# Solution: Close other apps, increase Docker limits
```

## File System and Paths

### Important Directories

```bash
# Minikube files
~/.minikube/

# kubectl config
~/.kube/config

# Docker Desktop
~/Library/Containers/com.docker.docker/

# Homebrew
/opt/homebrew/  # Apple Silicon
/usr/local/     # Intel
```

### File Watching (macOS specific)

```bash
# macOS has file descriptor limits
# Increase for development

# Check current limit
ulimit -n

# Increase temporarily
ulimit -n 65536

# Increase permanently (add to ~/.zshrc)
echo 'ulimit -n 65536' >> ~/.zshrc
```

## Clipboard Integration

### Copy kubectl output to clipboard

```bash
# Install pbcopy (built-in on macOS)
kubectl get pods -o yaml | pbcopy

# Paste from clipboard
pbpaste | kubectl apply -f -

# Useful aliases (add to ~/.zshrc)
alias k2clip='kubectl get -o yaml | pbcopy'
alias clipapply='pbpaste | kubectl apply -f -'
```

## VS Code Integration

### Install VS Code

```bash
# Install via Homebrew
brew install --cask visual-studio-code

# Add to PATH for 'code' command
# Add to ~/.zshrc:
export PATH="$PATH:/Applications/Visual Studio Code.app/Contents/Resources/app/bin"
```

### Recommended Extensions

```bash
# Kubernetes
code --install-extension ms-kubernetes-tools.vscode-kubernetes-tools

# YAML
code --install-extension redhat.vscode-yaml

# Docker
code --install-extension ms-azuretools.vscode-docker

# GitLens
code --install-extension eamodio.gitlens

# Remote - SSH (for SSH to minikube)
code --install-extension ms-vscode-remote.remote-ssh
```

### VS Code Settings for Kubernetes

```json
{
  "yaml.schemas": {
    "kubernetes": "*.yaml"
  },
  "yaml.customTags": [
    "!And",
    "!If",
    "!Not",
    "!Equals",
    "!Or",
    "!FindInMap sequence",
    "!Base64",
    "!Cidr",
    "!Ref",
    "!Sub",
    "!GetAtt",
    "!GetAZs",
    "!ImportValue",
    "!Select",
    "!Split",
    "!Join sequence"
  ],
  "files.associations": {
    "*.yaml": "yaml",
    "*.yml": "yaml"
  }
}
```

## Network Configuration

### VPN Issues

```bash
# If VPN blocks minikube:

# Option 1: Disconnect VPN temporarily

# Option 2: Configure split tunneling in VPN client

# Option 3: Use minikube tunnel
minikube tunnel

# Option 4: Configure static IP
minikube start --static-ip=192.168.99.99
```

### DNS Configuration

```bash
# Add custom DNS to /etc/hosts
echo "$(minikube ip) myapp.local" | sudo tee -a /etc/hosts

# Test
curl http://myapp.local

# Clean up when done
sudo sed -i '' '/myapp.local/d' /etc/hosts
```

## Monitoring and Debugging

### Activity Monitor

```bash
# Open Activity Monitor
open -a "Activity Monitor"

# Watch for:
# - Docker Desktop
# - com.docker.hyperkit (if using hyperkit)
# - minikube processes
```

### Resource Usage

```bash
# Docker stats
docker stats

# Minikube resource usage
minikube ssh "top -bn1 | head -20"

# Overall system
istats  # Install: brew install iStats
```

## Automation Scripts

### Quick Start Script

```bash
# Create ~/k8s-start.sh
cat > ~/k8s-start.sh << 'EOF'
#!/bin/bash
echo "🚀 Starting Kubernetes environment..."

# Check Docker
if ! docker ps &>/dev/null; then
    echo "⚠️  Starting Docker Desktop..."
    open -a Docker
    echo "⏳ Waiting for Docker..."
    while ! docker ps &>/dev/null; do sleep 1; done
    echo "✅ Docker running"
fi

# Start Minikube
if ! minikube status &>/dev/null; then
    echo "🎯 Starting Minikube..."
    minikube start --cpus=4 --memory=8192
else
    echo "✅ Minikube already running"
fi

# Enable addons
minikube addons enable metrics-server
minikube addons enable ingress

# Display info
kubectl cluster-info
kubectl get nodes

echo "✅ Environment ready!"
EOF

chmod +x ~/k8s-start.sh
```

### Quick Stop Script

```bash
# Create ~/k8s-stop.sh
cat > ~/k8s-stop.sh << 'EOF'
#!/bin/bash
echo "🛑 Stopping Kubernetes environment..."

# Pause Minikube
minikube pause

echo "✅ Environment paused (use 'minikube unpause' to resume)"
EOF

chmod +x ~/k8s-stop.sh
```

## Troubleshooting

### Common Issues

#### 1. "Cannot connect to Docker daemon"

```bash
# Solution 1: Start Docker Desktop
open -a Docker

# Solution 2: Use Colima instead
brew install colima
colima start
```

#### 2. "Minikube won't start"

```bash
# Solution 1: Delete and recreate
minikube delete
minikube start

# Solution 2: Try different driver
minikube start --driver=hyperkit  # Intel
minikube start --driver=docker    # All Macs
```

#### 3. "Out of memory"

```bash
# Solution 1: Increase Docker resources
# Docker Desktop → Preferences → Resources

# Solution 2: Reduce Minikube allocation
minikube start --memory=4096 --cpus=2

# Solution 3: Close other applications
```

#### 4. "Port already in use"

```bash
# Find process using port
lsof -ti :8080

# Kill process
kill -9 $(lsof -ti :8080)

# Or use different port
kubectl port-forward pod/nginx 8081:80
```

### Log Locations

```bash
# Docker logs
~/Library/Containers/com.docker.docker/Data/log/

# Minikube logs
minikube logs
~/.minikube/logs/

# kubectl verbose output
kubectl get pods -v=9
```

## Performance Tips

1. **Use SSD**: Ensure Docker and Minikube use SSD storage
2. **Close unused apps**: Free up RAM and CPU
3. **Use multiple terminal tabs**: One for commands, one for watching
4. **Enable tab completion**: Save typing time
5. **Use aliases**: Reduce keystrokes
6. **Clean up regularly**: Remove unused containers and images

## Study Environment Setup

### Ideal Setup

```
┌─────────────────────────────────────┐
│  Terminal (iTerm2)                  │
│  ┌─────────┬─────────┬─────────┐   │
│  │ kubectl │  logs   │  watch  │   │
│  │ commands│         │ -n 1    │   │
│  │         │         │ kubectl │   │
│  │         │         │ get pods│   │
│  └─────────┴─────────┴─────────┘   │
└─────────────────────────────────────┘

┌─────────────────────────────────────┐
│  VS Code                            │
│  - YAML files                       │
│  - Kubernetes extension             │
│  - Integrated terminal              │
└─────────────────────────────────────┘

┌─────────────────────────────────────┐
│  Browser                            │
│  - Kubernetes docs                  │
│  - Minikube dashboard               │
└─────────────────────────────────────┘
```

### Multiple Monitors

If you have multiple monitors:
- **Monitor 1**: Terminal with split panes
- **Monitor 2**: VS Code for editing YAML
- **Monitor 3** (optional): Browser with docs

## Exam Day macOS Checklist

- [ ] Close all unnecessary applications
- [ ] Disable notifications (Do Not Disturb)
- [ ] Ensure stable internet connection
- [ ] Fully charge laptop (or plug in)
- [ ] Clean up Docker and Minikube
- [ ] Test webcam and microphone
- [ ] Clear /etc/hosts file
- [ ] Have water and snacks ready
- [ ] Set up quiet workspace

```bash
# Enable Do Not Disturb
# System Preferences → Notifications → Do Not Disturb

# Clean up
docker system prune -a
minikube delete --all
minikube start --cpus=4 --memory=8192

# Test setup
kubectl cluster-info
kubectl get nodes
```

---

**Back to**: [Main README](../README.md) | [Setup Guide](../docs/00-setup-macos.md)
