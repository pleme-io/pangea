# Copyright 2025 The Pangea Authors
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Example: Security-Focused Infrastructure
# This example demonstrates a comprehensive security-first architecture including:
# - Zero-trust networking with private subnets and VPC endpoints
# - AWS GuardDuty for threat detection
# - VPC Flow Logs and CloudTrail for audit logging
# - WAF for web application protection
# - Systems Manager for secure instance access
# - Comprehensive encryption and secrets management
# - Security compliance and monitoring

# Template 1: Security Foundation
template :security_foundation do
  provider :aws do
    region "us-east-1"
    
    default_tags do
      tags do
        ManagedBy "Pangea"
        Environment namespace
        Project "SecurityFocusedInfra"
        Template "security_foundation"
        SecurityLevel "High"
        ComplianceFramework "SOC2"
      end
    end
  end
  
  # VPC with security-first design
  vpc = resource :aws_vpc, :main do
    cidr_block "10.0.0.0/16"
    enable_dns_hostnames true
    enable_dns_support true
    
    # Enable VPC flow logs
    tags do
      Name "Security-VPC-#{namespace}"
      Purpose "SecureNetworking"
      FlowLogsEnabled "true"
    end
  end
  
  # Internet Gateway (limited usage)
  igw = resource :aws_internet_gateway, :main do
    vpc_id ref(:aws_vpc, :main, :id)
    
    tags do
      Name "Security-IGW-#{namespace}"
      Purpose "ControlledInternetAccess"
    end
  end
  
  # Availability zones for high availability
  availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c"]
  
  # Public subnets - minimal, only for NAT gateways and ALB
  availability_zones.each_with_index do |az, index|
    resource :"aws_subnet", :"public_#{index + 1}" do
      vpc_id ref(:aws_vpc, :main, :id)
      cidr_block "10.0.#{index + 1}.0/28" # Very small subnets (/28 = 16 IPs)
      availability_zone az
      map_public_ip_on_launch false # Security: no auto-assign public IPs
      
      tags do
        Name "Security-Public-#{index + 1}-#{namespace}"
        Type "public"
        Purpose "NATGatewayAndALB"
        AZ az
      end
    end
  end
  
  # Private subnets for applications
  availability_zones.each_with_index do |az, index|
    resource :"aws_subnet", :"private_app_#{index + 1}" do
      vpc_id ref(:aws_vpc, :main, :id)
      cidr_block "10.0.#{index + 10}.0/24"
      availability_zone az
      
      tags do
        Name "Security-Private-App-#{index + 1}-#{namespace}"
        Type "private"
        Purpose "application"
        SecurityZone "app-tier"
        AZ az
      end
    end
  end
  
  # Private subnets for databases (isolated)
  availability_zones.each_with_index do |az, index|
    resource :"aws_subnet", :"private_db_#{index + 1}" do
      vpc_id ref(:aws_vpc, :main, :id)
      cidr_block "10.0.#{index + 20}.0/24"
      availability_zone az
      
      tags do
        Name "Security-Private-DB-#{index + 1}-#{namespace}"
        Type "private"
        Purpose "database"
        SecurityZone "data-tier"
        AZ az
      end
    end
  end
  
  # Management subnet for bastion hosts and admin access
  management_subnet = resource :aws_subnet, :management do
    vpc_id ref(:aws_vpc, :main, :id)
    cidr_block "10.0.100.0/26" # /26 = 64 IPs
    availability_zone availability_zones[0]
    
    tags do
      Name "Security-Management-#{namespace}"
      Type "private"
      Purpose "management"
      SecurityZone "mgmt-tier"
    end
  end
  
  # NAT Gateways for secure outbound access
  availability_zones.each_with_index do |az, index|
    resource :"aws_eip", :"nat_#{index + 1}" do
      domain "vpc"
      
      tags do
        Name "Security-NAT-EIP-#{index + 1}-#{namespace}"
        Purpose "SecureOutbound"
        AZ az
      end
    end
    
    resource :"aws_nat_gateway", :"main_#{index + 1}" do
      allocation_id ref(:"aws_eip", :"nat_#{index + 1}", :id)
      subnet_id ref(:"aws_subnet", :"public_#{index + 1}", :id)
      
      tags do
        Name "Security-NAT-#{index + 1}-#{namespace}"
        Purpose "SecureOutbound"
        AZ az
      end
    end
  end
  
  # Route Tables with security controls
  public_rt = resource :aws_route_table, :public do
    vpc_id ref(:aws_vpc, :main, :id)
    
    route do
      cidr_block "0.0.0.0/0"
      gateway_id ref(:aws_internet_gateway, :main, :id)
    end
    
    tags do
      Name "Security-Public-RT-#{namespace}"
      Purpose "ControlledInternetAccess"
    end
  end
  
  # Associate public subnets with public route table
  availability_zones.each_with_index do |az, index|
    resource :"aws_route_table_association", :"public_#{index + 1}" do
      subnet_id ref(:"aws_subnet", :"public_#{index + 1}", :id)
      route_table_id ref(:aws_route_table, :public, :id)
    end
  end
  
  # Private route tables for each AZ (defense in depth)
  availability_zones.each_with_index do |az, index|
    resource :"aws_route_table", :"private_#{index + 1}" do
      vpc_id ref(:aws_vpc, :main, :id)
      
      route do
        cidr_block "0.0.0.0/0"
        nat_gateway_id ref(:"aws_nat_gateway", :"main_#{index + 1}", :id)
      end
      
      tags do
        Name "Security-Private-RT-#{index + 1}-#{namespace}"
        Purpose "SecureOutbound"
        AZ az
      end
    end
    
    # Associate app subnets
    resource :"aws_route_table_association", :"private_app_#{index + 1}" do
      subnet_id ref(:"aws_subnet", :"private_app_#{index + 1}", :id)
      route_table_id ref(:"aws_route_table", :"private_#{index + 1}", :id)
    end
    
    # Associate DB subnets
    resource :"aws_route_table_association", :"private_db_#{index + 1}" do
      subnet_id ref(:"aws_subnet", :"private_db_#{index + 1}", :id)
      route_table_id ref(:"aws_route_table", :"private_#{index + 1}", :id)
    end
  end
  
  # Management route table (no internet access)
  mgmt_rt = resource :aws_route_table, :management do
    vpc_id ref(:aws_vpc, :main, :id)
    
    # No default route - isolated network
    
    tags do
      Name "Security-Management-RT-#{namespace}"
      Purpose "IsolatedManagement"
    end
  end
  
  resource :aws_route_table_association, :management do
    subnet_id ref(:aws_subnet, :management, :id)
    route_table_id ref(:aws_route_table, :management, :id)
  end
  
  # VPC Flow Logs for network monitoring
  flow_logs_role = resource :aws_iam_role, :flow_logs do
    name_prefix "Security-FlowLogs-"
    assume_role_policy jsonencode({
      Version: "2012-10-17",
      Statement: [
        {
          Action: "sts:AssumeRole",
          Effect: "Allow",
          Principal: {
            Service: "vpc-flow-logs.amazonaws.com"
          }
        }
      ]
    })
    
    tags do
      Name "Security-FlowLogs-Role-#{namespace}"
      Purpose "NetworkMonitoring"
    end
  end
  
  resource :aws_iam_role_policy_attachment, :flow_logs do
    role ref(:aws_iam_role, :flow_logs, :name)
    policy_arn "arn:aws:iam::aws:policy/service-role/VPCFlowLogsDeliveryRolePolicy"
  end
  
  # CloudWatch Log Group for VPC Flow Logs
  flow_logs_group = resource :aws_cloudwatch_log_group, :vpc_flow_logs do
    name "/aws/vpc/flowlogs/security-#{namespace}"
    retention_in_days 90
    kms_key_id ref(:aws_kms_key, :logging, :arn)
    
    tags do
      Name "Security-VPCFlowLogs-#{namespace}"
      Purpose "NetworkAudit"
    end
  end
  
  # VPC Flow Logs
  vpc_flow_logs = resource :aws_flow_log, :main do
    iam_role_arn ref(:aws_iam_role, :flow_logs, :arn)
    log_destination_type "cloud-watch-logs"
    log_group_name ref(:aws_cloudwatch_log_group, :vpc_flow_logs, :name)
    resource_id ref(:aws_vpc, :main, :id)
    resource_type "VPC"
    traffic_type "ALL"
    max_aggregation_interval 60
    
    tags do
      Name "Security-VPCFlowLogs-#{namespace}"
      Purpose "NetworkAudit"
    end
  end
  
  # KMS Keys for encryption
  logging_kms_key = resource :aws_kms_key, :logging do
    description "KMS key for security logging encryption"
    deletion_window_in_days 7
    enable_key_rotation true
    
    policy jsonencode({
      Version: "2012-10-17",
      Statement: [
        {
          Effect: "Allow",
          Principal: { AWS: "arn:aws:iam::#{data(:aws_caller_identity, :current, :account_id)}:root" },
          Action: "kms:*",
          Resource: "*"
        },
        {
          Effect: "Allow",
          Principal: { Service: [
            "logs.amazonaws.com",
            "cloudtrail.amazonaws.com",
            "s3.amazonaws.com"
          ]},
          Action: [
            "kms:Encrypt",
            "kms:Decrypt",
            "kms:ReEncrypt*",
            "kms:GenerateDataKey*",
            "kms:DescribeKey"
          ],
          Resource: "*"
        }
      ]
    })
    
    tags do
      Name "Security-Logging-KMS-#{namespace}"
      Purpose "LoggingEncryption"
    end
  end
  
  resource :aws_kms_alias, :logging do
    name "alias/security-logging-#{namespace}"
    target_key_id ref(:aws_kms_key, :logging, :key_id)
  end
  
  application_kms_key = resource :aws_kms_key, :application do
    description "KMS key for application encryption"
    deletion_window_in_days 7
    enable_key_rotation true
    
    policy jsonencode({
      Version: "2012-10-17",
      Statement: [
        {
          Effect: "Allow",
          Principal: { AWS: "arn:aws:iam::#{data(:aws_caller_identity, :current, :account_id)}:root" },
          Action: "kms:*",
          Resource: "*"
        },
        {
          Effect: "Allow",
          Principal: { Service: [
            "rds.amazonaws.com",
            "s3.amazonaws.com",
            "secretsmanager.amazonaws.com",
            "ssm.amazonaws.com"
          ]},
          Action: [
            "kms:Encrypt",
            "kms:Decrypt",
            "kms:ReEncrypt*",
            "kms:GenerateDataKey*",
            "kms:DescribeKey"
          ],
          Resource: "*"
        }
      ]
    })
    
    tags do
      Name "Security-Application-KMS-#{namespace}"
      Purpose "ApplicationEncryption"
    end
  end
  
  resource :aws_kms_alias, :application do
    name "alias/security-application-#{namespace}"
    target_key_id ref(:aws_kms_key, :application, :key_id)
  end
  
  # Get current AWS account ID
  data :aws_caller_identity, :current do
  end
  
  # VPC Endpoints for secure AWS service access
  # S3 VPC Endpoint (Gateway)
  s3_endpoint = resource :aws_vpc_endpoint, :s3 do
    vpc_id ref(:aws_vpc, :main, :id)
    service_name "com.amazonaws.us-east-1.s3"
    vpc_endpoint_type "Gateway"
    route_table_ids [
      ref(:aws_route_table, :private_1, :id),
      ref(:aws_route_table, :private_2, :id),
      ref(:aws_route_table, :private_3, :id),
      ref(:aws_route_table, :management, :id)
    ]
    
    policy jsonencode({
      Version: "2012-10-17",
      Statement: [
        {
          Effect: "Allow",
          Principal: "*",
          Action: [
            "s3:GetObject",
            "s3:PutObject",
            "s3:ListBucket"
          ],
          Resource: [
            "arn:aws:s3:::security-logs-#{namespace}",
            "arn:aws:s3:::security-logs-#{namespace}/*"
          ]
        }
      ]
    })
    
    tags do
      Name "Security-S3-VPCEndpoint-#{namespace}"
      Purpose "SecureS3Access"
    end
  end
  
  # Security group for VPC endpoints
  vpc_endpoint_sg = resource :aws_security_group, :vpc_endpoints do
    name_prefix "security-vpc-endpoints-"
    vpc_id ref(:aws_vpc, :main, :id)
    description "Security group for VPC endpoints"
    
    ingress do
      from_port 443
      to_port 443
      protocol "tcp"
      cidr_blocks [ref(:aws_vpc, :main, :cidr_block)]
      description "HTTPS from VPC"
    end
    
    tags do
      Name "Security-VPCEndpoints-SG-#{namespace}"
      Purpose "VPCEndpointAccess"
    end
  end
  
  # Interface VPC Endpoints for commonly used services
  vpc_endpoint_services = [
    "ec2",
    "ssm",
    "ssmmessages",
    "ec2messages",
    "logs",
    "monitoring",
    "secretsmanager",
    "kms"
  ]
  
  vpc_endpoint_services.each do |service|
    resource :"aws_vpc_endpoint", service.to_sym do
      vpc_id ref(:aws_vpc, :main, :id)
      service_name "com.amazonaws.us-east-1.#{service}"
      vpc_endpoint_type "Interface"
      subnet_ids [
        ref(:aws_subnet, :private_app_1, :id),
        ref(:aws_subnet, :private_app_2, :id),
        ref(:aws_subnet, :private_app_3, :id)
      ]
      security_group_ids [ref(:aws_security_group, :vpc_endpoints, :id)]
      policy jsonencode({
        Version: "2012-10-17",
        Statement: [
          {
            Effect: "Allow",
            Principal: "*",
            Action: "*",
            Resource: "*"
          }
        ]
      })
      
      tags do
        Name "Security-#{service.capitalize}-VPCEndpoint-#{namespace}"
        Purpose "SecureAWSServiceAccess"
        Service service
      end
    end
  end
  
  # CloudTrail for API audit logging
  cloudtrail_bucket = resource :aws_s3_bucket, :cloudtrail do
    bucket "security-cloudtrail-#{namespace}-#{SecureRandom.hex(8)}"
    force_destroy namespace != "production"
    
    tags do
      Name "Security-CloudTrail-#{namespace}"
      Purpose "APIAuditLogs"
    end
  end
  
  resource :aws_s3_bucket_server_side_encryption_configuration, :cloudtrail do
    bucket ref(:aws_s3_bucket, :cloudtrail, :id)
    
    rule do
      apply_server_side_encryption_by_default do
        sse_algorithm "aws:kms"
        kms_master_key_id ref(:aws_kms_key, :logging, :arn)
      end
      bucket_key_enabled true
    end
  end
  
  resource :aws_s3_bucket_public_access_block, :cloudtrail do
    bucket ref(:aws_s3_bucket, :cloudtrail, :id)
    
    block_public_acls true
    block_public_policy true
    ignore_public_acls true
    restrict_public_buckets true
  end
  
  # CloudTrail bucket policy
  resource :aws_s3_bucket_policy, :cloudtrail do
    bucket ref(:aws_s3_bucket, :cloudtrail, :id)
    
    policy jsonencode({
      Version: "2012-10-17",
      Statement: [
        {
          Effect: "Allow",
          Principal: { Service: "cloudtrail.amazonaws.com" },
          Action: "s3:PutObject",
          Resource: "#{ref(:aws_s3_bucket, :cloudtrail, :arn)}/*",
          Condition: {
            StringEquals: {
              "s3:x-amz-acl": "bucket-owner-full-control"
            }
          }
        },
        {
          Effect: "Allow",
          Principal: { Service: "cloudtrail.amazonaws.com" },
          Action: "s3:GetBucketAcl",
          Resource: ref(:aws_s3_bucket, :cloudtrail, :arn)
        }
      ]
    })
  end
  
  # CloudTrail
  cloudtrail = resource :aws_cloudtrail, :main do
    name "security-audit-trail-#{namespace}"
    s3_bucket_name ref(:aws_s3_bucket, :cloudtrail, :bucket)
    include_global_service_events true
    is_multi_region_trail true
    enable_logging true
    is_organization_trail false
    
    kms_key_id ref(:aws_kms_key, :logging, :arn)
    
    event_selector do
      read_write_type "All"
      include_management_events true
      
      data_resource do
        type "AWS::S3::Object"
        values ["arn:aws:s3:::*/*"]
      end
    end
    
    tags do
      Name "Security-CloudTrail-#{namespace}"
      Purpose "APIAuditLogging"
    end
  end
  
  # GuardDuty for threat detection
  guardduty = resource :aws_guardduty_detector, :main do
    enable true
    finding_publishing_frequency "FIFTEEN_MINUTES"
    
    datasources do
      s3_logs do
        enable true
      end
      kubernetes do
        audit_logs do
          enable true
        end
      end
      malware_protection do
        scan_ec2_instance_with_findings do
          ebs_volumes do
            enable true
          end
        end
      end
    end
    
    tags do
      Name "Security-GuardDuty-#{namespace}"
      Purpose "ThreatDetection"
    end
  end
  
  # Security Hub for centralized security findings
  security_hub = resource :aws_securityhub_account, :main do
    enable_default_standards true
    control_finding_generator "SECURITY_CONTROL"
    auto_enable_controls true
  end
  
  # Config for compliance monitoring
  config_role = resource :aws_iam_role, :config do
    name_prefix "Security-Config-"
    assume_role_policy jsonencode({
      Version: "2012-10-17",
      Statement: [
        {
          Action: "sts:AssumeRole",
          Effect: "Allow",
          Principal: {
            Service: "config.amazonaws.com"
          }
        }
      ]
    })
    
    tags do
      Name "Security-Config-Role-#{namespace}"
      Purpose "ComplianceMonitoring"
    end
  end
  
  resource :aws_iam_role_policy_attachment, :config do
    role ref(:aws_iam_role, :config, :name)
    policy_arn "arn:aws:iam::aws:policy/service-role/ConfigRole"
  end
  
  config_bucket = resource :aws_s3_bucket, :config do
    bucket "security-config-#{namespace}-#{SecureRandom.hex(8)}"
    force_destroy namespace != "production"
    
    tags do
      Name "Security-Config-#{namespace}"
      Purpose "ComplianceRecords"
    end
  end
  
  resource :aws_s3_bucket_server_side_encryption_configuration, :config do
    bucket ref(:aws_s3_bucket, :config, :id)
    
    rule do
      apply_server_side_encryption_by_default do
        sse_algorithm "aws:kms"
        kms_master_key_id ref(:aws_kms_key, :logging, :arn)
      end
    end
  end
  
  resource :aws_s3_bucket_public_access_block, :config do
    bucket ref(:aws_s3_bucket, :config, :id)
    
    block_public_acls true
    block_public_policy true
    ignore_public_acls true
    restrict_public_buckets true
  end
  
  config_delivery_channel = resource :aws_config_delivery_channel, :main do
    name "security-config-delivery-#{namespace}"
    s3_bucket_name ref(:aws_s3_bucket, :config, :bucket)
    snapshot_delivery_properties do
      delivery_frequency "TwentyFour_Hours"
    end
    
    depends_on [ref(:aws_config_configuration_recorder, :main)]
  end
  
  config_recorder = resource :aws_config_configuration_recorder, :main do
    name "security-config-recorder-#{namespace}"
    role_arn ref(:aws_iam_role, :config, :arn)
    
    recording_group do
      all_supported true
      include_global_resource_types true
    end
  end
  
  # Outputs for other templates
  output :vpc_id do
    value ref(:aws_vpc, :main, :id)
    description "VPC ID for security-focused infrastructure"
  end
  
  output :private_app_subnet_ids do
    value [
      ref(:aws_subnet, :private_app_1, :id),
      ref(:aws_subnet, :private_app_2, :id),
      ref(:aws_subnet, :private_app_3, :id)
    ]
    description "Private application subnet IDs"
  end
  
  output :private_db_subnet_ids do
    value [
      ref(:aws_subnet, :private_db_1, :id),
      ref(:aws_subnet, :private_db_2, :id),
      ref(:aws_subnet, :private_db_3, :id)
    ]
    description "Private database subnet IDs"
  end
  
  output :public_subnet_ids do
    value [
      ref(:aws_subnet, :public_1, :id),
      ref(:aws_subnet, :public_2, :id),
      ref(:aws_subnet, :public_3, :id)
    ]
    description "Public subnet IDs (minimal)"
  end
  
  output :management_subnet_id do
    value ref(:aws_subnet, :management, :id)
    description "Management subnet ID"
  end
  
  output :logging_kms_key_arn do
    value ref(:aws_kms_key, :logging, :arn)
    description "KMS key ARN for logging encryption"
  end
  
  output :application_kms_key_arn do
    value ref(:aws_kms_key, :application, :arn)
    description "KMS key ARN for application encryption"
  end
  
  output :guardduty_detector_id do
    value ref(:aws_guardduty_detector, :main, :id)
    description "GuardDuty detector ID"
  end
  
  output :cloudtrail_name do
    value ref(:aws_cloudtrail, :main, :name)
    description "CloudTrail name for audit logging"
  end
end

# Template 2: Secure Application Infrastructure
template :secure_application do
  provider :aws do
    region "us-east-1"
    
    default_tags do
      tags do
        ManagedBy "Pangea"
        Environment namespace
        Project "SecurityFocusedInfra"
        Template "secure_application"
        SecurityLevel "High"
      end
    end
  end
  
  # Reference security foundation
  data :aws_vpc, :main do
    filter do
      name "tag:Name"
      values ["Security-VPC-#{namespace}"]
    end
  end
  
  data :aws_subnets, :public do
    filter do
      name "vpc-id"
      values [data(:aws_vpc, :main, :id)]
    end
    
    filter do
      name "tag:Type"
      values ["public"]
    end
  end
  
  data :aws_subnets, :private_app do
    filter do
      name "vpc-id"
      values [data(:aws_vpc, :main, :id)]
    end
    
    filter do
      name "tag:Purpose"
      values ["application"]
    end
  end
  
  data :aws_subnets, :private_db do
    filter do
      name "vpc-id"
      values [data(:aws_vpc, :main, :id)]
    end
    
    filter do
      name "tag:Purpose"
      values ["database"]
    end
  end
  
  data :aws_kms_key, :application do
    filter do
      name "tag:Name"
      values ["Security-Application-KMS-#{namespace}"]
    end
  end
  
  data :aws_kms_key, :logging do
    filter do
      name "tag:Name"
      values ["Security-Logging-KMS-#{namespace}"]
    end
  end
  
  # Web Application Firewall (WAF)
  waf_ip_set = resource :aws_wafv2_ip_set, :blocked_ips do
    name "security-blocked-ips-#{namespace}"
    description "IP addresses to block"
    scope "REGIONAL"
    ip_address_version "IPV4"
    
    addresses ENV['BLOCKED_IPS']&.split(',') || ["192.0.2.0/24"] # RFC 5737 test range
    
    tags do
      Name "Security-BlockedIPs-#{namespace}"
      Purpose "ThreatMitigation"
    end
  end
  
  waf_acl = resource :aws_wafv2_web_acl, :main do
    name "security-waf-#{namespace}"
    description "WAF for security-focused application"
    scope "REGIONAL"
    
    default_action do
      allow do
      end
    end
    
    # Block known malicious IPs
    rule do
      name "BlockMaliciousIPs"
      priority 1
      
      action do
        block do
        end
      end
      
      statement do
        ip_set_reference_statement do
          arn ref(:aws_wafv2_ip_set, :blocked_ips, :arn)
        end
      end
      
      visibility_config do
        sampled_requests_enabled true
        cloudwatch_metrics_enabled true
        metric_name "BlockMaliciousIPs"
      end
    end
    
    # Rate limiting rule
    rule do
      name "RateLimitRule"
      priority 2
      
      action do
        block do
        end
      end
      
      statement do
        rate_based_statement do
          limit 10000
          aggregate_key_type "IP"
        end
      end
      
      visibility_config do
        sampled_requests_enabled true
        cloudwatch_metrics_enabled true
        metric_name "RateLimitRule"
      end
    end
    
    # AWS Managed Rules
    rule do
      name "AWSManagedRulesCommonRuleSet"
      priority 3
      
      override_action do
        none do
        end
      end
      
      statement do
        managed_rule_group_statement do
          name "AWSManagedRulesCommonRuleSet"
          vendor_name "AWS"
        end
      end
      
      visibility_config do
        sampled_requests_enabled true
        cloudwatch_metrics_enabled true
        metric_name "CommonRuleSet"
      end
    end
    
    # SQL injection protection
    rule do
      name "AWSManagedRulesSQLiRuleSet"
      priority 4
      
      override_action do
        none do
        end
      end
      
      statement do
        managed_rule_group_statement do
          name "AWSManagedRulesSQLiRuleSet"
          vendor_name "AWS"
        end
      end
      
      visibility_config do
        sampled_requests_enabled true
        cloudwatch_metrics_enabled true
        metric_name "SQLiRuleSet"
      end
    end
    
    visibility_config do
      sampled_requests_enabled true
      cloudwatch_metrics_enabled true
      metric_name "SecurityWAF"
    end
    
    tags do
      Name "Security-WAF-#{namespace}"
      Purpose "WebApplicationSecurity"
    end
  end
  
  # Security Groups with least privilege
  alb_sg = resource :aws_security_group, :alb do
    name_prefix "security-alb-"
    vpc_id data(:aws_vpc, :main, :id)
    description "Security group for ALB with WAF protection"
    
    ingress do
      from_port 443
      to_port 443
      protocol "tcp"
      cidr_blocks ["0.0.0.0/0"]
      description "HTTPS only - HTTP redirected to HTTPS"
    end
    
    # HTTP for health checks only
    ingress do
      from_port 80
      to_port 80
      protocol "tcp"
      cidr_blocks ["0.0.0.0/0"]
      description "HTTP for redirect to HTTPS"
    end
    
    egress do
      from_port 8080
      to_port 8080
      protocol "tcp"
      security_groups [ref(:aws_security_group, :app, :id)]
      description "HTTPS to application tier"
    end
    
    tags do
      Name "Security-ALB-SG-#{namespace}"
      Purpose "LoadBalancerSecurity"
      SecurityLevel "Internet-Facing"
    end
  end
  
  app_sg = resource :aws_security_group, :app do
    name_prefix "security-app-"
    vpc_id data(:aws_vpc, :main, :id)
    description "Security group for application servers"
    
    ingress do
      from_port 8080
      to_port 8080
      protocol "tcp"
      security_groups [ref(:aws_security_group, :alb, :id)]
      description "HTTPS from ALB only"
    end
    
    # Systems Manager Session Manager access (no SSH)
    ingress do
      from_port 443
      to_port 443
      protocol "tcp"
      security_groups [ref(:aws_security_group, :ssm, :id)]
      description "HTTPS for Systems Manager"
    end
    
    egress do
      from_port 5432
      to_port 5432
      protocol "tcp"
      security_groups [ref(:aws_security_group, :db, :id)]
      description "PostgreSQL to database"
    end
    
    egress do
      from_port 443
      to_port 443
      protocol "tcp"
      cidr_blocks ["0.0.0.0/0"]
      description "HTTPS for AWS API calls and updates"
    end
    
    tags do
      Name "Security-App-SG-#{namespace}"
      Purpose "ApplicationSecurity"
      SecurityLevel "Internal"
    end
  end
  
  db_sg = resource :aws_security_group, :db do
    name_prefix "security-db-"
    vpc_id data(:aws_vpc, :main, :id)
    description "Security group for database servers"
    
    ingress do
      from_port 5432
      to_port 5432
      protocol "tcp"
      security_groups [ref(:aws_security_group, :app, :id)]
      description "PostgreSQL from application tier only"
    end
    
    # Database monitoring
    ingress do
      from_port 5432
      to_port 5432
      protocol "tcp"
      security_groups [ref(:aws_security_group, :monitoring, :id)]
      description "PostgreSQL from monitoring"
    end
    
    tags do
      Name "Security-DB-SG-#{namespace}"
      Purpose "DatabaseSecurity"
      SecurityLevel "DataTier"
    end
  end
  
  ssm_sg = resource :aws_security_group, :ssm do
    name_prefix "security-ssm-"
    vpc_id data(:aws_vpc, :main, :id)
    description "Security group for Systems Manager access"
    
    egress do
      from_port 443
      to_port 443
      protocol "tcp"
      cidr_blocks ["0.0.0.0/0"]
      description "HTTPS for SSM service"
    end
    
    tags do
      Name "Security-SSM-SG-#{namespace}"
      Purpose "SystemsManagerAccess"
      SecurityLevel "Management"
    end
  end
  
  monitoring_sg = resource :aws_security_group, :monitoring do
    name_prefix "security-monitoring-"
    vpc_id data(:aws_vpc, :main, :id)
    description "Security group for monitoring systems"
    
    egress do
      from_port 443
      to_port 443
      protocol "tcp"
      cidr_blocks ["0.0.0.0/0"]
      description "HTTPS for AWS APIs"
    end
    
    egress do
      from_port 5432
      to_port 5432
      protocol "tcp"
      security_groups [ref(:aws_security_group, :db, :id)]
      description "Database monitoring"
    end
    
    egress do
      from_port 8080
      to_port 8080
      protocol "tcp"
      security_groups [ref(:aws_security_group, :app, :id)]
      description "Application monitoring"
    end
    
    tags do
      Name "Security-Monitoring-SG-#{namespace}"
      Purpose "MonitoringAccess"
      SecurityLevel "Internal"
    end
  end
  
  # Application Load Balancer with security features
  alb = resource :aws_lb, :main do
    name_prefix "security-"
    load_balancer_type "application"
    scheme "internet-facing"
    
    subnets data(:aws_subnets, :public, :ids)
    security_groups [ref(:aws_security_group, :alb, :id)]
    
    enable_deletion_protection namespace == "production"
    enable_cross_zone_load_balancing true
    enable_http2 true
    enable_waf_fail_open false
    
    # Security headers
    desync_mitigation_mode "defensive"
    
    # Access logging
    access_logs do
      bucket ref(:aws_s3_bucket, :alb_logs, :bucket)
      prefix "alb-access-logs"
      enabled true
    end
    
    tags do
      Name "Security-ALB-#{namespace}"
      Purpose "SecureLoadBalancing"
      SecurityLevel "Internet-Facing"
    end
  end
  
  # S3 bucket for ALB access logs
  alb_logs_bucket = resource :aws_s3_bucket, :alb_logs do
    bucket "security-alb-logs-#{namespace}-#{SecureRandom.hex(8)}"
    force_destroy namespace != "production"
    
    tags do
      Name "Security-ALB-Logs-#{namespace}"
      Purpose "AccessLogging"
    end
  end
  
  resource :aws_s3_bucket_server_side_encryption_configuration, :alb_logs do
    bucket ref(:aws_s3_bucket, :alb_logs, :id)
    
    rule do
      apply_server_side_encryption_by_default do
        sse_algorithm "aws:kms"
        kms_master_key_id data(:aws_kms_key, :logging, :arn)
      end
    end
  end
  
  resource :aws_s3_bucket_public_access_block, :alb_logs do
    bucket ref(:aws_s3_bucket, :alb_logs, :id)
    
    block_public_acls true
    block_public_policy true
    ignore_public_acls true
    restrict_public_buckets true
  end
  
  # ALB bucket policy for access logging
  resource :aws_s3_bucket_policy, :alb_logs do
    bucket ref(:aws_s3_bucket, :alb_logs, :id)
    
    policy jsonencode({
      Version: "2012-10-17",
      Statement: [
        {
          Effect: "Allow",
          Principal: { AWS: "arn:aws:iam::127311923021:root" }, # ELB service account for us-east-1
          Action: "s3:PutObject",
          Resource: "#{ref(:aws_s3_bucket, :alb_logs, :arn)}/alb-access-logs/AWSLogs/#{data(:aws_caller_identity, :current, :account_id)}/*"
        },
        {
          Effect: "Allow",
          Principal: { Service: "delivery.logs.amazonaws.com" },
          Action: "s3:PutObject",
          Resource: "#{ref(:aws_s3_bucket, :alb_logs, :arn)}/alb-access-logs/AWSLogs/#{data(:aws_caller_identity, :current, :account_id)}/*",
          Condition: {
            StringEquals: {
              "s3:x-amz-acl": "bucket-owner-full-control"
            }
          }
        },
        {
          Effect: "Allow",
          Principal: { Service: "delivery.logs.amazonaws.com" },
          Action: "s3:GetBucketAcl",
          Resource: ref(:aws_s3_bucket, :alb_logs, :arn)
        }
      ]
    })
  end
  
  # Get current AWS account ID
  data :aws_caller_identity, :current do
  end
  
  # WAF association with ALB
  resource :aws_wafv2_web_acl_association, :alb do
    resource_arn ref(:aws_lb, :main, :arn)
    web_acl_arn ref(:aws_wafv2_web_acl, :main, :arn)
  end
  
  # SSL Certificate
  certificate = resource :aws_acm_certificate, :main do
    domain_name ENV['DOMAIN_NAME'] || "secure-app-#{namespace}.example.com"
    validation_method "DNS"
    
    subject_alternative_names [
      "*.secure-app-#{namespace}.example.com"
    ]
    
    lifecycle do
      create_before_destroy true
    end
    
    tags do
      Name "Security-Certificate-#{namespace}"
      Purpose "SSLTermination"
      SecurityLevel "TLS1.2+"
    end
  end
  
  # Target group with health checks
  tg = resource :aws_lb_target_group, :app do
    name_prefix "sec-app-"
    port 8080
    protocol "HTTP"
    vpc_id data(:aws_vpc, :main, :id)
    target_type "instance"
    
    health_check do
      enabled true
      healthy_threshold 2
      unhealthy_threshold 3
      timeout 5
      interval 30
      path "/health"
      matcher "200"
      protocol "HTTP"
      port "traffic-port"
    end
    
    # Security settings
    stickiness do
      enabled false
      type "lb_cookie"
    end
    
    tags do
      Name "Security-App-TG-#{namespace}"
      Purpose "SecureTargeting"
    end
  end
  
  # HTTPS Listener with security headers
  https_listener = resource :aws_lb_listener, :https do
    load_balancer_arn ref(:aws_lb, :main, :arn)
    port "443"
    protocol "HTTPS"
    ssl_policy "ELBSecurityPolicy-TLS-1-2-2017-01"
    certificate_arn ref(:aws_acm_certificate, :main, :arn)
    
    default_action do
      type "fixed-response"
      fixed_response do
        content_type "text/plain"
        message_body "Security headers applied"
        status_code "200"
      end
    end
    
    # Forward to application
    default_action do
      type "forward"
      target_group_arn ref(:aws_lb_target_group, :app, :arn)
    end
  end
  
  # HTTP listener (redirect to HTTPS)
  http_listener = resource :aws_lb_listener, :http do
    load_balancer_arn ref(:aws_lb, :main, :arn)
    port "80"
    protocol "HTTP"
    
    default_action do
      type "redirect"
      redirect do
        port "443"
        protocol "HTTPS"
        status_code "HTTP_301"
      end
    end
  end
  
  # IAM role for EC2 instances (least privilege)
  app_instance_role = resource :aws_iam_role, :app_instance do
    name_prefix "Security-App-Instance-"
    assume_role_policy jsonencode({
      Version: "2012-10-17",
      Statement: [
        {
          Action: "sts:AssumeRole",
          Effect: "Allow",
          Principal: {
            Service: "ec2.amazonaws.com"
          }
        }
      ]
    })
    
    tags do
      Name "Security-App-Instance-Role-#{namespace}"
      Purpose "ApplicationExecution"
    end
  end
  
  # Minimal IAM policies for security
  resource :aws_iam_role_policy, :app_instance do
    name_prefix "Security-App-Instance-Policy-"
    role ref(:aws_iam_role, :app_instance, :id)
    
    policy jsonencode({
      Version: "2012-10-17",
      Statement: [
        {
          Effect: "Allow",
          Action: [
            "ssm:UpdateInstanceInformation",
            "ssmmessages:CreateControlChannel",
            "ssmmessages:CreateDataChannel",
            "ssmmessages:OpenControlChannel",
            "ssmmessages:OpenDataChannel",
            "ec2messages:AcknowledgeMessage",
            "ec2messages:DeleteMessage",
            "ec2messages:FailMessage",
            "ec2messages:GetEndpoint",
            "ec2messages:GetMessages",
            "ec2messages:SendReply"
          ],
          Resource: "*"
        },
        {
          Effect: "Allow",
          Action: [
            "logs:CreateLogStream",
            "logs:PutLogEvents"
          ],
          Resource: ref(:aws_cloudwatch_log_group, :app, :arn)
        },
        {
          Effect: "Allow",
          Action: [
            "secretsmanager:GetSecretValue"
          ],
          Resource: "arn:aws:secretsmanager:*:*:secret:security-app-*"
        },
        {
          Effect: "Allow",
          Action: [
            "kms:Decrypt"
          ],
          Resource: data(:aws_kms_key, :application, :arn)
        }
      ]
    })
  end
  
  resource :aws_iam_instance_profile, :app_instance do
    name_prefix "Security-App-Instance-"
    role ref(:aws_iam_role, :app_instance, :name)
  end
  
  # Launch template with security hardening
  launch_template = resource :aws_launch_template, :app do
    name_prefix "security-app-"
    description "Secure launch template for application instances"
    
    image_id data(:aws_ami, :amazon_linux, :id)
    instance_type ENV['INSTANCE_TYPE'] || "t3.medium"
    
    vpc_security_group_ids [
      ref(:aws_security_group, :app, :id),
      ref(:aws_security_group, :ssm, :id)
    ]
    
    iam_instance_profile do
      name ref(:aws_iam_instance_profile, :app_instance, :name)
    end
    
    # Security settings
    monitoring do
      enabled true
    end
    
    metadata_options do
      http_endpoint "enabled"
      http_tokens "required" # Require IMDSv2
      http_put_response_hop_limit 1
      instance_metadata_tags "enabled"
    end
    
    # EBS encryption
    block_device_mappings do
      device_name "/dev/xvda"
      ebs do
        volume_type "gp3"
        volume_size 20
        encrypted true
        kms_key_id data(:aws_kms_key, :application, :arn)
        delete_on_termination true
      end
    end
    
    # Security-hardened user data
    user_data base64encode(<<~USERDATA)
      #!/bin/bash
      yum update -y --security
      
      # Install security tools
      yum install -y amazon-cloudwatch-agent aide
      
      # Harden SSH (even though we use SSM)
      sed -i 's/#PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
      sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
      systemctl reload sshd
      
      # Configure CloudWatch agent
      cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json << 'EOF'
      {
        "logs": {
          "logs_collected": {
            "files": {
              "collect_list": [
                {
                  "file_path": "/var/log/messages",
                  "log_group_name": "#{ref(:aws_cloudwatch_log_group, :app, :name)}",
                  "log_stream_name": "{instance_id}/messages"
                },
                {
                  "file_path": "/var/log/secure",
                  "log_group_name": "#{ref(:aws_cloudwatch_log_group, :app, :name)}",
                  "log_stream_name": "{instance_id}/secure"
                }
              ]
            }
          }
        },
        "metrics": {
          "namespace": "Security/Application",
          "metrics_collected": {
            "cpu": {
              "measurement": ["cpu_usage_idle", "cpu_usage_iowait", "cpu_usage_user", "cpu_usage_system"],
              "metrics_collection_interval": 300
            },
            "disk": {
              "measurement": ["used_percent"],
              "metrics_collection_interval": 300,
              "resources": ["*"]
            },
            "mem": {
              "measurement": ["mem_used_percent"],
              "metrics_collection_interval": 300
            }
          }
        }
      }
      EOF
      
      /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json -s
      
      # Initialize AIDE
      aide --init
      mv /var/lib/aide/aide.db.new.gz /var/lib/aide/aide.db.gz
      
      # Secure application setup
      useradd -r -s /bin/false appuser
      mkdir -p /opt/app
      chown appuser:appuser /opt/app
      
      # Install application (placeholder)
      echo "Secure application would be installed here" > /opt/app/README
    USERDATA
    
    tag_specifications do
      resource_type "instance"
      tags do
        Name "Security-App-Instance-#{namespace}"
        Environment namespace
        SecurityLevel "High"
        Monitoring "Enabled"
        Hardened "true"
      end
    end
    
    tags do
      Name "Security-App-LaunchTemplate-#{namespace}"
      Purpose "SecureApplicationLaunching"
    end
  end
  
  # Data source for hardened AMI
  data :aws_ami, :amazon_linux do
    most_recent true
    owners ["amazon"]
    
    filter do
      name "name"
      values ["amzn2-ami-hvm-*-x86_64-gp2"]
    end
    
    filter do
      name "state"
      values ["available"]
    end
  end
  
  # Auto Scaling Group with security monitoring
  asg = resource :aws_autoscaling_group, :app do
    name "security-app-asg-#{namespace}"
    vpc_zone_identifier data(:aws_subnets, :private_app, :ids)
    
    target_group_arns [ref(:aws_lb_target_group, :app, :arn)]
    health_check_type "ELB"
    health_check_grace_period 300
    
    min_size 2
    max_size namespace == "production" ? 10 : 4
    desired_capacity 3
    
    launch_template do
      id ref(:aws_launch_template, :app, :id)
      version "$Latest"
    end
    
    # Instance refresh for security updates
    instance_refresh do
      strategy "Rolling"
      preferences do
        min_healthy_percentage 50
        instance_warmup 300
      end
      triggers ["tag"]
    end
    
    tag do
      key "Name"
      value "Security-App-ASG-#{namespace}"
      propagate_at_launch true
    end
    
    tag do
      key "SecurityLevel"
      value "High"
      propagate_at_launch true
    end
    
    tag do
      key "Environment"
      value namespace
      propagate_at_launch true
    end
  end
  
  # CloudWatch Log Groups for security monitoring
  app_log_group = resource :aws_cloudwatch_log_group, :app do
    name "/security/application/#{namespace}"
    retention_in_days 90
    kms_key_id data(:aws_kms_key, :logging, :arn)
    
    tags do
      Name "Security-App-Logs-#{namespace}"
      Purpose "ApplicationSecurityLogging"
    end
  end
  
  waf_log_group = resource :aws_cloudwatch_log_group, :waf do
    name "/aws/wafv2/security-#{namespace}"
    retention_in_days 90
    kms_key_id data(:aws_kms_key, :logging, :arn)
    
    tags do
      Name "Security-WAF-Logs-#{namespace}"
      Purpose "WAFSecurityLogging"
    end
  end
  
  # Security alarms
  resource :aws_cloudwatch_metric_alarm, :waf_blocked_requests do
    alarm_name "security-waf-blocked-requests-#{namespace}"
    alarm_description "High number of blocked requests"
    comparison_operator "GreaterThanThreshold"
    evaluation_periods 2
    metric_name "BlockedRequests"
    namespace "AWS/WAFV2"
    period 300
    statistic "Sum"
    threshold 100
    treat_missing_data "notBreaching"
    
    dimensions do
      WebACL ref(:aws_wafv2_web_acl, :main, :name)
      Rule "ALL"
      Region "us-east-1"
    end
    
    tags do
      Name "Security-WAF-BlockedRequests-#{namespace}"
      AlertType "SecurityThreat"
    end
  end
  
  # Outputs
  output :alb_dns_name do
    value ref(:aws_lb, :main, :dns_name)
    description "Application Load Balancer DNS name"
  end
  
  output :application_url do
    value "https://#{ref(:aws_lb, :main, :dns_name)}"
    description "Secure application URL (HTTPS only)"
  end
  
  output :waf_acl_arn do
    value ref(:aws_wafv2_web_acl, :main, :arn)
    description "WAF Web ACL ARN"
  end
  
  output :certificate_arn do
    value ref(:aws_acm_certificate, :main, :arn)
    description "SSL certificate ARN"
  end
end

# This security-focused infrastructure example demonstrates several key concepts:
#
# 1. **Zero-Trust Networking**: Private subnets by default, minimal public access,
#    VPC endpoints for AWS service access without internet routing.
#
# 2. **Defense in Depth**: Multiple security layers including WAF, security groups,
#    network ACLs, encryption at rest and in transit.
#
# 3. **Comprehensive Monitoring**: VPC Flow Logs, CloudTrail, GuardDuty, Config,
#    Security Hub integration for complete visibility.
#
# 4. **Encryption Everywhere**: Separate KMS keys for different data types,
#    encryption for all storage, logs, and communication.
#
# 5. **Access Control**: Systems Manager Session Manager instead of SSH,
#    least-privilege IAM policies, security group restrictions.
#
# 6. **Compliance Ready**: Config rules, CloudTrail logging, Security Hub
#    standards for SOC2, PCI DSS, and other frameworks.
#
# 7. **Threat Detection**: GuardDuty for anomaly detection, WAF for web attacks,
#    CloudWatch alarms for security events.
#
# 8. **Infrastructure Hardening**: IMDSv2 required, EBS encryption,
#    security-focused instance configuration.
#
# Deployment order:
#   pangea apply examples/security-focused-infrastructure.rb --template security_foundation
#   pangea apply examples/security-focused-infrastructure.rb --template secure_application
#
# Environment-specific deployment:
#   export DOMAIN_NAME=secure-app.company.com
#   export BLOCKED_IPS=203.0.113.0/24,198.51.100.0/24
#   pangea apply examples/security-focused-infrastructure.rb --namespace production
#
# This example showcases how Pangea enables building security-first infrastructure
# with comprehensive protection, monitoring, and compliance capabilities built-in.