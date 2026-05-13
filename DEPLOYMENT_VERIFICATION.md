# EC2 Deployment Checklist & Verification

## Quick Fix Summary

The Docker Compose warnings are now fixed by:

1. **Fixed CI/CD Workflow** - Updated `.github/workflows/ci-cd.yml` to properly export environment variables via SSH
2. **Created `.env` File** - Local development `.env` file with database defaults
3. **Added GitHub Secrets** - Instructions in `GITHUB_SECRETS_SETUP.md`

---

## Deployment Steps

### Step 1: Add GitHub Secrets

Go to your GitHub repo → **Settings** → **Secrets and variables** → **Actions**

Add these 4 secrets:

```
DB_USER        = postgres
DB_PASSWORD    = your_secure_password
DB_NAME        = portfolio_db
EC2_HOST       = your-ec2-ip-address
EC2_USER       = ec2-user  (or ubuntu)
EC2_KEY        = (paste your PEM file content)
GITHUB_TOKEN   = (your GitHub personal access token)
```

### Step 2: Verify Secrets Are Added

```bash
# Check GitHub Actions logs after next push
# Repo → Actions → Latest workflow run → Deploy to EC2 step
```

### Step 3: Test Deployment

Push a commit to trigger the workflow:

```bash
git add .github/workflows/ci-cd.yml .env GITHUB_SECRETS_SETUP.md
git commit -m "fix: add environment variable configuration for Docker Compose"
git push origin main
```

### Step 4: Verify No Warnings

SSH into your EC2 instance and check logs:

```bash
# SSH into EC2
ssh -i your-key.pem ec2-user@your-ec2-ip

# Check if .env file was created with values
cat /opt/portfolio-app/.env

# Should show:
# DB_USER=postgres
# DB_PASSWORD=your_password
# DB_NAME=portfolio_db

# Check Docker Compose logs
cd /opt/portfolio-app
docker compose logs | head -20

# Should NOT show "variable is not set" warnings
```

---

## If Warnings Still Appear

### Check 1: Verify .env file exists and has values

```bash
cd /opt/portfolio-app
ls -la .env
cat .env
```

Expected output:
```
DB_USER=postgres
DB_PASSWORD=postgres
DB_NAME=portfolio_db
```

### Check 2: Verify Docker Compose is using .env

```bash
docker compose config | grep -A 5 "POSTGRES_USER"
```

Should show actual values, not `${DB_USER}`.

### Check 3: Check GitHub Actions logs

Go to **Repo → Actions → [Latest Run] → Deploy to EC2** and look for errors in the deployment script.

### Check 4: Verify SSH connection in workflow

Add this to workflow for debugging:

```yaml
- name: Debug - Check .env file
  run: |
    ssh -i ~/.ssh/ec2-key.pem ${{ secrets.EC2_USER }}@${{ secrets.EC2_HOST }} \
      'cat /opt/portfolio-app/.env || echo "File not found"'
```

---

## What Was Changed

### File: `.github/workflows/ci-cd.yml`

**Before:**
```bash
ssh -o StrictHostKeyChecking=accept-new -i ~/.ssh/ec2-key.pem ${{ secrets.EC2_USER }}@${{ secrets.EC2_HOST }} \
  DB_USER='${{ secrets.DB_USER }}' \
  DB_PASSWORD='${{ secrets.DB_PASSWORD }}' \
  ...
```

**After:**
```bash
ssh -o StrictHostKeyChecking=accept-new -i ~/.ssh/ec2-key.pem ${{ secrets.EC2_USER }}@${{ secrets.EC2_HOST }} 'bash -s' << 'EOFSCRIPT'
set -e

export DB_USER="${{ secrets.DB_USER }}"
export DB_PASSWORD="${{ secrets.DB_PASSWORD }}"
export DB_NAME="${{ secrets.DB_NAME }}"
...
```

This properly exports the secrets as environment variables before creating the `.env` file.

---

## Root Cause

The original deployment script tried to pass environment variables via SSH command prefix:

```bash
ssh ... VAR1='value' VAR2='value' 'command'
```

This doesn't work reliably. The fix uses proper variable export:

```bash
ssh ... 'bash -s' << 'SCRIPT'
export VAR1='value'
export VAR2='value'
...
SCRIPT
```

Now Docker Compose can read from the `.env` file created with actual values.

---

## Verification Commands

After deployment, run these on your EC2 instance:

```bash
# 1. Check if containers are running
docker ps -a

# 2. Check logs for warnings
docker compose logs 2>&1 | grep WARN

# 3. If no output, warnings are fixed! ✅
```

---

## Support

If you're still seeing warnings, check:

1. ✅ All GitHub Secrets added correctly
2. ✅ EC2 instance accessible via SSH
3. ✅ `.env` file created at `/opt/portfolio-app/.env`
4. ✅ GitHub Actions workflow execution logs
