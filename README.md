# CI/CD Pipeline with GitHub Actions and AWS ECS

End-to-end CI/CD pipeline using GitHub Actions for Docker builds, security scanning, ECR publishing, and automated ECS blue/green deployments.

## 📋 Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Features](#features)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Infrastructure Setup](#infrastructure-setup)
- [GitHub Actions Workflows](#github-actions-workflows)
- [Deployment Strategies](#deployment-strategies)
- [Security](#security)
- [Rollback Procedures](#rollback-procedures)
- [Monitoring and Logging](#monitoring-and-logging)
- [Troubleshooting](#troubleshooting)

## 🎯 Overview

This project demonstrates a production-ready CI/CD pipeline that:
- Builds and tests a containerized Node.js application
- Performs container vulnerability scanning with Trivy
- Pushes Docker images to Amazon ECR
- Deploys to Amazon ECS using blue/green deployment strategies
- Implements IAM least-privilege access controls
- Supports multiple environments (dev, prod)
- Provides rollback capabilities

## 🏗️ Architecture

```
┌─────────────────┐
│  GitHub Actions │
│   CI/CD Pipeline│
└────────┬────────┘
         │
         ├──► Build & Test
         ├──► Security Scan (Trivy)
         ├──► Push to ECR
         └──► Deploy to ECS
              │
              ├──► Development (Rolling)
              └──► Production (Blue/Green)
```

### Infrastructure Components

- **VPC**: Isolated network with public and private subnets across 2 AZs
- **Application Load Balancer**: Distributes traffic with health checks
- **ECS Fargate**: Serverless container orchestration
- **ECR**: Private Docker image registry
- **CloudWatch**: Centralized logging and monitoring
- **CodeDeploy**: Blue/green deployment orchestration
- **IAM**: Least-privilege access control

## ✨ Features

### CI/CD Pipeline
- ✅ Automated testing on every commit
- ✅ Container security scanning with Trivy
- ✅ Multi-stage Docker builds for optimal image size
- ✅ Automatic deployment to dev on develop branch
- ✅ Blue/green deployment to production on main branch
- ✅ Pull request validation

### Security
- ✅ Container vulnerability scanning
- ✅ IAM least-privilege policies
- ✅ Non-root container user
- ✅ Image scanning on ECR push
- ✅ Encrypted ECR repositories
- ✅ Security group network isolation
- ✅ HTTPS support ready

### High Availability
- ✅ Multi-AZ deployment
- ✅ Auto-scaling based on CPU/Memory
- ✅ Health checks and automatic recovery
- ✅ Circuit breaker deployment
- ✅ Zero-downtime deployments

### Monitoring
- ✅ CloudWatch container insights
- ✅ Application and infrastructure logs
- ✅ ALB access logs
- ✅ Task-level metrics

## 📦 Prerequisites

### Required Tools
- AWS CLI (v2+)
- Terraform (v1.0+)
- Docker
- Node.js 18+ (for local development)
- Git

### AWS Account Setup
- AWS Account with appropriate permissions
- AWS credentials configured (`aws configure`)

### GitHub Setup
- GitHub repository with Actions enabled
- GitHub secrets configured (see below)

## 🚀 Quick Start

### 1. Clone the Repository

```bash
git clone https://github.com/iotda-ol/rsa2-mlaw-github-actions-ecs-cicd.git
cd rsa2-mlaw-github-actions-ecs-cicd
```

### 2. Configure GitHub Secrets

Add the following secrets to your GitHub repository (Settings → Secrets and variables → Actions):

```
AWS_ACCESS_KEY_ID          # AWS access key for GitHub Actions
AWS_SECRET_ACCESS_KEY      # AWS secret access key
```

**Note**: For enhanced security, consider using OIDC instead of long-lived credentials. See [OIDC Setup](#oidc-setup).

### 3. Deploy Infrastructure

```bash
# Development environment
cd terraform/environments/dev
terraform init
terraform plan
terraform apply

# Production environment
cd ../prod
terraform init
terraform plan
terraform apply
```

### 4. Build and Test Locally

```bash
# Install dependencies
cd app
npm install

# Run tests
npm test

# Build Docker image
docker build -t cicd-demo-app:local .

# Run locally
docker run -p 3000:3000 cicd-demo-app:local
```

### 5. Trigger Deployment

Push to the develop branch to deploy to development:
```bash
git checkout develop
git push origin develop
```

Push to the main branch to deploy to production:
```bash
git checkout main
git push origin main
```

## 🛠️ Infrastructure Setup

### Terraform Modules

The infrastructure is organized into reusable modules:

- **`modules/networking`**: VPC, subnets, security groups, NAT gateways
- **`modules/iam`**: IAM roles and policies for ECS, CodeDeploy, GitHub Actions
- **`modules/ecr`**: Container registry with lifecycle policies
- **`modules/ecs`**: ECS cluster, services, task definitions, ALB, auto-scaling

### Environment Configuration

#### Development Environment
- Location: `terraform/environments/dev/`
- Features:
  - Rolling deployments
  - Lower resource allocation (256 CPU, 512 MB)
  - 1-3 tasks
  - 7-day log retention

#### Production Environment
- Location: `terraform/environments/prod/`
- Features:
  - Blue/green deployments with CodeDeploy
  - Higher resource allocation (512 CPU, 1024 MB)
  - 2-10 tasks with auto-scaling
  - 30-day log retention
  - Deletion protection on ALB

### Terraform Commands

```bash
# Initialize Terraform
terraform init

# Plan changes
terraform plan -out=tfplan

# Apply changes
terraform apply tfplan

# Destroy resources (use with caution)
terraform destroy
```

## ⚙️ GitHub Actions Workflows

### Main CI/CD Pipeline (`.github/workflows/cicd-pipeline.yml`)

**Triggers:**
- Push to `main` or `develop`
- Pull requests to `main` or `develop`

**Jobs:**

1. **Test** - Runs unit tests and generates coverage reports
2. **Build** - Builds Docker image with multi-stage optimization
3. **Security Scan** - Scans for vulnerabilities using Trivy
4. **Push to ECR** - Pushes tagged images to Amazon ECR
5. **Deploy to Dev** - Deploys to development (develop branch only)
6. **Deploy to Production** - Blue/green deployment (main branch only)

### Rollback Workflow (`.github/workflows/rollback.yml`)

**Trigger:** Manual workflow dispatch

**Parameters:**
- `environment`: Choose development or production
- `task_definition_revision`: Optional specific revision to rollback to

**Usage:**
1. Go to Actions tab in GitHub
2. Select "Rollback Deployment" workflow
3. Click "Run workflow"
4. Select environment and optional revision
5. Confirm rollback

## 🔄 Deployment Strategies

### Development Environment - Rolling Deployment

- **Strategy**: ECS rolling update
- **Process**:
  1. New tasks are started
  2. Health checks validate new tasks
  3. Old tasks are drained and stopped
  4. Circuit breaker rolls back on failure
- **Downtime**: Zero downtime
- **Rollback**: Automatic on deployment failure

### Production Environment - Blue/Green Deployment

- **Strategy**: CodeDeploy blue/green with ALB
- **Process**:
  1. New tasks (green) are deployed alongside existing (blue)
  2. Health checks validate green tasks
  3. Test traffic is routed to green
  4. Production traffic is shifted to green
  5. Blue tasks are terminated after 5 minutes
- **Downtime**: Zero downtime
- **Rollback**: Automatic on failure, manual via workflow

### Blue/Green Flow

```
Blue (Current) ──────► Production Traffic (100%)
                       │
                       │ Deploy New Version
                       │
Green (New)    ──────► Test Traffic
                       │
                       │ Health Checks Pass
                       │
Green (New)    ──────► Production Traffic (100%)
                       │
Blue (Old)     ──────► Terminated (after 5min)
```

## 🔒 Security

### Container Security

1. **Multi-stage Builds**: Reduces image size and attack surface
2. **Non-root User**: Application runs as unprivileged user
3. **Minimal Base Image**: Uses Alpine Linux
4. **Vulnerability Scanning**: Trivy scans for CVEs
5. **Image Scanning**: ECR scans on push

### Network Security

1. **Private Subnets**: ECS tasks run in private subnets
2. **Security Groups**: Least-privilege network rules
3. **NAT Gateway**: Controlled internet access
4. **ALB**: Public endpoint with configurable rules

### IAM Security

1. **Least Privilege**: Minimal permissions for each role
2. **Role Separation**: Distinct roles for execution and task
3. **OIDC Support**: Federated authentication for GitHub Actions
4. **Service-specific Policies**: Scoped to specific resources

#### IAM Roles

- **ECS Task Execution Role**: Pulls images, writes logs
- **ECS Task Role**: Application runtime permissions
- **CodeDeploy Role**: Blue/green deployment orchestration
- **GitHub Actions Role**: CI/CD pipeline permissions

### OIDC Setup

To use OIDC instead of long-lived credentials:

1. Enable OIDC in Terraform:
```hcl
variable "enable_github_oidc" {
  default = true
}
```

2. Update workflow to use OIDC:
```yaml
- name: Configure AWS credentials
  uses: aws-actions/configure-aws-credentials@v4
  with:
    role-to-assume: ${{ secrets.AWS_ROLE_ARN }}
    aws-region: us-east-1
```

3. Remove `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` secrets

## 🔙 Rollback Procedures

### Automatic Rollback

- **Development**: ECS deployment circuit breaker
- **Production**: CodeDeploy automatic rollback on failure

### Manual Rollback

#### Option 1: Using GitHub Actions Workflow

1. Navigate to Actions → Rollback Deployment
2. Click "Run workflow"
3. Select environment and optional revision
4. Monitor rollback progress

#### Option 2: Using AWS CLI

```bash
# List task definition revisions
aws ecs list-task-definitions --family-prefix cicd-demo-prod

# Update service to previous revision
aws ecs update-service \
  --cluster cicd-demo-cluster-prod \
  --service cicd-demo-service-prod \
  --task-definition cicd-demo-prod:PREVIOUS_REVISION \
  --force-new-deployment
```

#### Option 3: Using AWS Console

1. Go to ECS → Clusters → Service
2. Click "Update"
3. Select previous task definition revision
4. Click "Update service"

### Rollback Verification

```bash
# Check service status
aws ecs describe-services \
  --cluster cicd-demo-cluster-prod \
  --services cicd-demo-service-prod

# View running tasks
aws ecs list-tasks \
  --cluster cicd-demo-cluster-prod \
  --service-name cicd-demo-service-prod

# Check health
curl http://<ALB_DNS>/health
```

## 📊 Monitoring and Logging

### CloudWatch Logs

**View Logs:**
```bash
# List log streams
aws logs describe-log-streams \
  --log-group-name /ecs/prod-cicd-demo-service

# Tail logs
aws logs tail /ecs/prod-cicd-demo-service --follow
```

### CloudWatch Metrics

Key metrics to monitor:
- **ECS Service**: CPU, Memory utilization
- **ALB**: Request count, latency, HTTP errors
- **Tasks**: Running count, deployment status

### Container Insights

Enable detailed container metrics:
- CPU and memory at task/container level
- Network metrics
- Storage metrics

### Alarms (Recommended)

```bash
# Example: High CPU alarm
aws cloudwatch put-metric-alarm \
  --alarm-name ecs-high-cpu \
  --alarm-description "Alert when CPU exceeds 80%" \
  --metric-name CPUUtilization \
  --namespace AWS/ECS \
  --statistic Average \
  --period 300 \
  --threshold 80 \
  --comparison-operator GreaterThanThreshold
```

## 🔧 Troubleshooting

### Common Issues

#### 1. Deployment Failed

**Symptom**: GitHub Actions deployment job fails

**Solutions**:
- Check CloudWatch logs for application errors
- Verify security group rules allow ALB → ECS traffic
- Ensure task definition has correct image URI
- Check IAM role permissions

#### 2. Health Check Failures

**Symptom**: Tasks failing health checks and being replaced

**Solutions**:
- Verify `/health` endpoint is responding
- Check application logs for startup errors
- Increase health check grace period
- Verify security group rules

#### 3. Unable to Pull Image from ECR

**Symptom**: Tasks fail with "CannotPullContainerError"

**Solutions**:
- Verify task execution role has ECR permissions
- Check ECR repository exists and image is tagged
- Ensure ECR is in the same region as ECS

#### 4. Service Not Receiving Traffic

**Symptom**: ALB returns 503 errors

**Solutions**:
- Verify target group has healthy targets
- Check security group allows ALB → ECS traffic (port 3000)
- Ensure tasks are in RUNNING state
- Verify task ENI has correct security group

#### 5. Terraform Apply Fails

**Symptom**: Terraform errors during apply

**Solutions**:
- Check AWS credentials and permissions
- Verify region and availability zones
- Review Terraform state for conflicts
- Check for resource limits (VPC, EIP, etc.)

### Debugging Commands

```bash
# Check ECS service events
aws ecs describe-services \
  --cluster cicd-demo-cluster-prod \
  --services cicd-demo-service-prod \
  --query 'services[0].events[0:5]'

# Check task status
aws ecs describe-tasks \
  --cluster cicd-demo-cluster-prod \
  --tasks $(aws ecs list-tasks --cluster cicd-demo-cluster-prod --service-name cicd-demo-service-prod --query 'taskArns[0]' --output text)

# Check ALB target health
aws elbv2 describe-target-health \
  --target-group-arn <TARGET_GROUP_ARN>

# View recent logs
aws logs tail /ecs/prod-cicd-demo-service --since 5m
```

### Getting Help

- **AWS Support**: For infrastructure issues
- **GitHub Issues**: For pipeline and code issues
- **Documentation**: AWS ECS, CodeDeploy, GitHub Actions docs

## 📝 Additional Resources

- [AWS ECS Best Practices](https://docs.aws.amazon.com/AmazonECS/latest/bestpracticesguide/intro.html)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Docker Best Practices](https://docs.docker.com/develop/dev-best-practices/)
- [Trivy Scanner](https://github.com/aquasecurity/trivy)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License.

## 👥 Authors

CI/CD Pipeline Implementation Team

---

**Note**: This is a demonstration project. For production use, ensure you:
- Configure remote Terraform state (S3 + DynamoDB)
- Set up proper DNS and SSL/TLS certificates
- Implement comprehensive monitoring and alerting
- Configure backup and disaster recovery
- Review and adjust security settings for your requirements
- Implement cost management and budgets
