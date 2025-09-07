# AWS Security Lake Resources

## Overview

AWS Security Lake resources enable centralized security data collection, normalization, and analysis using the Open Cybersecurity Schema Framework (OCSF). These resources help organizations aggregate security data from multiple sources into a data lake for advanced analytics, threat hunting, and compliance reporting.

## Key Concepts

### Security Data Lake Architecture
- **Centralized Storage**: S3-based data lake for all security data
- **OCSF Normalization**: Automatic conversion of security logs to OCSF format
- **Multi-Account Support**: Aggregate data across AWS Organizations
- **Query Integration**: Native integration with Amazon Athena and AWS Glue

### Data Source Categories
1. **AWS Native Sources**: CloudTrail, VPC Flow Logs, Security Hub, etc.
2. **Third-Party Sources**: Custom log sources from security tools
3. **Partner Integrations**: Pre-built connectors for security vendors
4. **Custom Sources**: User-defined data sources with OCSF transformation

### Access Patterns
- **Lake Formation**: Fine-grained access control using AWS Lake Formation
- **S3 Access**: Direct S3 bucket access with IAM policies
- **Query Services**: Integration with Athena, QuickSight, and third-party analytics tools
- **Streaming Access**: Real-time data access via subscribers

## Resources

### aws_securitylake_data_lake
Primary resource for creating and managing the Security Lake data store.

**Key Features:**
- Multi-region data lake setup
- Encryption and lifecycle management
- Cross-region replication
- Integration with AWS analytics services

**Common Patterns:**
```ruby
# Basic single-region data lake
aws_securitylake_data_lake(:main_lake, {
  configuration: [
    {
      region: "us-east-1",
      encryption_configuration: {
        kms_key_id: "alias/security-lake-key"
      },
      lifecycle_configuration: {
        expiration: {
          days: 2555  # 7 years retention
        },
        transitions: [
          {
            days: 30,
            storage_class: "STANDARD_IA"
          },
          {
            days: 365,
            storage_class: "GLACIER"
          }
        ]
      }
    }
  ],
  tags: {
    Environment: "production",
    DataClassification: "sensitive"
  }
})

# Multi-region data lake with replication
aws_securitylake_data_lake(:global_lake, {
  configuration: [
    {
      region: "us-east-1",
      encryption_configuration: {
        kms_key_id: "alias/security-lake-primary"
      },
      replication_configuration: {
        regions: ["us-west-2", "eu-west-1"],
        role_arn: aws_iam_role(:replication_role).arn
      }
    },
    {
      region: "us-west-2",
      encryption_configuration: {
        kms_key_id: "alias/security-lake-replica"
      }
    }
  ],
  tags: {
    Scope: "global",
    Compliance: "required"
  }
})

# Data lake with custom meta store manager
aws_securitylake_data_lake(:managed_lake, {
  configuration: [
    {
      region: "us-east-1",
      encryption_configuration: {
        kms_key_id: aws_kms_key(:lake_key).arn
      }
    }
  ],
  meta_store_manager_role_arn: aws_iam_role(:lake_manager).arn,
  tags: {
    ManagedBy: "security-team",
    AutomationLevel: "full"
  }
})
```

### aws_securitylake_aws_log_source
Enables native AWS services to send logs to Security Lake.

**Key Features:**
- Pre-configured OCSF transformation
- Multi-account data collection
- Regional data source configuration
- Automatic schema management

**Common Patterns:**
```ruby
# Enable CloudTrail management events
aws_securitylake_aws_log_source(:cloudtrail_mgmt, {
  source: {
    regions: ["us-east-1", "us-west-2"],
    source_name: "CLOUDTRAIL_MGMT",
    source_version: "2.0"
  }
})

# Enable VPC Flow Logs for specific accounts
aws_securitylake_aws_log_source(:vpc_flow, {
  source: {
    accounts: production_account_ids,
    regions: ["us-east-1"],
    source_name: "VPC_FLOW",
    source_version: "5.0"
  }
})

# Comprehensive AWS log source enablement
aws_native_sources = [
  { name: "CLOUDTRAIL_MGMT", version: "2.0" },
  { name: "CLOUDTRAIL_DATA", version: "2.0" },
  { name: "VPC_FLOW", version: "5.0" },
  { name: "SH_FINDINGS", version: "1.0" },
  { name: "ROUTE53", version: "1.0" }
]

aws_native_sources.each do |source_config|
  aws_securitylake_aws_log_source(:"#{source_config[:name].downcase}", {
    source: {
      regions: primary_regions,
      source_name: source_config[:name],
      source_version: source_config[:version],
      accounts: all_account_ids
    }
  })
end

# Conditional source enablement
if container_workloads_enabled?
  aws_securitylake_aws_log_source(:eks_audit, {
    source: {
      accounts: kubernetes_account_ids,
      regions: kubernetes_regions,
      source_name: "EKS_AUDIT",
      source_version: "1.0"
    }
  })
end

if waf_enabled?
  aws_securitylake_aws_log_source(:waf_logs, {
    source: {
      regions: web_app_regions,
      source_name: "WAF",
      source_version: "1.0"
    }
  })
end
```

### aws_securitylake_custom_log_source
Integrates third-party and custom security data sources.

**Key Features:**
- Custom OCSF event class mapping
- Flexible data ingestion patterns
- Integration with AWS Glue crawlers
- Custom provider identity management

**Common Patterns:**
```ruby
# Custom security tool integration
aws_securitylake_custom_log_source(:custom_ids, {
  source_name: "CustomIDS",
  source_version: "1.0",
  event_classes: ["NETWORK_ACTIVITY", "SECURITY_FINDING"],
  configuration: {
    crawler_configuration: {
      role_arn: aws_iam_role(:crawler_role).arn
    },
    provider_identity: {
      external_id: "ids-integration-001",
      principal: "arn:aws:iam::123456789012:role/IDSIntegrationRole"
    }
  },
  attributes: {
    crawler_arn: aws_glue_crawler(:ids_crawler).arn,
    database_arn: aws_glue_catalog_database(:security_db).arn,
    table_arn: aws_glue_catalog_table(:ids_events).arn
  },
  tags: {
    DataSource: "IDS",
    Vendor: "CustomSecurity"
  }
})

# SIEM data integration
aws_securitylake_custom_log_source(:siem_events, {
  source_name: "SIEM",
  source_version: "2.1",
  event_classes: [
    "SECURITY_FINDING", 
    "AUTHENTICATION", 
    "AUTHORIZATION", 
    "ACCOUNT_CHANGE"
  ],
  configuration: {
    crawler_configuration: {
      role_arn: aws_iam_role(:siem_crawler).arn
    },
    provider_identity: {
      external_id: generate_external_id,
      principal: siem_integration_role_arn
    }
  },
  tags: {
    Integration: "SIEM",
    Priority: "high"
  }
})

# Application security logs
application_sources = [
  { name: "WebApp", classes: ["WEB_RESOURCES_ACTIVITY", "SECURITY_FINDING"] },
  { name: "APIGateway", classes: ["API_ACTIVITY", "AUTHENTICATION"] },
  { name: "Database", classes: ["DATABASE_ACTIVITY", "SECURITY_FINDING"] }
]

application_sources.each do |app_source|
  aws_securitylake_custom_log_source(:"#{app_source[:name].downcase}_logs", {
    source_name: app_source[:name],
    source_version: "1.0",
    event_classes: app_source[:classes],
    configuration: {
      provider_identity: {
        external_id: "#{app_source[:name]}-#{Time.now.to_i}",
        principal: application_role_arn
      }
    },
    tags: {
      Application: app_source[:name],
      Environment: "production"
    }
  })
end
```

### aws_securitylake_subscriber
Manages access to Security Lake data for analysis and monitoring tools.

**Key Features:**
- Fine-grained data source access
- Lake Formation or S3 access patterns
- Cross-account data sharing
- Integration with analytics services

**Common Patterns:**
```ruby
# SIEM subscriber with full access
aws_securitylake_subscriber(:siem_subscriber, {
  source: [
    {
      aws_log_source_resource: {
        source_name: "CLOUDTRAIL_MGMT",
        source_version: "2.0"
      }
    },
    {
      aws_log_source_resource: {
        source_name: "VPC_FLOW",
        source_version: "5.0"
      }
    },
    {
      custom_log_source_resource: {
        source_name: "CustomIDS",
        source_version: "1.0"
      }
    }
  ],
  subscriber_identity: {
    external_id: "siem-integration-001",
    principal: "arn:aws:iam::999888777666:role/SIEMAccessRole"
  },
  subscriber_name: "Primary SIEM",
  subscriber_description: "Main SIEM tool for security operations",
  access_type: "LAKEFORMATION",
  tags: {
    Tool: "SIEM",
    AccessLevel: "full"
  }
})

# Analytics team subscriber with specific sources
aws_securitylake_subscriber(:analytics_subscriber, {
  source: [
    {
      aws_log_source_resource: {
        source_name: "CLOUDTRAIL_MGMT"
      }
    },
    {
      aws_log_source_resource: {
        source_name: "SH_FINDINGS"
      }
    }
  ],
  subscriber_identity: {
    external_id: "analytics-team-001",
    principal: "arn:aws:iam::111222333444:role/AnalyticsTeamRole"
  },
  subscriber_name: "Security Analytics Team",
  subscriber_description: "Security analytics and reporting team",
  access_type: "S3",
  tags: {
    Team: "analytics",
    Purpose: "reporting"
  }
})

# Third-party security tool subscriber
aws_securitylake_subscriber(:security_tool_subscriber, {
  source: [
    {
      aws_log_source_resource: {
        source_name: "CLOUDTRAIL_MGMT"
      }
    },
    {
      aws_log_source_resource: {
        source_name: "VPC_FLOW"
      }
    }
  ],
  subscriber_identity: {
    external_id: third_party_external_id,
    principal: third_party_role_arn
  },
  subscriber_name: "ThirdPartySecurityTool",
  access_type: "LAKEFORMATION",
  tags: {
    Vendor: "SecurityVendor",
    Integration: "api"
  }
})
```

### aws_securitylake_subscriber_notification
Configures real-time notifications for Security Lake subscribers.

**Key Features:**
- SQS and HTTPS notification endpoints
- Event-driven data processing
- Secure notification delivery
- Integration with processing workflows

**Common Patterns:**
```ruby
# SQS notification for real-time processing
aws_securitylake_subscriber_notification(:siem_notifications, {
  subscriber_arn: aws_securitylake_subscriber(:siem_subscriber).arn,
  configuration: {
    sqs_configuration: {
      queue_arn: aws_sqs_queue(:security_events).arn
    }
  }
})

# HTTPS webhook notification
aws_securitylake_subscriber_notification(:webhook_notifications, {
  subscriber_arn: aws_securitylake_subscriber(:analytics_subscriber).arn,
  configuration: {
    https_notification_configuration: {
      endpoint: "https://analytics.example.com/security-lake-webhook",
      http_method: "POST",
      target_role_arn: aws_iam_role(:webhook_role).arn,
      authorization_api_key_name: "X-API-Key",
      authorization_api_key_value: webhook_api_key
    }
  }
})

# Multiple notification endpoints for high availability
primary_queue = aws_sqs_queue(:security_events_primary, {
  visibility_timeout_seconds: 300,
  message_retention_seconds: 1209600  # 14 days
})

backup_queue = aws_sqs_queue(:security_events_backup, {
  visibility_timeout_seconds: 300,
  message_retention_seconds: 1209600
})

# Primary notification
aws_securitylake_subscriber_notification(:primary_notifications, {
  subscriber_arn: aws_securitylake_subscriber(:siem_subscriber).arn,
  configuration: {
    sqs_configuration: {
      queue_arn: primary_queue.arn
    }
  }
})

# Backup notification for different subscriber
aws_securitylake_subscriber_notification(:backup_notifications, {
  subscriber_arn: aws_securitylake_subscriber(:backup_processor).arn,
  configuration: {
    sqs_configuration: {
      queue_arn: backup_queue.arn
    }
  }
})
```

### aws_securitylake_data_lake_exception_subscription
Manages error and exception notifications for data lake operations.

**Key Features:**
- Data processing error notifications
- Configurable retention periods
- Multiple notification protocols
- Integration with monitoring systems

**Common Patterns:**
```ruby
# SQS-based exception handling
aws_securitylake_data_lake_exception_subscription(:sqs_exceptions, {
  notification_endpoint: aws_sqs_queue(:lake_exceptions).arn,
  subscription_protocol: "sqs",
  exception_time_to_live: 30  # Keep exceptions for 30 days
})

# Email notifications for critical exceptions
aws_securitylake_data_lake_exception_subscription(:email_exceptions, {
  notification_endpoint: "security-ops@example.com",
  subscription_protocol: "email",
  exception_time_to_live: 7
})

# Lambda-based exception processing
aws_securitylake_data_lake_exception_subscription(:lambda_exceptions, {
  notification_endpoint: aws_lambda_function(:exception_processor).arn,
  subscription_protocol: "lambda",
  exception_time_to_live: 14
})

# HTTPS endpoint for external monitoring
aws_securitylake_data_lake_exception_subscription(:webhook_exceptions, {
  notification_endpoint: "https://monitoring.example.com/security-lake-exceptions",
  subscription_protocol: "https",
  exception_time_to_live: 7
})
```

### aws_securitylake_organization_configuration
Configures Security Lake for AWS Organizations with automatic onboarding.

**Key Features:**
- Auto-enable for new organization accounts
- Regional data source configuration
- Centralized management
- Consistent security data collection

**Common Patterns:**
```ruby
# Basic organization-wide enablement
aws_securitylake_organization_configuration(:org_config, {
  auto_enable_new_account: [
    {
      region: "us-east-1",
      sources: [
        {
          source_name: "CLOUDTRAIL_MGMT",
          source_version: "2.0"
        },
        {
          source_name: "VPC_FLOW",
          source_version: "5.0"
        }
      ]
    }
  ]
})

# Multi-region organization configuration
aws_securitylake_organization_configuration(:multi_region_config, {
  auto_enable_new_account: [
    {
      region: "us-east-1",
      sources: [
        { source_name: "CLOUDTRAIL_MGMT", source_version: "2.0" },
        { source_name: "CLOUDTRAIL_DATA", source_version: "2.0" },
        { source_name: "VPC_FLOW", source_version: "5.0" },
        { source_name: "SH_FINDINGS", source_version: "1.0" }
      ]
    },
    {
      region: "us-west-2",
      sources: [
        { source_name: "CLOUDTRAIL_MGMT", source_version: "2.0" },
        { source_name: "VPC_FLOW", source_version: "5.0" }
      ]
    },
    {
      region: "eu-west-1",
      sources: [
        { source_name: "CLOUDTRAIL_MGMT", source_version: "2.0" },
        { source_name: "VPC_FLOW", source_version: "5.0" }
      ]
    }
  ]
})

# Comprehensive organization configuration
all_standard_sources = [
  { source_name: "CLOUDTRAIL_MGMT", source_version: "2.0" },
  { source_name: "VPC_FLOW", source_version: "5.0" },
  { source_name: "SH_FINDINGS", source_version: "1.0" },
  { source_name: "ROUTE53", source_version: "1.0" }
]

primary_regions = ["us-east-1", "us-west-2", "eu-west-1"]

aws_securitylake_organization_configuration(:comprehensive_config, {
  auto_enable_new_account: primary_regions.map do |region|
    {
      region: region,
      sources: all_standard_sources
    }
  end
})
```

## Best Practices

### Data Lake Architecture
1. **Multi-Region Setup**
   - Deploy data lakes in primary operational regions
   - Use cross-region replication for disaster recovery
   - Consider data sovereignty requirements

2. **Storage Optimization**
   - Implement lifecycle policies for cost management
   - Use appropriate encryption for sensitive data
   - Plan for long-term retention requirements

3. **Access Control**
   - Use Lake Formation for fine-grained permissions
   - Implement least-privilege access policies
   - Regular access reviews and audits

### Data Source Management
1. **Source Selection**
   - Enable core AWS sources (CloudTrail, VPC Flow Logs)
   - Add service-specific sources as needed (EKS, WAF)
   - Evaluate third-party integration requirements

2. **Custom Sources**
   - Use consistent OCSF event class mappings
   - Implement proper data validation and transformation
   - Monitor data quality and completeness

3. **Organization Enablement**
   - Start with essential sources for new accounts
   - Use regional configuration based on workload distribution
   - Plan for account-specific customizations

### Subscriber Management
1. **Access Patterns**
   - Use Lake Formation for complex analytical queries
   - Use S3 access for simple data exports
   - Implement proper authentication and authorization

2. **Notification Strategy**
   - Use SQS for high-throughput processing
   - Implement error handling and retry logic
   - Monitor notification delivery and processing

3. **Data Processing**
   - Design for eventual consistency
   - Implement idempotent processing logic
   - Plan for data format evolution

## Integration Examples

### Complete Security Data Platform
```ruby
# Comprehensive Security Lake implementation
template :security_data_platform do
  # Primary data lake with multi-region support
  main_lake = aws_securitylake_data_lake(:security_lake, {
    configuration: [
      {
        region: "us-east-1",
        encryption_configuration: {
          kms_key_id: aws_kms_key(:lake_key).arn
        },
        lifecycle_configuration: {
          expiration: { days: 2555 },  # 7 years
          transitions: [
            { days: 30, storage_class: "STANDARD_IA" },
            { days: 365, storage_class: "GLACIER" }
          ]
        },
        replication_configuration: {
          regions: ["us-west-2"],
          role_arn: aws_iam_role(:replication_role).arn
        }
      }
    ],
    tags: security_data_tags
  })

  # Enable all AWS native sources
  aws_sources = [
    { name: "CLOUDTRAIL_MGMT", version: "2.0" },
    { name: "CLOUDTRAIL_DATA", version: "2.0" },
    { name: "VPC_FLOW", version: "5.0" },
    { name: "SH_FINDINGS", version: "1.0" },
    { name: "ROUTE53", version: "1.0" },
    { name: "WAF", version: "1.0" }
  ]

  aws_sources.each do |source|
    aws_securitylake_aws_log_source(:"#{source[:name].downcase}", {
      source: {
        regions: primary_regions,
        source_name: source[:name],
        source_version: source[:version],
        accounts: organization_account_ids
      }
    })
  end

  # Custom log source for application security events
  aws_securitylake_custom_log_source(:app_security, {
    source_name: "ApplicationSecurity",
    source_version: "1.0",
    event_classes: ["SECURITY_FINDING", "AUTHENTICATION", "WEB_RESOURCES_ACTIVITY"],
    configuration: {
      crawler_configuration: {
        role_arn: aws_iam_role(:app_crawler).arn
      },
      provider_identity: {
        external_id: "app-security-001",
        principal: application_security_role_arn
      }
    },
    tags: security_data_tags
  })

  # SIEM subscriber with comprehensive access
  siem_subscriber = aws_securitylake_subscriber(:siem, {
    source: aws_sources.map do |source|
      {
        aws_log_source_resource: {
          source_name: source[:name],
          source_version: source[:version]
        }
      }
    end + [
      {
        custom_log_source_resource: {
          source_name: "ApplicationSecurity",
          source_version: "1.0"
        }
      }
    ],
    subscriber_identity: {
      external_id: siem_external_id,
      principal: siem_role_arn
    },
    subscriber_name: "Primary SIEM",
    access_type: "LAKEFORMATION",
    tags: security_data_tags
  })

  # Real-time notifications for SIEM
  aws_securitylake_subscriber_notification(:siem_notifications, {
    subscriber_arn: siem_subscriber.arn,
    configuration: {
      sqs_configuration: {
        queue_arn: aws_sqs_queue(:siem_events).arn
      }
    }
  })

  # Exception monitoring
  aws_securitylake_data_lake_exception_subscription(:exceptions, {
    notification_endpoint: aws_lambda_function(:exception_handler).arn,
    subscription_protocol: "lambda",
    exception_time_to_live: 14
  })

  # Organization-wide auto-enablement
  aws_securitylake_organization_configuration(:org_config, {
    auto_enable_new_account: primary_regions.map do |region|
      {
        region: region,
        sources: aws_sources.map { |s| { source_name: s[:name], source_version: s[:version] } }
      }
    end
  })
end
```

### Multi-Tenant Analytics Platform
```ruby
# Multi-tenant security analytics with Security Lake
template :multi_tenant_analytics do
  # Shared data lake for all tenants
  shared_lake = aws_securitylake_data_lake(:shared_analytics, {
    configuration: [
      {
        region: "us-east-1",
        encryption_configuration: {
          kms_key_id: aws_kms_key(:tenant_key).arn
        }
      }
    ],
    tags: {
      Purpose: "multi-tenant-analytics",
      Billing: "shared"
    }
  })

  # Enable core sources
  ["CLOUDTRAIL_MGMT", "VPC_FLOW", "SH_FINDINGS"].each do |source_name|
    aws_securitylake_aws_log_source(:"#{source_name.downcase}", {
      source: {
        regions: ["us-east-1"],
        source_name: source_name,
        accounts: tenant_account_ids
      }
    })
  end

  # Per-tenant subscribers with isolated access
  tenants.each do |tenant|
    tenant_subscriber = aws_securitylake_subscriber(:"tenant_#{tenant[:id]}", {
      source: [
        {
          aws_log_source_resource: {
            source_name: "CLOUDTRAIL_MGMT"
          }
        },
        {
          aws_log_source_resource: {
            source_name: "SH_FINDINGS"
          }
        }
      ],
      subscriber_identity: {
        external_id: "tenant-#{tenant[:id]}-#{SecureRandom.uuid}",
        principal: tenant[:analytics_role_arn]
      },
      subscriber_name: "#{tenant[:name]} Analytics",
      access_type: "LAKEFORMATION",
      tags: {
        TenantID: tenant[:id],
        TenantName: tenant[:name]
      }
    })

    # Per-tenant notification queue
    aws_securitylake_subscriber_notification(:"tenant_#{tenant[:id]}_notifications", {
      subscriber_arn: tenant_subscriber.arn,
      configuration: {
        sqs_configuration: {
          queue_arn: tenant[:notification_queue_arn]
        }
      }
    })
  end
end
```

### Compliance and Audit Platform
```ruby
# Security Lake for compliance and audit requirements
template :compliance_audit_platform do
  # Long-term retention data lake
  compliance_lake = aws_securitylake_data_lake(:compliance, {
    configuration: [
      {
        region: "us-east-1",
        encryption_configuration: {
          kms_key_id: aws_kms_key(:compliance_key).arn
        },
        lifecycle_configuration: {
          expiration: { days: 3653 },  # 10 years for compliance
          transitions: [
            { days: 90, storage_class: "STANDARD_IA" },
            { days: 365, storage_class: "GLACIER" },
            { days: 1095, storage_class: "DEEP_ARCHIVE" }
          ]
        }
      }
    ],
    tags: {
      Purpose: "compliance",
      DataClassification: "restricted",
      RetentionPeriod: "10years"
    }
  })

  # Enable all audit-relevant sources
  compliance_sources = [
    "CLOUDTRAIL_MGMT",
    "CLOUDTRAIL_DATA", 
    "SH_FINDINGS"
  ]

  compliance_sources.each do |source_name|
    aws_securitylake_aws_log_source(:"compliance_#{source_name.downcase}", {
      source: {
        regions: compliance_regions,
        source_name: source_name,
        accounts: all_organization_accounts
      }
    })
  end

  # Audit team subscriber
  audit_subscriber = aws_securitylake_subscriber(:audit_team, {
    source: compliance_sources.map do |source_name|
      {
        aws_log_source_resource: {
          source_name: source_name
        }
      }
    end,
    subscriber_identity: {
      external_id: "audit-team-001",
      principal: audit_team_role_arn
    },
    subscriber_name: "Compliance Audit Team",
    access_type: "LAKEFORMATION",
    tags: {
      Team: "audit",
      AccessLevel: "read-only"
    }
  })

  # External auditor subscriber (temporary access)
  if external_audit_enabled?
    aws_securitylake_subscriber(:external_auditor, {
      source: [
        {
          aws_log_source_resource: {
            source_name: "CLOUDTRAIL_MGMT"
          }
        }
      ],
      subscriber_identity: {
        external_id: external_auditor_external_id,
        principal: external_auditor_role_arn
      },
      subscriber_name: "External Auditor (Temporary)",
      access_type: "S3",
      tags: {
        AccessType: "temporary",
        ValidUntil: external_audit_end_date
      }
    })
  end

  # Compliance monitoring exceptions
  aws_securitylake_data_lake_exception_subscription(:compliance_exceptions, {
    notification_endpoint: compliance_monitoring_email,
    subscription_protocol: "email",
    exception_time_to_live: 90  # Extended retention for compliance
  })
end
```

## Common Pitfalls and Solutions

### Data Volume and Costs
**Problem**: Unexpectedly high storage costs due to data volume
**Solution**: 
- Implement proper lifecycle policies
- Monitor data ingestion rates per source
- Use cost allocation tags for accountability

### Access Control Complexity
**Problem**: Complex permissions with Lake Formation and cross-account access
**Solution**:
- Start with S3-based access for simplicity
- Use Lake Formation for fine-grained control when needed
- Document access patterns clearly

### OCSF Schema Evolution
**Problem**: Data format changes breaking downstream consumers
**Solution**:
- Version custom log sources properly
- Test schema changes in non-production environments
- Implement backward-compatible processing logic

### Performance Issues
**Problem**: Slow queries or data processing bottlenecks
**Solution**:
- Use appropriate partitioning strategies
- Optimize query patterns for time-series data
- Consider data preprocessing for frequently accessed patterns