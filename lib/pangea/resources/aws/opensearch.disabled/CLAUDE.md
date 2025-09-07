# OpenSearch Service Resources

## Overview

OpenSearch Service resources provide comprehensive enterprise search and analytics capabilities with full security, scalability, and operational features. These resources support both traditional OpenSearch domains and modern serverless collections for diverse enterprise search scenarios.

## Resources

### Core Domain Resources

#### aws_opensearch_domain
Creates a managed OpenSearch domain with comprehensive enterprise features.

```ruby
# Production-ready search cluster
search_domain = aws_opensearch_domain(:enterprise_search, {
  domain_name: "enterprise-search-prod",
  engine_version: "OpenSearch_2.11",
  
  cluster_config: {
    instance_type: "r6g.xlarge.search",
    instance_count: 3,
    dedicated_master_enabled: true,
    master_instance_type: "r6g.medium.search",
    master_instance_count: 3,
    zone_awareness_enabled: true,
    zone_awareness_config: {
      availability_zone_count: 3
    }
  },
  
  ebs_options: {
    ebs_enabled: true,
    volume_type: "gp3",
    volume_size: 100,
    iops: 3000,
    throughput: 125
  },
  
  vpc_options: {
    subnet_ids: ["subnet-12345", "subnet-67890", "subnet-abcde"],
    security_group_ids: ["sg-opensearch"]
  },
  
  advanced_security_options: {
    enabled: true,
    internal_user_database_enabled: false,
    master_user_options: {
      master_user_arn: "arn:aws:iam::123456789012:role/OpenSearchMasterRole"
    }
  },
  
  encrypt_at_rest: {
    enabled: true,
    kms_key_id: "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012"
  },
  
  node_to_node_encryption: {
    enabled: true
  },
  
  domain_endpoint_options: {
    enforce_https: true,
    tls_security_policy: "Policy-Min-TLS-1-2-2019-07",
    custom_endpoint_enabled: true,
    custom_endpoint: "search.company.com",
    custom_endpoint_certificate_arn: "arn:aws:acm:us-east-1:123456789012:certificate/12345678-1234-1234-1234-123456789012"
  },
  
  log_publishing_options: {
    index_slow_logs: {
      enabled: true,
      cloudwatch_log_group_arn: "arn:aws:logs:us-east-1:123456789012:log-group:/aws/opensearch/domains/enterprise-search/index-slow-logs"
    },
    search_slow_logs: {
      enabled: true,
      cloudwatch_log_group_arn: "arn:aws:logs:us-east-1:123456789012:log-group:/aws/opensearch/domains/enterprise-search/search-slow-logs"
    },
    audit_logs: {
      enabled: true,
      cloudwatch_log_group_arn: "arn:aws:logs:us-east-1:123456789012:log-group:/aws/opensearch/domains/enterprise-search/audit-logs"
    }
  },
  
  auto_tune_options: {
    desired_state: "ENABLED",
    maintenance_schedule: {
      start_at: "2024-01-01T02:00:00Z",
      duration: {
        value: 2,
        unit: "HOURS"
      },
      cron_expression_for_recurrence: "cron(0 2 * * SUN *)"
    }
  },
  
  tags: {
    Environment: "production",
    Team: "data-engineering",
    CostCenter: "analytics"
  }
})

# Access cluster information
puts "Domain endpoint: #{search_domain.endpoint}"
puts "Dashboards URL: #{search_domain.dashboards_url}"
puts "Production ready: #{search_domain.production_ready?}"
puts "Multi-AZ enabled: #{search_domain.multi_az?}"
```

**Key Features:**
- Multi-AZ deployment with zone awareness
- Advanced security with fine-grained access control
- Encryption at rest and in transit
- Custom domain endpoints with SSL certificates
- Auto-tune for performance optimization
- Comprehensive logging and monitoring
- Production-ready configuration validation

#### aws_opensearch_domain_endpoint
Configures custom domain endpoints for OpenSearch domains.

```ruby
# Custom domain endpoint
custom_endpoint = aws_opensearch_domain_endpoint(:custom_endpoint, {
  domain_arn: search_domain.arn,
  domain_endpoint_options: {
    custom_endpoint_enabled: true,
    custom_endpoint: "search.company.com",
    custom_endpoint_certificate_arn: "arn:aws:acm:us-east-1:123456789012:certificate/12345678-1234-1234-1234-123456789012",
    enforce_https: true,
    tls_security_policy: "Policy-Min-TLS-1-2-2019-07"
  }
})

puts "Custom endpoint URL: #{custom_endpoint.endpoint_url}"
puts "HTTPS enforced: #{custom_endpoint.https_enforced?}"
```

#### aws_opensearch_domain_saml_options
Configures SAML authentication for OpenSearch domains.

```ruby
# SAML authentication
saml_config = aws_opensearch_domain_saml_options(:saml_auth, {
  domain_name: "enterprise-search-prod",
  saml_options: {
    enabled: true,
    idp: {
      entity_id: "https://company.okta.com/saml2/service-provider",
      metadata_content: File.read("saml-metadata.xml")
    },
    master_user_name: "admin",
    subject_key: "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/name",
    roles_key: "http://schemas.microsoft.com/ws/2008/06/identity/claims/role",
    session_timeout_minutes: 180
  }
})

puts "SAML enabled: #{saml_config.saml_enabled?}"
puts "Session timeout: #{saml_config.session_timeout_minutes} minutes"
```

### Cross-Cluster Resources

#### aws_opensearch_outbound_connection
Creates outbound connections for cross-cluster search.

```ruby
# Cross-region search connection
outbound_connection = aws_opensearch_outbound_connection(:cross_region_search, {
  connection_alias: "prod-to-analytics",
  local_domain_info: {
    domain_name: "enterprise-search-prod",
    region: "us-east-1"
  },
  remote_domain_info: {
    domain_name: "analytics-search-cluster",
    region: "us-west-2"
  },
  connection_mode: "VPC_ENDPOINT"
})

puts "Connection active: #{outbound_connection.active?}"
puts "Cross-region: #{outbound_connection.cross_region?}"
```

#### aws_opensearch_inbound_connection
Accepts inbound connections for cross-cluster search.

```ruby
# Accept incoming connection
inbound_connection = aws_opensearch_inbound_connection(:accept_connection, {
  connection_id: "conn-12345678",
  accept_connection: true
})

puts "Connection accepted: #{inbound_connection.accepted?}"
puts "Status: #{inbound_connection.connection_status}"
```

### Security and Access

#### aws_opensearch_domain_policy
Configures domain-level access policies.

```ruby
# Domain access policy
domain_policy = aws_opensearch_domain_policy(:access_policy, {
  domain_name: "enterprise-search-prod",
  access_policies: JSON.pretty_generate({
    "Version" => "2012-10-17",
    "Statement" => [
      {
        "Effect" => "Allow",
        "Principal" => {
          "AWS" => "arn:aws:iam::123456789012:role/OpenSearchAccessRole"
        },
        "Action" => "es:*",
        "Resource" => "arn:aws:es:us-east-1:123456789012:domain/enterprise-search-prod/*"
      }
    ]
  })
})

puts "Allows public access: #{domain_policy.allows_public_access?}"
puts "VPC restricted: #{domain_policy.restricted_to_vpc?}"
```

### Package Management

#### aws_opensearch_package
Creates packages for plugins and dictionaries.

```ruby
# Custom analyzer plugin
analyzer_plugin = aws_opensearch_package(:custom_analyzer, {
  package_name: "custom-analyzers",
  package_type: "ZIP-PLUGIN",
  package_description: "Custom text analyzers for enterprise search",
  package_source: {
    s3_bucket_name: "opensearch-packages",
    s3_key: "plugins/custom-analyzers-1.0.zip"
  }
})

puts "Package available: #{analyzer_plugin.available?}"
puts "Source location: #{analyzer_plugin.source_location}"
```

#### aws_opensearch_package_association
Associates packages with domains.

```ruby
# Associate plugin with domain
package_association = aws_opensearch_package_association(:plugin_association, {
  package_id: analyzer_plugin.package_id,
  domain_name: "enterprise-search-prod"
})

puts "Association status: #{package_association.domain_package_status}"
puts "Successfully associated: #{package_association.associated?}"
```

### Network Access

#### aws_opensearch_vpc_endpoint
Creates VPC endpoints for private domain access.

```ruby
# VPC endpoint for private access
vpc_endpoint = aws_opensearch_vpc_endpoint(:private_access, {
  domain_arn: search_domain.arn,
  vpc_options: {
    subnet_ids: ["subnet-private-1", "subnet-private-2"],
    security_group_ids: ["sg-opensearch-private"]
  }
})

puts "Endpoint URL: #{vpc_endpoint.endpoint_url}"
puts "Multi-AZ: #{vpc_endpoint.multi_az?}"
```

### Serverless Resources

#### aws_opensearch_serverless_collection
Creates serverless OpenSearch collections.

```ruby
# Serverless search collection
serverless_collection = aws_opensearch_serverless_collection(:log_analytics, {
  name: "log-analytics-prod",
  description: "Serverless collection for log analytics",
  type: "TIMESERIES",
  standby_replicas: "ENABLED",
  tags: {
    Environment: "production",
    UseCase: "log-analytics"
  }
})

puts "Collection URL: #{serverless_collection.collection_url}"
puts "Dashboard URL: #{serverless_collection.dashboard_url}"
puts "Collection type: #{serverless_collection.collection_type}"
puts "Standby replicas: #{serverless_collection.standby_replicas_enabled?}"
```

#### aws_opensearch_serverless_security_policy
Creates security policies for serverless collections.

```ruby
# Encryption security policy
encryption_policy = aws_opensearch_serverless_security_policy(:encryption, {
  name: "log-analytics-encryption",
  type: "encryption",
  description: "Encryption policy for log analytics collection",
  policy: JSON.pretty_generate({
    "Rules" => [
      {
        "ResourceType" => "collection",
        "Resource" => ["collection/log-analytics-*"]
      }
    ],
    "AWSOwnedKey" => true
  })
})

puts "Policy type: #{encryption_policy.policy_type}"
puts "Applies to collections: #{encryption_policy.applies_to_collections}"
```

#### aws_opensearch_serverless_access_policy
Creates data access policies for serverless collections.

```ruby
# Data access policy
access_policy = aws_opensearch_serverless_access_policy(:data_access, {
  name: "log-analytics-access",
  type: "data",
  description: "Data access policy for log analytics",
  policy: JSON.pretty_generate({
    "Rules" => [
      {
        "ResourceType" => "collection",
        "Resource" => ["collection/log-analytics-prod"],
        "Permission" => [
          "aoss:CreateCollectionItems",
          "aoss:UpdateCollectionItems",
          "aoss:DescribeCollectionItems"
        ],
        "Principal" => ["arn:aws:iam::123456789012:role/LogAnalyticsRole"]
      }
    ]
  })
})

puts "Granted principals: #{access_policy.granted_principals}"
puts "Permitted collections: #{access_policy.permitted_collections}"
puts "Admin access for role: #{access_policy.grants_admin_access?('arn:aws:iam::123456789012:role/LogAnalyticsRole')}"
```

## Enterprise Search Patterns

### Multi-Environment Search Infrastructure

```ruby
template :search_infrastructure do
  # Production search domain
  prod_search = aws_opensearch_domain(:production, {
    domain_name: "search-prod",
    engine_version: "OpenSearch_2.11",
    cluster_config: {
      instance_type: "r6g.large.search",
      instance_count: 3,
      zone_awareness_enabled: true
    },
    advanced_security_options: {
      enabled: true,
      master_user_options: {
        master_user_arn: "arn:aws:iam::123456789012:role/SearchMasterRole"
      }
    }
  })
  
  # Development serverless collection
  dev_search = aws_opensearch_serverless_collection(:development, {
    name: "search-dev",
    type: "SEARCH",
    standby_replicas: "DISABLED"
  })
  
  # Cross-cluster connection for analytics
  aws_opensearch_outbound_connection(:analytics_connection, {
    connection_alias: "prod-to-analytics",
    local_domain_info: {
      domain_name: prod_search.domain_name
    },
    remote_domain_info: {
      domain_name: "analytics-cluster"
    }
  })
end
```

### Enterprise Security Configuration

```ruby
template :search_security do
  # Domain with comprehensive security
  secure_domain = aws_opensearch_domain(:secure_search, {
    domain_name: "secure-enterprise-search",
    advanced_security_options: {
      enabled: true,
      saml_options: {
        enabled: true,
        idp: {
          entity_id: "https://company.okta.com",
          metadata_content: saml_metadata
        }
      }
    },
    encrypt_at_rest: { enabled: true },
    node_to_node_encryption: { enabled: true }
  })
  
  # Restrictive access policy
  aws_opensearch_domain_policy(:secure_policy, {
    domain_name: secure_domain.domain_name,
    access_policies: restrictive_policy_json
  })
  
  # VPC-only access
  aws_opensearch_vpc_endpoint(:private_endpoint, {
    domain_arn: secure_domain.arn,
    vpc_options: {
      subnet_ids: private_subnet_ids,
      security_group_ids: [security_group_id]
    }
  })
end
```

## Best Practices

### Production Deployment
- Use multi-AZ configurations with dedicated masters
- Enable encryption at rest and in transit
- Configure comprehensive logging and monitoring
- Implement fine-grained access control
- Use custom endpoints for production domains

### Performance Optimization
- Choose appropriate instance types for workload
- Configure EBS optimization for storage-intensive workloads
- Enable Auto-Tune for automatic performance tuning
- Use warm storage for cost-effective data retention
- Implement proper index lifecycle management

### Security Hardening
- Enable advanced security features
- Use IAM roles instead of embedded credentials
- Implement network-level access controls
- Enable audit logging for compliance
- Regular security policy reviews

### Cost Management
- Use serverless collections for variable workloads
- Implement proper data lifecycle policies
- Monitor usage and optimize instance sizing
- Use reserved instances for predictable workloads
- Regular cost optimization reviews

### Disaster Recovery
- Configure cross-region replication
- Implement automated backup strategies
- Test restore procedures regularly
- Document recovery processes
- Monitor replication lag and health

OpenSearch Service resources provide enterprise-grade search and analytics capabilities with comprehensive security, monitoring, and operational features for production-scale deployments.