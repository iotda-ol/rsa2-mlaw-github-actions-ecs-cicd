# Quick Reference Guide

Quick commands and references for common tasks.

## Quick Start

```bash
# Clone repository
git clone https://github.com/iotda-ol/rsa2-mlaw-github-actions-ecs-cicd.git
cd rsa2-mlaw-github-actions-ecs-cicd

# Deploy dev infrastructure
cd terraform/environments/dev
terraform init
terraform apply

# Deploy prod infrastructure
cd ../prod
terraform init
terraform apply

# Deploy application
git checkout develop
git push origin develop  # Deploys to dev

git checkout main
git push origin main     # Deploys to prod
```

## Common AWS CLI Commands

### ECR

```bash
# Login to ECR
aws ecr get-login-password --region us-east-1 | \
  docker login --username AWS --password-stdin ACCOUNT.dkr.ecr.us-east-1.amazonaws.com

# List images
aws ecr list-images --repository-name cicd-demo-app

# Describe repository
aws ecr describe-repositories --repository-names cicd-demo-app

# Delete image
aws ecr batch-delete-image \
  --repository-name cicd-demo-app \
  --image-ids imageTag=TAG
```

### ECS

```bash
# List clusters
aws ecs list-clusters

# Describe cluster
aws ecs describe-clusters --clusters dev-cicd-demo-cluster

# List services
aws ecs list-services --cluster dev-cicd-demo-cluster

# Describe service
aws ecs describe-services \
  --cluster dev-cicd-demo-cluster \
  --services dev-cicd-demo-service

# List tasks
aws ecs list-tasks \
  --cluster dev-cicd-demo-cluster \
  --service-name dev-cicd-demo-service

# Describe task
aws ecs describe-tasks \
  --cluster dev-cicd-demo-cluster \
  --tasks TASK_ARN

# Update service (force new deployment)
aws ecs update-service \
  --cluster dev-cicd-demo-cluster \
  --service dev-cicd-demo-service \
  --force-new-deployment

# Scale service
aws ecs update-service \
  --cluster dev-cicd-demo-cluster \
  --service dev-cicd-demo-service \
  --desired-count 3

# Stop task
aws ecs stop-task \
  --cluster dev-cicd-demo-cluster \
  --task TASK_ARN
```

### CloudWatch Logs

```bash
# List log groups
aws logs describe-log-groups --log-group-name-prefix /ecs/

# Tail logs
aws logs tail /ecs/dev-cicd-demo-service --follow

# Get logs (last 5 minutes)
aws logs tail /ecs/dev-cicd-demo-service --since 5m

# Get logs (specific time range)
aws logs tail /ecs/dev-cicd-demo-service \
  --since "2024-01-01T00:00:00" \
  --until "2024-01-01T01:00:00"
```

### Application Load Balancer

```bash
# List load balancers
aws elbv2 describe-load-balancers

# Describe target groups
aws elbv2 describe-target-groups

# Describe target health
aws elbv2 describe-target-health \
  --target-group-arn TARGET_GROUP_ARN

# Get ALB DNS name
aws elbv2 describe-load-balancers \
  --names dev-cicd-demo-service-alb \
  --query 'LoadBalancers[0].DNSName' \
  --output text
```

### CodeDeploy (Production)

```bash
# List applications
aws deploy list-applications

# List deployments
aws deploy list-deployments \
  --application-name prod-cicd-demo-service-app

# Get deployment
aws deploy get-deployment --deployment-id DEPLOYMENT_ID

# Stop deployment
aws deploy stop-deployment \
  --deployment-id DEPLOYMENT_ID \
  --auto-rollback-enabled
```

## Docker Commands

```bash
# Build image
docker build -t cicd-demo-app:latest .

# Run container
docker run -p 3000:3000 -e NODE_ENV=development cicd-demo-app:latest

# Run in background
docker run -d -p 3000:3000 cicd-demo-app:latest

# View logs
docker logs CONTAINER_ID

# Stop container
docker stop CONTAINER_ID

# Remove container
docker rm CONTAINER_ID

# List images
docker images

# Remove image
docker rmi IMAGE_ID

# Scan with Trivy
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
  aquasec/trivy image cicd-demo-app:latest
```

## Terraform Commands

```bash
# Initialize
terraform init

# Validate
terraform validate

# Format
terraform fmt

# Plan
terraform plan -out=tfplan

# Apply
terraform apply tfplan

# Show
terraform show

# Output
terraform output

# Destroy
terraform destroy

# State list
terraform state list

# State show
terraform state show RESOURCE

# Import
terraform import RESOURCE ID

# Refresh
terraform refresh
```

## Git Workflow

```bash
# Create feature branch
git checkout -b feature/my-feature

# Make changes
git add .
git commit -m "Description of changes"

# Push to remote
git push origin feature/my-feature

# Create PR via GitHub UI

# Merge to develop (deploys to dev)
git checkout develop
git merge feature/my-feature
git push origin develop

# Merge to main (deploys to prod)
git checkout main
git merge develop
git push origin main
```

## Testing Commands

```bash
# Install dependencies
cd app
npm install

# Run tests
npm test

# Run tests with coverage
npm test -- --coverage

# Run tests in watch mode
npm test -- --watch

# Lint code (if configured)
npm run lint
```

## Health Check Commands

```bash
# Local
curl http://localhost:3000/health

# Development
curl http://DEV_ALB_DNS/health

# Production
curl http://PROD_ALB_DNS/health

# With JSON formatting
curl -s http://ALB_DNS/health | jq .

# Check all endpoints
curl http://ALB_DNS/
curl http://ALB_DNS/health
```

## Debugging Commands

```bash
# Get task logs
aws logs tail /ecs/dev-cicd-demo-service --since 5m

# Check service events
aws ecs describe-services \
  --cluster dev-cicd-demo-cluster \
  --services dev-cicd-demo-service \
  --query 'services[0].events[0:5]'

# Check task definition
aws ecs describe-task-definition \
  --task-definition dev-cicd-demo-service

# Check running tasks
aws ecs list-tasks \
  --cluster dev-cicd-demo-cluster \
  --service-name dev-cicd-demo-service

# Describe specific task
TASK_ARN=$(aws ecs list-tasks \
  --cluster dev-cicd-demo-cluster \
  --service-name dev-cicd-demo-service \
  --query 'taskArns[0]' \
  --output text)

aws ecs describe-tasks \
  --cluster dev-cicd-demo-cluster \
  --tasks $TASK_ARN

# Check security groups
aws ec2 describe-security-groups \
  --filters "Name=tag:Name,Values=dev-ecs-tasks-sg"

# Check VPC
aws ec2 describe-vpcs \
  --filters "Name=tag:Environment,Values=dev"
```

## Monitoring Commands

```bash
# CloudWatch metrics
aws cloudwatch get-metric-statistics \
  --namespace AWS/ECS \
  --metric-name CPUUtilization \
  --dimensions Name=ServiceName,Value=dev-cicd-demo-service \
              Name=ClusterName,Value=dev-cicd-demo-cluster \
  --start-time 2024-01-01T00:00:00Z \
  --end-time 2024-01-01T01:00:00Z \
  --period 300 \
  --statistics Average

# List alarms
aws cloudwatch describe-alarms

# Get alarm state
aws cloudwatch describe-alarms \
  --alarm-names ecs-high-cpu
```

## Rollback Commands

```bash
# Via GitHub Actions
# 1. Go to Actions → Rollback Deployment
# 2. Click "Run workflow"
# 3. Select environment and optional revision
# 4. Click "Run workflow"

# Via AWS CLI - Get previous revision
aws ecs list-task-definitions \
  --family-prefix dev-cicd-demo \
  --sort DESC \
  --max-items 5

# Rollback to specific revision
aws ecs update-service \
  --cluster dev-cicd-demo-cluster \
  --service dev-cicd-demo-service \
  --task-definition dev-cicd-demo:PREVIOUS_REVISION

# For production (CodeDeploy)
aws deploy stop-deployment \
  --deployment-id DEPLOYMENT_ID \
  --auto-rollback-enabled
```

## Environment Variables

```bash
# Set for local development
export NODE_ENV=development
export PORT=3000
export APP_VERSION=local

# AWS profile
export AWS_PROFILE=default
export AWS_REGION=us-east-1

# Docker build args
docker build \
  --build-arg NODE_ENV=production \
  --build-arg APP_VERSION=1.0.0 \
  -t cicd-demo-app:latest .
```

## Useful Aliases

Add to `~/.bashrc` or `~/.zshrc`:

```bash
# AWS ECS
alias ecs-dev='aws ecs describe-services --cluster dev-cicd-demo-cluster --services dev-cicd-demo-service'
alias ecs-prod='aws ecs describe-services --cluster prod-cicd-demo-cluster --services prod-cicd-demo-service'
alias ecs-tasks-dev='aws ecs list-tasks --cluster dev-cicd-demo-cluster --service-name dev-cicd-demo-service'
alias ecs-tasks-prod='aws ecs list-tasks --cluster prod-cicd-demo-cluster --service-name prod-cicd-demo-service'

# CloudWatch Logs
alias logs-dev='aws logs tail /ecs/dev-cicd-demo-service --follow'
alias logs-prod='aws logs tail /ecs/prod-cicd-demo-service --follow'

# Terraform
alias tf='terraform'
alias tfi='terraform init'
alias tfp='terraform plan'
alias tfa='terraform apply'
alias tfd='terraform destroy'
alias tfo='terraform output'

# Docker
alias dps='docker ps'
alias dimg='docker images'
alias dlogs='docker logs'
alias dstop='docker stop $(docker ps -q)'
alias drm='docker rm $(docker ps -aq)'
```

## Directory Structure

```
.
├── .github/
│   └── workflows/
│       ├── cicd-pipeline.yml    # Main CI/CD workflow
│       └── rollback.yml          # Rollback workflow
├── app/
│   ├── server.js                 # Application code
│   ├── server.test.js            # Tests
│   ├── package.json              # Dependencies
│   └── jest.config.js            # Test configuration
├── docs/
│   ├── ARCHITECTURE.md           # Architecture details
│   ├── DEPLOYMENT.md             # Deployment strategies
│   ├── SECURITY.md               # Security documentation
│   └── SETUP.md                  # Setup guide
├── terraform/
│   ├── modules/
│   │   ├── ecr/                  # ECR module
│   │   ├── ecs/                  # ECS module
│   │   ├── iam/                  # IAM module
│   │   └── networking/           # VPC/networking module
│   └── environments/
│       ├── dev/                  # Dev environment
│       └── prod/                 # Prod environment
├── Dockerfile                    # Container definition
├── appspec.yaml                  # CodeDeploy config
├── .gitignore                    # Git ignore rules
└── README.md                     # Main documentation
```

## GitHub Secrets Required

```
AWS_ACCESS_KEY_ID         # AWS access key for deployments
AWS_SECRET_ACCESS_KEY     # AWS secret key for deployments

# Or for OIDC (recommended):
AWS_ROLE_ARN              # IAM role ARN for GitHub Actions
```

## Terraform Outputs

```bash
# Get all outputs
terraform output

# Get specific output
terraform output ecr_repository_url
terraform output alb_dns_name
terraform output ecs_cluster_name
terraform output ecs_service_name

# Get as JSON
terraform output -json

# Use in scripts
ECR_URL=$(terraform output -raw ecr_repository_url)
ALB_DNS=$(terraform output -raw alb_dns_name)
```

## Cost Estimation

```bash
# Development (~$30-50/month)
- Fargate: $10-20
- NAT Gateway: $15-20
- ALB: $5-10

# Production (~$80-120/month)
- Fargate: $30-50
- NAT Gateway: $30-40
- ALB: $10-15
- CodeDeploy: Free (for ECS)

# Shared
- ECR: $0.10/GB
- CloudWatch Logs: $0.50/GB
- Data Transfer: Variable
```

## Important URLs

```bash
# Local
http://localhost:3000

# Development
http://dev-cicd-demo-service-alb-XXXXXXXX.us-east-1.elb.amazonaws.com

# Production
http://prod-cicd-demo-service-alb-XXXXXXXX.us-east-1.elb.amazonaws.com

# AWS Console
https://console.aws.amazon.com/ecs/
https://console.aws.amazon.com/ecr/
https://console.aws.amazon.com/cloudwatch/
https://console.aws.amazon.com/codesuite/codedeploy/

# GitHub
https://github.com/iotda-ol/rsa2-mlaw-github-actions-ecs-cicd
https://github.com/iotda-ol/rsa2-mlaw-github-actions-ecs-cicd/actions
```

## Emergency Procedures

### Service Down

```bash
# 1. Check service status
aws ecs describe-services \
  --cluster CLUSTER \
  --services SERVICE

# 2. Check task health
aws ecs list-tasks --cluster CLUSTER --service-name SERVICE

# 3. Check logs
aws logs tail /ecs/ENV-cicd-demo-service --since 10m

# 4. Force new deployment
aws ecs update-service \
  --cluster CLUSTER \
  --service SERVICE \
  --force-new-deployment

# 5. Scale up if needed
aws ecs update-service \
  --cluster CLUSTER \
  --service SERVICE \
  --desired-count 4
```

### Rollback Production

```bash
# Option 1: GitHub Actions (recommended)
# Actions → Rollback Deployment → Run

# Option 2: AWS CLI
aws ecs update-service \
  --cluster prod-cicd-demo-cluster \
  --service prod-cicd-demo-service \
  --task-definition prod-cicd-demo:PREVIOUS_REVISION

# Option 3: CodeDeploy
aws deploy stop-deployment \
  --deployment-id DEPLOYMENT_ID \
  --auto-rollback-enabled
```

## Support

- **Documentation**: Check `docs/` folder
- **Issues**: GitHub Issues
- **Security**: Create Security Advisory
- **AWS Support**: AWS Support Console

## Resources

- [Main README](../README.md)
- [Setup Guide](SETUP.md)
- [Architecture](ARCHITECTURE.md)
- [Security](SECURITY.md)
- [Deployment](DEPLOYMENT.md)
