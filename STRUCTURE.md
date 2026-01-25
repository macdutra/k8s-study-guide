# Repository Structure

```
k8s-cka-study-guide/
│
├── README.md                          # Main documentation
├── LICENSE                            # MIT License
├── CONTRIBUTING.md                    # Contribution guidelines
│
├── docs/                              # Detailed topic documentation
│   ├── 00-setup-macos.md             # macOS environment setup
│   ├── 01-hpa-autoscaling.md         # HPA deep dive
│   ├── 02-ingress-networking.md      # Ingress and networking (to be created)
│   ├── 03-resource-management.md     # Resource requests/limits (to be created)
│   ├── 04-storage-management.md      # PV, PVC, StorageClass (to be created)
│   ├── 05-network-policies.md        # NetworkPolicy guide (to be created)
│   ├── 06-sidecar-patterns.md        # Multi-container pods (to be created)
│   ├── 07-priority-class.md          # Pod scheduling priority (to be created)
│   ├── 08-gateway-api.md             # Gateway API tutorial (to be created)
│   ├── 09-etcd-troubleshooting.md    # Control plane debugging (to be created)
│   ├── 10-crd-management.md          # Custom Resources (to be created)
│   ├── 11-helm-package-management.md # Helm guide (to be created)
│   ├── 12-argocd-gitops.md           # ArgoCD tutorial (to be created)
│   ├── 13-configmap-immutable.md     # ConfigMap advanced (to be created)
│   └── 14-linux-networking.md        # Linux system admin (to be created)
│
├── scripts/                           # Automation scripts
│   ├── setup-macos.sh                # Automated setup for macOS
│   ├── practice-exam-beginner.sh     # Beginner practice test (to be created)
│   ├── practice-exam-intermediate.sh # Intermediate practice (to be created)
│   ├── practice-exam-advanced.sh     # Advanced practice (to be created)
│   └── practice-exam-full.sh         # Full CKA simulation (to be created)
│
├── examples/                          # Practice exams and examples
│   ├── practice-exam-beginner.md     # 8 tasks, 60 minutes (to be created)
│   ├── practice-exam-intermediate.md # 12 tasks, 90 minutes (to be created)
│   ├── practice-exam-advanced.md     # 16 tasks, 120 minutes (to be created)
│   ├── practice-exam-full.md         # Complete CKA simulation
│   ├── hpa-examples.yaml             # HPA YAML examples (to be created)
│   ├── ingress-examples.yaml         # Ingress examples (to be created)
│   ├── storage-examples.yaml         # Storage examples (to be created)
│   └── networkpolicy-examples.yaml   # NetworkPolicy examples (to be created)
│
└── cheat-sheets/                      # Quick reference guides
    ├── kubectl-cheatsheet.md         # Essential kubectl commands
    ├── yaml-templates.md             # Common YAML templates (to be created)
    ├── troubleshooting.md            # Common issues and solutions (to be created)
    └── macos-tips.md                 # macOS-specific tips
```

## Current Status

### ✅ Completed Files

- [x] README.md - Main documentation with study path
- [x] LICENSE - MIT License
- [x] CONTRIBUTING.md - Contribution guidelines
- [x] docs/00-setup-macos.md - Complete macOS setup guide
- [x] docs/01-hpa-autoscaling.md - HPA deep dive with examples
- [x] scripts/setup-macos.sh - Automated installation script
- [x] examples/practice-exam-full.md - Complete 16-task practice exam
- [x] cheat-sheets/kubectl-cheatsheet.md - Comprehensive kubectl reference
- [x] cheat-sheets/macos-tips.md - macOS optimization guide

### 📝 To Be Created

The following files would complete the study guide:

#### Documentation (docs/)
- [ ] 02-ingress-networking.md
- [ ] 03-resource-management.md
- [ ] 04-storage-management.md
- [ ] 05-network-policies.md
- [ ] 06-sidecar-patterns.md
- [ ] 07-priority-class.md
- [ ] 08-gateway-api.md
- [ ] 09-etcd-troubleshooting.md
- [ ] 10-crd-management.md
- [ ] 11-helm-package-management.md
- [ ] 12-argocd-gitops.md
- [ ] 13-configmap-immutable.md
- [ ] 14-linux-networking.md

#### Scripts (scripts/)
- [ ] practice-exam-beginner.sh
- [ ] practice-exam-intermediate.sh
- [ ] practice-exam-advanced.sh
- [ ] practice-exam-full.sh

#### Examples (examples/)
- [ ] practice-exam-beginner.md
- [ ] practice-exam-intermediate.md
- [ ] practice-exam-advanced.md
- [ ] hpa-examples.yaml
- [ ] ingress-examples.yaml
- [ ] storage-examples.yaml
- [ ] networkpolicy-examples.yaml

#### Cheat Sheets (cheat-sheets/)
- [ ] yaml-templates.md
- [ ] troubleshooting.md

## Getting Started

1. Clone the repository
2. Run the setup script:
   ```bash
   chmod +x scripts/setup-macos.sh
   ./scripts/setup-macos.sh
   ```
3. Follow the study path in README.md
4. Practice with the exam in examples/practice-exam-full.md

## File Naming Convention

- **Documentation**: `##-topic-name.md` (numbered for order)
- **Scripts**: `descriptive-name.sh` (executable)
- **Examples**: `practice-exam-level.md` or `resource-examples.yaml`
- **Cheat Sheets**: `topic-cheatsheet.md`

## Documentation Standards

Each documentation file should include:

1. **Title and Overview**
2. **Table of Contents**
3. **Prerequisites**
4. **Step-by-step Instructions**
5. **Hands-on Examples**
6. **Troubleshooting Section**
7. **Exam Tips**
8. **Practice Questions**
9. **Navigation Links** (back to README)

## Script Standards

Each script should:

1. Include shebang (`#!/bin/bash`)
2. Have clear comments
3. Use error handling (`set -e`)
4. Provide user feedback
5. Be tested on macOS
6. Include usage instructions

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines on:
- Adding new documentation
- Creating practice exams
- Improving existing content
- Reporting issues

---

**Back to**: [Main README](README.md)
