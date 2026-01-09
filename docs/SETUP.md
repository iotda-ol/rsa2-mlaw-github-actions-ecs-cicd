# Setup Guide

This guide walks you through setting up the complete CI/CD pipeline from scratch.

## Prerequisites Checklist

- [ ] AWS account with admin access
- [ ] AWS CLI installed and configured
- [ ] Terraform >= 1.0 installed
- [ ] Docker installed
- [ ] Node.js 18+ installed
- [ ] Git installed
- [ ] GitHub account with repository access

## Step-by-Step Setup

### Step 1: AWS Account Setup

1. **Create AWS Account** (if you don't have one)
   - Visit https://aws.amazon.com
   - Follow the account creation process
   - Verify your email and payment method

2. **Create IAM User for Terraform**
   ```bash
   # Create user
   aws iam create-user --user-name terraform-user
   
   # Attach AdministratorAccess policy (for initial setup)
   aws iam attach-user-policy \
     --user-name terraform-user \
     --policy-arn arn:aws:iam::aws:policy/AdministratorAccess
   
   # Create access key
   aws iam create-access-key --user-name terraform-user
   ```
   
   **Note**: For production, use a more restrictive policy.

3. **Configure AWS CLI**
   ```bash
   aws configure
   # Enter:
   # - AWS Access Key ID
   # - AWS Secret Access Key
   # - Default region: us-east-1
   # - Default output format: json
   ```

4. **Verify Configuration**
   ```bash
   aws sts get-caller-identity
   ```

### Step 2: Clone Repository

```bash
# Clone the repository
git clone https://github.com/iotda-ol/rsa2-mlaw-github-actions-ecs-cicd.git

# Navigate to the directory
cd rsa2-mlaw-github-actions-ecs-cicd

# Verify structure
ls -la
```

### Step 3: Configure Terraform Backend (Optional but Recommended)

For production use, configure remote state storage:

1. **Create S3 Bucket for Terraform State**
   ```bash
   # Create bucket (replace with unique name)
   aws s3 mb s3://my-terraform-state-bucket-unique-name
   
   # Enable versioning
   aws s3api put-bucket-versioning \
     --bucket my-terraform-state-bucket-unique-name \
     --versioning-configuration Status=Enabled
   
   # Enable encryption
   aws s3api put-bucket-encryption \
     --bucket my-terraform-state-bucket-unique-name \
     --server-side-encryption-configuration '{
       "Rules": [{
         "ApplyServerSideEncryptionByDefault": {
           "SSEAlgorithm": "AES256"
         }
       }]
     }'
   ```

2. **Create DynamoDB Table for State Locking**
   ```bash
   aws dynamodb create-table \
     --table-name terraform-state-lock \
     --attribute-definitions AttributeName=LockID,AttributeType=S \
     --key-schema AttributeName=LockID,KeyType=HASH \
     --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5
   ```

3. **Update Terraform Configuration**
   
   Edit `terraform/environments/dev/main.tf` and uncomment the backend block:
   ```hcl
   backend "s3" {
     bucket         = "my-terraform-state-bucket-unique-name"
     key            = "dev/terraform.tfstate"
     region         = "us-east-1"
     encrypt        = true
     dynamodb_table = "terraform-state-lock"
   }
   ```

### Step 4: Deploy Development Infrastructure

1. **Navigate to Dev Environment**
   ```bash
   cd terraform/environments/dev
   ```

2. **Initialize Terraform**
   ```bash
   terraform init
   ```

3. **Review Planned Changes**
   ```bash
   terraform plan
   ```
   
   Review the output to understand what will be created.

4. **Apply Infrastructure**
   ```bash
   terraform apply
   ```
   
   Type `yes` when prompted.
   
   This will create:
   - VPC with subnets
   - Security groups
   - ECR repository
   - ECS cluster
   - ALB
   - IAM roles
   - CloudWatch log groups

5. **Save Outputs**
   ```bash
   terraform output > outputs.txt
   ```

6. **Note Important Values**
   - ECR repository URL
   - ALB DNS name
   - ECS cluster name
   - GitHub Actions role ARN (if OIDC enabled)

### Step 5: Deploy Production Infrastructure

1. **Navigate to Prod Environment**
   ```bash
   cd ../prod
   ```

2. **Initialize Terraform**
   ```bash
   terraform init
   ```

3. **Apply Infrastructure**
   ```bash
   terraform apply
   ```

4. **Save Outputs**
   ```bash
   terraform output > outputs.txt
   ```

### Step 6: Configure GitHub Repository

1. **Add GitHub Secrets**
   
   Navigate to: Repository → Settings → Secrets and variables → Actions → New repository secret
   
   Add the following secrets:
   - `AWS_ACCESS_KEY_ID`: Your AWS access key
   - `AWS_SECRET_ACCESS_KEY`: Your AWS secret key
   
   **Alternative (Recommended): Use OIDC**
   - `AWS_ROLE_ARN`: The GitHub Actions role ARN from Terraform output

2. **Enable GitHub Actions**
   - Navigate to Actions tab
   - Enable workflows if prompted

3. **Protect Main Branch**
   - Go to Settings → Branches
   - Add branch protection rule for `main`
   - Enable:
     - Require pull request reviews
     - Require status checks to pass
     - Include administrators

### Step 7: Test Local Application

1. **Install Dependencies**
   ```bash
   cd ../../../app
   npm install
   ```

2. **Run Tests**
   ```bash
   npm test
   ```

3. **Run Locally**
   ```bash
   npm start
   ```
   
   Visit http://localhost:3000

4. **Test Health Endpoint**
   ```bash
   curl http://localhost:3000/health
   ```

### Step 8: Build and Test Docker Image

1. **Build Image**
   ```bash
   cd ..
   docker build -t cicd-demo-app:test .
   ```

2. **Run Container**
   ```bash
   docker run -p 3000:3000 -e NODE_ENV=development cicd-demo-app:test
   ```

3. **Test Container**
   ```bash
   curl http://localhost:3000
   curl http://localhost:3000/health
   ```

4. **Stop Container**
   ```bash
   docker ps  # Find container ID
   docker stop <container-id>
   ```

### Step 9: Push Initial Image to ECR

This ensures the ECS service has an image to start with:

1. **Login to ECR**
   ```bash
   aws ecr get-login-password --region us-east-1 | \
     docker login --username AWS --password-stdin <ECR_REGISTRY_URL>
   ```

2. **Tag Image**
   ```bash
   docker tag cicd-demo-app:test <ECR_REPOSITORY_URL>:latest
   ```

3. **Push Image**
   ```bash
   docker push <ECR_REPOSITORY_URL>:latest
   ```

### Step 10: Initial Deployment

1. **Create Develop Branch**
   ```bash
   git checkout -b develop
   git push origin develop
   ```

2. **Trigger First Deployment**
   ```bash
   # Make a small change
   echo "\n# Initial deployment" >> README.md
   git add README.md
   git commit -m "Initial deployment"
   git push origin develop
   ```

3. **Monitor Deployment**
   - Go to GitHub Actions tab
   - Watch the workflow run
   - Verify all jobs complete successfully

4. **Verify Deployment**
   ```bash
   # Get ALB DNS from Terraform output
   ALB_DNS=$(cd terraform/environments/dev && terraform output -raw alb_dns_name)
   
   # Test endpoint
   curl http://$ALB_DNS/health
   ```

### Step 11: Deploy to Production

1. **Merge to Main**
   ```bash
   git checkout main
   git merge develop
   git push origin main
   ```

2. **Monitor Blue/Green Deployment**
   - Watch GitHub Actions
   - Monitor CodeDeploy console
   - Verify traffic shift

3. **Verify Production**
   ```bash
   ALB_DNS=$(cd terraform/environments/prod && terraform output -raw alb_dns_name)
   curl http://$ALB_DNS/health
   ```

## Verification Steps

### 1. Verify Infrastructure

```bash
# Check VPC
aws ec2 describe-vpcs --filters "Name=tag:Environment,Values=dev"

# Check ECS cluster
aws ecs describe-clusters --clusters dev-cicd-demo-cluster

# Check running tasks
aws ecs list-tasks --cluster dev-cicd-demo-cluster

# Check ECR images
aws ecr list-images --repository-name cicd-demo-app
```

### 2. Verify Application

```bash
# Health check
curl http://<ALB_DNS>/health

# Main endpoint
curl http://<ALB_DNS>/

# Expected response:
# {
#   "message": "CI/CD Pipeline Demo Application",
#   "version": "1.0.0",
#   "environment": "development"
# }
```

### 3. Verify Monitoring

```bash
# View logs
aws logs tail /ecs/dev-cicd-demo-service --follow

# Check metrics
aws cloudwatch list-metrics --namespace AWS/ECS
```

## Troubleshooting Setup Issues

### Issue: Terraform Init Fails

**Solution**:
```bash
# Clear Terraform cache
rm -rf .terraform .terraform.lock.hcl

# Re-initialize
terraform init
```

### Issue: AWS Credentials Not Working

**Solution**:
```bash
# Verify credentials
aws sts get-caller-identity

# Re-configure if needed
aws configure
```

### Issue: ECS Tasks Not Starting

**Solutions**:
1. Check CloudWatch logs for errors
2. Verify ECR image exists
3. Check security group rules
4. Verify task execution role permissions

```bash
# Check service events
aws ecs describe-services \
  --cluster dev-cicd-demo-cluster \
  --services dev-cicd-demo-service \
  --query 'services[0].events[0:5]'
```

### Issue: ALB Returns 503

**Solutions**:
1. Verify tasks are running
2. Check target group health
3. Verify security group rules

```bash
# Check target group
aws elbv2 describe-target-health \
  --target-group-arn <TARGET_GROUP_ARN>
```

### Issue: Cannot Push to ECR

**Solutions**:
1. Verify ECR login
2. Check repository name
3. Verify IAM permissions

```bash
# Re-login to ECR
aws ecr get-login-password --region us-east-1 | \
  docker login --username AWS --password-stdin <ECR_URL>
```

## Next Steps

After successful setup:

1. **Configure Custom Domain**
   - Set up Route53 hosted zone
   - Create ACM certificate
   - Update ALB listener

2. **Enable HTTPS**
   - Request ACM certificate
   - Add HTTPS listener to ALB
   - Redirect HTTP to HTTPS

3. **Set Up Monitoring**
   - Create CloudWatch dashboards
   - Configure alarms
   - Set up SNS notifications

4. **Implement Additional Environments**
   - Create staging environment
   - Configure environment promotion

5. **Enhance Security**
   - Enable OIDC for GitHub Actions
   - Implement WAF rules
   - Enable VPC flow logs
   - Configure AWS Config rules

6. **Cost Optimization**
   - Review auto-scaling settings
   - Implement ECR lifecycle policies
   - Set up AWS Budgets
   - Enable Cost Explorer

## Clean Up (When Needed)

To tear down the infrastructure:

```bash
# Destroy production
cd terraform/environments/prod
terraform destroy

# Destroy development
cd ../dev
terraform destroy

# Delete ECR images (if needed)
aws ecr batch-delete-image \
  --repository-name cicd-demo-app \
  --image-ids "$(aws ecr list-images --repository-name cicd-demo-app --query 'imageIds[*]' --output json)"

# Delete ECR repository (if needed)
aws ecr delete-repository \
  --repository-name cicd-demo-app \
  --force
```

## Support

For issues or questions:
- Check [Troubleshooting Guide](../README.md#troubleshooting)
- Review [Architecture Documentation](ARCHITECTURE.md)
- Open GitHub issue
- Check AWS documentation

## Additional Resources

- [AWS ECS Getting Started](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/getting-started.html)
- [Terraform Tutorial](https://learn.hashicorp.com/terraform)
- [GitHub Actions Quickstart](https://docs.github.com/en/actions/quickstart)
- [Docker Best Practices](https://docs.docker.com/develop/dev-best-practices/)
