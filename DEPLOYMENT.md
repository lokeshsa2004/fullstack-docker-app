# Portfolio Manager - AWS EC2 Deployment Guide

Complete guide to deploying Portfolio Manager to AWS EC2 with automated CI/CD using GitHub Actions.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Create EC2 Instance](#create-ec2-instance)
3. [Setup GitHub Secrets](#setup-github-secrets)
4. [Enable CI/CD Pipeline](#enable-cicd-pipeline)
5. [Manual Deployment](#manual-deployment)
6. [Monitoring & Maintenance](#monitoring--maintenance)
7. [Troubleshooting](#troubleshooting)

## Prerequisites

### AWS Account

- Active AWS account with EC2 access
- EC2 launch templates available

### GitHub

- GitHub repository with this code
- GitHub Personal Access Token (PAT) created
- Repository settings accessible

### Local Machine

- AWS CLI configured (for manual deployment)
- SSH key pair created
- Git installed

## Create EC2 Instance

### Step 1: Launch EC2 Instance

1. Go to **AWS Console > EC2 > Instances > Launch Instances**

2. **Choose AMI**
   - Select "Amazon Linux 2" or "Ubuntu 20.04 LTS"
   - Free tier eligible recommended

3. **Instance Type**
   - Recommended: `t3.medium` or `t3.small`
   - Free tier: `t2.micro` (may be slow)

4. **Instance Details**
   - Network: Default VPC
   - Enable public IP: ✓ Yes
   - IAM instance profile: Optional

5. **Storage**
   - EBS volume: 20 GB (gp2 or gp3)
   - Encryption: Optional

6. **Tags**

   ```
   Name: portfolio-manager
   Environment: production
   ```

7. **Security Group**

   ```
   Inbound Rules:
   - SSH (22)     from Your IP
   - HTTP (80)    from 0.0.0.0/0
   - HTTPS (443)  from 0.0.0.0/0

   Outbound Rules:
   - All traffic allowed
   ```

8. **Key Pair**
   - Create new: `portfolio-manager-key`
   - Download and save: `portfolio-manager-key.pem`
   - Set permissions: `chmod 600 portfolio-manager-key.pem`

9. **Review & Launch**
   - Click "Launch Instances"
   - Wait for instance to be running

### Step 2: Get Instance Details

1. Go to **EC2 > Instances**
2. Select your instance
3. Note down:
   - **Public IPv4**: Used to access the application
   - **Public DNS**: Alternative access method
   - **Private IPv4**: Internal network address

Example:

```
Public IPv4: 54.123.45.67
Public DNS: ec2-54-123-45-67.compute-1.amazonaws.com
```

## Setup GitHub Secrets

GitHub Secrets are used by the CI/CD pipeline to deploy to your EC2 instance.

### Step 1: Create GitHub Secrets

1. Go to your **GitHub Repository > Settings > Secrets and Variables > Actions**

2. Create the following secrets:

#### EC2 Configuration

- **EC2_HOST**: `54.123.45.67` (your public IP)
- **EC2_USER**: `ec2-user` (Amazon Linux) or `ubuntu` (Ubuntu)
- **EC2_SSH_KEY**: Content of your `portfolio-manager-key.pem` file

To get the SSH key content:

```bash
cat portfolio-manager-key.pem  # Copy entire output
```

#### Database Configuration

- **DB_USER**: `postgres` (or your preferred user)
- **DB_PASSWORD**: Strong password (e.g., `MyP@ssw0rd123!`)
- **DB_NAME**: `portfolio_db`

#### Optional

- **SLACK_WEBHOOK_URL**: Slack webhook for deployment notifications

### Step 2: Verify Secrets

```bash
# On your local machine, test SSH connection
ssh -i portfolio-manager-key.pem ec2-user@54.123.45.67
# Should connect without password prompt
exit
```

## Enable CI/CD Pipeline

### Step 1: Push Code to Main Branch

```bash
git remote set-url origin https://github.com/your-username/portfolio-manager.git
git add .
git commit -m "Initial commit for deployment"
git push origin main
```

### Step 2: Monitor Deployment

1. Go to **GitHub Repository > Actions**
2. Watch the **CI/CD Pipeline** workflow
3. Should show:
   - ✓ Test job
   - ✓ Build & Push job
   - ✓ Deploy job
   - ✓ Cleanup job

### Step 3: Verify Application

Once deployment completes:

```bash
# Open in browser
http://54.123.45.67

# Test API
curl http://54.123.45.67/api/v1/portfolios

# View application logs
ssh -i portfolio-manager-key.pem ec2-user@54.123.45.67
docker-compose logs -f
```

## Manual Deployment

If CI/CD is not available, deploy manually:

### Step 1: Connect to EC2

```bash
ssh -i portfolio-manager-key.pem ec2-user@54.123.45.67
```

### Step 2: Install Dependencies

```bash
# Update system
sudo yum update -y

# Install Docker
sudo yum install docker -y
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker $USER

# Install Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" \
  -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Verify installation
docker --version
docker-compose --version
```

### Step 3: Clone Repository

```bash
cd /opt
sudo git clone https://github.com/your-username/portfolio-manager.git
cd portfolio-manager
sudo chown -R $USER:$USER .
```

### Step 4: Configure Environment

```bash
# Copy environment file
cp .env.example .env

# Edit configuration
nano .env
```

Update values:

```env
DEBUG=False
DB_USER=postgres
DB_PASSWORD=your_secure_password
DB_NAME=portfolio_db
LOG_LEVEL=INFO
```

### Step 5: Start Application

```bash
# Start containers
docker-compose up -d

# Wait for services to start
sleep 10

# Check status
docker-compose ps

# Verify application is running
curl http://localhost:8000/health
```

### Step 6: Setup Domain (Optional)

```bash
# Edit nginx config to use your domain
sudo nano /opt/portfolio-manager/nginx/nginx.conf

# Update server_name from _ to your domain
# server_name yourdomain.com www.yourdomain.com;
```

## Monitoring & Maintenance

### View Logs

```bash
# SSH into instance
ssh -i portfolio-manager-key.pem ec2-user@54.123.45.67
cd /opt/portfolio-manager

# View all logs
docker-compose logs

# View specific service
docker-compose logs app      # Application logs
docker-compose logs db       # Database logs
docker-compose logs nginx    # Nginx logs

# Follow logs in real-time
docker-compose logs -f
```

### Create Database Backup

```bash
# On EC2 instance
cd /opt/portfolio-manager
bash scripts/backup.sh

# View backups
ls -lh backups/
```

### Monitor Container Health

```bash
# Check resource usage
docker stats

# Check if containers are healthy
docker ps --format "table {{.Names}}\t{{.Status}}"
```

### Restart Services

```bash
# Restart single service
docker-compose restart app

# Restart all services
docker-compose restart

# Full restart
docker-compose down
docker-compose up -d
```

### Update Application

```bash
# Pull latest code
cd /opt/portfolio-manager
git pull origin main

# Rebuild and restart
docker-compose down
docker-compose up -d --build
```

### Cron Job for Backups

```bash
# SSH into instance
ssh -i portfolio-manager-key.pem ec2-user@54.123.45.67

# Open crontab
crontab -e

# Add backup every day at 2 AM
0 2 * * * cd /opt/portfolio-manager && bash scripts/backup.sh
```

## Troubleshooting

### Connection Issues

**Can't SSH to EC2:**

```bash
# Check security group allows your IP
# Add your IP to EC2 security group inbound rule (port 22)

# Verify key permissions
chmod 600 portfolio-manager-key.pem

# Test connection
ssh -v -i portfolio-manager-key.pem ec2-user@54.123.45.67
```

**Can't access application:**

```bash
# Check if containers are running
ssh -i portfolio-manager-key.pem ec2-user@54.123.45.67
cd /opt/portfolio-manager
docker-compose ps

# Check security group allows HTTP (80)
# Add 80 to security group inbound rules

# Test locally
curl http://localhost
curl http://localhost:8000/health
```

### Deployment Issues

**GitHub Actions fails:**

1. Check GitHub Secrets are set correctly
2. Verify EC2_HOST, EC2_USER, EC2_SSH_KEY
3. Check EC2 security group allows SSH from GitHub Actions IPs

**Docker pull fails:**

```bash
# Check docker is running
docker ps

# Login to Docker (if using private registry)
docker login ghcr.io -u $GITHUB_ACTOR -p $GITHUB_TOKEN
```

**Database connection fails:**

```bash
# Check database container is running
docker-compose logs db

# Verify database is healthy
docker-compose exec db pg_isready -U postgres
```

### Performance Issues

**Application is slow:**

```bash
# Check container resources
docker stats

# Increase EC2 instance size (AWS Console > Instance Type)

# Check logs for errors
docker-compose logs app
```

**Disk space full:**

```bash
# Check disk usage
df -h

# Clean Docker images and containers
docker system prune -a

# Remove old backups
find backups/ -type f -mtime +30 -delete
```

## Security Best Practices

1. **Update Security Group**
   - Remove SSH access from `0.0.0.0/0`
   - Add only your IP or bastion host

2. **Use Strong Passwords**
   - Database password: min 20 characters
   - Include numbers, special characters

3. **Enable HTTPS**
   - Get SSL certificate (Let's Encrypt)
   - Configure in nginx.conf
   - Redirect HTTP to HTTPS

4. **Backup Regularly**
   - Automate with cron job
   - Store backups outside EC2
   - Test restore process

5. **Keep System Updated**

   ```bash
   sudo yum update -y    # Amazon Linux
   sudo apt update && sudo apt upgrade -y  # Ubuntu
   ```

6. **Monitor Logs**
   - Check application logs regularly
   - Set up log aggregation (CloudWatch, etc.)
   - Monitor security logs

## Cost Optimization

1. **Use Reserved Instances** for production
2. **Enable Auto Scaling** for variable load
3. **Use CloudFront** for static content
4. **Monitor costs** in AWS Billing Dashboard
5. **Stop instances** when not needed
6. **Use S3** for backups instead of EBS

## Next Steps

1. ✅ Test the application at http://your-ip
2. ✅ Create test portfolio and investments
3. ✅ Verify email notifications work
4. ✅ Set up monitoring (CloudWatch)
5. ✅ Configure domain name (Route 53)
6. ✅ Enable HTTPS (SSL certificate)
7. ✅ Schedule regular backups
8. ✅ Document your setup

---

**Questions?** See main [README.md](README.md) or create a GitHub issue.
