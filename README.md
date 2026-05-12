# Portfolio Manager - Production Ready Full Stack Application

A modern, scalable investment portfolio management application built with FastAPI, PostgreSQL, and Docker.

![Python](https://img.shields.io/badge/Python-3.11+-blue)
![FastAPI](https://img.shields.io/badge/FastAPI-0.104-green)
![Docker](https://img.shields.io/badge/Docker-Compose-blue)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-15-blue)
![License](https://img.shields.io/badge/License-MIT-green)

## 📋 Table of Contents

- [Features](#features)
- [Project Structure](#project-structure)
- [Prerequisites](#prerequisites)
- [Local Setup](#local-setup)
- [Running the Application](#running-the-application)
- [API Documentation](#api-documentation)
- [Docker & Deployment](#docker--deployment)
- [CI/CD Pipeline](#cicd-pipeline)
- [AWS EC2 Deployment](#aws-ec2-deployment)
- [Database Management](#database-management)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)

## ✨ Features

### Core Functionality

- ✅ Create and manage multiple investment portfolios
- ✅ Add, update, and delete individual investments
- ✅ Real-time portfolio value calculations
- ✅ Track investment performance (gain/loss)
- ✅ Responsive web interface
- ✅ RESTful API with full CRUD operations

### Technical Features

- ✅ Clean layered architecture (controllers, services, models)
- ✅ Database migrations with Alembic
- ✅ Comprehensive error handling
- ✅ Input validation with Pydantic
- ✅ CORS support for cross-origin requests
- ✅ Health check endpoints
- ✅ Structured logging
- ✅ Container orchestration with Docker Compose
- ✅ Nginx reverse proxy
- ✅ CI/CD pipeline with GitHub Actions
- ✅ Database backup and rollback scripts
- ✅ Production-ready configuration

## 📁 Project Structure

```
portfolio-manager/
├── backend/
│   ├── app/
│   │   ├── __init__.py
│   │   ├── main.py                 # FastAPI application entry point
│   │   ├── frontend_app.py         # Flask app for frontend
│   │   ├── api/
│   │   │   ├── routes/
│   │   │   │   ├── health.py
│   │   │   │   ├── investment.py
│   │   │   │   └── portfolio.py
│   │   ├── models/
│   │   │   ├── investment.py
│   │   │   └── portfolio.py
│   │   ├── schemas/
│   │   │   ├── investment.py
│   │   │   └── portfolio.py
│   │   ├── services/
│   │   │   ├── investment_service.py
│   │   │   └── portfolio_service.py
│   │   ├── core/
│   │   │   └── config.py
│   │   └── db/
│   │       └── base.py
│   ├── requirements.txt
│   ├── Dockerfile
│   └── migrations/
├── frontend/
│   ├── templates/
│   │   ├── base.html
│   │   ├── home.html
│   │   ├── dashboard.html
│   │   └── about.html
│   └── static/
│       ├── css/
│       │   ├── style.css
│       │   └── responsive.css
│       └── js/
│           ├── main.js
│           ├── home.js
│           └── dashboard.js
├── nginx/
│   ├── nginx.conf
│   └── ssl/
├── scripts/
│   ├── setup.sh
│   ├── start.sh
│   ├── stop.sh
│   ├── backup.sh
│   ├── rollback.sh
│   └── deploy.sh
├── .github/
│   └── workflows/
│       └── ci-cd.yml
├── docker-compose.yml
├── .env.example
├── .gitignore
├── Makefile
└── README.md
```

## 📦 Prerequisites

Before you begin, ensure you have installed:

- **Docker** (v20.10+) - [Install Docker](https://docs.docker.com/install/)
- **Docker Compose** (v1.29+) - [Install Docker Compose](https://docs.docker.com/compose/install/)
- **Git** - [Install Git](https://git-scm.com/downloads)
- **Make** (optional, for easier command execution)

For local development without Docker:

- **Python** (3.11+) - [Install Python](https://www.python.org/downloads/)
- **PostgreSQL** (15+) - [Install PostgreSQL](https://www.postgresql.org/download/)

## 🚀 Local Setup

### 1. Clone the Repository

```bash
git clone https://github.com/your-username/portfolio-manager.git
cd portfolio-manager
```

### 2. Setup Environment Variables

```bash
# Copy the example environment file
cp .env.example .env

# Edit .env with your configuration
nano .env  # or use your preferred editor
```

**Key environment variables:**

```env
DEBUG=False
DB_USER=postgres
DB_PASSWORD=postgres
DB_NAME=portfolio_db
CORS_ORIGINS=http://localhost,http://localhost:3000,http://localhost:80
```

### 3. Initialize the Application

Using make (recommended):

```bash
make setup
```

Or manually:

```bash
bash scripts/setup.sh
```

This will:

- Verify Docker and Docker Compose installation
- Create necessary directories
- Build Docker images

## ▶️ Running the Application

### Start All Containers

Using make:

```bash
make run
```

Or manually:

```bash
bash scripts/start.sh
```

The application will be available at:

- **Frontend**: http://localhost
- **API**: http://localhost:8000
- **API Docs**: http://localhost:8000/docs
- **Database**: localhost:5432

### Stop All Containers

```bash
make down
```

Or:

```bash
bash scripts/stop.sh
```

### View Application Logs

```bash
make logs
# or
docker-compose logs -f
```

### Check Running Containers

```bash
make ps
# or
docker-compose ps
```

## 📚 API Documentation

### Interactive Documentation

FastAPI automatically generates interactive API documentation at:

- **Swagger UI**: http://localhost:8000/docs
- **ReDoc**: http://localhost:8000/redoc

### Health Endpoints

```bash
# Basic health check
curl http://localhost:8000/health

# Readiness check (database connectivity)
curl http://localhost:8000/health/ready
```

### Portfolio Endpoints

```bash
# Get all portfolios
curl http://localhost:8000/api/v1/portfolios

# Create portfolio
curl -X POST http://localhost:8000/api/v1/portfolios \
  -H "Content-Type: application/json" \
  -d '{
    "name": "My Portfolio",
    "owner": "John Doe",
    "description": "Personal investment portfolio"
  }'

# Get portfolio by ID
curl http://localhost:8000/api/v1/portfolios/1

# Update portfolio
curl -X PATCH http://localhost:8000/api/v1/portfolios/1 \
  -H "Content-Type: application/json" \
  -d '{"description": "Updated description"}'

# Delete portfolio
curl -X DELETE http://localhost:8000/api/v1/portfolios/1

# Get portfolio total value
curl http://localhost:8000/api/v1/portfolios/1/total-value
```

### Investment Endpoints

```bash
# Create investment
curl -X POST http://localhost:8000/api/v1/investments \
  -H "Content-Type: application/json" \
  -d '{
    "portfolio_id": 1,
    "ticker": "AAPL",
    "name": "Apple Inc.",
    "quantity": 10,
    "purchase_price": 150.00,
    "current_price": 185.50,
    "sector": "Technology"
  }'

# Get investment by ID
curl http://localhost:8000/api/v1/investments/1

# Get investments by portfolio
curl http://localhost:8000/api/v1/investments/portfolio/1

# Update investment
curl -X PATCH http://localhost:8000/api/v1/investments/1 \
  -H "Content-Type: application/json" \
  -d '{"current_price": 190.00}'

# Delete investment
curl -X DELETE http://localhost:8000/api/v1/investments/1
```

## 🐳 Docker & Deployment

### Docker Architecture

The application uses three main services:

1. **Database (PostgreSQL)**
   - Image: postgres:15-alpine
   - Port: 5432
   - Volume: postgres_data

2. **Application (FastAPI)**
   - Built from: ./backend/Dockerfile
   - Port: 8000
   - Health check enabled

3. **Reverse Proxy (Nginx)**
   - Image: nginx:alpine
   - Port: 80 (HTTP), 443 (HTTPS - optional)
   - Serves static files and proxies API requests

### Building Images

```bash
# Build all images
docker-compose build

# Build specific service
docker-compose build app
```

### Running Services

```bash
# Start all services
docker-compose up -d

# Start specific service
docker-compose up -d app

# View logs
docker-compose logs -f app
```

### Volumes and Persistence

- **postgres_data**: Persists database data
- **./backend**: Mounts application code (for development)
- **./frontend/static**: Serves static files
- **./nginx/ssl**: Contains SSL certificates

## 🔄 CI/CD Pipeline

The project includes a GitHub Actions workflow that:

1. **Test**: Runs on every push and PR
   - Installs dependencies
   - Runs linters
   - Runs unit tests (if any)

2. **Build & Push**: Runs on main branch push
   - Builds Docker image
   - Pushes to GHCR (GitHub Container Registry)
   - Tags with git ref and latest

3. **Deploy**: Runs on main branch push
   - Deploys to EC2 instance
   - Runs health checks
   - Sends Slack notifications

### Setting Up GitHub Actions

1. **Create Personal Access Token**

   ```bash
   # Go to: Settings > Developer settings > Personal access tokens
   # Scopes needed: repo, write:packages
   ```

2. **Configure Repository Secrets**

   ```
   Settings > Secrets and variables > Actions > New repository secret
   ```

   Required secrets:

   ```
   EC2_HOST              - Your EC2 public IP or domain
   EC2_USER              - EC2 SSH user (default: ec2-user)
   EC2_SSH_KEY           - Private SSH key content
   DB_USER               - Database user
   DB_PASSWORD           - Database password
   DB_NAME               - Database name
   SLACK_WEBHOOK_URL     - (Optional) Slack notification webhook
   ```

3. **Trigger Workflow**
   ```bash
   git push origin main
   ```

## 🏗️ AWS EC2 Deployment

### Prerequisites

1. **EC2 Instance**
   - OS: Amazon Linux 2 or Ubuntu 20.04+
   - Type: t3.medium or larger
   - Security Group: Allow ports 22 (SSH), 80 (HTTP), 443 (HTTPS)
   - Storage: 20GB+ EBS volume

2. **SSH Key Pair**
   - Create in AWS EC2 console
   - Download and save locally
   - Set permissions: `chmod 600 key.pem`

3. **GitHub Token**
   - Create at: https://github.com/settings/tokens
   - Scopes: `repo`, `write:packages`

### Manual Deployment

1. **Set Environment Variables**

   ```bash
   # In .env file
   EC2_HOST=your-ec2-ip.compute-1.amazonaws.com
   EC2_USER=ec2-user  # or ubuntu for Ubuntu instances
   SSH_KEY_PATH=/path/to/key.pem
   ```

2. **Deploy**

   ```bash
   bash scripts/deploy.sh
   ```

3. **Access Application**
   ```
   http://your-ec2-ip
   ```

### Automated Deployment via CI/CD

1. Add EC2 secrets to GitHub repository
2. Push to main branch
3. GitHub Actions will automatically deploy

### EC2 Setup Steps (Manual)

```bash
# SSH into EC2 instance
ssh -i your-key.pem ec2-user@your-ec2-ip

# Update system
sudo yum update -y

# Install Docker
sudo yum install docker -y
sudo systemctl start docker
sudo usermod -aG docker ec2-user

# Install Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Clone repository
git clone https://github.com/your-username/portfolio-manager.git
cd portfolio-manager

# Setup environment
cp .env.example .env
# Edit .env with your values

# Start application
docker-compose up -d

# Check status
docker-compose ps
```

## 💾 Database Management

### Create Database Backup

```bash
make backup
# or
bash scripts/backup.sh
```

Backups are stored in `./backups/` directory.

### Restore from Backup

```bash
bash scripts/rollback.sh backups/backup_20240101_120000.sql
```

### Database Migrations

```bash
# Run migrations
make db-migrate
# or
docker-compose exec app alembic upgrade head

# Create new migration
docker-compose exec app alembic revision --autogenerate -m "Add new column"
```

### Direct Database Access

```bash
# Access psql shell
make shell-db

# Or with Docker
docker-compose exec db psql -U postgres -d portfolio_db
```

## 🧪 Development

### Install Development Dependencies

```bash
pip install -r backend/requirements.txt
pip install pytest pytest-asyncio black pylint
```

### Run Linter

```bash
make lint
```

### Format Code

```bash
make format
```

### Run Tests

```bash
make test
```

### Open Application Shell

```bash
make shell-app
```

## 🔧 Troubleshooting

### Application Won't Start

```bash
# Check logs
docker-compose logs app

# Check health
curl http://localhost:8000/health

# Restart containers
docker-compose restart
```

### Database Connection Error

```bash
# Check database is running
docker-compose ps db

# Check database health
docker-compose exec db pg_isready -U postgres

# View database logs
docker-compose logs db
```

### Port Already in Use

```bash
# Change ports in .env or docker-compose.yml
# Or kill process using the port

# For macOS/Linux
sudo lsof -i :80
sudo kill -9 <PID>

# For Windows
netstat -ano | findstr :80
taskkill /PID <PID> /F
```

### Static Files Not Loading

```bash
# Verify static files exist
ls -la frontend/static/

# Restart Nginx
docker-compose restart nginx
```

### Memory Issues

```bash
# View container resource usage
docker stats

# Increase Docker memory limit in Docker settings
```

### Reset Everything

```bash
# Remove all containers and volumes
make clean

# Rebuild
make setup

# Start fresh
make run
```

## 📋 Configuration

### Environment Variables

Key configuration variables in `.env`:

```env
# Application
APP_NAME=Portfolio Manager API
APP_VERSION=1.0.0
DEBUG=False
LOG_LEVEL=INFO

# Database
DB_USER=postgres
DB_PASSWORD=change_me
DB_NAME=portfolio_db
DATABASE_URL=postgresql://postgres:password@db:5432/portfolio_db

# Server
HOST=0.0.0.0
PORT=8000

# CORS
CORS_ORIGINS=http://localhost,http://localhost:80

# Docker Registry
DOCKER_REGISTRY=ghcr.io
DOCKER_IMAGE_NAME=your-username/portfolio-manager
```

### Nginx Configuration

Edit `nginx/nginx.conf`:

- Proxy settings
- SSL/TLS configuration
- Rate limiting
- Compression
- Security headers

## 🚀 Makefile Commands

```bash
make help              # Show all available commands
make setup             # Setup environment
make build             # Build Docker images
make run               # Start containers
make down              # Stop containers
make logs              # View logs
make health            # Health check
make backup            # Create database backup
make rollback          # Show available backups
make clean             # Remove containers and volumes
make deploy            # Deploy to EC2
```

## 📝 Frontend Pages

### Home Page (`/`)

- Welcome message
- Feature highlights
- Statistics dashboard
- Call-to-action buttons

### Dashboard (`/dashboard`)

- Portfolio management
- Investment tracking
- Add/edit/delete operations
- Real-time calculations
- Responsive design

### About Page (`/about`)

- Company information
- Technology stack details
- FAQ section
- Contact information

## 🔐 Security

### Best Practices Implemented

- ✅ CORS configuration
- ✅ Input validation with Pydantic
- ✅ SQL injection prevention with SQLAlchemy ORM
- ✅ XSS protection with HTML escaping
- ✅ HTTPS support (configurable)
- ✅ Security headers in Nginx
- ✅ Health checks
- ✅ Error handling
- ✅ Environment variable management

### Additional Security Considerations

1. **Production Deployment**
   - Use HTTPS with valid SSL certificate
   - Set `DEBUG=False`
   - Use strong database passwords
   - Keep Docker images updated
   - Regular backups

2. **Secret Management**
   - Never commit `.env` file
   - Use GitHub Secrets for CI/CD
   - Rotate passwords regularly

## 📞 Support & Contact

For issues and questions:

- GitHub Issues: [Create an issue](https://github.com/your-username/portfolio-manager/issues)
- Email: support@portfoliomanager.com
- Documentation: [Full Documentation](https://github.com/your-username/portfolio-manager)

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 👨‍💻 Contributing

Contributions are welcome! Please follow these steps:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit changes (`git commit -m 'Add AmazingFeature'`)
4. Push to branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 🎉 Acknowledgments

- FastAPI for the excellent web framework
- PostgreSQL for reliable database
- Docker for containerization
- GitHub Actions for CI/CD
- Nginx for reverse proxy functionality

---

**Last Updated**: January 2024
**Version**: 1.0.0
