# kubectl Cheat Sheet for CKA

Quick reference guide for essential kubectl commands.

## Table of Contents

- [Cluster Management](#cluster-management)
- [Contexts and Namespaces](#contexts-and-namespaces)
- [Creating Resources](#creating-resources)
- [Viewing Resources](#viewing-resources)
- [Editing Resources](#editing-resources)
- [Deleting Resources](#deleting-resources)
- [Debugging](#debugging)
- [Logs](#logs)
- [Advanced](#advanced)

## Cluster Management

```bash
# Display cluster info
kubectl cluster-info
kubectl cluster-info dump

# Display the current cluster
kubectl config current-context

# List all nodes
kubectl get nodes
kubectl get nodes -o wide

# Display node details
kubectl describe node <node-name>

# Show node resource usage
kubectl top node
kubectl top node <node-name>
```

## Contexts and Namespaces

```bash
# List all contexts
kubectl config get-contexts

# Display current context
kubectl config current-context

# Switch context
kubectl config use-context <context-name>

# Set namespace for current context
kubectl config set-context --current --namespace=<namespace>

# List all namespaces
kubectl get namespaces
kubectl get ns

# Create namespace
kubectl create namespace <namespace>
kubectl create ns <namespace>

# Delete namespace
kubectl delete namespace <namespace>
```

## Creating Resources

### Imperative Commands (Fast!)

```bash
# Create a pod
kubectl run <pod-name> --image=<image>
kubectl run nginx --image=nginx
kubectl run busybox --image=busybox --rm -it -- /bin/sh

# Create a deployment
kubectl create deployment <name> --image=<image>
kubectl create deployment nginx --image=nginx --replicas=3

# Create a service
kubectl expose deployment <name> --port=80 --type=ClusterIP
kubectl expose deployment nginx --port=80 --type=NodePort
kubectl expose deployment nginx --port=80 --type=LoadBalancer

# Create a job
kubectl create job <job-name> --image=<image>

# Create a cronjob
kubectl create cronjob <name> --image=<image> --schedule="*/5 * * * *"

# Create configmap
kubectl create configmap <name> --from-literal=key=value
kubectl create configmap <name> --from-file=<file>

# Create secret
kubectl create secret generic <name> --from-literal=password=secret
kubectl create secret docker-registry <name> --docker-server=<server> --docker-username=<user> --docker-password=<pwd>

# Create service account
kubectl create serviceaccount <name>
```

### Declarative (YAML)

```bash
# Apply configuration
kubectl apply -f <file.yaml>
kubectl apply -f <directory>/
kubectl apply -f https://example.com/manifest.yaml

# Create from stdin
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: nginx
spec:
  containers:
  - name: nginx
    image: nginx
EOF

# Dry run (don't actually create)
kubectl apply -f <file.yaml> --dry-run=client
kubectl create deployment nginx --image=nginx --dry-run=client -o yaml

# Generate YAML
kubectl create deployment nginx --image=nginx --dry-run=client -o yaml > deployment.yaml
kubectl run nginx --image=nginx --dry-run=client -o yaml > pod.yaml
```

## Viewing Resources

### Basic Get Commands

```bash
# Get all resources
kubectl get all
kubectl get all -A  # all namespaces
kubectl get all -n <namespace>

# Get specific resources
kubectl get pods
kubectl get po  # short form
kubectl get deployments
kubectl get deploy  # short form
kubectl get services
kubectl get svc  # short form
kubectl get nodes
kubectl get namespaces
kubectl get ns

# Wide output (more details)
kubectl get pods -o wide
kubectl get nodes -o wide

# Watch resources (live update)
kubectl get pods --watch
kubectl get pods -w

# Sort by creation time
kubectl get pods --sort-by=.metadata.creationTimestamp

# Filter by labels
kubectl get pods -l app=nginx
kubectl get pods -l 'app in (nginx,apache)'
kubectl get pods -l app!=nginx
```

### Output Formats

```bash
# YAML output
kubectl get pod <pod-name> -o yaml

# JSON output
kubectl get pod <pod-name> -o json

# Wide output
kubectl get pods -o wide

# Custom columns
kubectl get pods -o custom-columns=NAME:.metadata.name,STATUS:.status.phase

# JSONPath
kubectl get pods -o jsonpath='{.items[*].metadata.name}'
kubectl get pods -o jsonpath='{.items[*].status.podIP}'
kubectl get nodes -o jsonpath='{.items[*].status.addresses[?(@.type=="InternalIP")].address}'

# Show labels
kubectl get pods --show-labels

# Specific label columns
kubectl get pods -L app,version
```

## Editing Resources

```bash
# Edit resource (opens in editor)
kubectl edit pod <pod-name>
kubectl edit deployment <deployment-name>
kubectl edit svc <service-name>

# Scale deployment
kubectl scale deployment <name> --replicas=5

# Set image (rolling update)
kubectl set image deployment/<name> <container>=<image>
kubectl set image deployment/nginx nginx=nginx:1.20

# Rollout commands
kubectl rollout status deployment/<name>
kubectl rollout history deployment/<name>
kubectl rollout undo deployment/<name>
kubectl rollout undo deployment/<name> --to-revision=2

# Patch resource
kubectl patch deployment <name> -p '{"spec":{"replicas":3}}'
kubectl patch svc <name> -p '{"spec":{"type":"NodePort"}}'

# Replace resource
kubectl replace -f <file.yaml>
kubectl replace --force -f <file.yaml>  # delete and recreate

# Annotate
kubectl annotate pod <pod-name> description="my pod"

# Label
kubectl label pod <pod-name> env=prod
kubectl label pod <pod-name> env-  # remove label
```

## Deleting Resources

```bash
# Delete specific resource
kubectl delete pod <pod-name>
kubectl delete deployment <deployment-name>
kubectl delete svc <service-name>

# Delete from file
kubectl delete -f <file.yaml>

# Delete all of a type
kubectl delete pods --all
kubectl delete deployments --all

# Delete by label
kubectl delete pods -l app=nginx

# Force delete (immediate)
kubectl delete pod <pod-name> --force --grace-period=0

# Delete namespace and all resources
kubectl delete namespace <namespace>

# Delete all resources in namespace
kubectl delete all --all -n <namespace>
```

## Debugging

### Describe

```bash
# Describe pod
kubectl describe pod <pod-name>

# Describe deployment
kubectl describe deployment <deployment-name>

# Describe service
kubectl describe svc <service-name>

# Describe node
kubectl describe node <node-name>
```

### Events

```bash
# Get events
kubectl get events
kubectl get events -A
kubectl get events -n <namespace>

# Sort events by time
kubectl get events --sort-by='.lastTimestamp'

# Watch events
kubectl get events --watch
```

### Exec and Port Forward

```bash
# Execute command in pod
kubectl exec <pod-name> -- <command>
kubectl exec nginx -- ls /
kubectl exec nginx -- cat /etc/nginx/nginx.conf

# Interactive shell
kubectl exec -it <pod-name> -- /bin/bash
kubectl exec -it <pod-name> -- /bin/sh

# Exec specific container in multi-container pod
kubectl exec -it <pod-name> -c <container-name> -- /bin/sh

# Port forward
kubectl port-forward pod/<pod-name> 8080:80
kubectl port-forward svc/<service-name> 8080:80
kubectl port-forward deployment/<name> 8080:80

# Port forward in background
kubectl port-forward pod/<pod-name> 8080:80 &
```

### Copy Files

```bash
# Copy from pod to local
kubectl cp <pod-name>:/path/to/file ./local-file
kubectl cp <pod-name>:/var/log/app.log ./app.log

# Copy from local to pod
kubectl cp ./local-file <pod-name>:/path/to/file
kubectl cp ./config.yaml <pod-name>:/etc/config.yaml

# Copy from specific container
kubectl cp <pod-name>:/path/to/file ./local-file -c <container-name>
```

## Logs

```bash
# View pod logs
kubectl logs <pod-name>

# Follow logs (tail -f)
kubectl logs -f <pod-name>
kubectl logs --follow <pod-name>

# Last N lines
kubectl logs --tail=100 <pod-name>

# Since time
kubectl logs --since=1h <pod-name>
kubectl logs --since=5m <pod-name>

# Logs from specific container
kubectl logs <pod-name> -c <container-name>

# Previous container logs (after restart)
kubectl logs <pod-name> --previous
kubectl logs <pod-name> -p

# All containers in pod
kubectl logs <pod-name> --all-containers=true

# Logs from deployment
kubectl logs deployment/<deployment-name>

# Stream logs from multiple pods
kubectl logs -l app=nginx -f
```

## Advanced

### Resource Usage

```bash
# Node resource usage
kubectl top node

# Pod resource usage
kubectl top pod
kubectl top pod -n <namespace>
kubectl top pod --containers  # per-container

# Sort by CPU
kubectl top pod --sort-by=cpu

# Sort by memory
kubectl top pod --sort-by=memory
```

### kubectl explain

```bash
# Explain resource
kubectl explain pod
kubectl explain pod.spec
kubectl explain pod.spec.containers

# Recursive explain
kubectl explain pod.spec --recursive

# Explain specific field
kubectl explain deployment.spec.replicas
```

### Advanced Queries

```bash
# Get pod IPs
kubectl get pods -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.status.podIP}{"\n"}{end}'

# Get node internal IPs
kubectl get nodes -o jsonpath='{.items[*].status.addresses[?(@.type=="InternalIP")].address}'

# Get container images
kubectl get pods -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.spec.containers[*].image}{"\n"}{end}'

# Get pods not running
kubectl get pods --field-selector=status.phase!=Running

# Get pods on specific node
kubectl get pods --field-selector spec.nodeName=<node-name>

# Get resource names only
kubectl get pods -o name
```

### Labels and Selectors

```bash
# Show labels
kubectl get pods --show-labels

# Add label
kubectl label pod <pod-name> env=prod

# Update label
kubectl label pod <pod-name> env=dev --overwrite

# Remove label
kubectl label pod <pod-name> env-

# Select by label
kubectl get pods -l env=prod
kubectl get pods -l env!=prod
kubectl get pods -l 'env in (prod,staging)'
kubectl get pods -l 'env notin (prod,staging)'
kubectl get pods -l env,tier=frontend
```

### Taints and Tolerations

```bash
# Add taint to node
kubectl taint nodes <node-name> key=value:NoSchedule

# Remove taint
kubectl taint nodes <node-name> key=value:NoSchedule-

# View node taints
kubectl describe node <node-name> | grep Taint
```

### Cordon/Drain

```bash
# Cordon node (mark unschedulable)
kubectl cordon <node-name>

# Uncordon node
kubectl uncordon <node-name>

# Drain node (evict all pods)
kubectl drain <node-name> --ignore-daemonsets
kubectl drain <node-name> --force --delete-emptydir-data
```

### API Resources

```bash
# List all API resources
kubectl api-resources

# List with API versions
kubectl api-resources -o wide

# List specific kind
kubectl api-resources | grep deployment

# Short names
kubectl api-resources | grep pod
# pod, po
```

### Chaining Commands

```bash
# Delete all failed pods
kubectl get pods --field-selector=status.phase=Failed -o name | xargs kubectl delete

# Restart all pods in deployment
kubectl rollout restart deployment/<name>

# Get pod and exec into it
kubectl exec -it $(kubectl get pod -l app=nginx -o jsonpath='{.items[0].metadata.name}') -- /bin/sh

# Port forward dynamically
kubectl port-forward $(kubectl get pod -l app=nginx -o jsonpath='{.items[0].metadata.name}') 8080:80
```

## Common Patterns

### Create Temporary Pod for Testing

```bash
# Interactive busybox
kubectl run busybox --image=busybox --rm -it --restart=Never -- /bin/sh

# Test DNS
kubectl run dnsutils --image=gcr.io/kubernetes-e2e-test-images/dnsutils:1.3 --rm -it --restart=Never -- nslookup kubernetes.default

# Test curl
kubectl run curl --image=curlimages/curl --rm -it --restart=Never -- sh
```

### Quick Deployment Pattern

```bash
# Create deployment with 3 replicas
kubectl create deployment nginx --image=nginx --replicas=3

# Expose as NodePort
kubectl expose deployment nginx --port=80 --type=NodePort

# Get service details
kubectl get svc nginx

# ⚠️ MINIKUBE ONLY (not in exam):
minikube service nginx --url

# ✅ EXAM-SAFE: Get service URL
NODE_PORT=$(kubectl get svc nginx -o jsonpath='{.spec.ports[0].nodePort}')
NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[0].address}')
echo "http://$NODE_IP:$NODE_PORT"

# ✅ EXAM-SAFE: Test with port-forward
kubectl port-forward svc/nginx 8080:80
curl http://localhost:8080
# Press Ctrl+C to stop port-forward

# Scale up
kubectl scale deployment nginx --replicas=5

# Update image
kubectl set image deployment/nginx nginx=nginx:1.20

# Check rollout
kubectl rollout status deployment/nginx
```

## Keyboard Shortcuts (macOS)

When using `kubectl edit`:

- **Save and exit**: `:wq` (vim) or `Ctrl+O` then `Ctrl+X` (nano)
- **Quit without saving**: `:q!` (vim) or `Ctrl+X` then `N` (nano)
- **Set default editor**: `export EDITOR=nano` (add to ~/.zshrc)

## Time-Saving Aliases

Add to `~/.zshrc`:

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
```

## Quick Tips for CKA Exam

1. **Use imperative commands** when possible (faster than YAML)
2. **Use --dry-run=client -o yaml** to generate YAML templates
3. **Master kubectl explain** for syntax help
4. **Use aliases** to save time
5. **Use tab completion** (source <(kubectl completion zsh))
6. **Know JSONPath** for complex queries
7. **Practice typing fast** - time is critical

---

**Back to**: [Main README](../README.md) | [Setup Guide](../docs/00-setup-macos.md)
