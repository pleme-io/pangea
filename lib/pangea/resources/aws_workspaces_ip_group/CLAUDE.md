# AWS WorkSpaces IP Group - Implementation Notes

## Resource Overview

The `aws_workspaces_ip_group` resource manages IP-based access control for Amazon WorkSpaces. IP groups define which source IP addresses can connect to WorkSpaces, providing network-layer security for virtual desktop access.

## Architectural Considerations

### IP Group Model
- **Whitelist approach**: Only specified IPs can access
- **Directory association**: Groups are linked to WorkSpaces directories
- **Inheritance model**: All WorkSpaces in a directory inherit IP restrictions
- **Multiple groups**: Directories can have multiple IP groups (additive)

### Security Layers
```
Internet → IP Group Filter → Directory → WorkSpace → User Authentication
```

## Implementation Details

### Group Name Validation

```ruby
attribute :group_name, Resources::Types::String.constrained(
  min_size: 1,
  max_size: 100,
  format: /\A[a-zA-Z0-9\s._-]+\z/
)
```

Ensures names follow AWS naming conventions.

### CIDR Range Validation

```ruby
# WorkSpaces supports /16 to /32 for IP groups
if prefix < 16 || prefix > 32
  raise Dry::Struct::Error, "CIDR prefix must be between /16 and /32 for WorkSpaces IP groups"
end
```

### Duplicate Detection

```ruby
ip_rules = attrs[:user_rules].map { |rule| rule[:ip_rule] || rule['ip_rule'] }
if ip_rules.uniq.length != ip_rules.length
  raise Dry::Struct::Error, "Duplicate IP rules are not allowed"
end
```

### Private IP Detection

```ruby
def is_private_ip?(cidr)
  ip = cidr.split('/')[0]
  octets = ip.split('.').map(&:to_i)
  
  # Check for private IP ranges
  return true if octets[0] == 10  # 10.0.0.0/8
  return true if octets[0] == 172 && (16..31).include?(octets[1])  # 172.16.0.0/12
  return true if octets[0] == 192 && octets[1] == 168  # 192.168.0.0/16
  return true if octets[0] == 127  # 127.0.0.0/8 (loopback)
  
  false
end
```

## Advanced Usage Patterns

### 1. Dynamic IP Group Management
```ruby
def create_dynamic_ip_group(name, ip_sources)
  # Fetch current IPs from external sources
  current_ips = ip_sources.flat_map do |source|
    case source[:type]
    when :dns
      resolve_dns_to_ips(source[:hostname])
    when :api
      fetch_ips_from_api(source[:endpoint])
    when :static
      source[:ips]
    end
  end
  
  # Create rules from current IPs
  rules = current_ips.map.with_index do |ip, index|
    {
      ip_rule: "#{ip}/32",
      rule_desc: "Dynamic IP #{index + 1} from #{source[:name]}"
    }
  end.take(10)  # Maximum 10 rules
  
  aws_workspaces_ip_group(name, {
    group_name: "Dynamic-#{name.to_s.capitalize}",
    group_desc: "Dynamically managed IP group",
    user_rules: rules,
    tags: {
      Type: "Dynamic",
      LastUpdated: Time.now.iso8601
    }
  })
end
```

### 2. Compliance-Based IP Groups
```ruby
def create_compliance_ip_group(compliance_type)
  case compliance_type
  when :sox
    # SOX compliance - restrict to audited networks
    aws_workspaces_ip_group(:sox_compliant, {
      group_name: "SOX-Compliant-Networks",
      group_desc: "Networks approved for SOX compliance",
      user_rules: [
        {
          ip_rule: "10.0.0.0/16",
          rule_desc: "Corporate datacenter (audited)"
        },
        {
          ip_rule: "10.1.0.0/16",
          rule_desc: "DR datacenter (audited)"
        }
      ],
      tags: {
        Compliance: "SOX",
        AuditDate: "2024-01-15",
        NextReview: "2024-07-15"
      }
    })
  when :pci
    # PCI compliance - very restrictive
    aws_workspaces_ip_group(:pci_compliant, {
      group_name: "PCI-DSS-Networks",
      group_desc: "PCI-DSS compliant network access",
      user_rules: [
        {
          ip_rule: "10.100.50.0/28",
          rule_desc: "PCI secured subnet only"
        }
      ],
      tags: {
        Compliance: "PCI-DSS",
        Scope: "Cardholder-Data-Environment"
      }
    })
  when :hipaa
    # HIPAA compliance - healthcare networks
    aws_workspaces_ip_group(:hipaa_compliant, {
      group_name: "HIPAA-Authorized-Networks",
      group_desc: "HIPAA-compliant access points",
      user_rules: [
        {
          ip_rule: "172.20.0.0/20",
          rule_desc: "Hospital network (encrypted)"
        },
        {
          ip_rule: "172.20.16.0/24",
          rule_desc: "Medical office VPN"
        }
      ],
      tags: {
        Compliance: "HIPAA",
        EncryptionRequired: "true"
      }
    })
  end
end
```

### 3. Time-Based Access Patterns
```ruby
def create_contractor_ip_group(contractor_name, contract_end_date)
  aws_workspaces_ip_group(:"contractor_#{contractor_name}", {
    group_name: "Contractor-#{contractor_name}",
    group_desc: "Temporary access for #{contractor_name}",
    user_rules: [
      {
        ip_rule: "198.51.100.50/32",
        rule_desc: "#{contractor_name} home office"
      },
      {
        ip_rule: "203.0.113.100/32",
        rule_desc: "#{contractor_name} alternate location"
      }
    ],
    tags: {
      Type: "Contractor",
      ContractorName: contractor_name,
      ExpirationDate: contract_end_date,
      AutoRemove: "true"
    }
  })
end
```

### 4. Geographic Distribution Pattern
```ruby
def create_geographic_ip_groups(regions)
  regions.map do |region, config|
    aws_workspaces_ip_group(:"#{region}_access", {
      group_name: "#{region.to_s.upcase}-Regional-Access",
      group_desc: "Access from #{config[:description]}",
      user_rules: config[:networks].map do |network|
        {
          ip_rule: network[:cidr],
          rule_desc: "#{network[:city]} - #{network[:type]}"
        }
      end,
      tags: {
        Region: region.to_s,
        Timezone: config[:timezone],
        SupportHours: config[:support_hours]
      }
    })
  end
end

# Usage
geographic_groups = create_geographic_ip_groups({
  americas: {
    description: "North and South America",
    timezone: "America/New_York",
    support_hours: "9AM-5PM EST",
    networks: [
      { cidr: "54.0.0.0/16", city: "New York", type: "Office" },
      { cidr: "52.0.0.0/16", city: "San Francisco", type: "Office" },
      { cidr: "177.0.0.0/16", city: "São Paulo", type: "Office" }
    ]
  },
  emea: {
    description: "Europe, Middle East, and Africa",
    timezone: "Europe/London",
    support_hours: "9AM-5PM GMT",
    networks: [
      { cidr: "185.0.0.0/16", city: "London", type: "Office" },
      { cidr: "195.0.0.0/16", city: "Frankfurt", type: "DC" },
      { cidr: "196.0.0.0/16", city: "Dubai", type: "Office" }
    ]
  }
})
```

## Integration Patterns

### With Multiple Directories
```ruby
# Create shared IP groups
corporate_ips = aws_workspaces_ip_group(:corporate, {
  group_name: "Corporate-Wide-Access",
  user_rules: [
    { ip_rule: "10.0.0.0/8", rule_desc: "Internal networks" }
  ]
})

external_ips = aws_workspaces_ip_group(:external, {
  group_name: "External-Access",
  user_rules: [
    { ip_rule: "0.0.0.0/0", rule_desc: "Any location" }
  ]
})

# Apply to different directories
aws_workspaces_directory(:internal_directory, {
  directory_id: internal_ad.id,
  ip_group_ids: [corporate_ips.id]  # Internal only
})

aws_workspaces_directory(:contractor_directory, {
  directory_id: contractor_ad.id,
  ip_group_ids: [corporate_ips.id, external_ips.id]  # Both
})
```

### With VPN Integration
```ruby
# VPN endpoint IPs
vpn_endpoints = get_vpn_endpoint_ips()

vpn_ip_group = aws_workspaces_ip_group(:vpn_access, {
  group_name: "VPN-Exit-Points",
  group_desc: "Corporate VPN endpoints",
  user_rules: vpn_endpoints.map do |endpoint|
    {
      ip_rule: "#{endpoint[:ip]}/32",
      rule_desc: "VPN #{endpoint[:location]}"
    }
  end
})
```

## Monitoring and Alerting

### Access Pattern Analysis
```ruby
def analyze_ip_group_usage(ip_group)
  # Analyze which IPs are actually being used
  # This would integrate with CloudWatch Logs
  {
    total_rules: ip_group.total_rules,
    active_rules: count_active_rules(ip_group),
    unused_rules: identify_unused_rules(ip_group),
    access_frequency: calculate_access_frequency(ip_group),
    recommendations: generate_optimization_recommendations(ip_group)
  }
end
```

### Security Monitoring
```ruby
def monitor_ip_group_changes(ip_group)
  # Set up CloudWatch alarms for IP group modifications
  cloudwatch_alarm(:ip_group_modified, {
    alarm_name: "WorkSpaces-IP-Group-#{ip_group.group_name}-Modified",
    alarm_description: "Alert when IP group is modified",
    metric_name: "IPGroupModifications",
    namespace: "WorkSpaces/Security",
    statistic: "Sum",
    period: 300,
    evaluation_periods: 1,
    threshold: 1,
    comparison_operator: "GreaterThanOrEqualToThreshold"
  })
end
```

## Best Practices

### 1. IP Group Organization
- Group IPs by purpose (office, VPN, partner, emergency)
- Use descriptive names and descriptions
- Tag for lifecycle management
- Document IP ownership

### 2. Security Hardening
```ruby
# Never do this in production
bad_practice = {
  user_rules: [
    { ip_rule: "0.0.0.0/0", rule_desc: "Allow all" }
  ]
}

# Do this instead
good_practice = {
  user_rules: [
    { ip_rule: "203.0.113.0/24", rule_desc: "Office network" },
    { ip_rule: "198.51.100.0/24", rule_desc: "VPN range" }
  ]
}
```

### 3. Change Management
- Version control IP group definitions
- Require approval for changes
- Test changes in non-production first
- Document business justification

### 4. Regular Audits
- Review IP groups quarterly
- Remove unused IP ranges
- Verify IP ownership
- Update documentation

## Troubleshooting

### Common Issues

1. **Access Denied Despite Valid IP**
   - Check if IP group is associated with directory
   - Verify CIDR range includes user's IP
   - Confirm no typos in IP configuration
   - Check for multiple IP groups (all must allow)

2. **Cannot Create IP Group**
   - Verify unique group name
   - Check IP rule limit (max 10)
   - Validate CIDR notation
   - Ensure no duplicate rules

3. **IP Group Not Taking Effect**
   - Association with directory may be pending
   - WorkSpaces may need restart
   - Check CloudTrail for errors

### Debug Checklist
1. Verify user's source IP: `curl ifconfig.me`
2. Check IP group association in console
3. Review CloudTrail logs for denials
4. Test with broader CIDR range
5. Verify no conflicting security groups

## Performance Considerations

- IP group evaluation is fast (milliseconds)
- No performance impact on WorkSpace
- Changes take effect immediately
- No caching of IP rules

## Compliance and Audit

### Audit Trail
```ruby
# Tag for audit compliance
aws_workspaces_ip_group(:audited_access, {
  group_name: "Audited-Network-Access",
  user_rules: [...],
  tags: {
    LastAudit: Time.now.iso8601,
    AuditorName: "Security Team",
    NextAuditDate: (Time.now + 90.days).iso8601,
    ComplianceFramework: "ISO27001"
  }
})
```

### Reporting
- Export IP group configurations regularly
- Track changes via CloudTrail
- Generate access reports
- Monitor for anomalies