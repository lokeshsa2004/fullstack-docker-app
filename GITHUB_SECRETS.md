# GitHub Secrets Configuration

This document explains the required GitHub secrets for the CI/CD pipeline to work correctly.

## Required Secrets

Set these secrets in your GitHub repository:
**Settings → Secrets and variables → Actions**

### 1. EC2_HOST
**Description**: Your AWS EC2 instance's public IP address or hostname
**Example**: `ec2-user-12-345-678-910.compute-1.amazonaws.com` or `54.123.45.67`
**How to find**: 
- Go to AWS EC2 Dashboard
- Select your instance
- Copy "Public IPv4 address" or "Public IPv4 DNS"

### 2. EC2_USER
**Description**: The SSH user for your EC2 instance
**Common values**:
- `ec2-user` (Amazon Linux, RHEL)
- `ubuntu` (Ubuntu AMI)
- `admin` (Debian)
- `ec2-user` (Red Hat)
**Default for AWS**: `ec2-user`

### 3. EC2_KEY
**Description**: Your private SSH key for EC2 authentication
**How to get**:
1. Your EC2 key pair file (`.pem` file)
2. Open it in a text editor
3. Copy the entire content (including `-----BEGIN` and `-----END` lines)

**Example format**:
```
-----BEGIN RSA PRIVATE KEY-----
MIIEpAIBAAKCAQEA1234567890...
(many lines of key data)
-----END RSA PRIVATE KEY-----
```

**⚠️ Security Warning**: Never commit this to Git. Only store in GitHub Secrets.

### 4. DB_USER
**Description**: PostgreSQL username for the application
**Recommended**: `postgres` (default) or custom name like `app_user`
**Example**: `postgres`

### 5. DB_PASSWORD
**Description**: PostgreSQL password
**Security Requirements**:
- Minimum 12 characters
- Mix of uppercase, lowercase, numbers, special chars
- Not a common word or password
**Example**: `SecureP@ssw0rd123!`

### 6. DB_NAME
**Description**: PostgreSQL database name
**Recommended**: `portfolio_db`
**Example**: `portfolio_db`

### 7. SLACK_WEBHOOK_URL (Optional)
**Description**: Slack webhook for deployment notifications
**How to get**:
1. Go to your Slack workspace
2. Create a new app or use existing one
3. Enable Incoming Webhooks
4. Create a webhook URL for your channel
**Format**: `https://hooks.slack.com/services/YOUR/WEBHOOK/URL`
**Note**: If not set, deployment still works but no Slack notifications

## Setup Instructions

### Step 1: Generate EC2 Key Pair
```bash
# If you don't have one already
aws ec2 create-key-pair --key-name portfolio-key --region us-east-1 --query 'KeyMaterial' --output text > portfolio-key.pem
chmod 600 portfolio-key.pem
```

### Step 2: Add Secrets to GitHub
1. Go to your repository
2. Click **Settings** (top right)
3. Click **Secrets and variables** → **Actions**
4. Click **New repository secret**
5. For each required secret:
   - **Name**: Exact name from this document
   - **Value**: The value from your environment
   - Click **Add secret**

### Step 3: Verify Secrets
```bash
# List secrets (names only, values are hidden)
# This is for your reference only in GitHub UI
```

## Example: Creating Each Secret

### EC2_HOST
```
Name: EC2_HOST
Value: 54.123.45.67
```

### EC2_USER
```
Name: EC2_USER
Value: ec2-user
```

### EC2_KEY
```
Name: EC2_KEY
Value: -----BEGIN RSA PRIVATE KEY-----
MIIEpAIBAAKCAQEA...
(entire key content)
-----END RSA PRIVATE KEY-----
```

### DB_USER
```
Name: DB_USER
Value: postgres
```

### DB_PASSWORD
```
Name: DB_PASSWORD
Value: SuperSecure@Pass123!
```

### DB_NAME
```
Name: DB_NAME
Value: portfolio_db
```

## Testing Secrets

### Verify EC2 Access
```bash
# From your local machine
ssh -i portfolio-key.pem ec2-user@your-ec2-host
# Should work without prompting for password
```

### Verify Database Credentials
Once deployed, check:
```bash
# SSH to EC2
ssh -i portfolio-key.pem ec2-user@your-ec2-host

# Check running containers
docker compose ps

# Test DB connection
docker compose exec db psql -U postgres -d portfolio_db -c "SELECT 1"
```

### Verify Slack (if configured)
1. Make a change to `main` branch
2. GitHub Actions will run
3. Check your Slack channel for deployment notification

## Troubleshooting Secrets

### "Repository secrets could not be loaded"
- Clear browser cache
- Try different browser
- Check if you have repository access
- Ensure you're in the correct repository

### SSH Authentication Failed
- Verify EC2_HOST is correct IP/hostname
- Verify EC2_USER matches your AMI type
- Verify EC2_KEY has correct private key content
- Check EC2 security group allows SSH (port 22)
- Ensure key pair hasn't been deleted from EC2

### Database Connection Failed
- Verify DB_USER matches created user
- Verify DB_PASSWORD is correct
- Verify DB_NAME matches created database
- Check PostgreSQL is running: `docker compose ps db`

### Slack Webhook Errors
- Generate new webhook at slack.com/apps
- Verify URL includes `/services/` in path
- Not a critical error - deployment continues without Slack

## Secret Rotation

For security best practices:

### Rotating EC2_KEY
1. Create new key pair in AWS EC2
2. Add public key to EC2 instance
3. Update EC2_KEY secret in GitHub
4. Test deployment
5. Delete old key pair from AWS

### Rotating DB_PASSWORD
1. Update password in PostgreSQL
2. Update DB_PASSWORD secret in GitHub
3. Next deployment will use new password

### Rotating SLACK_WEBHOOK_URL
1. Generate new webhook at slack.com/apps
2. Update SLACK_WEBHOOK_URL secret in GitHub

## Security Best Practices

1. ✅ Never commit secrets to Git
2. ✅ Use strong, unique passwords
3. ✅ Rotate secrets periodically
4. ✅ Use dedicated IAM users/roles when possible
5. ✅ Restrict EC2 security group to GitHub IP ranges
6. ✅ Monitor GitHub Actions logs for errors
7. ✅ Review deployments in GitHub Actions tab
8. ✅ Keep SSH keys secure on your local machine

## Viewing Deployment Status

Check GitHub Actions:
1. Go to repository
2. Click **Actions** tab
3. View workflow runs
4. Click on a run to see:
   - Build status
   - Test results
   - Deployment logs
   - Health check results

## Support

If secrets aren't working:
1. Check GitHub Actions logs for error messages
2. Verify all secrets are set correctly
3. Ensure SSH key has correct permissions (600)
4. Check EC2 security group rules
5. Verify EC2 instance is running

---

**Last Updated**: May 2026
