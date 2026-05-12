# Portfolio Manager - Quick Start Guide

## 🚀 Getting Started in 5 Minutes

### Prerequisites

- Docker installed: https://docs.docker.com/install/
- Docker Compose installed: https://docs.docker.com/compose/install/

### Quick Start

```bash
# 1. Clone the repository
git clone https://github.com/your-username/portfolio-manager.git
cd portfolio-manager

# 2. Setup environment
bash scripts/setup.sh

# 3. Start the application
bash scripts/start.sh

# 4. Open in browser
# Frontend:  http://localhost
# API:       http://localhost:8000
# API Docs:  http://localhost:8000/docs
```

## 📊 Project Structure Overview

```
portfolio-manager/
├── backend/              # FastAPI application
│   └── app/
│       ├── api/          # REST API routes
│       ├── models/       # Database models
│       ├── schemas/      # Pydantic schemas
│       ├── services/     # Business logic
│       └── core/         # Configuration
├── frontend/             # Static website
│   ├── templates/        # HTML templates
│   └── static/
│       ├── css/          # Stylesheets
│       └── js/           # JavaScript
├── nginx/                # Reverse proxy
├── scripts/              # Automation scripts
├── docker-compose.yml    # Container orchestration
├── Dockerfile            # Backend container
└── Makefile             # Command shortcuts
```

## 🎯 Key Features

✅ **Full Stack Application**

- FastAPI backend with PostgreSQL
- Responsive HTML/CSS/JavaScript frontend
- Nginx reverse proxy

✅ **Container Ready**

- Docker & Docker Compose included
- One command startup: `make run`
- Health checks and restart policies

✅ **Production Ready**

- GitHub Actions CI/CD workflow
- AWS EC2 deployment scripts
- Database backup and rollback
- Structured logging

✅ **Developer Friendly**

- Makefile with common commands
- Hot reload in development
- Comprehensive API documentation
- Seed data included

## 🔧 Common Commands

```bash
# Using Makefile
make help              # Show all commands
make setup             # Initial setup
make run               # Start containers
make down              # Stop containers
make logs              # View logs
make backup            # Create database backup
make health            # Health check

# Direct commands
docker-compose up -d   # Start in background
docker-compose logs -f # Follow logs
docker-compose ps      # Show containers
```

## 📁 Important Files

| File                 | Purpose                        |
| -------------------- | ------------------------------ |
| `docker-compose.yml` | Container orchestration        |
| `backend/Dockerfile` | Backend image build            |
| `nginx/nginx.conf`   | Reverse proxy config           |
| `.env.example`       | Environment variables template |
| `scripts/setup.sh`   | Initial setup script           |
| `scripts/start.sh`   | Start application script       |
| `Makefile`           | Command shortcuts              |

## 🌐 API Endpoints

### Health Check

```bash
GET /health
GET /health/ready
```

### Portfolios

```bash
GET    /api/v1/portfolios              # List all
POST   /api/v1/portfolios              # Create
GET    /api/v1/portfolios/{id}         # Get one
PATCH  /api/v1/portfolios/{id}         # Update
DELETE /api/v1/portfolios/{id}         # Delete
GET    /api/v1/portfolios/{id}/total-value
```

### Investments

```bash
POST   /api/v1/investments             # Create
GET    /api/v1/investments/{id}        # Get one
GET    /api/v1/investments/portfolio/{id}  # By portfolio
PATCH  /api/v1/investments/{id}        # Update
DELETE /api/v1/investments/{id}        # Delete
```

## 🗄️ Database

### Access Database

```bash
make shell-db  # Or: docker-compose exec db psql -U postgres -d portfolio_db
```

### Create Backup

```bash
make backup    # Or: bash scripts/backup.sh
```

### Restore from Backup

```bash
bash scripts/rollback.sh backups/backup_YYYYMMDD_HHMMSS.sql
```

## 🚀 Deployment

### Local Development

```bash
make run      # Starts all containers with live code updates
```

### Production on EC2

1. Set environment variables in `.env`
2. Configure GitHub Secrets (EC2_HOST, SSH_KEY, etc.)
3. Push to main branch
4. GitHub Actions automatically deploys

Or manually:

```bash
bash scripts/deploy.sh
```

## 🔑 Environment Variables

Copy `.env.example` to `.env` and update:

```env
DEBUG=False                              # Set to True for development
DB_USER=postgres
DB_PASSWORD=your_secure_password
DB_NAME=portfolio_db
CORS_ORIGINS=http://localhost,...      # Allowed origins
EC2_HOST=your-ec2-ip.compute-1.amazonaws.com  # For deployment
SSH_KEY_PATH=/path/to/private/key.pem  # For deployment
```

## 📋 Checklist for Running

- [ ] Docker and Docker Compose installed
- [ ] Repository cloned
- [ ] `.env` file created from `.env.example`
- [ ] `bash scripts/setup.sh` executed
- [ ] `bash scripts/start.sh` executed
- [ ] Visit http://localhost in browser
- [ ] Create a portfolio in the dashboard
- [ ] Add some investments

## 🆘 Troubleshooting

**Port already in use:**

```bash
# Change port in docker-compose.yml or .env
# Or kill the process
sudo lsof -i :80  # Find process
sudo kill -9 <PID>  # Kill it
```

**Database won't connect:**

```bash
docker-compose logs db    # Check database logs
docker-compose down -v    # Remove and try again
make run                  # Restart
```

**Static files not loading:**

```bash
docker-compose restart nginx  # Restart nginx
ls frontend/static/          # Verify files exist
```

**API not responding:**

```bash
curl http://localhost:8000/health  # Test API
docker-compose logs app            # Check app logs
```

## 📚 More Information

- **Full Documentation**: See [README.md](README.md)
- **API Documentation**: http://localhost:8000/docs
- **Frontend**: http://localhost
- **GitHub Issues**: Report bugs or request features

## 💡 Next Steps

1. **Customize**: Edit frontend and backend as needed
2. **Add Features**: Extend models, add new endpoints
3. **Deploy**: Set up EC2 and GitHub Actions
4. **Monitor**: Check logs with `make logs`
5. **Backup**: Regular backups with `make backup`

## 🤝 Contributing

Found a bug or want to contribute?

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

---

**Need Help?** Check the full README.md or create an issue on GitHub!
