# Architecture Documentation

## Overview

This document provides detailed architecture information for the CI/CD pipeline.

## System Architecture

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         GitHub Repository                        │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐          │
│  │ Application  │  │   Terraform  │  │   Workflows  │          │
│  │    Code      │  │     IaC      │  │    CI/CD     │          │
│  └──────────────┘  └──────────────┘  └──────────────┘          │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         │ Git Push / PR
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│                      GitHub Actions                              │
│  ┌─────────┐  ┌─────────┐  ┌──────────┐  ┌──────────┐          │
│  │  Test   │→ │  Build  │→ │  Scan    │→ │  Deploy  │          │
│  └─────────┘  └─────────┘  └──────────┘  └──────────┘          │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         │ Deploy
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│                       AWS Cloud                                  │
│                                                                  │
│  ┌────────────────────────────────────────────────────────┐    │
│  │                          VPC                            │    │
│  │  ┌──────────────────────────────────────────────────┐  │    │
│  │  │            Public Subnets (2 AZs)                │  │    │
│  │  │  ┌──────────────┐         ┌─────────────────┐   │  │    │
│  │  │  │     ALB      │────────►│   NAT Gateway   │   │  │    │
│  │  │  └──────────────┘         └─────────────────┘   │  │    │
│  │  └──────────────────────────────────────────────────┘  │    │
│  │                           │                             │    │
│  │  ┌──────────────────────────────────────────────────┐  │    │
│  │  │           Private Subnets (2 AZs)                │  │    │
│  │  │  ┌─────────────────────────────────────────┐    │  │    │
│  │  │  │         ECS Fargate Cluster             │    │  │    │
│  │  │  │  ┌────────┐  ┌────────┐  ┌────────┐    │    │  │    │
│  │  │  │  │ Task 1 │  │ Task 2 │  │ Task N │    │    │  │    │
│  │  │  │  └────────┘  └────────┘  └────────┘    │    │  │    │
│  │  │  └─────────────────────────────────────────┘    │  │    │
│  │  └──────────────────────────────────────────────────┘  │    │
│  └────────────────────────────────────────────────────────┘    │
│                                                                  │
│  ┌────────────┐  ┌──────────────┐  ┌────────────────┐         │
│  │    ECR     │  │  CloudWatch  │  │   CodeDeploy   │         │
│  │  Registry  │  │   Logs       │  │   (Prod Only)  │         │
│  └────────────┘  └──────────────┘  └────────────────┘         │
└─────────────────────────────────────────────────────────────────┘
```

## Component Details

### 1. Application Layer

**Technology**: Node.js with Express
**Purpose**: Demo web application with health checks
**Key Features**:
- RESTful API endpoints
- Health check endpoint
- Graceful shutdown handling
- Environment-aware configuration

### 2. CI/CD Pipeline

**Platform**: GitHub Actions
**Stages**:

1. **Test Stage**
   - Runs unit tests
   - Generates coverage reports
   - Validates code quality

2. **Build Stage**
   - Multi-stage Docker build
   - Image optimization
   - Tagging with commit SHA

3. **Security Scan Stage**
   - Trivy vulnerability scanning
   - SARIF report generation
   - Critical/High severity detection

4. **Push Stage**
   - ECR authentication
   - Image push with tags
   - Latest tag update

5. **Deploy Stage**
   - Environment-specific deployment
   - Rolling update (dev)
   - Blue/green deployment (prod)

### 3. Container Registry

**Service**: Amazon ECR
**Features**:
- Image scanning on push
- Lifecycle policies (keep 30 images)
- AES256 encryption
- Private repository

### 4. Compute Layer

**Service**: Amazon ECS Fargate
**Configuration**:

**Development**:
- CPU: 256 units (0.25 vCPU)
- Memory: 512 MB
- Tasks: 1-3 (auto-scaling)
- Deployment: Rolling

**Production**:
- CPU: 512 units (0.5 vCPU)
- Memory: 1024 MB
- Tasks: 2-10 (auto-scaling)
- Deployment: Blue/Green

**Auto-scaling Triggers**:
- CPU > 70%
- Memory > 80%

### 5. Load Balancing

**Service**: Application Load Balancer
**Configuration**:
- Internet-facing
- HTTP/HTTPS listeners
- Health checks on `/health`
- Target groups for blue/green

**Health Check Settings**:
- Interval: 30 seconds
- Timeout: 5 seconds
- Healthy threshold: 2
- Unhealthy threshold: 3

### 6. Networking

**VPC Configuration**:
- CIDR: 10.0.0.0/16 (dev), 10.1.0.0/16 (prod)
- Availability Zones: 2
- Public Subnets: 2 (ALB, NAT)
- Private Subnets: 2 (ECS tasks)

**Security Groups**:

**ALB Security Group**:
- Inbound: 80, 443 from 0.0.0.0/0
- Outbound: All traffic

**ECS Tasks Security Group**:
- Inbound: 3000 from ALB SG
- Outbound: All traffic

### 7. Deployment Orchestration

**Development**: ECS Rolling Update
- No additional service required
- Circuit breaker for automatic rollback
- Maximum 200% of desired count
- Minimum 100% healthy

**Production**: AWS CodeDeploy
- Blue/Green deployment
- Traffic shifting
- Automatic rollback
- 5-minute termination wait

### 8. Monitoring & Logging

**CloudWatch Logs**:
- Log group per environment
- Retention: 7 days (dev), 30 days (prod)
- Structured logging

**Container Insights**:
- Enabled on ECS cluster
- CPU, memory, network metrics
- Task-level visibility

**Metrics**:
- Application metrics
- Infrastructure metrics
- Custom metrics support

### 9. IAM & Security

**IAM Roles**:

1. **ECS Task Execution Role**
   - ECR image pull
   - CloudWatch log writes
   - Secrets Manager (if needed)

2. **ECS Task Role**
   - Application runtime permissions
   - AWS service access (least privilege)

3. **CodeDeploy Role**
   - ECS service updates
   - Traffic shifting
   - Rollback operations

4. **GitHub Actions Role** (Optional OIDC)
   - ECR push access
   - ECS deployment
   - CodeDeploy triggering

## Data Flow

### Development Deployment Flow

```
1. Developer pushes to develop branch
2. GitHub Actions triggered
3. Run tests
4. Build Docker image
5. Scan for vulnerabilities
6. Push to ECR
7. Update ECS task definition
8. ECS performs rolling update
   a. Start new tasks
   b. Health check new tasks
   c. Stop old tasks
9. Deployment complete
```

### Production Deployment Flow

```
1. Developer merges to main branch
2. GitHub Actions triggered
3. Run tests
4. Build Docker image
5. Scan for vulnerabilities
6. Push to ECR
7. Update ECS task definition
8. Trigger CodeDeploy
9. CodeDeploy Blue/Green process:
   a. Deploy green tasks
   b. Health check green tasks
   c. Route test traffic to green
   d. Route production traffic to green
   e. Wait 5 minutes
   f. Terminate blue tasks
10. Deployment complete
```

## Scalability

### Horizontal Scaling
- Auto-scaling based on CPU/Memory
- Scale out: 60 second cooldown
- Scale in: 300 second cooldown
- Minimum: 1 (dev), 2 (prod)
- Maximum: 3 (dev), 10 (prod)

### Vertical Scaling
- Adjust task CPU/Memory in Terraform
- Larger instance types available
- Memory optimization for Node.js

## High Availability

### Multi-AZ Deployment
- 2 availability zones
- Tasks distributed across AZs
- ALB routes to healthy targets

### Fault Tolerance
- Health checks detect failures
- Automatic task replacement
- Circuit breaker deployment
- Automatic rollback

### Disaster Recovery
- Infrastructure as Code (Terraform)
- ECR image retention
- Task definition versioning
- CloudWatch log retention

## Security Considerations

### Network Security
- Private subnets for compute
- NAT gateway for outbound
- Security group restrictions
- VPC flow logs (optional)

### Application Security
- Non-root container user
- Read-only root filesystem (optional)
- Secrets via environment variables
- Container vulnerability scanning

### Access Control
- IAM least privilege
- Role-based access
- Service-specific permissions
- OIDC for GitHub (recommended)

### Compliance
- Encryption at rest (ECR)
- Encryption in transit (HTTPS ready)
- Audit logging (CloudTrail)
- Security scanning (Trivy)

## Cost Optimization

### Compute Costs
- Fargate pricing based on vCPU/Memory
- Auto-scaling reduces waste
- Right-sized task definitions

### Storage Costs
- ECR lifecycle policies
- CloudWatch log retention limits
- Image cleanup automation

### Network Costs
- NAT gateway data transfer
- Inter-AZ traffic
- ALB usage

### Recommendations
- Use ECR lifecycle policies
- Monitor CloudWatch logs size
- Review auto-scaling thresholds
- Consider Reserved Capacity (if predictable)

## Future Enhancements

### Potential Improvements
1. **HTTPS/SSL**: Add ACM certificates
2. **Custom Domain**: Route53 DNS
3. **WAF**: Web Application Firewall
4. **CDN**: CloudFront distribution
5. **Database**: RDS/DynamoDB integration
6. **Caching**: ElastiCache/Redis
7. **Monitoring**: Enhanced metrics, alarms
8. **Multi-Region**: Cross-region deployment
9. **Service Mesh**: App Mesh integration
10. **Secrets Management**: AWS Secrets Manager

### Testing Enhancements
1. Integration tests
2. E2E tests
3. Performance tests
4. Security tests (SAST/DAST)
5. Chaos engineering

## References

- [AWS ECS Documentation](https://docs.aws.amazon.com/ecs/)
- [AWS CodeDeploy Documentation](https://docs.aws.amazon.com/codedeploy/)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/)
