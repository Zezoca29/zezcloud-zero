# Cost Analysis

## Monthly Cost: $0.00

This project is engineered to operate within AWS Free Tier limits indefinitely.

---

## Free Tier Boundaries

| Service | Free Tier Limit | This Project's Usage | Cost |
|---------|----------------|----------------------|------|
| EC2 t2.micro | 750 hours/month | ~730 hours (1 instance) | **$0** |
| S3 Storage | 5 GB | < 100 MB (state files) | **$0** |
| S3 Requests | 20,000 GET / 2,000 PUT | Minimal | **$0** |
| DynamoDB | 25 GB / 25 WCU / 25 RCU | < 1 MB (lock entries) | **$0** |
| CloudWatch Metrics | 10 custom metrics | 4 metrics used | **$0** |
| CloudWatch Logs | 5 GB ingestion | < 100 MB/month | **$0** |
| CloudWatch Alarms | 10 alarms | 4 alarms | **$0** |
| SSM Parameter Store | 10,000 API calls | < 100/month | **$0** |
| Data Transfer | 1 GB/month outbound | Demo traffic only | **$0** |
| **Total** | | | **$0.00/month** |

*Free Tier: 12 months for new accounts. After 12 months, EC2 t2.micro costs ~$8.47/month in us-east-1.*

---

## Services Intentionally Avoided

### NAT Gateway — avoided ❌
- Cost: $32/month minimum (fixed hourly + data transfer)
- Strategy: EC2 in public subnet with proper security groups

### Application Load Balancer — avoided ❌
- Cost: $16/month minimum
- Strategy: Nginx reverse proxy on EC2

### ECS Fargate — avoided ❌
- Cost: CPU + memory per second
- Strategy: Docker Compose on EC2 t2.micro

### RDS PostgreSQL — avoided ❌
- Cost: $15-25/month (even db.t3.micro after Free Tier)
- Strategy: PostgreSQL container with persistent volume

### Secrets Manager — avoided ❌
- Cost: $0.40/secret/month
- Strategy: SSM Parameter Store (free tier) + GitHub Secrets

### WAF — avoided ❌
- Cost: $5/month + per-request fees
- Strategy: Cloudflare Free tier (DDoS protection included)

---

## Future Evolution Cost Estimate

When evolving this architecture to full production:

| Addition | Monthly Cost Estimate |
|----------|----------------------|
| ECS Fargate (2 tasks) | ~$30 |
| RDS db.t3.micro | ~$15 |
| ALB | ~$16 |
| NAT Gateway | ~$32 |
| **Total production** | **~$93/month** |

The current architecture demonstrates the same engineering concepts at $0 cost,
proving architectural knowledge without financial barrier.
