# Cluster & Application Troubleshooting

Complete troubleshooting guide for debugging Kubernetes clusters, nodes, pods, and services. **30% of the CKA exam!**

## Table of Contents

- [Overview](#overview)
- [Pod Troubleshooting](#pod-troubleshooting)
- [Node Troubleshooting](#node-troubleshooting)
- [Service Troubleshooting](#service-troubleshooting)
- [DNS Troubleshooting](#dns-troubleshooting)
- [Control Plane Troubleshooting](#control-plane-troubleshooting)
- [Network Troubleshooting](#network-troubleshooting)
- [Storage Troubleshooting](#storage-troubleshooting)
- [Exam Tips](#exam-tips)

## Overview

Troubleshooting is **30% of the CKA exam** - the largest section!

### Troubleshooting Workflow

```
1. Identify the problem
   ↓
2. Gather information (describe, logs, events)
   ↓
3. Form hypothesis
   ↓
4. Test fix
   ↓
5. Verify solution
```

### Essential Commands

```bash
# The Big 5 troubleshooting commands
kubectl get <resource>           # Check status
kubectl describe <resource>      # Detailed info + events
kubectl logs <pod>              # Container logs
kubectl exec -it <pod> -- sh    # Get inside container
kubectl get events              # Cluster events
```

## Pod Troubleshooting

### Common Pod States

| State | Meaning | Common Causes |
|-------|---------|---------------|
| Pending | Not scheduled | Resource constraints, node selectors |
| ImagePullBackOff | Can't pull image | Wrong image name, auth |
| CrashLoopBackOff | Container keeps crashing | App error, missing deps |
| Error | Container exited with error | App failure |
| OOMKilled | Out of memory | Memory limit too low |
| RunContainerError | Can't start container | Volume mount issues |

### Pod Stuck in Pending

```bash
# Check pod status
kubectl get pod <pod-name>

# Get detailed info
kubectl describe pod <pod-name>

# Look for:
# Events:
#   Warning  FailedScheduling  pod has unbound immediate PersistentVolumeClaims
#   Warning  FailedScheduling  0/1 nodes available: insufficient memory

# Common fixes:

# Fix 1: Insufficient resources
kubectl describe nodes  # Check available resources
kubectl top nodes       # See current usage

# Fix 2: PVC not bound
kubectl get pvc
kubectl describe pvc <pvc-name>

# Fix 3: Node selector doesn't match
kubectl get pod <pod> -o yaml | grep nodeSelector
kubectl get nodes --show-labels
```

### ImagePullBackOff

```bash
# Check error
kubectl describe pod <pod-name>

# Events:
#   Warning  Failed  Failed to pull image "ngin:latest": rpc error: code = Unknown

# Common issues:

# Fix 1: Typo in image name
kubectl edit pod <pod-name>
# Change: image: ngin → image: nginx

# Fix 2: Private registry (need secret)
kubectl create secret docker-registry regcred \
  --docker-server=<registry> \
  --docker-username=<user> \
  --docker-password=<pass>

kubectl patch pod <pod> -p '{"spec":{"imagePullSecrets":[{"name":"regcred"}]}}'

# Fix 3: Image doesn't exist
docker pull nginx:1.99  # Test if image exists
```

### CrashLoopBackOff

```bash
# Check logs
kubectl logs <pod-name>
kubectl logs <pod-name> --previous  # Logs from last crash

# Common causes:

# Fix 1: Application error
kubectl logs <pod> | tail -20  # See error message
# Fix application code

# Fix 2: Missing environment variable
kubectl describe pod <pod> | grep -A 10 Environment
kubectl set env deployment/<deploy> KEY=value

# Fix 3: Health check failing
kubectl describe pod <pod> | grep -A 5 Liveness
# Adjust liveness probe or fix app

# Fix 4: Command not found
kubectl get pod <pod> -o yaml | grep command
# Check if command exists in container
kubectl run test --image=<same-image> -it --rm -- sh
# which <command>
```

### OOMKilled (Out of Memory)

```bash
# Check if OOMKilled
kubectl describe pod <pod> | grep -i oom
# Last State: Terminated
#   Reason: OOMKilled

# Check current limits
kubectl get pod <pod> -o yaml | grep -A 5 resources

# Fix: Increase memory limit
kubectl set resources deployment <deploy> \
  --limits=memory=512Mi \
  --requests=memory=256Mi

# Monitor memory usage
kubectl top pod <pod>
```

### Container Won't Start

```bash
# Check logs
kubectl logs <pod>

# If no logs, check events
kubectl describe pod <pod>

# Common issues:

# Fix 1: Volume mount issue
# Events: Error: failed to create containerd task: failed to create shim task
kubectl get pod <pod> -o yaml | grep -A 10 volumeMounts
# Check if ConfigMap/Secret exists
kubectl get cm,secret

# Fix 2: Wrong command
kubectl get pod <pod> -o jsonpath='{.spec.containers[*].command}'
kubectl exec <pod> -- which <command>  # Check if exists

# Fix 3: Container user permissions
kubectl exec <pod> -- id  # Check user
kubectl exec <pod> -- ls -la /path  # Check file permissions
```

## Node Troubleshooting

### Node in NotReady State

```bash
# Check nodes
kubectl get nodes

# NAME    STATUS     ROLES    AGE   VERSION
# node1   NotReady   <none>   5d    v1.28.0

# Get detailed info
kubectl describe node node1

# Look for:
# Conditions:
#   Ready  False  Tue, 26 Jan 2026  kubelet stopped posting node status

# Common fixes:

# Fix 1: kubelet not running
ssh node1
systemctl status kubelet

# If not running:
systemctl start kubelet
systemctl enable kubelet

# Fix 2: kubelet errors
journalctl -u kubelet -f
journalctl -u kubelet --since "10 minutes ago"

# Fix 3: Network plugin issue
kubectl get pods -n kube-system | grep -E "weave|calico|flannel"
kubectl logs -n kube-system <network-pod>

# Fix 4: Disk pressure
df -h  # Check disk space
docker system prune -a  # Clean up
```

### Kubelet Not Starting

```bash
# Check kubelet status
systemctl status kubelet

# View logs
journalctl -u kubelet -n 50

# Common errors:

# Error 1: Config file issue
# Fix:
sudo vi /var/lib/kubelet/config.yaml
systemctl restart kubelet

# Error 2: Certificate issue
# Fix:
ls -la /var/lib/kubelet/pki/
sudo kubeadm token create --print-join-command

# Error 3: CRI (containerd/docker) not running
systemctl status containerd
systemctl start containerd
systemctl restart kubelet
```

### Node Resource Issues

```bash
# Check resource usage
kubectl top nodes
kubectl describe node <node>

# Check disk
ssh node1
df -h
du -sh /var/lib/docker/*
du -sh /var/lib/containerd/*

# Clean up
docker system prune -a
crictl rmi --prune

# Check memory
free -h
top

# Check processes
ps aux | head
```

## Service Troubleshooting

### Service Not Accessible

```bash
# Check service
kubectl get svc <service>

# Check endpoints
kubectl get endpoints <service>

# If endpoints is <none>:
# Problem: Service selector doesn't match pod labels

# Fix:
kubectl get svc <service> -o yaml | grep -A 5 selector
kubectl get pods --show-labels

# Update service selector
kubectl edit svc <service>
# Match selector to pod labels
```

### Can't Access Service from Pod

```bash
# Test from within cluster
kubectl run test --image=busybox -it --rm -- sh

# Inside pod:
wget -O- http://<service-name>
nslookup <service-name>

# If DNS fails:
# Check CoreDNS
kubectl get pods -n kube-system -l k8s-app=kube-dns
kubectl logs -n kube-system -l k8s-app=kube-dns

# If connection refused:
# Check service port
kubectl get svc <service>
kubectl describe svc <service>

# Check pod port
kubectl get pod <pod> -o yaml | grep containerPort
```

### NodePort Not Working

```bash
# Get NodePort
kubectl get svc <service>
# PORT(S): 80:30123/TCP

# Get Node IP
kubectl get nodes -o wide

# Test from outside
curl http://<node-ip>:30123

# If fails:
# Check firewall
sudo iptables -L
sudo ufw status

# Check kube-proxy
kubectl get pods -n kube-system -l k8s-app=kube-proxy
kubectl logs -n kube-system -l k8s-app=kube-proxy
```

## DNS Troubleshooting

### DNS Not Resolving

```bash
# Test DNS
kubectl run test --image=busybox -it --rm -- nslookup kubernetes

# Expected output:
# Server:    10.96.0.10
# Address 1: 10.96.0.10 kube-dns.kube-system.svc.cluster.local
# Name:      kubernetes
# Address 1: 10.96.0.1 kubernetes.default.svc.cluster.local

# If fails:

# Fix 1: Check CoreDNS pods
kubectl get pods -n kube-system -l k8s-app=kube-dns
kubectl logs -n kube-system <coredns-pod>

# Fix 2: Check CoreDNS service
kubectl get svc -n kube-system kube-dns
kubectl describe svc -n kube-system kube-dns

# Fix 3: Check ConfigMap
kubectl get cm -n kube-system coredns -o yaml

# Fix 4: Restart CoreDNS
kubectl rollout restart deployment coredns -n kube-system
```

### Pod Can't Resolve External DNS

```bash
# Test
kubectl run test --image=busybox -it --rm -- nslookup google.com

# If fails:

# Check CoreDNS forward configuration
kubectl get cm -n kube-system coredns -o yaml

# Should have:
# forward . /etc/resolv.conf

# Check node's resolv.conf
ssh node1
cat /etc/resolv.conf
```

## Control Plane Troubleshooting

### API Server Not Responding

```bash
# Check API server pod
kubectl get pods -n kube-system | grep apiserver

# If kubectl doesn't work:
ssh controlplane
docker ps | grep apiserver
docker logs <container-id>

# Check manifest
cat /etc/kubernetes/manifests/kube-apiserver.yaml

# Common fixes:
# 1. Fix YAML syntax errors
# 2. Check certificate paths
# 3. Restart kubelet
systemctl restart kubelet
```

### Scheduler Not Working

```bash
# Pods stuck in Pending
kubectl get pods

# Check scheduler
kubectl get pods -n kube-system | grep scheduler
kubectl logs -n kube-system kube-scheduler-controlplane

# Restart scheduler
ssh controlplane
docker ps | grep scheduler
docker restart <scheduler-container>
```

### Controller Manager Issues

```bash
# Check controller manager
kubectl get pods -n kube-system | grep controller-manager
kubectl logs -n kube-system kube-controller-manager-controlplane

# Common issue: Resources not created
# (e.g., endpoints not updating)

# Restart
ssh controlplane
docker restart <controller-manager-container>
```

## Network Troubleshooting

### Pod-to-Pod Communication Failing

```bash
# Get pod IPs
kubectl get pods -o wide

# Test connectivity
kubectl exec <pod1> -- ping <pod2-ip>

# If fails:

# Fix 1: Check NetworkPolicy
kubectl get networkpolicy
kubectl describe networkpolicy <policy>

# Fix 2: Check CNI plugin
kubectl get pods -n kube-system | grep -E "weave|calico|flannel"
kubectl logs -n kube-system <cni-pod>

# Fix 3: Check routes
kubectl exec <pod> -- ip route
```

### Network Plugin Not Running

```bash
# Check CNI pods
kubectl get pods -n kube-system

# If CNI pods missing or failing:

# Check CNI config
ls /etc/cni/net.d/
cat /etc/cni/net.d/*.conf

# Reinstall CNI (example for Weave)
kubectl apply -f "https://cloud.weave.works/k8s/net?k8s-version=$(kubectl version | base64 | tr -d '\n')"
```

## Storage Troubleshooting

### PVC Stuck in Pending

```bash
# Check PVC
kubectl get pvc

# Describe
kubectl describe pvc <pvc-name>

# Events:
#   Warning  ProvisioningFailed  no volume plugin found

# Common fixes:

# Fix 1: No StorageClass
kubectl get storageclass
# Create one if missing

# Fix 2: No PV available
kubectl get pv
# Create PV or use dynamic provisioning

# Fix 3: Wrong StorageClass
kubectl patch pvc <pvc> -p '{"spec":{"storageClassName":"<correct-class>"}}'
```

### Pod Can't Mount Volume

```bash
# Check error
kubectl describe pod <pod>

# Events:
#   Warning  FailedMount  Unable to attach or mount volumes

# Common fixes:

# Fix 1: PVC doesn't exist
kubectl get pvc
kubectl create -f pvc.yaml

# Fix 2: PVC in wrong namespace
kubectl get pvc -n <namespace>

# Fix 3: Volume in use by another pod
kubectl get pods -o wide | grep <pvc-name>
kubectl delete pod <other-pod>
```

## Exam Tips

### Troubleshooting Workflow for Exam

**Step 1: Identify (30 seconds)**
```bash
kubectl get <resource>
```

**Step 2: Describe (1 minute)**
```bash
kubectl describe <resource> <name>
# Look at Events section at bottom
```

**Step 3: Logs (1 minute)**
```bash
kubectl logs <pod>
kubectl logs <pod> --previous
```

**Step 4: Fix (2-3 minutes)**
```bash
kubectl edit <resource>
# or
kubectl delete <resource>
kubectl apply -f fixed.yaml
```

**Step 5: Verify (30 seconds)**
```bash
kubectl get <resource>
kubectl describe <resource>
```

### Most Common Exam Scenarios

**Scenario 1: Pod won't start**
```bash
kubectl get pod <pod>      # Check state
kubectl describe pod <pod>  # Check events
kubectl logs <pod>         # Check logs
# Fix based on error
```

**Scenario 2: Node NotReady**
```bash
kubectl describe node <node>  # Check conditions
ssh <node>
systemctl status kubelet
journalctl -u kubelet
systemctl restart kubelet
```

**Scenario 3: Service not working**
```bash
kubectl get svc <svc>
kubectl get endpoints <svc>  # Should have IPs
kubectl describe svc <svc>   # Check selector
# Fix selector to match pod labels
```

### Essential Troubleshooting Commands

```bash
# Pod debugging
kubectl get pods
kubectl describe pod <pod>
kubectl logs <pod>
kubectl logs <pod> --previous
kubectl exec -it <pod> -- sh

# Node debugging  
kubectl get nodes
kubectl describe node <node>
kubectl top nodes

# Service debugging
kubectl get svc
kubectl get endpoints
kubectl describe svc <svc>

# Events
kubectl get events --sort-by='.lastTimestamp'
kubectl get events -A --sort-by='.lastTimestamp'

# DNS testing
kubectl run test --image=busybox -it --rm -- nslookup <service>

# Network testing
kubectl run test --image=nicolaka/netshoot -it --rm -- bash
```

### Time-Saving Tips

1. **Always check events first**
   ```bash
   kubectl describe <resource> | grep -A 10 Events
   ```

2. **Use short forms**
   ```bash
   kubectl get po  # pods
   kubectl get svc # services
   kubectl get no  # nodes
   ```

3. **Quick logs**
   ```bash
   kubectl logs <pod> --tail=20
   kubectl logs <pod> --previous --tail=20
   ```

4. **Fast pod creation for testing**
   ```bash
   kubectl run test --image=busybox -it --rm -- sh
   ```

## Quick Reference

```bash
# Pod Issues
kubectl get pod <pod>
kubectl describe pod <pod>
kubectl logs <pod>
kubectl logs <pod> --previous
kubectl exec -it <pod> -- sh

# Node Issues
kubectl describe node <node>
ssh <node>
systemctl status kubelet
journalctl -u kubelet

# Service Issues
kubectl get svc <svc>
kubectl get endpoints <svc>
kubectl describe svc <svc>

# DNS Issues
kubectl get pods -n kube-system -l k8s-app=kube-dns
kubectl logs -n kube-system <coredns-pod>
kubectl run test --image=busybox -it --rm -- nslookup <service>

# Events
kubectl get events --sort-by='.lastTimestamp'
```

---

**Troubleshooting is 30% of the exam. Practice these scenarios until they're second nature!**

---

**Back to**: [Main README](../README.md) | [Previous: RBAC](10-rbac.md) | [Next: Helm Basics](12-helm-basics.md)
