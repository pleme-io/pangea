# AWS WAF v2 Web ACL Resource - Technical Documentation

## Resource Overview

The `aws_wafv2_web_acl` resource provides comprehensive web application firewall capabilities for protecting applications against common exploits, DDoS attacks, and application-layer threats. It supports the full spectrum of WAF v2 features including managed rule groups, custom rules, rate limiting, geo-blocking, and advanced threat protection.

## Architecture Integration Patterns

### 1. Multi-Layered Security Architecture

```ruby
template :comprehensive_web_security do
  # Edge protection with CloudFront-scoped Web ACL
  edge_protection = aws_wafv2_web_acl(:edge_security, {
    name: "EdgeSecurityWebACL",
    scope: "CLOUDFRONT",
    default_action: { allow: {} },
    rules: [
      {
        name: "EdgeRateLimiting",
        priority: 100,
        action: { block: {} },
        statement: {
          rate_based_statement: {
            limit: 10000, # Higher limit for edge
            aggregate_key_type: "IP"
          }
        },
        visibility_config: {
          cloudwatch_metrics_enabled: true,
          metric_name: "EdgeRateLimit",
          sampled_requests_enabled: true
        }
      }
    ],
    visibility_config: {
      cloudwatch_metrics_enabled: true,
      metric_name: "EdgeSecurity",
      sampled_requests_enabled: true
    }
  })

  # Application-layer protection with regional Web ACL
  app_protection = aws_wafv2_web_acl(:app_security, {
    name: "AppSecurityWebACL", 
    scope: "REGIONAL",
    default_action: { allow: {} },
    rules: [
      {
        name: "SQLInjectionProtection",
        priority: 100,
        action: { 
          captcha: {
            custom_request_handling: {
              insert_headers: [
                { name: "X-Security-Level", value: "High" }
              ]
            }
          }
        },
        statement: {
          sqli_match_statement: {
            field_to_match: {
              json_body: {
                match_pattern: { all: {} },
                match_scope: "ALL",
                invalid_fallback_behavior: "EVALUATE_AS_STRING"
              }
            },
            text_transformations: [
              { priority: 0, type: "URL_DECODE" },
              { priority: 1, type: "HTML_ENTITY_DECODE" },
              { priority: 2, type: "NORMALIZE_PATH" }
            ]
          }
        },
        visibility_config: {
          cloudwatch_metrics_enabled: true,
          metric_name: "SQLInjectionProtection",
          sampled_requests_enabled: true
        },
        captcha_config: {
          immunity_time_property: {
            immunity_time: 3600 # 1 hour immunity
          }
        }
      }
    ],
    visibility_config: {
      cloudwatch_metrics_enabled: true,
      metric_name: "AppSecurity", 
      sampled_requests_enabled: true
    },
    captcha_config: {
      immunity_time_property: {
        immunity_time: 3600
      }
    },
    token_domains: ["myapp.com", "api.myapp.com"]
  })
end
```

### 2. API-First Security Architecture

```ruby
template :api_security_architecture do  
  # API-specific Web ACL with comprehensive protection
  api_protection = aws_wafv2_web_acl(:api_security, {
    name: "APISecurityWebACL",
    scope: "REGIONAL",
    default_action: { allow: {} },
    rules: [
      # Rate limiting by API key
      {
        name: "APIRateLimiting",
        priority: 50,
        action: {
          block: {
            custom_response: {
              response_code: 429,
              custom_response_body_key: "api_rate_limit",
              response_headers: [
                { name: "Retry-After", value: "60" },
                { name: "X-RateLimit-Exceeded", value: "true" }
              ]
            }
          }
        },
        statement: {
          rate_based_statement: {
            limit: 1000,
            aggregate_key_type: "IP",
            scope_down_statement: {
              byte_match_statement: {
                field_to_match: { single_header: { name: "Content-Type" } },
                positional_constraint: "CONTAINS",
                search_string: "application/json",
                text_transformations: [
                  { priority: 0, type: "LOWERCASE" }
                ]
              }
            }
          }
        },
        visibility_config: {
          cloudwatch_metrics_enabled: true,
          metric_name: "APIRateLimit",
          sampled_requests_enabled: true
        }
      },
      
      # JSON-specific protection
      {
        name: "JSONPayloadProtection", 
        priority: 100,
        action: { challenge: {} },
        statement: {
          and_statement: {
            statements: [
              {
                byte_match_statement: {
                  field_to_match: { single_header: { name: "Content-Type" } },
                  positional_constraint: "CONTAINS",
                  search_string: "application/json",
                  text_transformations: [
                    { priority: 0, type: "LOWERCASE" }
                  ]
                }
              },
              {
                or_statement: {
                  statements: [
                    {
                      sqli_match_statement: {
                        field_to_match: {
                          json_body: {
                            match_pattern: { all: {} },
                            match_scope: "VALUE"
                          }
                        },
                        text_transformations: [
                          { priority: 0, type: "URL_DECODE" },
                          { priority: 1, type: "HTML_ENTITY_DECODE" }
                        ]
                      }
                    },
                    {
                      xss_match_statement: {
                        field_to_match: {
                          json_body: {
                            match_pattern: { all: {} },
                            match_scope: "VALUE"
                          }
                        },
                        text_transformations: [
                          { priority: 0, type: "URL_DECODE" },
                          { priority: 1, type: "HTML_ENTITY_DECODE" }
                        ]
                      }
                    }
                  ]
                }
              }
            ]
          }
        },
        visibility_config: {
          cloudwatch_metrics_enabled: true,
          metric_name: "JSONPayloadProtection",
          sampled_requests_enabled: true
        },
        challenge_config: {
          immunity_time_property: {
            immunity_time: 1800 # 30 minutes
          }
        }
      }
    ],
    custom_response_bodies: {
      "api_rate_limit" => {
        content: '{"error":"Rate limit exceeded","message":"Too many requests. Please retry after 60 seconds."}',
        content_type: "APPLICATION_JSON"
      }
    },
    visibility_config: {
      cloudwatch_metrics_enabled: true,
      metric_name: "APISecurityWebACL",
      sampled_requests_enabled: true
    }
  })
end
```

### 3. Enterprise Security with Managed Rules

```ruby
template :enterprise_security_stack do
  # Enterprise-grade Web ACL with multiple managed rule groups
  enterprise_waf = aws_wafv2_web_acl(:enterprise_protection, {
    name: "EnterpriseSecurityWebACL",
    scope: "REGIONAL",
    default_action: { allow: {} },
    rules: [
      # Core protection rules
      {
        name: "AWSManagedRulesCommonRuleSet",
        priority: 100,
        action: { captcha: {} },
        statement: {
          managed_rule_group_statement: {
            vendor_name: "AWS",
            name: "AWSManagedRulesCommonRuleSet",
            excluded_rules: [
              { name: "SizeRestrictions_QUERYSTRING" },
              { name: "SizeRestrictions_BODY" }
            ]
          }
        },
        visibility_config: {
          cloudwatch_metrics_enabled: true,
          metric_name: "CommonRuleSet",
          sampled_requests_enabled: true
        }
      },
      
      # Known bad inputs protection
      {
        name: "AWSManagedRulesKnownBadInputsRuleSet",
        priority: 200,
        action: { block: {} },
        statement: {
          managed_rule_group_statement: {
            vendor_name: "AWS",
            name: "AWSManagedRulesKnownBadInputsRuleSet"
          }
        },
        visibility_config: {
          cloudwatch_metrics_enabled: true,
          metric_name: "KnownBadInputs",
          sampled_requests_enabled: true
        }
      },
      
      # SQL database protection
      {
        name: "AWSManagedRulesSQLiRuleSet",
        priority: 300,
        action: { 
          block: {
            custom_response: {
              response_code: 403,
              custom_response_body_key: "sql_injection_blocked"
            }
          }
        },
        statement: {
          managed_rule_group_statement: {
            vendor_name: "AWS",
            name: "AWSManagedRulesSQLiRuleSet",
            excluded_rules: [
              { name: "SQLi_QUERYARGUMENTS" } # May cause false positives
            ]
          }
        },
        visibility_config: {
          cloudwatch_metrics_enabled: true,
          metric_name: "SQLiProtection",
          sampled_requests_enabled: true
        }
      },
      
      # Admin interface protection
      {
        name: "AdminInterfaceProtection",
        priority: 50,
        action: {
          block: {
            custom_response: {
              response_code: 403,
              custom_response_body_key: "admin_blocked"
            }
          }
        },
        statement: {
          and_statement: {
            statements: [
              {
                byte_match_statement: {
                  field_to_match: { uri_path: {} },
                  positional_constraint: "STARTS_WITH",
                  search_string: "/admin",
                  text_transformations: [
                    { priority: 0, type: "LOWERCASE" }
                  ]
                }
              },
              {
                not_statement: {
                  statement: {
                    ip_set_reference_statement: {
                      arn: "${aws_wafv2_ip_set.admin_whitelist.arn}"
                    }
                  }
                }
              }
            ]
          }
        },
        visibility_config: {
          cloudwatch_metrics_enabled: true,
          metric_name: "AdminProtection",
          sampled_requests_enabled: true
        }
      }
    ],
    custom_response_bodies: {
      "sql_injection_blocked" => {
        content: "Security violation detected. Your request has been blocked.",
        content_type: "TEXT_PLAIN"
      },
      "admin_blocked" => {
        content: "Access denied. Administrative access is restricted.",
        content_type: "TEXT_PLAIN"
      }
    },
    visibility_config: {
      cloudwatch_metrics_enabled: true,
      metric_name: "EnterpriseWebACL",
      sampled_requests_enabled: true
    }
  })
end
```

## Advanced Configuration Patterns

### Dynamic Rate Limiting Based on Request Type

```ruby
# Rate limiting with different thresholds for different endpoints
rules = [
  {
    name: "APIEndpointRateLimit",
    priority: 100,
    action: { block: {} },
    statement: {
      and_statement: {
        statements: [
          {
            byte_match_statement: {
              field_to_match: { uri_path: {} },
              positional_constraint: "STARTS_WITH",
              search_string: "/api/",
              text_transformations: [{ priority: 0, type: "LOWERCASE" }]
            }
          },
          {
            rate_based_statement: {
              limit: 5000, # Higher limit for API endpoints
              aggregate_key_type: "IP"
            }
          }
        ]
      }
    },
    visibility_config: {
      cloudwatch_metrics_enabled: true,
      metric_name: "APIRateLimit",
      sampled_requests_enabled: true
    }
  },
  {
    name: "StaticContentRateLimit", 
    priority: 200,
    action: { block: {} },
    statement: {
      and_statement: {
        statements: [
          {
            byte_match_statement: {
              field_to_match: { uri_path: {} },
              positional_constraint: "STARTS_WITH", 
              search_string: "/static/",
              text_transformations: [{ priority: 0, type: "LOWERCASE" }]
            }
          },
          {
            rate_based_statement: {
              limit: 10000, # Higher limit for static content
              aggregate_key_type: "IP"
            }
          }
        ]
      }
    },
    visibility_config: {
      cloudwatch_metrics_enabled: true,
      metric_name: "StaticRateLimit",
      sampled_requests_enabled: true
    }
  }
]
```

### Geographic and Time-Based Access Control

```ruby
# Complex geographic access control with exceptions
geographic_rule = {
  name: "GeographicAccessControl",
  priority: 50,
  action: { 
    block: {
      custom_response: {
        response_code: 403,
        custom_response_body_key: "geo_blocked"
      }
    }
  },
  statement: {
    and_statement: {
      statements: [
        {
          geo_match_statement: {
            country_codes: ["CN", "RU", "KP", "IR"],
            forwarded_ip_config: {
              header_name: "X-Forwarded-For",
              fallback_behavior: "MATCH"
            }
          }
        },
        {
          not_statement: {
            statement: {
              ip_set_reference_statement: {
                arn: "${aws_wafv2_ip_set.trusted_partners.arn}"
              }
            }
          }
        }
      ]
    }
  },
  visibility_config: {
    cloudwatch_metrics_enabled: true,
    metric_name: "GeographicControl",
    sampled_requests_enabled: true
  }
}
```

## Performance Optimization Strategies

### 1. Capacity Unit Management

```ruby
# Monitor and estimate capacity consumption
def estimate_capacity_usage(web_acl_config)
  base_capacity = 1
  rules_capacity = web_acl_config[:rules].sum do |rule|
    statement = rule[:statement]
    
    case
    when statement[:managed_rule_group_statement]
      100 # Managed rules are capacity-heavy
    when statement[:rate_based_statement]
      50  # Rate-based rules moderate capacity
    when statement[:and_statement], statement[:or_statement]
      30  # Logical statements moderate capacity  
    when statement[:geo_match_statement]
      10  # Geography matching lightweight
    when statement[:ip_set_reference_statement]
      10  # IP set references lightweight
    else
      20  # Default capacity for other statements
    end
  end
  
  total_capacity = base_capacity + rules_capacity
  
  if total_capacity > 1500
    raise "Estimated capacity #{total_capacity} exceeds AWS limit of 1500 WCUs"
  end
  
  total_capacity
end
```

### 2. Rule Priority Optimization

```ruby
# Optimize rule ordering for performance
def optimize_rule_priorities(rules)
  # Sort rules by expected match frequency (high frequency = low priority number)
  optimized = rules.sort_by do |rule|
    case rule[:statement].keys.first
    when :rate_based_statement
      10  # Rate limiting should be early
    when :ip_set_reference_statement
      20  # IP allowlists should be early
    when :geo_match_statement  
      30  # Geographic blocking early
    when :managed_rule_group_statement
      40  # Managed rules after basic checks
    else
      50  # Custom rules last
    end
  end
  
  # Reassign priorities
  optimized.each_with_index do |rule, index|
    rule[:priority] = (index + 1) * 100
  end
  
  optimized
end
```

## Security Best Practices Implementation

### 1. Defense in Depth

```ruby
template :layered_security do
  # Layer 1: Edge protection
  edge_waf = aws_wafv2_web_acl(:edge_protection, {
    scope: "CLOUDFRONT",
    # Focus on volumetric attacks and basic filtering
  })
  
  # Layer 2: Application protection  
  app_waf = aws_wafv2_web_acl(:app_protection, {
    scope: "REGIONAL", 
    # Focus on application-layer attacks and business logic
  })
  
  # Layer 3: Database protection (via application rules)
  db_protection_rules = [
    {
      name: "DatabaseAccessPattern",
      priority: 100,
      action: { challenge: {} },
      statement: {
        and_statement: {
          statements: [
            {
              byte_match_statement: {
                field_to_match: { uri_path: {} },
                positional_constraint: "CONTAINS",
                search_string: "/api/database",
                text_transformations: [{ priority: 0, type: "LOWERCASE" }]
              }
            },
            {
              size_constraint_statement: {
                field_to_match: { body: {} },
                comparison_operator: "GT",
                size: 8192, # Large payload detection
                text_transformations: [{ priority: 0, type: "NONE" }]
              }
            }
          ]
        }
      },
      visibility_config: {
        cloudwatch_metrics_enabled: true,
        metric_name: "DatabaseAccessPattern",
        sampled_requests_enabled: true
      }
    }
  ]
end
```

### 2. Incident Response Integration

```ruby
# WAF configuration with incident response capabilities
incident_response_waf = aws_wafv2_web_acl(:incident_response, {
  name: "IncidentResponseWebACL",
  scope: "REGIONAL",
  default_action: { allow: {} },
  rules: [
    {
      name: "IncidentModeBlock",
      priority: 1, # Highest priority
      action: {
        block: {
          custom_response: {
            response_code: 503,
            custom_response_body_key: "maintenance_mode",
            response_headers: [
              { name: "Retry-After", value: "3600" }
            ]
          }
        }
      },
      statement: {
        byte_match_statement: {
          field_to_match: { single_header: { name: "X-Incident-Mode" } },
          positional_constraint: "EXACTLY",
          search_string: "active",
          text_transformations: [{ priority: 0, type: "LOWERCASE" }]
        }
      },
      visibility_config: {
        cloudwatch_metrics_enabled: true,
        metric_name: "IncidentMode",
        sampled_requests_enabled: false # Reduce noise during incidents
      }
    }
  ],
  custom_response_bodies: {
    "maintenance_mode" => {
      content: "Service temporarily unavailable due to maintenance. Please try again later.",
      content_type: "TEXT_PLAIN"
    }
  },
  visibility_config: {
    cloudwatch_metrics_enabled: true,
    metric_name: "IncidentResponseWebACL",
    sampled_requests_enabled: true
  }
})
```

## Monitoring and Alerting Integration

### CloudWatch Dashboard Integration

```ruby
# Create comprehensive monitoring for WAF
template :waf_monitoring do
  web_acl = aws_wafv2_web_acl(:monitored_app, { ... })
  
  # CloudWatch dashboard for WAF metrics
  aws_cloudwatch_dashboard(:waf_dashboard, {
    dashboard_name: "WAF-Security-Dashboard",
    dashboard_body: {
      widgets: [
        {
          type: "metric",
          properties: {
            metrics: [
              ["AWS/WAFV2", "AllowedRequests", "WebACL", web_acl.outputs[:name], "Region", "us-east-1", "Rule", "ALL"],
              [".", "BlockedRequests", ".", ".", ".", ".", ".", "."],
              [".", "CountedRequests", ".", ".", ".", ".", ".", "."]
            ],
            period: 300,
            stat: "Sum",
            region: "us-east-1",
            title: "WAF Request Summary"
          }
        },
        {
          type: "metric", 
          properties: {
            metrics: web_acl.computed[:rules].map do |rule|
              ["AWS/WAFV2", "BlockedRequests", "WebACL", web_acl.outputs[:name], "Rule", rule[:name]]
            end,
            period: 300,
            stat: "Sum",
            region: "us-east-1",
            title: "Blocked Requests by Rule"
          }
        }
      ]
    }.to_json
  })
  
  # Alarms for security events
  aws_cloudwatch_metric_alarm(:waf_high_block_rate, {
    alarm_name: "WAF-HighBlockRate",
    comparison_operator: "GreaterThanThreshold",
    evaluation_periods: 2,
    metric_name: "BlockedRequests",
    namespace: "AWS/WAFV2",
    period: 300,
    statistic: "Sum",
    threshold: 1000,
    alarm_description: "High number of blocked requests detected",
    dimensions: {
      WebACL: web_acl.outputs[:name],
      Region: "us-east-1"
    }
  })
end
```

## Compliance and Audit Features

### 1. PCI DSS Compliance Configuration

```ruby
pci_compliant_waf = aws_wafv2_web_acl(:pci_compliance, {
  name: "PCICompliantWebACL",
  scope: "REGIONAL",
  default_action: { allow: {} },
  rules: [
    # PCI DSS Requirement 6.5.1 - SQL Injection
    {
      name: "PCISQLInjectionProtection",
      priority: 100,
      action: { block: {} },
      statement: {
        managed_rule_group_statement: {
          vendor_name: "AWS",
          name: "AWSManagedRulesSQLiRuleSet"
        }
      },
      visibility_config: {
        cloudwatch_metrics_enabled: true,
        metric_name: "PCISQLIProtection", 
        sampled_requests_enabled: true
      }
    },
    
    # PCI DSS Requirement 6.5.7 - Cross-site scripting
    {
      name: "PCIXSSProtection",
      priority: 200, 
      action: { block: {} },
      statement: {
        xss_match_statement: {
          field_to_match: { all_query_arguments: {} },
          text_transformations: [
            { priority: 0, type: "URL_DECODE" },
            { priority: 1, type: "HTML_ENTITY_DECODE" }
          ]
        }
      },
      visibility_config: {
        cloudwatch_metrics_enabled: true,
        metric_name: "PCIXSSProtection",
        sampled_requests_enabled: true
      }
    }
  ],
  visibility_config: {
    cloudwatch_metrics_enabled: true,
    metric_name: "PCICompliantWebACL",
    sampled_requests_enabled: true
  }
})
```

This technical documentation provides comprehensive coverage of the AWS WAF v2 Web ACL resource implementation, focusing on enterprise-grade security patterns, performance optimization, and compliance requirements. The resource supports the full spectrum of WAF v2 capabilities while maintaining type safety and validation through dry-struct and RBS integration.