# Security-Focused Infrastructure

This example demonstrates a comprehensive security-first infrastructure using Pangea, implementing defense-in-depth strategies, zero-trust networking, and compliance-ready monitoring and auditing capabilities.

## Overview

The security-focused infrastructure includes:

- **Zero-Trust Networking**: VPC endpoints, private subnets, minimal public exposure
- **Defense in Depth**: Multiple security layers (WAF, security groups, encryption)
- **Threat Detection**: GuardDuty, Security Hub, CloudTrail
- **Access Control**: Systems Manager, IAM least privilege, no direct SSH
- **Compliance Monitoring**: AWS Config, automated compliance checks
- **Comprehensive Encryption**: KMS keys for all data at rest and in transit
- **Security Logging**: VPC Flow Logs, CloudTrail, centralized logging

## Security Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                            Internet                                  │
└────────────────────────────┬────────────────────────────────────────┘
                             │
                    ┌────────▼────────┐
                    │      WAF        │
                    │ (Web Firewall)  │
                    └────────┬────────┘
                             │
                    ┌────────▼────────┐
                    │   CloudFront    │
                    │      (CDN)      │
                    └────────┬────────┘
                             │
┌─────────────────────────────────────────────────────────────────────┐
│                    VPC (10.0.0.0/16)                                │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │             Public Subnets (Minimal - /28)                    │  │
│  │  ┌─────────┐  ┌─────────┐  ┌─────────┐                      │  │
│  │  │  NAT 1  │  │  NAT 2  │  │  NAT 3  │    ┌──────────┐     │  │
│  │  └────┬────┘  └────┬────┘  └────┬────┘    │   ALB    │     │  │
│  │       │            │            │          └────┬─────┘     │  │
│  └───────┼────────────┼────────────┼───────────────┼───────────┘  │
│          │            │            │               │               │
│  ┌───────▼────────────▼────────────▼───────────────▼───────────┐  │
│  │                Private App Subnets                           │  │
│  │  ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────────┐    │  │
│  │  │  App 1  │  │  App 2  │  │  App 3  │  │ VPC Endpoints│   │  │
│  │  └─────────┘  └─────────┘  └─────────┘  └─────────────┘    │  │
│  └──────────────────────────────────────────────────────────────┘  │
│                                                                     │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │                Private DB Subnets (Isolated)                 │  │
│  │  ┌─────────┐  ┌─────────┐  ┌─────────┐                      │  │
│  │  │   DB 1  │  │   DB 2  │  │   DB 3  │                      │  │
│  │  └─────────┘  └─────────┘  └─────────┘                      │  │
│  └──────────────────────────────────────────────────────────────┘  │
│                                                                     │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │            Management Subnet (Isolated)                      │  │
│  │  ┌──────────────┐  ┌──────────────┐                         │  │
│  │  │ Session Mgr  │  │  Monitoring  │                         │  │
│  │  └──────────────┘  └──────────────┘                         │  │
│  └──────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────┘

Security Services:
┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐
│  GuardDuty  │  │Security Hub │  │ CloudTrail  │  │    Config   │
│  (Threat    │  │  (Central   │  │   (Audit    │  │(Compliance) │
│  Detection) │  │  Findings)  │  │   Logging)  │  │             │
└─────────────┘  └─────────────┘  └─────────────┘  └─────────────┘
```

## Templates

### 1. Security Foundation (`security_foundation`)

Core security infrastructure:
- VPC with minimal public subnets (/28)
- Private subnets for apps and databases
- Management subnet for administrative access
- VPC endpoints for AWS service access
- VPC Flow Logs for network monitoring
- CloudTrail for API auditing
- GuardDuty for threat detection
- Security Hub for centralized findings
- AWS Config for compliance monitoring
- KMS keys for encryption

### 2. Secure Application (`secure_application`)

Application layer with security controls:
- WAF for web application protection
- Application Load Balancer with SSL/TLS
- Security groups with least privilege
- Auto Scaling with security hardening
- Systems Manager for secure access
- CloudWatch logging with encryption
- Security alarms and monitoring

## Security Features

### Network Security

1. **Zero-Trust Design**
   - No direct internet access for applications
   - All AWS API calls through VPC endpoints
   - Minimal public subnet footprint

2. **Traffic Control**
   - WAF rules for common attacks
   - Rate limiting protection
   - IP blocking capabilities
   - Security group chaining

3. **Network Monitoring**
   - VPC Flow Logs to CloudWatch
   - Real-time traffic analysis
   - Anomaly detection alerts

### Access Control

1. **No SSH Access**
   - Systems Manager Session Manager only
   - All sessions logged and auditable
   - MFA enforcement possible

2. **IAM Least Privilege**
   - Minimal permissions per role
   - No wildcard permissions
   - Service-specific access only

3. **Instance Metadata v2**
   - Required for all instances
   - Prevents SSRF attacks
   - Token-based access

### Data Protection

1. **Encryption at Rest**
   - EBS volumes encrypted with KMS
   - S3 buckets with SSE-KMS
   - RDS encryption enabled
   - Separate keys for different data types

2. **Encryption in Transit**
   - TLS 1.2+ enforced
   - HTTPS-only communication
   - VPN for admin access

3. **Key Management**
   - Automated key rotation
   - Separate keys for logging and application data
   - Key policies with least privilege

### Compliance and Auditing

1. **Logging**
   - CloudTrail for all API calls
   - VPC Flow Logs for network traffic
   - Application logs to CloudWatch
   - All logs encrypted with KMS

2. **Compliance Monitoring**
   - AWS Config rules
   - Security Hub standards
   - Automated compliance checks
   - Real-time alerts

3. **Threat Detection**
   - GuardDuty enabled
   - Malware scanning
   - Anomaly detection
   - Integration with Security Hub

## Deployment

### Prerequisites

1. AWS account with appropriate permissions
2. S3 buckets for state management
3. KMS keys for state encryption
4. Route 53 hosted zone (for custom domains)

### Development Environment

```bash
# Deploy security foundation
pangea apply infrastructure.rb --template security_foundation

# Deploy secure application
pangea apply infrastructure.rb --template secure_application
```

### Production Environment

```bash
# Set production variables
export DOMAIN_NAME=secure-app.company.com
export BLOCKED_IPS=203.0.113.0/24,198.51.100.0/24
export INSTANCE_TYPE=t3.large

# Deploy with manual approval
pangea apply infrastructure.rb --namespace production --no-auto-approve
```

## Security Operations

### Incident Response

1. **Detection**
   - GuardDuty findings in Security Hub
   - CloudWatch alarms for anomalies
   - WAF blocked request alerts

2. **Investigation**
   - VPC Flow Logs analysis
   - CloudTrail event history
   - Application logs review

3. **Response**
   - Block IPs in WAF
   - Isolate affected instances
   - Rotate compromised credentials

### Security Monitoring

Monitor these key metrics:

```bash
# Check GuardDuty findings
aws guardduty list-findings --detector-id $(pangea output infrastructure.rb --template security_foundation | jq -r .guardduty_detector_id)

# Review Security Hub findings
aws securityhub get-findings --filters '{"ProductArn": [{"Value": "arn:aws:securityhub:*:*:product/aws/guardduty", "Comparison": "EQUALS"}]}'

# Check WAF blocked requests
aws cloudwatch get-metric-statistics \
  --namespace AWS/WAFV2 \
  --metric-name BlockedRequests \
  --dimensions Name=WebACL,Value=security-waf-production \
  --statistics Sum \
  --start-time 2024-01-01T00:00:00Z \
  --end-time 2024-01-02T00:00:00Z \
  --period 3600
```

### Compliance Validation

1. **AWS Config Rules**
   - Encrypted volumes check
   - Security group compliance
   - IAM policy validation
   - S3 bucket public access

2. **Security Hub Standards**
   - CIS AWS Foundations Benchmark
   - PCI DSS compliance
   - AWS Foundational Security Best Practices

3. **Custom Checks**
   - Application security headers
   - TLS configuration
   - Access patterns

## Security Best Practices

### Application Security

1. **Secure Coding**
   - Input validation
   - Output encoding
   - Parameterized queries
   - Security headers

2. **Dependency Management**
   - Regular vulnerability scanning
   - Automated patching
   - Supply chain security

3. **Secret Management**
   - AWS Secrets Manager integration
   - Rotation policies
   - Least privilege access

### Infrastructure Security

1. **Patch Management**
   - Automated OS patching
   - Application updates
   - Security patches priority

2. **Backup and Recovery**
   - Encrypted backups
   - Cross-region replication
   - Regular restore testing

3. **Access Reviews**
   - Quarterly IAM audits
   - Unused resource cleanup
   - Permission boundary enforcement

## Cost Optimization

### Security Cost Management

1. **GuardDuty**: ~$5-10/month for small workloads
2. **Security Hub**: Free tier covers basics
3. **Config**: $2 per rule per month
4. **CloudTrail**: First trail free, S3 storage costs
5. **VPC Flow Logs**: CloudWatch Logs pricing
6. **WAF**: $5/month + $1 per million requests

### Cost Reduction Strategies

1. **Use AWS Free Tier**
   - CloudTrail first trail
   - Config evaluation on-demand
   - Security Hub basic features

2. **Optimize Logging**
   - Set appropriate retention periods
   - Use S3 lifecycle policies
   - Compress logs

3. **Right-size Resources**
   - Review GuardDuty findings
   - Optimize WAF rules
   - Consolidate log streams

## Troubleshooting

### Common Issues

1. **VPC Endpoint Connectivity**
   - Check security groups
   - Verify endpoint policies
   - Test DNS resolution

2. **Session Manager Access**
   - Verify IAM permissions
   - Check instance profile
   - Validate SSM agent

3. **WAF False Positives**
   - Review rule matches
   - Adjust sensitivity
   - Whitelist legitimate traffic

## Clean Up

Remove infrastructure in reverse order:

```bash
# Remove application layer
pangea destroy infrastructure.rb --template secure_application

# Remove security foundation
pangea destroy infrastructure.rb --template security_foundation
```

## Next Steps

1. Integrate with SIEM solution
2. Implement automated remediation
3. Add container security scanning
4. Set up security training pipeline
5. Implement zero-trust identity