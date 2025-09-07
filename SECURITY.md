# Security Policy

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| 0.1.x   | :white_check_mark: |
| < 0.1   | :x:                |

## Reporting a Vulnerability

If you discover a security vulnerability in Pangea, please report it responsibly:

### Private Disclosure

1. **Do not** open a public GitHub issue for security vulnerabilities
2. Send an email to: security@example.com (replace with actual security contact)
3. Include detailed information about the vulnerability:
   - Description of the issue
   - Steps to reproduce
   - Potential impact
   - Suggested fix (if known)

### Response Timeline

- **Initial Response**: Within 48 hours
- **Status Update**: Within 1 week
- **Resolution**: Varies based on complexity, typically 2-4 weeks

### What to Expect

1. We will acknowledge receipt of your report
2. We will investigate and validate the vulnerability
3. We will work on a fix and coordinate disclosure timing with you
4. We will credit you in our security advisory (unless you prefer to remain anonymous)

## Security Best Practices

When using Pangea:

### Credentials Management
- Never commit AWS credentials or API keys to your repository
- Use IAM roles when running in AWS environments
- Store sensitive values in AWS Secrets Manager or similar services
- Use `.env` files for local development (excluded by .gitignore)

### State File Security
- Enable S3 bucket encryption for remote state
- Use DynamoDB state locking to prevent concurrent modifications
- Restrict access to state buckets using IAM policies
- Enable versioning on state buckets for recovery

### Template Security
- Review all third-party templates before use
- Validate input parameters in custom components
- Follow principle of least privilege for IAM resources
- Regularly audit created resources for compliance

### Network Security
- Use VPCs and security groups appropriately
- Enable VPC Flow Logs for monitoring
- Implement network segmentation
- Use private subnets for sensitive resources

## Security Features

Pangea includes several security-focused features:

- **Template Isolation**: Each template uses separate state files
- **Parameter Validation**: Type checking prevents malformed configurations  
- **Audit Logging**: All infrastructure changes are logged
- **Backend Encryption**: S3 backends support KMS encryption
- **Access Control**: Integration with AWS IAM for permissions

## Vulnerability Disclosure

We follow responsible disclosure practices:

1. Security issues are fixed before public disclosure
2. CVE numbers are assigned when appropriate
3. Security advisories are published on GitHub
4. Fixes are backported to supported versions when possible

## Contact

For security-related questions or concerns:
- Email: security@example.com (replace with actual contact)
- GPG Key: [Link to public key if available]

Thank you for helping keep Pangea secure!