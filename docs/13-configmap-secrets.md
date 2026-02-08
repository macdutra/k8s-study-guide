# ConfigMap & Secrets - Configuration Management

Complete guide to ConfigMaps and Secrets for CKA preparation.

## Table of Contents

- [Overview](#overview)
- [ConfigMaps](#configmaps)
- [Secrets](#secrets)
- [Using in Pods](#using-in-pods)
- [Immutable ConfigMaps](#immutable-configmaps)
- [Best Practices](#best-practices)
- [Exam Tips](#exam-tips)

## Overview

ConfigMaps and Secrets store configuration data separately from container images, making applications more portable and secure.

### ConfigMap vs Secret

| Feature | ConfigMap | Secret |
|---------|-----------|--------|
| **Purpose** | Non-sensitive config | Sensitive data |
| **Storage** | Plain text | Base64 encoded |
| **Use Cases** | App config, env vars | Passwords, tokens, keys |
| **Size Limit** | 1MB | 1MB |
| **Encryption** | No | Optional (at rest) |

## ConfigMaps

### Create ConfigMap - Literal Values

```bash
# From literal values
kubectl create configmap app-config \
  --from-literal=app.name=myapp \
  --from-literal=app.env=production

# Verify
kubectl get configmap app-config
kubectl describe configmap app-config
```

### Create ConfigMap - From File

```bash
# Create config file
cat > app.properties <<EOF
database.host=mysql
database.port=3306
database.name=mydb
log.level=INFO
EOF

# Create ConfigMap from file
kubectl create configmap app-config --from-file=app.properties

# Or with custom key
kubectl create configmap app-config --from-file=config=app.properties
```

### Create ConfigMap - From Directory

```bash
# Create directory with config files
mkdir config
echo "host=localhost" > config/database.conf
echo "level=INFO" > config/logging.conf

# Create ConfigMap from directory
kubectl create configmap app-config --from-file=config/

# Each file becomes a key in ConfigMap
kubectl describe configmap app-config
```

### Create ConfigMap - From YAML

```bash
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
data:
  app.name: "myapp"
  app.env: "production"
  database.host: "mysql"
  database.port: "3306"
  # Multi-line values
  app.properties: |
    database.host=mysql
    database.port=3306
    database.name=mydb
    log.level=INFO
EOF
```

## Secrets

### Create Secret - Literal Values

```bash
# From literal values
kubectl create secret generic db-secret \
  --from-literal=username=admin \
  --from-literal=password=secret123

# Verify (values are base64 encoded)
kubectl get secret db-secret -o yaml
```

### Create Secret - From File

```bash
# Create files
echo -n 'admin' > username.txt
echo -n 'secret123' > password.txt

# Create secret from files
kubectl create secret generic db-secret \
  --from-file=username=username.txt \
  --from-file=password=password.txt

# Clean up files (important for security!)
rm username.txt password.txt
```

### Create Secret - TLS

```bash
# Create TLS certificate (self-signed)
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout tls.key \
  -out tls.crt \
  -subj "/CN=example.com"

# Create TLS secret
kubectl create secret tls my-tls-secret \
  --cert=tls.crt \
  --key=tls.key

# Clean up
rm tls.key tls.crt
```

### Create Secret - Docker Registry

```bash
# For private Docker registry
kubectl create secret docker-registry my-registry-secret \
  --docker-server=https://index.docker.io/v1/ \
  --docker-username=myuser \
  --docker-password=mypassword \
  --docker-email=myemail@example.com
```

### Create Secret - From YAML

```bash
# Encode values manually
echo -n 'admin' | base64
# Output: YWRtaW4=

echo -n 'secret123' | base64
# Output: c2VjcmV0MTIz

# Create secret
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Secret
metadata:
  name: db-secret
type: Opaque
data:
  username: YWRtaW4=        # base64 encoded 'admin'
  password: c2VjcmV0MTIz    # base64 encoded 'secret123'
EOF
```

## Using in Pods

### ConfigMap as Environment Variables

```bash
# Create ConfigMap
kubectl create configmap app-config \
  --from-literal=APP_NAME=myapp \
  --from-literal=APP_ENV=production

# Use in pod
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: myapp
spec:
  containers:
  - name: app
    image: nginx
    env:
    - name: APP_NAME
      valueFrom:
        configMapKeyRef:
          name: app-config
          key: APP_NAME
    - name: APP_ENV
      valueFrom:
        configMapKeyRef:
          name: app-config
          key: APP_ENV
EOF

# Verify environment variables
kubectl exec myapp -- env | grep APP_
```

### ConfigMap - All Keys as Env Vars

```bash
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: myapp
spec:
  containers:
  - name: app
    image: nginx
    envFrom:
    - configMapRef:
        name: app-config
EOF

# All keys from ConfigMap become environment variables
kubectl exec myapp -- env
```

### ConfigMap as Volume

```bash
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: myapp
spec:
  containers:
  - name: app
    image: nginx
    volumeMounts:
    - name: config
      mountPath: /etc/config
      readOnly: true
  volumes:
  - name: config
    configMap:
      name: app-config
EOF

# Check mounted files
kubectl exec myapp -- ls /etc/config
kubectl exec myapp -- cat /etc/config/APP_NAME
```

### Secret as Environment Variables

```bash
# Create secret
kubectl create secret generic db-secret \
  --from-literal=username=admin \
  --from-literal=password=secret123

# Use in pod
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: myapp
spec:
  containers:
  - name: app
    image: nginx
    env:
    - name: DB_USERNAME
      valueFrom:
        secretKeyRef:
          name: db-secret
          key: username
    - name: DB_PASSWORD
      valueFrom:
        secretKeyRef:
          name: db-secret
          key: password
EOF

# Verify (values are decoded automatically)
kubectl exec myapp -- env | grep DB_
```

### Secret as Volume

```bash
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: myapp
spec:
  containers:
  - name: app
    image: nginx
    volumeMounts:
    - name: secret
      mountPath: /etc/secret
      readOnly: true
  volumes:
  - name: secret
    secret:
      secretName: db-secret
EOF

# Check mounted files (values are decoded)
kubectl exec myapp -- ls /etc/secret
kubectl exec myapp -- cat /etc/secret/username
kubectl exec myapp -- cat /etc/secret/password
```

## Immutable ConfigMaps

### Why Immutable?

- ✅ **Performance**: No need to watch for changes
- ✅ **Safety**: Prevents accidental updates
- ✅ **Rollout Control**: Forces pod restart on config change

### Create Immutable ConfigMap

```bash
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
data:
  app.name: "myapp"
  app.env: "production"
immutable: true
EOF

# Try to update (will fail)
kubectl patch configmap app-config --patch '{"data":{"app.name":"newapp"}}'
# Error: field is immutable
```

### Update Immutable ConfigMap

```bash
# Must delete and recreate
kubectl delete configmap app-config

cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
data:
  app.name: "newapp"  # Updated value
  app.env: "production"
immutable: true
EOF

# Restart pods to pick up new config
kubectl rollout restart deployment myapp
```

## Best Practices

### ConfigMap Best Practices

```bash
# ✅ Use descriptive names
kubectl create configmap nginx-config ...

# ✅ Organize by environment
kubectl create configmap app-config-prod ...
kubectl create configmap app-config-dev ...

# ✅ Use immutable for production
immutable: true

# ✅ Keep configs small (<1MB)
# ✅ One ConfigMap per application component

# ❌ Don't store secrets in ConfigMaps
```

### Secret Best Practices

```bash
# ✅ Use Secrets for sensitive data only
kubectl create secret generic db-creds ...

# ✅ Enable encryption at rest
# (requires cluster configuration)

# ✅ Use RBAC to control access
kubectl create role secret-reader --verb=get --resource=secrets

# ✅ Avoid committing secrets to Git
# Use sealed-secrets or external secret managers

# ✅ Rotate secrets regularly
kubectl delete secret db-creds
kubectl create secret generic db-creds ...

# ❌ Don't log secret values
# ❌ Don't use secrets in command args (visible in ps)
```

### Security Considerations

```bash
# Secrets are base64 encoded, NOT encrypted by default!
kubectl get secret db-secret -o jsonpath='{.data.password}' | base64 -d
# Shows: secret123

# To actually encrypt secrets at rest:
# 1. Enable encryption in API server
# 2. Use external secret managers (Vault, AWS Secrets Manager)
# 3. Use SealedSecrets or SOPS

# For exam: Know that secrets are base64 encoded only!
```

## Troubleshooting

### ConfigMap Not Found

```bash
# Check if ConfigMap exists
kubectl get configmap

# Check in specific namespace
kubectl get configmap -n production

# Describe pod to see error
kubectl describe pod myapp | grep -i configmap
```

### Secret Not Mounting

```bash
# Check secret exists
kubectl get secret db-secret

# View secret data
kubectl get secret db-secret -o yaml

# Check pod events
kubectl describe pod myapp

# Exec into pod and check mount
kubectl exec myapp -- ls /etc/secret
```

### ConfigMap/Secret Updates Not Reflected

```bash
# For environment variables: Must restart pod
kubectl delete pod myapp

# For volumes: Updates automatically (may take 1-2 minutes)
kubectl exec myapp -- cat /etc/config/APP_NAME

# Force immediate update with immutable ConfigMaps:
# 1. Delete and recreate ConfigMap
# 2. Rollout restart deployment
kubectl rollout restart deployment myapp
```

## Exam Tips

### Essential Commands

```bash
# Create ConfigMap
kubectl create configmap <n> --from-literal=key=value
kubectl create configmap <n> --from-file=file.txt

# Create Secret
kubectl create secret generic <n> --from-literal=key=value
kubectl create secret tls <n> --cert=cert.crt --key=key.key

# View
kubectl get configmap
kubectl get secret
kubectl describe configmap <n>
kubectl describe secret <n>

# Get values
kubectl get configmap <n> -o yaml
kubectl get secret <n> -o jsonpath='{.data.password}' | base64 -d

# Delete
kubectl delete configmap <n>
kubectl delete secret <n>
```

### Quick Creation

```bash
# ConfigMap one-liner
kubectl create cm app-config --from-literal=env=prod -o yaml --dry-run=client | kubectl apply -f -

# Secret one-liner
kubectl create secret generic db-secret --from-literal=pass=secret123 -o yaml --dry-run=client | kubectl apply -f -
```

### Common Exam Scenarios

```bash
# Scenario 1: Create ConfigMap from file
echo "host=localhost" > db.conf
kubectl create configmap db-config --from-file=db.conf

# Scenario 2: Mount secret as volume
kubectl create secret generic api-key --from-literal=key=abc123
# Then create pod with secret volume mount

# Scenario 3: Inject as environment variables
kubectl create configmap app-env --from-literal=ENV=prod
# Then create pod with env from ConfigMap
```

## Quick Reference

### ConfigMap Commands

```bash
kubectl create configmap <n> --from-literal=k=v
kubectl create configmap <n> --from-file=file
kubectl create configmap <n> --from-file=dir/
kubectl get configmap
kubectl describe configmap <n>
kubectl edit configmap <n>
kubectl delete configmap <n>
```

### Secret Commands

```bash
kubectl create secret generic <n> --from-literal=k=v
kubectl create secret generic <n> --from-file=file
kubectl create secret tls <n> --cert=c --key=k
kubectl create secret docker-registry <n> --docker-server=s
kubectl get secret
kubectl describe secret <n>
kubectl delete secret <n>

# Decode secret
kubectl get secret <n> -o jsonpath='{.data.key}' | base64 -d
```

### Usage Patterns

```yaml
# As environment variable
env:
- name: VAR
  valueFrom:
    configMapKeyRef:
      name: my-config
      key: my-key

# All keys as env vars
envFrom:
- configMapRef:
    name: my-config

# As volume
volumes:
- name: config
  configMap:
    name: my-config
```

## Summary

**ConfigMaps** and **Secrets** separate configuration from code:
- ConfigMaps: Non-sensitive configuration
- Secrets: Sensitive data (passwords, keys)
- Both can be used as env vars or volumes
- Immutable ConfigMaps prevent accidental updates

**For the exam:**
- ✅ Create from literal values
- ✅ Create from files
- ✅ Use as environment variables
- ✅ Mount as volumes
- ✅ Decode secret values (base64)

**Remember:**
- Secrets are only base64 encoded (not encrypted by default!)
- ConfigMap/Secret size limit: 1MB
- Updates to volumes reflect automatically (env vars need pod restart)

---

**Back to**: [Main README](../README.md) | [Previous: Helm Basics](12-helm-basics.md) | [Next: kubectl Tips & Tricks](14-kubectl-tips.md)
