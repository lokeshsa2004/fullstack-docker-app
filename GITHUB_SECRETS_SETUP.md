# GitHub Secrets Setup for CI/CD Deployment

## Required Secrets for Environment Variables

Add these secrets in your GitHub repository:

**Settings → Secrets and variables → Actions → New repository secret**

### Database Secrets (Required)

| Secret Name | Description | Example Value |
|---|---|---|
| `DB_USER` | PostgreSQL username | `postgres` |
| `DB_PASSWORD` | PostgreSQL password | `your_secure_password_here` |
| `DB_NAME` | Database name | `portfolio_db` |

### EC2 Deployment Secrets (Required)

| Secret Name | Description | Example Value |
|---|---|---|
| `EC2_HOST` | EC2 instance IP address | `10.0.1.39` |
| `EC2_USER` | SSH user | `ec2-user` or `ubuntu` |
| `EC2_KEY` | EC2 private key (PEM format) | `-----BEGIN RSA PRIVATE KEY-----...` |
| `GITHUB_TOKEN` | GitHub token for registry access | (Personal access token with `read:packages` scope) |

## How to Add Secrets

1. Go to your GitHub repository
2. Click **Settings** (top right)
3. Click **Secrets and variables** → **Actions**
4. Click **New repository secret**
5. Enter the secret name and value
6. Click **Add secret**

## Database Values

Use values that match your database setup:

```bash
DB_USER=postgres
DB_PASSWORD=postgres  # Change this to something secure!
DB_NAME=portfolio_db
```

## EC2 Setup

To get your EC2 key, you can copy it from your local machine:

```bash
# On your local machine, if you have the key locally:
cat /path/to/your/ec2-key.pem | pbcopy  # macOS
# or
cat /path/to/your/ec2-key.pem | xclip -selection clipboard  # Linux
```

Then paste it as the `EC2_KEY` secret value.

## Verification

After adding all secrets, the CI/CD pipeline will:

1. Build and test your application
2. Push images to GitHub Container Registry (GHCR)
3. SSH into your EC2 instance
4. Create a `.env` file with the database credentials
5. Pull the latest Docker images
6. Deploy using `docker compose up -d`

If you see warnings like `WARN[0000] The "DB_USER" variable is not set`, it means the `.env` file wasn't created with values. Check:
- All secrets are added correctly
- The EC2 instance can be accessed via SSH
- The deployment script created the `.env` file properly

## Troubleshooting

### Secrets not being used

Check the GitHub Actions logs:
1. Go to your repository
2. Click **Actions** tab
3. Click on the failed workflow run
4. Click **Deploy to EC2** step
5. Check if `docker compose logs` shows warnings

### Connection issues

SSH key not working? Try:

```bash
# Test SSH connection manually (from GitHub Actions)
ssh -i ~/.ssh/ec2-key.pem ec2-user@your-ec2-ip "echo 'SSH works!'"
```

### Missing .env file

If Docker Compose still shows warnings, the `.env` file wasn't created. Check:

```bash
# On EC2 instance
cat /opt/portfolio-app/.env
docker compose logs
```
