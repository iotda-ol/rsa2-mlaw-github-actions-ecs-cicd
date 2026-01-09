# Deployment Strategies Guide

This guide explains the deployment strategies used for different environments.

## Overview

The CI/CD pipeline implements two deployment strategies:
- **Rolling Deployment** for Development
- **Blue/Green Deployment** for Production

## Development Environment - Rolling Deployment

### What is Rolling Deployment?

Rolling deployment gradually replaces old tasks with new ones without creating a duplicate environment.

### How It Works

```
Step 1: Current State
┌─────────┐  ┌─────────┐
│ Task v1 │  │ Task v1 │  ← 100% traffic
└─────────┘  └─────────┘

Step 2: Start New Task
┌─────────┐  ┌─────────┐  ┌─────────┐
│ Task v1 │  │ Task v1 │  │ Task v2 │ ← Health checking
└─────────┘  └─────────┘  └─────────┘

Step 3: New Task Healthy
┌─────────┐  ┌─────────┐  ┌─────────┐
│ Task v1 │  │ Task v1 │  │ Task v2 │ ← Receives traffic
└─────────┘  └─────────┘  └─────────┘

Step 4: Stop Old Task
┌─────────┐  ┌─────────┐
│ Task v1 │  │ Task v2 │
└─────────┘  └─────────┘

Step 5: Continue Rolling
┌─────────┐  ┌─────────┐  ┌─────────┐
│ Task v1 │  │ Task v2 │  │ Task v2 │
└─────────┘  └─────────┘  └─────────┘

Step 6: Complete
┌─────────┐  ┌─────────┐
│ Task v2 │  │ Task v2 │  ← 100% traffic
└─────────┘  └─────────┘
```

### Configuration

**ECS Service Settings**:
```hcl
deployment_configuration {
  maximum_percent         = 200  # Can run 2x desired count
  minimum_healthy_percent = 100  # Always maintain full capacity
  
  deployment_circuit_breaker {
    enable   = true   # Auto-detect failures
    rollback = true   # Auto-rollback on failure
  }
}
```

### Advantages

✅ **Simple**: No additional infrastructure required  
✅ **Cost-effective**: No duplicate environment  
✅ **Fast**: Quicker than blue/green for small changes  
✅ **Resource-efficient**: Only runs what's needed  

### Disadvantages

⚠️ **Version Mix**: Old and new versions run simultaneously  
⚠️ **Slower Rollback**: Must deploy previous version  
⚠️ **Testing Window**: Limited time to detect issues  

### When Rolling Fails

**Circuit Breaker Detection**:
- Health checks fail
- Tasks crash repeatedly
- Service becomes unstable

**Automatic Actions**:
1. Stop deployment
2. Mark deployment as failed
3. Roll back to previous task definition
4. Alert via CloudWatch

### Best Practices

1. **Backward Compatibility**: Ensure new version works with old
2. **Database Migrations**: Make them backward compatible
3. **API Changes**: Version your APIs
4. **Health Checks**: Implement comprehensive checks
5. **Monitoring**: Watch metrics during deployment

## Production Environment - Blue/Green Deployment

### What is Blue/Green Deployment?

Blue/Green creates a complete duplicate environment (green) alongside the current one (blue), validates it, then switches traffic.

### How It Works

```
Step 1: Current State (Blue)
┌──────────────────────────────┐
│        Blue Environment       │
│  ┌─────────┐  ┌─────────┐   │ ← 100% Production Traffic
│  │ Task v1 │  │ Task v1 │   │
│  └─────────┘  └─────────┘   │
└──────────────────────────────┘

Step 2: Deploy Green
┌──────────────────────────────┐
│        Blue Environment       │
│  ┌─────────┐  ┌─────────┐   │ ← 100% Production Traffic
│  │ Task v1 │  │ Task v1 │   │
│  └─────────┘  └─────────┘   │
└──────────────────────────────┘
┌──────────────────────────────┐
│       Green Environment       │
│  ┌─────────┐  ┌─────────┐   │ ← Deploying
│  │ Task v2 │  │ Task v2 │   │
│  └─────────┘  └─────────┘   │
└──────────────────────────────┘

Step 3: Health Check Green
┌──────────────────────────────┐
│        Blue Environment       │
│  ┌─────────┐  ┌─────────┐   │ ← 100% Production Traffic
│  │ Task v1 │  │ Task v1 │   │
│  └─────────┘  └─────────┘   │
└──────────────────────────────┘
┌──────────────────────────────┐
│       Green Environment       │
│  ┌─────────┐  ┌─────────┐   │ ← Health Checks
│  │ Task v2 │  │ Task v2 │   │
│  └─────────┘  └─────────┘   │
└──────────────────────────────┘

Step 4: Test Traffic to Green
┌──────────────────────────────┐
│        Blue Environment       │
│  ┌─────────┐  ┌─────────┐   │ ← 100% Production Traffic
│  │ Task v1 │  │ Task v1 │   │
│  └─────────┘  └─────────┘   │
└──────────────────────────────┘
┌──────────────────────────────┐
│       Green Environment       │
│  ┌─────────┐  ┌─────────┐   │ ← Test Traffic Only
│  │ Task v2 │  │ Task v2 │   │
│  └─────────┘  └─────────┘   │
└──────────────────────────────┘

Step 5: Shift Production Traffic
┌──────────────────────────────┐
│        Blue Environment       │
│  ┌─────────┐  ┌─────────┐   │ ← Draining
│  │ Task v1 │  │ Task v1 │   │
│  └─────────┘  └─────────┘   │
└──────────────────────────────┘
┌──────────────────────────────┐
│       Green Environment       │
│  ┌─────────┐  ┌─────────┐   │ ← 100% Production Traffic
│  │ Task v2 │  │ Task v2 │   │
│  └─────────┘  └─────────┘   │
└──────────────────────────────┘

Step 6: Terminate Blue
┌──────────────────────────────┐
│       Green Environment       │
│  ┌─────────┐  ┌─────────┐   │ ← 100% Production Traffic
│  │ Task v2 │  │ Task v2 │   │
│  └─────────┘  └─────────┘   │
└──────────────────────────────┘
```

### Configuration

**CodeDeploy Settings**:
```hcl
deployment_config_name = "CodeDeployDefault.ECSAllAtOnce"

blue_green_deployment_config {
  deployment_ready_option {
    action_on_timeout = "CONTINUE_DEPLOYMENT"
  }

  terminate_blue_instances_on_deployment_success {
    action                           = "TERMINATE"
    termination_wait_time_in_minutes = 5
  }
}
```

### Traffic Shift Options

**1. All-at-Once** (Current Configuration)
- Shifts 100% traffic immediately
- Fastest deployment
- Higher risk

**2. Canary** (Alternative)
```hcl
deployment_config_name = "CodeDeployDefault.ECSCanary10Percent5Minutes"
```
- 10% traffic → Wait 5 min → 100% traffic
- Safer for critical services

**3. Linear** (Alternative)
```hcl
deployment_config_name = "CodeDeployDefault.ECSLinear10PercentEvery1Minutes"
```
- 10% every minute → 100% after 10 minutes
- Gradual rollout

### Advantages

✅ **Zero Downtime**: Seamless cutover  
✅ **Full Testing**: Test production-like environment  
✅ **Fast Rollback**: Switch back to blue instantly  
✅ **Risk Mitigation**: Validate before production traffic  
✅ **Clean Separation**: No version mixing  

### Disadvantages

⚠️ **Cost**: Runs duplicate environment temporarily  
⚠️ **Complexity**: Requires CodeDeploy, ALB  
⚠️ **Resources**: Needs 2x capacity during deployment  
⚠️ **Time**: Slower than rolling deployment  

### Rollback Process

**Automatic Rollback**:
- Health checks fail on green
- Deployment errors occur
- CloudWatch alarms triggered

**Manual Rollback**:
```bash
# Via GitHub Actions
1. Go to Actions → Rollback Deployment
2. Select "production"
3. Run workflow

# Via AWS Console
1. CodeDeploy → Deployments
2. Select deployment
3. Click "Stop and roll back"
```

**Instant Switch**:
```bash
# CodeDeploy instantly switches ALB back to blue target group
# Blue tasks still running → immediate recovery
```

### Best Practices

1. **Database State**: Ensure schema compatibility
2. **Feature Flags**: Enable gradual feature rollout
3. **Monitoring**: Watch metrics during deployment
4. **Automated Tests**: Run smoke tests on green
5. **Rollback Plan**: Document rollback procedure

## Deployment Comparison

| Feature | Rolling | Blue/Green |
|---------|---------|------------|
| **Complexity** | Low | High |
| **Cost** | Low | Medium |
| **Rollback Speed** | Slow | Fast |
| **Risk** | Medium | Low |
| **Testing** | Limited | Extensive |
| **Resources** | Efficient | 2x during deploy |
| **Downtime** | Zero | Zero |
| **Version Mix** | Yes | No |

## Environment-Specific Rationale

### Why Rolling for Development?

1. **Cost Efficiency**: Dev doesn't need duplicate infrastructure
2. **Fast Iteration**: Quick deployments for testing
3. **Lower Risk**: Issues in dev are acceptable
4. **Simplicity**: Easier to understand and maintain
5. **Resource Conservation**: Minimal AWS costs

### Why Blue/Green for Production?

1. **Zero Risk**: Full testing before production traffic
2. **Fast Rollback**: Instant recovery from issues
3. **Compliance**: Many standards require this level
4. **Customer Experience**: No service degradation
5. **Confidence**: Thorough validation before cutover

## Deployment Timeline

### Rolling Deployment (Dev)

```
0:00 - Trigger deployment
0:30 - Build and test complete
1:00 - Push to ECR complete
1:15 - Start new task
1:45 - Health checks pass
2:00 - Stop old task #1
2:15 - Start new task
2:45 - Health checks pass
3:00 - Stop old task #2
3:15 - Deployment complete

Total: ~3-5 minutes
```

### Blue/Green Deployment (Prod)

```
0:00 - Trigger deployment
0:30 - Build and test complete
1:00 - Push to ECR complete
1:15 - CodeDeploy starts
1:30 - Deploy green tasks
2:00 - Green tasks running
2:30 - Health checks pass
3:00 - Test traffic validation
3:30 - Production traffic shift
4:00 - Monitor green environment
9:00 - Terminate blue tasks
9:15 - Deployment complete

Total: ~9-12 minutes
```

## Monitoring During Deployment

### Key Metrics to Watch

**Rolling Deployment**:
- Task count (should never drop below desired)
- Health check status
- Response times
- Error rates

**Blue/Green Deployment**:
- Green task health
- Blue task health
- ALB target group health
- Traffic distribution
- Response times
- Error rates (compare blue vs green)

### CloudWatch Alarms

```bash
# Set alarms for:
- CPU > 80%
- Memory > 90%
- HTTP 5xx errors > threshold
- Task count < desired
- Health check failures
```

## Handling Database Migrations

### Compatible Migrations (Recommended)

**Phase 1: Add New**
```sql
-- Deploy v1: Add new column (nullable)
ALTER TABLE users ADD COLUMN email VARCHAR(255);
```

**Phase 2: Migrate Data**
```sql
-- Background job: Populate data
UPDATE users SET email = old_email WHERE email IS NULL;
```

**Phase 3: Enforce**
```sql
-- Deploy v2: Make required
ALTER TABLE users ALTER COLUMN email SET NOT NULL;
```

**Phase 4: Remove Old**
```sql
-- Deploy v3: Drop old column
ALTER TABLE users DROP COLUMN old_email;
```

### Incompatible Changes (Avoid)

❌ **Don't**: Drop columns immediately  
❌ **Don't**: Rename columns in one step  
❌ **Don't**: Change data types breaking old code  
❌ **Don't**: Add non-null columns without default  

## Troubleshooting Deployments

### Rolling Deployment Issues

**Problem**: Deployment stuck  
**Solution**: Check task health, logs, security groups

**Problem**: Circuit breaker triggered  
**Solution**: Review logs, fix issue, redeploy

**Problem**: Version incompatibility  
**Solution**: Ensure backward compatibility

### Blue/Green Deployment Issues

**Problem**: Green tasks unhealthy  
**Solution**: Check logs, fix issue, automatic rollback

**Problem**: CodeDeploy timeout  
**Solution**: Increase timeout, check target group settings

**Problem**: Traffic not shifting  
**Solution**: Verify ALB listener rules, target groups

## Future Enhancements

### Canary Deployments
```yaml
# Shift 10% → Monitor → Shift 100%
- More gradual than all-at-once
- Better for high-traffic services
```

### Shadow Traffic
```yaml
# Mirror production traffic to green
- Test with real traffic
- No user impact
- Validates performance
```

### Feature Flags
```javascript
if (featureFlags.newFeature && user.betaTester) {
  // New code path
} else {
  // Old code path
}
```

## References

- [AWS ECS Deployment Types](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/deployment-types.html)
- [AWS CodeDeploy for ECS](https://docs.aws.amazon.com/codedeploy/latest/userguide/deployment-steps-ecs.html)
- [Blue/Green Deployment Best Practices](https://docs.aws.amazon.com/whitepapers/latest/blue-green-deployments/blue-green-deployments.html)
- [Martin Fowler - BlueGreenDeployment](https://martinfowler.com/bliki/BlueGreenDeployment.html)
