# Interactive Practice Quizzes

These scripts provide interactive, exam-style practice with automatic validation and scoring.

## 📋 Available Quizzes

| Quiz | Topics | Questions | Time |
|------|--------|-----------|------|
| `network-policies-quiz.sh` | NetworkPolicy creation, pod/namespace selectors, ingress/egress rules | 3 | 15 min |
| `rbac-quiz.sh` | Roles, RoleBindings, ClusterRoles, ServiceAccounts | 2 | 10 min |

## 🚀 How to Use

### 1. Make Scripts Executable

```bash
cd k8s-cka-study-guide/practice-scripts
chmod +x *.sh
```

### 2. Run a Quiz

```bash
./network-policies-quiz.sh
```

### 3. Quiz Format

```
Question 1
══════════════════════════════════════════════════

Create a NetworkPolicy named 'database-access' that:
  - Applies to pods with label: app=database
  - Allows ingress ONLY from pods with label: app=api
  - On port 5432 (TCP)

Work on your solution, then press ENTER when ready to validate...
```

**You do:**
1. Read the question
2. Create your YAML and apply it with `kubectl`
3. Press ENTER when done

**Script does:**
1. Validates your work automatically
2. Shows ✅ or ❌ with feedback
3. Gives you points
4. Shows the correct solution after

### 4. Example Session

```bash
$ ./network-policies-quiz.sh

Question 1
══════════════════════════════════════════════════

Create a NetworkPolicy named 'database-access'...

Work on your solution, then press ENTER when ready to validate...

# You run your commands:
$ cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: database-access
...
EOF

# Then press ENTER

Validating your answer...

✓ NetworkPolicy structure is correct
✅ CORRECT! (+10 points)

Current Score: 10/30

Press ENTER to see the solution...
```

## 📊 Scoring

- Each question is worth 10-15 points
- At the end, you get:
  - Final score (e.g., 25/30)
  - Percentage (e.g., 83%)
  - Grade:
    - 90%+: 🌟 EXCELLENT!
    - 70-89%: 👍 GOOD!
    - <70%: 📚 NEEDS WORK!

## ✅ Features

### What Makes These Great

- ✅ **Real Validation**: Scripts actually check your `kubectl` resources
- ✅ **Instant Feedback**: Know immediately if you're right or wrong
- ✅ **Learn from Mistakes**: See the correct solution after each question
- ✅ **Exam-Like**: Same format and pressure as the real CKA
- ✅ **No Spoilers**: You can't see answers before you try
- ✅ **Auto Cleanup**: Scripts clean up resources automatically

### What Gets Validated

**NetworkPolicy Quiz:**
- NetworkPolicy exists with correct name
- podSelector matches requirements
- Ingress/Egress rules configured correctly
- Ports and protocols are correct
- Namespace selectors are accurate

**RBAC Quiz:**
- Role/ClusterRole exists with correct name
- Verbs include all required permissions
- Resources are correctly specified
- RoleBinding references correct Role
- ServiceAccount/User binding is correct

## 🎯 Tips for Success

### Before You Start

1. ✅ Have Minikube running
2. ✅ For NetworkPolicy quiz: Ensure Calico CNI is installed
3. ✅ Have `kubectl` configured
4. ✅ Clear terminal for best experience

### During the Quiz

1. **Read Carefully**: Questions specify exact names and configurations
2. **Use kubectl Imperative**: Faster than writing YAML from scratch
   ```bash
   kubectl create networkpolicy ... --dry-run=client -o yaml
   ```
3. **Check Your Work**: Before pressing ENTER, verify with:
   ```bash
   kubectl get networkpolicy
   kubectl describe networkpolicy <name>
   ```
4. **Don't Peek**: Try your best before seeing solutions

### After the Quiz

1. **Review Solutions**: Even if you got it right, see alternative approaches
2. **Retry**: Run the quiz again to improve your score
3. **Time Yourself**: Practice under time pressure like the real exam

## 🔧 Troubleshooting

### Quiz Won't Run

```bash
# Make sure script is executable
chmod +x network-policies-quiz.sh

# Run with bash explicitly
bash network-policies-quiz.sh
```

### Validation Fails but You Think You're Right

```bash
# Check exact resource name
kubectl get networkpolicy

# Check the resource details
kubectl get networkpolicy <name> -o yaml

# Make sure you're in the default namespace
kubectl config view --minify | grep namespace
```

### Want to Start Over

```bash
# Clean up manually
kubectl delete networkpolicy --all
kubectl delete pod --all
kubectl delete svc --all

# Re-run the quiz
./network-policies-quiz.sh
```

## 📚 Study Recommendations

### First Time?

1. Read the documentation first
2. Do the manual exercises
3. Then try these quizzes

### Preparing for Exam?

1. Run each quiz 3-4 times
2. Try to get 100% score
3. Time yourself (aim for 5 min per quiz)
4. Practice writing YAML from memory

### Week Before Exam?

1. Do all quizzes daily
2. Focus on questions you get wrong
3. Practice imperative commands for speed

## 🎓 Next Steps

After mastering these quizzes:

1. ✅ Try the full practice exam (coming soon)
2. ✅ Practice on [killer.sh](https://killer.sh)
3. ✅ Time yourself doing all docs exercises
4. ✅ Schedule your CKA exam!

## 📝 Feedback

Want more quizzes? Have suggestions?
- Add issues to the GitHub repo
- Or create your own following the same format!

---

**Good luck with your practice! 🚀**

Remember: The more you practice, the easier the exam becomes!
