# Team Development Guide – Red & Blue Teams

## 📋 Project Overview
This document defines the development workflow, repository structure, and responsibilities for our **two-team project structure**.  
Each team has a dedicated area of the codebase and its own branch to work within.

---

## 🏗 Repository Structure

```plaintext
project-repo/
├── README.md
├── .gitignore
├── .github/
│   └── CODEOWNERS
├── Core_Entities/          # 🔴 TEAM RED
│   ├── src/
│   ├── tests/
│   ├── docs/
│   └── README.md
├── Enterprise_Division/    # 🔵 TEAM BLUE
│   ├── src/
│   ├── tests/
│   ├── docs/
│   └── README.md

```

---

## 🔴 Team Red – Core Entities
- **Folder:** `Core_Entities/`  
- **Branch:** `team-red`  
- **Responsibility:** Core entity-related functionality  

### Workflow
1. **Initial Setup**
   ```bash
   git clone https://github.com/[owner]/[repo-name].git
   cd [repo-name]
   git checkout team-red
   git pull origin team-red
   ```

2. **Create Feature Branch**
   ```bash
   git checkout -b team-red-m
   ```
  

3. **Work on Your Code**
   - Modify files **only inside** `Core_Entities/`  
   - Write tests in `Core_Entities/tests/`  
   - Update docs in `Core_Entities/docs/`  

4. **Commit & Push**
   ```bash
   git add Core_Entities/
   git commit -m "Add user authentication to Core_Entities"
   git push origin team-red-m
   ```

5. **Pull Request Flow**
   - Developer → `team-red-m → team-red`  
   - **Team Red Leader** reviews & merges  
   - Leader → `team-red → main`  
   - **Repo Owner** reviews & merges  

---

## 🔵 Team Blue – Enterprise Division
- **Folder:** `Enterprise_Division/`  
- **Branch:** `team-blue`  
- **Responsibility:** Enterprise division functionality  

### Workflow
1. **Initial Setup**
   ```bash
   git clone https://github.com/[owner]/[repo-name].git
   cd [repo-name]
   git checkout team-blue
   git pull origin team-blue
   ```

2. **Create Feature Branch**
   ```bash
   git checkout -b team-blue-m
   ```
   

3. **Work on Your Code**
   - Modify files **only inside** `Enterprise_Division/`  
   - Write tests in `Enterprise_Division/tests/`  
   - Update docs in `Enterprise_Division/docs/`  

4. **Commit & Push**
   ```bash
   git add Enterprise_Division/
   git commit -m "Add enterprise dashboard to Enterprise_Division"
   git push origin team-blue-m
   ```

5. **Pull Request Flow**
   - Developer → `team-blue-m → team-blue`  
   - **Team Blue Leader** reviews & merges  
   - Leader → `team-blue → main`  
   - **Repo Owner** reviews & merges  

---

## 🚨 Critical Rules
❌ **Do Not**  
- Modify files outside your team folder  
- Push directly to `main`  
- Push directly to another team’s branch  
- Delete/move files from other teams  

✅ **Do**  
- Work only in your assigned folder  
- Branch **only from your team branch**  
- Write descriptive commit messages  
- Test code before PRs  
- Ask if unsure  

---

## 👥 Team Leader Responsibilities
- **Team Red Leader**
  - Review all PRs into `team-red`  
  - Ensure only `Core_Entities/` is modified  
  - Create PRs from `team-red → main`  
  - Coordinate with Team Blue Leader on shared resources  

- **Team Blue Leader**
  - Review all PRs into `team-blue`  
  - Ensure only `Enterprise_Division/` is modified  
  - Create PRs from `team-blue → main`  
  - Coordinate with Team Red Leader on shared resources  

---

## 🔧 Useful Git Commands

```bash
# Show current branch
git branch --show-current

# List all branches
git branch -a

# See changed files
git status
git diff --name-only

# Pull latest changes
git pull origin [your-team-branch]

# Switch branches
git checkout [branch-name]
```

---

## 🆘 Emergency Commands

```bash
# Save changes temporarily
git stash
git checkout [correct-branch]
git stash pop

# Undo last commit (keep changes)
git reset --soft HEAD~1

# Revert wrong folder changes
git checkout -- [wrong-folder]/
```

---

## 📈 Branch Flow Summary
```plaintext
Feature Branch → Team Branch → Main
```

Example:  
1. `team-red-m → team-red` (Team Red Leader approval)  
2. `team-red → main` (Repo Owner approval)  

---

## ⚡ Quick Start Checklist

**Team Red**
- Clone repo  
- Switch to `team-red`  
- Create feature branch: `team-red-m`  
- Work in `Core_Entities/` only  
- Push → PR to `team-red`  

**Team Blue**
- Clone repo  
- Switch to `team-blue`  
- Create feature branch: `team-blue-m`  
- Work in `Enterprise_Division/` only  
- Push → PR to `team-blue`  

---

## 📝 Notes
- **Repo Owner** has final approval for merges to `main`  
- `CODEOWNERS` enforces folder ownership  
- Branch protection prevents direct pushes to `main`  
- Clean up merged feature branches regularly  
- Always pull latest changes before starting new work  

---

📅 *Last Updated: [Replace with date]*  
💬 Questions? Contact your **team leader** or the **repository owner**.  
