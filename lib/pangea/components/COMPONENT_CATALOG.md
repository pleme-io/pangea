# Pangea Component Catalog: 100 Essential Infrastructure Components

## Component Directory Structure
Each component follows the resource-per-directory pattern:
```
lib/pangea/components/
├── secure_vpc/
│   ├── CLAUDE.md          # Implementation documentation
│   ├── README.md          # User-facing usage guide
│   ├── component.rb       # Component implementation
│   ├── types.rb           # Component-specific dry-struct types
│   └── examples.rb        # Usage examples
└── ... (99 other components)
```

## Complete Component Catalog (100 Components)

### Networking Components (20)

1. **secure_vpc** ✅ IMPLEMENTED
   - VPC with flow logs, DNS resolution, and security monitoring
   - Includes: VPC + CloudWatch Log Group (VPC Flow Logs pending aws_flow_log resource)

2. **public_private_subnets** ✅ IMPLEMENTED
   - Subnet pair with NAT Gateway and proper routing
   - Includes: Public Subnet + Private Subnet + NAT Gateway + Route Tables + Elastic IP

3. **web_tier_subnets** ✅ IMPLEMENTED
   - Public subnets across multiple AZs for web tier
   - Includes: Multiple Public Subnets + Internet Gateway + Route Tables

4. **app_tier_subnets**
   - Private subnets for application tier with NAT access
   - Includes: Multiple Private Subnets + NAT Gateways + Route Tables

5. **db_tier_subnets**
   - Database subnets with subnet groups across AZs
   - Includes: DB Subnets + DB Subnet Group + Network ACLs

6. **bastion_network**
   - Bastion subnet with security and monitoring
   - Includes: Public Subnet + Security Group + CloudWatch Logs

7. **transit_gateway_attachment**
   - VPC attachment to Transit Gateway with route propagation
   - Includes: TGW Attachment + Route Table Associations + Propagation

8. **vpc_peering_connection**
   - Bidirectional VPC peering with route table updates
   - Includes: Peering Connection + Route Table Entries (both VPCs)

9. **vpc_endpoints_gateway**
   - Gateway endpoints for S3 and DynamoDB
   - Includes: Gateway Endpoints + Route Table Associations

10. **vpc_endpoints_interface**
    - Interface endpoints for AWS services
    - Includes: Interface Endpoints + Security Groups + DNS

11. **network_firewall_subnet**
    - Dedicated subnet for AWS Network Firewall
    - Includes: Firewall Subnet + Network Firewall + Rules

12. **direct_connect_gateway**
    - Direct Connect Gateway with virtual interfaces
    - Includes: DX Gateway + Virtual Interface + BGP Configuration

13. **site_to_site_vpn**
    - Site-to-Site VPN with redundant tunnels
    - Includes: VPN Gateway + Customer Gateway + VPN Connection

14. **client_vpn_endpoint**
    - Client VPN with certificate authentication
    - Includes: Client VPN Endpoint + Authorization Rules + Security Groups

15. **nat_instance_cluster**
    - High-availability NAT instances with auto-scaling
    - Includes: Launch Template + Auto Scaling Group + Elastic IP

16. **dns_resolver_endpoints**
    - Route 53 Resolver endpoints for hybrid DNS
    - Includes: Inbound/Outbound Endpoints + Security Groups + Rules

17. **global_accelerator_endpoint**
    - Global Accelerator with health checks
    - Includes: Accelerator + Listener + Endpoint Group

18. **cloudfront_distribution_basic**
    - CloudFront distribution with common settings
    - Includes: Distribution + Origin + Cache Behaviors

19. **multi_region_vpc_lattice**
    - VPC Lattice service network across regions
    - Includes: Service Network + VPC Associations + Security Policies

20. **ipam_pool_management**
    - IPAM pools with automated CIDR allocation
    - Includes: IPAM Pool + Allocations + Monitoring

### Security Components (15)

21. **web_security_group** ✅ IMPLEMENTED
    - Security group for web servers (HTTP/HTTPS)
    - Includes: Security Group + Ingress/Egress Rules + Security Analysis

22. **app_security_group**
    - Security group for application servers
    - Includes: Security Group + Custom Port Rules + Logging

23. **db_security_group**
    - Security group for databases with minimal access
    - Includes: Security Group + Database Port Rules + Source Restrictions

24. **bastion_security_group**
    - Security group for bastion hosts with SSH logging
    - Includes: Security Group + SSH Rules + Session Manager

25. **internal_security_group**
    - Security group for internal service communication
    - Includes: Security Group + Internal Rules + VPC References

26. **waf_web_acl**
    - WAF Web ACL with common protections
    - Includes: Web ACL + Managed Rules + Rate Limiting

27. **network_acl_secure**
    - Network ACL with security best practices
    - Includes: Network ACL + Subnet Associations + Logging

28. **secrets_manager_rotation**
    - Secrets Manager secret with automatic rotation
    - Includes: Secret + Rotation Lambda + IAM Role

29. **kms_key_management**
    - KMS key with policies and aliases
    - Includes: KMS Key + Key Policy + Alias + Grants

30. **certificate_manager_validation**
    - ACM certificate with DNS validation
    - Includes: Certificate + DNS Validation + Route 53 Records

31. **iam_role_service**
    - Service-linked IAM role with policies
    - Includes: IAM Role + Policies + Instance Profile

32. **security_hub_standards**
    - Security Hub with compliance standards
    - Includes: Security Hub + Standards + Custom Insights

33. **guardduty_threat_detection**
    - GuardDuty with threat intelligence feeds
    - Includes: GuardDuty Detector + Findings + S3 Export

34. **config_compliance_rules**
    - Config rules for compliance monitoring
    - Includes: Config Rules + Remediation + SNS Notifications

35. **cloudtrail_security_logging**
    - CloudTrail with security event monitoring
    - Includes: CloudTrail + S3 Bucket + CloudWatch Insights

### Compute Components (15)

36. **web_server_instance**
    - EC2 instance optimized for web serving
    - Includes: EC2 Instance + Security Group + User Data + Monitoring

37. **bastion_host**
    - Secure bastion host with session logging
    - Includes: EC2 Instance + Elastic IP + Session Manager + Logging

38. **auto_scaling_web_servers**
    - Auto Scaling Group for web servers
    - Includes: ASG + Launch Template + Policies + Target Group

39. **auto_scaling_app_servers**
    - Auto Scaling Group for application servers
    - Includes: ASG + Launch Template + Internal LB + Health Checks

40. **spot_fleet_compute**
    - Spot Fleet for cost-optimized compute
    - Includes: Spot Fleet + Mixed Instance Types + Interruption Handling

41. **ec2_fleet_diversified**
    - EC2 Fleet with instance diversification
    - Includes: EC2 Fleet + Multiple Instance Types + AZ Distribution

42. **launch_template_web**
    - Launch template for web servers
    - Includes: Launch Template + User Data + Security Groups

43. **launch_template_app**
    - Launch template for application servers
    - Includes: Launch Template + IAM Role + Monitoring

44. **dedicated_host_group**
    - Dedicated hosts for compliance workloads
    - Includes: Dedicated Host + Host Resource Group + Placement

45. **placement_group_cluster**
    - Placement group for high-performance computing
    - Includes: Placement Group + Instance Constraints

46. **elastic_beanstalk_environment**
    - Elastic Beanstalk with custom configuration
    - Includes: Application + Environment + Configuration Template

47. **batch_compute_environment**
    - AWS Batch compute environment
    - Includes: Compute Environment + Job Queue + Job Definition

48. **ecs_optimized_instance**
    - ECS-optimized EC2 instance
    - Includes: EC2 Instance + ECS Agent + IAM Role + Monitoring

49. **nitro_enclave_instance**
    - EC2 instance with Nitro Enclaves enabled
    - Includes: EC2 Instance + Enclave Configuration + KMS Integration

50. **graviton_instance_optimized**
    - Graviton processor optimized instance
    - Includes: Graviton Instance + Performance Monitoring + Cost Tracking

### Database Components (10)

51. **mysql_database**
    - RDS MySQL with backups and monitoring
    - Includes: RDS Instance + Subnet Group + Parameter Group + Monitoring

52. **postgresql_database**
    - RDS PostgreSQL with security enhancements
    - Includes: RDS Instance + Security Groups + Backups + Performance Insights

53. **redis_cache**
    - ElastiCache Redis with clustering
    - Includes: Redis Cluster + Subnet Group + Parameter Group + Monitoring

54. **memcached_cache**
    - ElastiCache Memcached cluster
    - Includes: Memcached Cluster + Security Groups + CloudWatch

55. **dynamodb_table**
    - DynamoDB table with encryption and backups
    - Includes: Table + Encryption + Backup + Alarms

56. **documentdb_cluster**
    - DocumentDB cluster with security
    - Includes: Cluster + Instances + Subnet Group + Encryption

57. **aurora_mysql_cluster**
    - Aurora MySQL cluster with global tables
    - Includes: Aurora Cluster + Reader Endpoints + Backups

58. **aurora_postgresql_cluster**
    - Aurora PostgreSQL with performance monitoring
    - Includes: Aurora Cluster + Performance Insights + Monitoring

59. **timestream_database**
    - TimeStream database for time series data
    - Includes: Database + Table + Retention Policies + Queries

60. **neptune_graph_database**
    - Neptune graph database cluster
    - Includes: Cluster + Instances + Subnet Group + IAM Auth

### Storage Components (10)

61. **secure_s3_bucket**
    - S3 bucket with encryption and lifecycle
    - Includes: S3 Bucket + Encryption + Versioning + Lifecycle Rules

62. **static_website_bucket**
    - S3 bucket configured for static hosting
    - Includes: S3 Bucket + Website Configuration + CloudFront

63. **backup_bucket**
    - S3 bucket for backups with compliance
    - Includes: S3 Bucket + Lifecycle + Glacier + Compliance

64. **data_lake_bucket**
    - S3 bucket for data lake with partitioning
    - Includes: S3 Bucket + Partitioning + Athena + Glue Catalog

65. **application_file_system**
    - EFS file system with encryption and access points
    - Includes: EFS + Mount Targets + Access Points + Security Groups

66. **high_performance_file_system**
    - FSx for Lustre file system
    - Includes: FSx + Security Groups + Performance Monitoring

67. **windows_file_system**
    - FSx for Windows File Server
    - Includes: FSx + Active Directory + Security Groups

68. **ebs_encrypted_volumes**
    - EBS volumes with encryption and snapshots
    - Includes: EBS Volume + Encryption + Snapshot Schedule

69. **storage_gateway_hybrid**
    - Storage Gateway for hybrid storage
    - Includes: Storage Gateway + S3 Integration + Monitoring

70. **backup_vault_encrypted**
    - AWS Backup vault with encryption
    - Includes: Backup Vault + KMS Key + Backup Plans

### Load Balancing Components (8)

71. **application_load_balancer**
    - ALB with target groups and health checks
    - Includes: ALB + Target Groups + Listeners + Health Checks

72. **network_load_balancer**
    - NLB for high-performance load balancing
    - Includes: NLB + Target Groups + Cross-Zone + Monitoring

73. **internal_load_balancer**
    - Internal ALB for service-to-service communication
    - Includes: Internal ALB + Service Discovery + Health Checks

74. **global_load_balancer**
    - Global Load Balancer with health checking
    - Includes: Global Accelerator + Multiple Regions + Failover

75. **api_gateway_rest**
    - REST API Gateway with common configurations
    - Includes: API Gateway + Resources + Methods + Deployment

76. **api_gateway_websocket**
    - WebSocket API for real-time communication
    - Includes: WebSocket API + Routes + Integration + Monitoring

77. **cloudfront_with_alb**
    - CloudFront distribution with ALB origin
    - Includes: CloudFront + ALB Integration + Caching + Security

78. **elastic_load_balancer_classic**
    - Classic Load Balancer for legacy applications
    - Includes: Classic ELB + Health Checks + Sticky Sessions

### Monitoring Components (8)

79. **cloudwatch_dashboard_infrastructure**
    - CloudWatch dashboard for infrastructure metrics
    - Includes: Dashboard + Widgets + Alarms + SNS

80. **application_insights_monitoring**
    - Application Insights for application monitoring
    - Includes: Application Insights + Log Groups + Metrics

81. **xray_tracing_service**
    - X-Ray tracing for service monitoring
    - Includes: X-Ray Service + Sampling Rules + Service Map

82. **prometheus_monitoring_stack**
    - Prometheus monitoring with Grafana
    - Includes: Prometheus + Grafana + Alert Manager + EKS Integration

83. **log_aggregation_pipeline**
    - Centralized logging with Kinesis
    - Includes: Kinesis Data Streams + Firehose + ElasticSearch

84. **metric_filter_alarms**
    - CloudWatch metric filters with alarms
    - Includes: Log Groups + Metric Filters + Alarms + Actions

85. **synthetics_monitoring**
    - CloudWatch Synthetics for uptime monitoring
    - Includes: Synthetic Canaries + Alarms + S3 Artifacts

86. **cost_anomaly_detection**
    - Cost anomaly detection and alerting
    - Includes: Cost Anomaly Detection + Budgets + Alerts

### Serverless Components (8)

87. **serverless_function**
    - Lambda function with IAM role and monitoring
    - Includes: Lambda + IAM Role + CloudWatch Logs + Alarms

88. **lambda_api_backend**
    - Lambda function with API Gateway integration
    - Includes: Lambda + API Gateway + Authorizer + CORS

89. **event_driven_lambda**
    - Lambda triggered by various AWS events
    - Includes: Lambda + Event Rules + Dead Letter Queue + Retry

90. **scheduled_lambda_function**
    - Lambda function with EventBridge scheduling
    - Includes: Lambda + EventBridge Rule + IAM + Monitoring

91. **lambda_layer_shared**
    - Lambda layer for shared dependencies
    - Includes: Lambda Layer + Versioning + Permissions

92. **step_functions_workflow**
    - Step Functions state machine with error handling
    - Includes: State Machine + IAM Role + CloudWatch Integration

93. **eventbridge_event_bus**
    - EventBridge custom event bus with rules
    - Includes: Event Bus + Rules + Targets + Schema Registry

94. **sqs_queue_with_dlq**
    - SQS queue with dead letter queue
    - Includes: Main Queue + DLQ + Redrive Policy + Monitoring

### Container Components (6)

95. **ecs_cluster_optimized**
    - ECS cluster with capacity providers
    - Includes: ECS Cluster + Capacity Providers + Service Discovery

96. **ecs_service_web**
    - ECS service for web applications
    - Includes: ECS Service + Task Definition + ALB Integration

97. **eks_cluster_managed**
    - EKS cluster with managed node groups
    - Includes: EKS Cluster + Node Groups + IRSA + Monitoring

98. **eks_fargate_profile**
    - EKS Fargate profile for serverless containers
    - Includes: Fargate Profile + Pod Execution Role + Logging

99. **container_registry_ecr**
    - ECR repository with lifecycle policies
    - Includes: ECR Repository + Lifecycle + Scanning + Policies

100. **container_image_pipeline**
     - CodePipeline for container image builds
     - Includes: CodePipeline + CodeBuild + ECR + Security Scanning

## Component Implementation Guidelines

### Type Safety Requirements
All components must implement:
- dry-struct attribute validation
- RBS type definitions
- Comprehensive error handling
- Input validation with meaningful errors

### Resource Function Usage
Components may only use:
- Typed Pangea resource functions (aws_vpc, aws_subnet, etc.)
- Other Pangea components (for composition)
- Standard Ruby libraries for logic

Components may NOT use:
- Direct terraform-synthesizer calls
- Raw terraform resource blocks
- External dependencies without approval

### Documentation Standards
Each component requires:
- CLAUDE.md with implementation details
- README.md with usage examples
- types.rb with dry-struct definitions
- examples.rb with common usage patterns

### Testing Requirements
All components must include:
- Unit tests for type validation
- Integration tests with resource functions
- Example usage verification
- Error condition testing

This catalog provides a comprehensive set of reusable infrastructure building blocks that bridge the gap between individual AWS resources and complete architecture solutions, enabling teams to compose infrastructure with consistent patterns and best practices.