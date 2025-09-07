# AWS Detective Resources

## Overview

AWS Detective resources enable automated security investigation and analysis of AWS workloads. These resources help security teams identify the root cause of security findings, investigate suspicious activities, and visualize security data across AWS accounts.

## Key Concepts

### Behavior Graphs
- **Purpose**: Central data structure that aggregates and analyzes security data
- **Data Sources**: CloudTrail logs, VPC Flow Logs, GuardDuty findings
- **Analysis**: Machine learning models identify unusual patterns and behaviors
- **Multi-Account**: Supports investigation across member accounts

### Investigation Workflow
1. **Data Collection**: Automatic ingestion from AWS security services
2. **Graph Analysis**: ML-powered analysis of relationships and patterns
3. **Finding Generation**: Identification of security issues and anomalies
4. **Investigation**: Interactive exploration of security incidents
5. **Remediation**: Integration with response and remediation tools

### Organization Integration
- **Delegated Admin**: Designate security account as Detective admin
- **Auto-Enable**: Automatically enable Detective for new organization accounts
- **Centralized Management**: Manage all member accounts from admin account
- **Cross-Account Analysis**: Investigate security issues across the organization

## Resources

### aws_detective_graph
Primary resource for creating and managing Detective behavior graphs.

**Key Features:**
- Multi-account security data aggregation
- ML-powered anomaly detection
- Integration with AWS security services
- Customizable data source configuration

**Common Patterns:**
```ruby
# Basic behavior graph
aws_detective_graph(:security_graph, {
  tags: {
    Environment: "production",
    Team: "security"
  }
})

# Graph with datasource configuration
aws_detective_graph(:advanced_graph, {
  datasource_packages: [
    {
      package_ingest_state: "STARTED",
      last_ingest_state_change: {
        timestamp: "2024-01-01T00:00:00Z"
      }
    }
  ],
  auto_enable_members: true,
  tags: {
    Environment: "production",
    Compliance: "required"
  }
})

# Organization-wide graph
aws_detective_graph(:org_graph, {
  auto_enable_members: true,
  disable_email_notification: true,
  tags: {
    Scope: "organization",
    ManagedBy: "security-team"
  }
})
```

### aws_detective_member
Manages member accounts in a Detective behavior graph.

**Key Features:**
- Invite AWS accounts to contribute data
- Manage member account permissions
- Monitor member account status
- Control notification settings

**Common Patterns:**
```ruby
# Add member account
aws_detective_member(:prod_member, {
  graph_arn: aws_detective_graph(:security_graph).graph_arn,
  account_id: "123456789012",
  email_address: "security@example.com",
  message: "Please accept this invitation to join our security monitoring"
})

# Add member without email notification
aws_detective_member(:dev_member, {
  graph_arn: aws_detective_graph(:security_graph).graph_arn,
  account_id: "234567890123",
  email_address: "dev-security@example.com",
  disable_email_notification: true
})

# Bulk member addition pattern
["123456789012", "234567890123", "345678901234"].each_with_index do |account_id, index|
  aws_detective_member(:"member_#{index}", {
    graph_arn: aws_detective_graph(:security_graph).graph_arn,
    account_id: account_id,
    email_address: "security-#{account_id}@example.com",
    message: "Join our centralized security monitoring"
  })
end
```

### aws_detective_invitation_accepter
Accepts invitations to join Detective behavior graphs.

**Key Features:**
- Automated invitation acceptance
- Cross-account collaboration
- Simplified onboarding process

**Common Patterns:**
```ruby
# Accept invitation in member account
aws_detective_invitation_accepter(:accept_invite, {
  graph_arn: "arn:aws:detective:us-east-1:123456789012:graph:abc123"
})

# Conditional acceptance based on environment
if production_account?
  aws_detective_invitation_accepter(:prod_acceptance, {
    graph_arn: central_security_graph_arn
  })
end
```

### aws_detective_organization_admin_account
Designates the Detective administrator account for an AWS Organization.

**Key Features:**
- Centralized security management
- Delegated administration
- Organization-wide Detective deployment

**Common Patterns:**
```ruby
# Designate security account as admin
aws_detective_organization_admin_account(:detective_admin, {
  account_id: "999888777666"  # Security account ID
})

# Multi-service security admin pattern
security_account_id = "999888777666"

aws_detective_organization_admin_account(:detective_admin, {
  account_id: security_account_id
})

# Also set for other security services
aws_guardduty_organization_admin_account(:guardduty_admin, {
  account_id: security_account_id
})

aws_securityhub_organization_admin_account(:securityhub_admin, {
  account_id: security_account_id
})
```

### aws_detective_organization_configuration
Configures Detective settings for AWS Organizations.

**Key Features:**
- Auto-enable for new accounts
- Datasource package management
- Organization-wide settings

**Common Patterns:**
```ruby
# Basic organization configuration
aws_detective_organization_configuration(:org_config, {
  graph_arn: aws_detective_graph(:org_graph).graph_arn,
  auto_enable: true
})

# Advanced configuration with datasource packages
aws_detective_organization_configuration(:advanced_config, {
  graph_arn: aws_detective_graph(:org_graph).graph_arn,
  auto_enable: true,
  datasource_packages_configuration: [
    {
      datasource_package: "DETECTIVE_CORE",
      auto_enable: true
    },
    {
      datasource_package: "EKS_AUDIT",
      auto_enable: true
    },
    {
      datasource_package: "ASFF_SECURITYHUB_FINDING",
      auto_enable: true
    }
  ]
})

# Selective datasource enablement
aws_detective_organization_configuration(:selective_config, {
  graph_arn: aws_detective_graph(:org_graph).graph_arn,
  auto_enable: true,
  datasource_packages_configuration: [
    {
      datasource_package: "DETECTIVE_CORE",
      auto_enable: true
    },
    {
      datasource_package: "EKS_AUDIT",
      auto_enable: false  # Enable manually for EKS accounts
    }
  ]
})
```

### aws_detective_datasource_package
Manages individual datasource packages for Detective graphs.

**Key Features:**
- Fine-grained data source control
- Package state management
- Cost optimization through selective enablement

**Common Patterns:**
```ruby
# Enable core Detective package
aws_detective_datasource_package(:core_package, {
  graph_arn: aws_detective_graph(:security_graph).graph_arn,
  datasource_package: "DETECTIVE_CORE",
  package_ingest_state: "STARTED"
})

# Enable EKS audit logs for container security
aws_detective_datasource_package(:eks_package, {
  graph_arn: aws_detective_graph(:security_graph).graph_arn,
  datasource_package: "EKS_AUDIT",
  package_ingest_state: "STARTED"
})

# Conditional package enablement
if kubernetes_workloads_present?
  aws_detective_datasource_package(:eks_monitoring, {
    graph_arn: aws_detective_graph(:security_graph).graph_arn,
    datasource_package: "EKS_AUDIT",
    package_ingest_state: "STARTED"
  })
else
  aws_detective_datasource_package(:eks_monitoring, {
    graph_arn: aws_detective_graph(:security_graph).graph_arn,
    datasource_package: "EKS_AUDIT",
    package_ingest_state: "DISABLED"
  })
end

# Security Hub integration
aws_detective_datasource_package(:securityhub_package, {
  graph_arn: aws_detective_graph(:security_graph).graph_arn,
  datasource_package: "ASFF_SECURITYHUB_FINDING",
  package_ingest_state: "STARTED"
})
```

### aws_detective_finding
Represents security findings within Detective behavior graphs.

**Key Features:**
- Custom finding creation
- Finding lifecycle management
- Integration with investigation workflows
- Severity and status tracking

**Common Patterns:**
```ruby
# High-severity security finding
aws_detective_finding(:critical_finding, {
  graph_arn: aws_detective_graph(:security_graph).graph_arn,
  finding_id: "susp-data-exfil-001",
  finding_type: "DataExfiltration",
  severity: "CRITICAL",
  status: "ACTIVE",
  title: "Suspected Data Exfiltration Activity",
  description: "Unusual data transfer patterns detected from production database",
  first_observed_at: "2024-01-15T10:30:00Z",
  last_observed_at: "2024-01-15T14:45:00Z",
  entities: [
    {
      entity_type: "AWS_ACCOUNT",
      entity_arn: "arn:aws:iam::123456789012:root"
    },
    {
      entity_type: "EC2_INSTANCE",
      entity_value: "i-1234567890abcdef0"
    }
  ]
})

# Medium-severity compliance finding
aws_detective_finding(:compliance_finding, {
  graph_arn: aws_detective_graph(:security_graph).graph_arn,
  finding_id: "compliance-iam-002",
  finding_type: "ComplianceViolation",
  severity: "MEDIUM",
  status: "ACTIVE",
  title: "IAM Policy Compliance Violation",
  description: "Overly permissive IAM policies detected",
  entities: [
    {
      entity_type: "IAM_ROLE",
      entity_arn: "arn:aws:iam::123456789012:role/OverlyPermissiveRole"
    }
  ]
})

# Archived resolved finding
aws_detective_finding(:resolved_finding, {
  graph_arn: aws_detective_graph(:security_graph).graph_arn,
  finding_id: "resolved-vuln-003",
  finding_type: "Vulnerability",
  severity: "HIGH",
  status: "ARCHIVED",
  title: "Resolved Security Vulnerability",
  description: "Previously identified vulnerability has been patched"
})
```

### aws_detective_indicator
Manages threat indicators within Detective behavior graphs.

**Key Features:**
- Threat intelligence integration
- Custom indicator management
- Automated threat detection
- Indicator lifecycle tracking

**Common Patterns:**
```ruby
# Malicious IP indicator
aws_detective_indicator(:malicious_ip, {
  graph_arn: aws_detective_graph(:security_graph).graph_arn,
  indicator_type: "IP_ADDRESS",
  indicator_value: "192.0.2.100",
  indicator_detail: {
    threat_intelligence_source: "Internal Threat Intel",
    threat_types: ["C2", "Malware"],
    confidence_score: 90,
    first_seen: "2024-01-01T00:00:00Z",
    last_seen: "2024-01-15T12:00:00Z"
  },
  status: "ACTIVE",
  tags: {
    ThreatLevel: "high",
    Source: "honeypot"
  }
})

# Suspicious domain indicator
aws_detective_indicator(:suspicious_domain, {
  graph_arn: aws_detective_graph(:security_graph).graph_arn,
  indicator_type: "DOMAIN",
  indicator_value: "suspicious-site.example",
  indicator_detail: {
    threat_intelligence_source: "OSINT",
    threat_types: ["Phishing", "Malware"],
    confidence_score: 75,
    first_seen: "2024-01-10T00:00:00Z"
  },
  status: "ACTIVE",
  tags: {
    Campaign: "phishing-2024-q1"
  }
})

# Hash-based malware indicator
aws_detective_indicator(:malware_hash, {
  graph_arn: aws_detective_graph(:security_graph).graph_arn,
  indicator_type: "HASH",
  indicator_value: "d41d8cd98f00b204e9800998ecf8427e",
  indicator_detail: {
    threat_intelligence_source: "Malware Analysis Team",
    threat_types: ["Ransomware"],
    confidence_score: 100,
    first_seen: "2024-01-05T00:00:00Z"
  },
  status: "ACTIVE",
  tags: {
    MalwareFamily: "LockBit",
    Severity: "critical"
  }
})

# Bulk indicator import pattern
threat_indicators = [
  { type: "IP_ADDRESS", value: "192.0.2.101", threats: ["C2"] },
  { type: "IP_ADDRESS", value: "192.0.2.102", threats: ["Scanner"] },
  { type: "DOMAIN", value: "bad-domain.example", threats: ["Phishing"] }
]

threat_indicators.each_with_index do |indicator, index|
  aws_detective_indicator(:"threat_indicator_#{index}", {
    graph_arn: aws_detective_graph(:security_graph).graph_arn,
    indicator_type: indicator[:type],
    indicator_value: indicator[:value],
    indicator_detail: {
      threat_intelligence_source: "Automated Feed",
      threat_types: indicator[:threats],
      confidence_score: 80,
      first_seen: Time.now.utc.iso8601
    },
    status: "ACTIVE"
  })
end
```

## Best Practices

### Security Architecture
1. **Centralized Management**
   - Use organization admin account for Detective
   - Enable auto-enrollment for new accounts
   - Implement consistent tagging strategy

2. **Data Source Selection**
   - Enable core package for all accounts
   - Selectively enable EKS audit for container workloads
   - Integrate Security Hub findings for comprehensive view

3. **Investigation Workflow**
   - Define clear finding severity criteria
   - Implement automated indicator updates
   - Regular review and archive resolved findings

### Cost Optimization
1. **Data Volume Management**
   - Monitor ingestion rates per member account
   - Disable unused datasource packages
   - Archive old findings and indicators

2. **Package Selection**
   - Start with core package only
   - Enable additional packages based on workload types
   - Regular review of package utilization

### Compliance Considerations
1. **Data Retention**
   - Understand Detective's 1-year retention
   - Plan for long-term archival if needed
   - Document investigation procedures

2. **Access Control**
   - Implement least-privilege IAM policies
   - Use SCPs for organization-wide controls
   - Regular access reviews

## Integration Examples

### Complete Security Operations Center
```ruby
# Centralized SOC setup with Detective
template :security_operations do
  # Detective setup
  detective_graph = aws_detective_graph(:soc_graph, {
    auto_enable_members: true,
    tags: {
      Component: "SOC",
      CostCenter: "Security"
    }
  })

  # Enable all data sources
  ["DETECTIVE_CORE", "EKS_AUDIT", "ASFF_SECURITYHUB_FINDING"].each do |package|
    aws_detective_datasource_package(:"#{package.downcase}_pkg", {
      graph_arn: detective_graph.graph_arn,
      datasource_package: package,
      package_ingest_state: "STARTED"
    })
  end

  # Organization configuration
  aws_detective_organization_configuration(:soc_org_config, {
    graph_arn: detective_graph.graph_arn,
    auto_enable: true,
    datasource_packages_configuration: [
      { datasource_package: "DETECTIVE_CORE", auto_enable: true },
      { datasource_package: "EKS_AUDIT", auto_enable: true },
      { datasource_package: "ASFF_SECURITYHUB_FINDING", auto_enable: true }
    ]
  })

  # Import threat intelligence
  load_threat_indicators.each_with_index do |indicator, idx|
    aws_detective_indicator(:"ti_#{idx}", {
      graph_arn: detective_graph.graph_arn,
      indicator_type: indicator[:type],
      indicator_value: indicator[:value],
      indicator_detail: indicator[:detail],
      status: "ACTIVE",
      tags: indicator[:tags]
    })
  end
end
```

### Multi-Account Security Monitoring
```ruby
# Security monitoring across multiple AWS accounts
template :multi_account_security do
  # Admin account setup
  aws_detective_organization_admin_account(:admin, {
    account_id: security_account_id
  })

  # Create main graph
  main_graph = aws_detective_graph(:main, {
    auto_enable_members: true,
    disable_email_notification: true,
    tags: standard_security_tags
  })

  # Add critical production accounts
  critical_accounts.each do |account|
    aws_detective_member(:"member_#{account[:id]}", {
      graph_arn: main_graph.graph_arn,
      account_id: account[:id],
      email_address: account[:email],
      message: "Critical account - mandatory security monitoring"
    })
  end

  # Configure organization settings
  aws_detective_organization_configuration(:org_settings, {
    graph_arn: main_graph.graph_arn,
    auto_enable: true,
    datasource_packages_configuration: [
      {
        datasource_package: "DETECTIVE_CORE",
        auto_enable: true
      },
      {
        datasource_package: "EKS_AUDIT",
        auto_enable: account_has_eks?
      },
      {
        datasource_package: "ASFF_SECURITYHUB_FINDING",
        auto_enable: security_hub_enabled?
      }
    ]
  })

  # High-value target indicators
  high_value_indicators.each do |indicator|
    aws_detective_indicator(:"hv_#{indicator[:id]}", {
      graph_arn: main_graph.graph_arn,
      indicator_type: indicator[:type],
      indicator_value: indicator[:value],
      indicator_detail: {
        threat_intelligence_source: "Critical Asset Registry",
        threat_types: ["HighValueTarget"],
        confidence_score: 100
      },
      status: "ACTIVE",
      tags: {
        AssetValue: "critical",
        MonitoringPriority: "highest"
      }
    })
  end
end
```

### Automated Threat Response
```ruby
# Automated threat detection and response with Detective
template :threat_response do
  detective_graph = aws_detective_graph(:threat_graph, {
    tags: {
      Component: "ThreatResponse",
      Automation: "enabled"
    }
  })

  # Lambda for automated finding creation
  finding_creator = aws_lambda_function(:finding_creator, {
    runtime: "python3.9",
    handler: "index.handler",
    code: threat_detection_code,
    environment: {
      variables: {
        DETECTIVE_GRAPH_ARN: detective_graph.graph_arn
      }
    }
  })

  # EventBridge rule for GuardDuty findings
  aws_events_rule(:guardduty_to_detective, {
    event_pattern: {
      source: ["aws.guardduty"],
      detail_type: ["GuardDuty Finding"]
    },
    targets: [
      {
        target_id: "1",
        arn: finding_creator.arn
      }
    ]
  })

  # Automated indicator updates from threat feeds
  threat_feed_processor = aws_lambda_function(:threat_feed_processor, {
    runtime: "python3.9",
    handler: "index.handler",
    code: threat_feed_code,
    environment: {
      variables: {
        DETECTIVE_GRAPH_ARN: detective_graph.graph_arn,
        THREAT_FEED_BUCKET: threat_feed_bucket.id
      }
    }
  })

  # Schedule threat feed updates
  aws_events_rule(:threat_feed_schedule, {
    schedule_expression: "rate(1 hour)",
    targets: [
      {
        target_id: "1",
        arn: threat_feed_processor.arn
      }
    ]
  })
end
```

## Common Pitfalls and Solutions

### Data Ingestion Issues
**Problem**: High data ingestion costs or volume limits
**Solution**: 
- Review and disable unnecessary datasource packages
- Implement VPC Flow Log sampling
- Use Detective metrics to identify high-volume accounts

### Investigation Complexity
**Problem**: Too many findings to investigate effectively
**Solution**:
- Implement finding priority scoring
- Automate low-severity finding archival
- Use ML insights for finding correlation

### Cross-Account Permissions
**Problem**: Member accounts can't accept invitations
**Solution**:
- Verify IAM permissions in member accounts
- Use organization admin account for auto-enable
- Check for SCPs blocking Detective APIs

### Performance Optimization
**Problem**: Slow graph queries or timeouts
**Solution**:
- Limit time range for investigations
- Use finding filters effectively
- Archive old findings regularly