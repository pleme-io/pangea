# AWS Systems Manager Patch Baseline Implementation

## Overview

The `aws_ssm_patch_baseline` resource provides type-safe AWS Systems Manager Patch Baseline management with comprehensive operating system support, patch filtering, approval rules, and compliance controls for automated patch management across diverse infrastructure.

## Key Features

### 1. Multi-OS Support with Validation
- **Windows Systems**: Complete support for Windows Server and Desktop with MSRC severity levels
- **Linux Distributions**: Amazon Linux, RHEL family, Debian family, SUSE with distribution-specific filters
- **OS-Specific Validation**: Filter key validation based on target operating system
- **Platform Consistency**: Unified interface across all supported platforms

### 2. Advanced Filtering System
- **Global Filters**: Apply filters across all patches in the baseline
- **Approval Rule Filters**: Fine-grained filtering within approval rules
- **Multi-Criteria Filtering**: Support for classification, severity, priority, and product filters
- **Custom Repository Support**: Integration with private package repositories

### 3. Flexible Approval Rules
- **Time-Based Approval**: Approve patches after specified days
- **Date-Based Approval**: Approve patches until specific date
- **Compliance Levels**: Assign compliance levels (CRITICAL, HIGH, MEDIUM, LOW, INFORMATIONAL)
- **Non-Security Controls**: Separate controls for security vs non-security patches

### 4. Explicit Patch Control
- **Approved Patches**: Explicitly specify approved patches by ID
- **Rejected Patches**: Block specific patches with action control
- **Dependency Handling**: Control rejected patch dependency behavior
- **Override Capability**: Override global rules with explicit patch lists

## Type Safety Implementation

### Core OS Validation
```ruby
def self.new(attributes = {})
  attrs = super(attributes)
  
  # OS-specific filter validation
  case attrs.operating_system
  when "WINDOWS"
    attrs.global_filter.each do |filter|
      windows_keys = ["PATCH_SET", "PRODUCT", "PRODUCT_FAMILY", "CLASSIFICATION", "MSRC_SEVERITY", "PATCH_ID"]
      unless windows_keys.include?(filter[:key])
        raise Dry::Struct::Error, "Invalid filter key '#{filter[:key]}' for Windows"
      end
    end
  when /\A(AMAZON_LINUX|REDHAT_ENTERPRISE_LINUX|CENTOS|ORACLE_LINUX)\z/
    attrs.global_filter.each do |filter|
      linux_keys = ["PATCH_SET", "PRODUCT", "CLASSIFICATION", "SEVERITY", "PATCH_ID", "SECTION", "PRIORITY", "REPOSITORY"]
      unless linux_keys.include?(filter[:key])
        raise Dry::Struct::Error, "Invalid filter key '#{filter[:key]}' for #{attrs.operating_system}"
      end
    end
  end
  
  # ... additional validations
end
```

### Approval Rule Validation
```ruby
attrs.approval_rule.each do |rule|
  # Must specify either approve_after_days or approve_until_date
  if !rule[:approve_after_days] && !rule[:approve_until_date]
    raise Dry::Struct::Error, "Approval rule must specify either approve_after_days or approve_until_date"
  end
  
  if rule[:approve_after_days] && rule[:approve_until_date]
    raise Dry::Struct::Error, "Approval rule cannot specify both approve_after_days and approve_until_date"
  end
  
  # Validate date format
  if rule[:approve_until_date]
    begin
      Date.iso8601(rule[:approve_until_date])
    rescue ArgumentError
      raise Dry::Struct::Error, "approve_until_date must be in ISO 8601 date format"
    end
  end
end
```

### Source Configuration Validation
```ruby
attrs.source.each do |source_config|
  unless source_config[:name].match?(/\A[a-zA-Z0-9_\-\.]{1,50}\z/)
    raise Dry::Struct::Error, "Source name must be 1-50 characters and contain only letters, numbers, hyphens, underscores, and periods"
  end
end
```

## Resource Synthesis

### Basic Configuration
```ruby
resource(:aws_ssm_patch_baseline, name) do
  patch_baseline_name baseline_attrs.name
  operating_system baseline_attrs.operating_system
  description baseline_attrs.description if baseline_attrs.description
  
  # Patch lists
  approved_patches baseline_attrs.approved_patches if baseline_attrs.has_approved_patches?
  rejected_patches baseline_attrs.rejected_patches if baseline_attrs.has_rejected_patches?
  
  # Compliance settings
  approved_patches_compliance_level baseline_attrs.approved_patches_compliance_level
  approved_patches_enable_non_security baseline_attrs.approved_patches_enable_non_security
  rejected_patches_action baseline_attrs.rejected_patches_action
end
```

### Global Filter Synthesis
```ruby
baseline_attrs.global_filter.each do |filter|
  global_filter do
    key filter[:key]
    values filter[:values]
  end
end
```

### Approval Rule Synthesis
```ruby
baseline_attrs.approval_rule.each do |rule|
  approval_rule do
    approve_after_days rule[:approve_after_days] if rule[:approve_after_days]
    approve_until_date rule[:approve_until_date] if rule[:approve_until_date]
    compliance_level rule[:compliance_level] if rule[:compliance_level]
    enable_non_security rule[:enable_non_security] if rule[:enable_non_security]
    
    rule[:patch_filter].each do |filter|
      patch_filter do
        key filter[:key]
        values filter[:values]
      end
    end
  end
end
```

### Source Configuration Synthesis
```ruby
baseline_attrs.source.each do |source_config|
  source do
    source_name source_config[:name]
    products source_config[:products]
    configuration source_config[:configuration]
  end
end
```

## Helper Configurations

### Critical Patches Only Pattern
```ruby
def self.critical_patches_baseline(name, operating_system)
  {
    name: name,
    operating_system: operating_system,
    description: "Critical patches only baseline",
    approved_patches_compliance_level: "CRITICAL",
    approval_rule: [
      {
        approve_after_days: 0,
        compliance_level: "CRITICAL",
        patch_filter: [
          {
            key: operating_system == "WINDOWS" ? "CLASSIFICATION" : "SEVERITY",
            values: operating_system == "WINDOWS" ? ["CriticalUpdates", "SecurityUpdates"] : ["Critical"]
          }
        ]
      }
    ]
  }
end
```

### Production Baseline Pattern
```ruby
def self.production_baseline(name, operating_system, approve_after_days: 14)
  filters = if operating_system == "WINDOWS"
    [{ key: "CLASSIFICATION", values: ["CriticalUpdates", "SecurityUpdates"] }]
  elsif ["UBUNTU", "DEBIAN"].include?(operating_system)
    [{ key: "PRIORITY", values: ["Important"] }]
  else
    [
      { key: "CLASSIFICATION", values: ["Security"] },
      { key: "SEVERITY", values: ["Critical", "Important"] }
    ]
  end

  {
    name: name,
    operating_system: operating_system,
    description: "Production environment baseline - security patches with #{approve_after_days} day delay",
    approved_patches_compliance_level: "HIGH",
    approved_patches_enable_non_security: false,
    rejected_patches_action: "BLOCK",
    approval_rule: [
      {
        approve_after_days: approve_after_days,
        compliance_level: "HIGH",
        enable_non_security: false,
        patch_filter: filters
      }
    ]
  }
end
```

## Computed Properties

### Operating System Detection
```ruby
def is_windows?
  operating_system == "WINDOWS"
end

def is_amazon_linux?
  ["AMAZON_LINUX", "AMAZON_LINUX_2"].include?(operating_system)
end

def is_redhat_family?
  ["REDHAT_ENTERPRISE_LINUX", "CENTOS", "ORACLE_LINUX", "ROCKY_LINUX", "ALMA_LINUX"].include?(operating_system)
end

def is_debian_family?
  ["UBUNTU", "DEBIAN"].include?(operating_system)
end
```

### Configuration Analysis
```ruby
def compliance_level_priority
  levels = {
    "CRITICAL" => 5,
    "HIGH" => 4,
    "MEDIUM" => 3,
    "LOW" => 2,
    "INFORMATIONAL" => 1,
    "UNSPECIFIED" => 0
  }
  levels[approved_patches_compliance_level] || 0
end

def filter_summary
  return {} unless has_global_filters?
  
  filters = {}
  global_filter.each do |filter|
    filters[filter[:key]] = filter[:values]
  end
  filters
end

def approval_rule_summary
  return [] unless has_approval_rules?
  
  approval_rule.map do |rule|
    summary = {
      compliance_level: rule[:compliance_level] || "UNSPECIFIED",
      enable_non_security: rule[:enable_non_security] || false
    }
    
    if rule[:approve_after_days]
      summary[:approval_method] = "after_#{rule[:approve_after_days]}_days"
    elsif rule[:approve_until_date]
      summary[:approval_method] = "until_#{rule[:approve_until_date]}"
    end
    
    summary[:filter_count] = rule[:patch_filter].count
    summary
  end
end
```

### Patch Management Analysis
```ruby
def total_patch_count
  approved_patches.count + rejected_patches.count
end

def blocks_rejected_patches?
  rejected_patches_action == "BLOCK"
end

def allows_rejected_as_dependency?
  rejected_patches_action == "ALLOW_AS_DEPENDENCY"
end
```

## Integration Patterns

### Multi-Environment Patch Strategy
```ruby
# Define patch baselines for different environments
environments = {
  development: {
    approval_delay: 0,
    compliance: "LOW",
    non_security: true,
    description: "Development - immediate patching"
  },
  staging: {
    approval_delay: 7,
    compliance: "MEDIUM",
    non_security: true,
    description: "Staging - 1 week delay"
  },
  production: {
    approval_delay: 21,
    compliance: "HIGH", 
    non_security: false,
    description: "Production - security only, 3 week delay"
  }
}

# Create baselines for each OS and environment combination
operating_systems = ["WINDOWS", "AMAZON_LINUX_2", "UBUNTU"]

operating_systems.each do |os|
  environments.each do |env_name, config|
    baseline_name = "#{env_name.to_s.capitalize}#{os.gsub('_', '')}Baseline"
    
    aws_ssm_patch_baseline(:"#{env_name}_#{os.downcase}_baseline", {
      name: baseline_name,
      operating_system: os,
      description: "#{config[:description]} for #{os}",
      approved_patches_compliance_level: config[:compliance],
      approved_patches_enable_non_security: config[:non_security],
      
      approval_rule: [
        {
          approve_after_days: config[:approval_delay],
          compliance_level: config[:compliance],
          enable_non_security: config[:non_security],
          patch_filter: get_os_appropriate_filters(os, env_name)
        }
      ],
      
      tags: {
        Environment: env_name.to_s,
        OperatingSystem: os.gsub('_', ''),
        PatchStrategy: "Automated"
      }
    })
  end
end
```

### Maintenance Window Integration
```ruby
# Create patch baseline
security_baseline = aws_ssm_patch_baseline(:security_patches, {
  name: "SecurityPatchBaseline",
  operating_system: "AMAZON_LINUX_2",
  description: "Security patches for production systems",
  approved_patches_compliance_level: "HIGH",
  
  approval_rule: [
    {
      approve_after_days: 14,
      compliance_level: "HIGH",
      patch_filter: [
        {
          key: "CLASSIFICATION",
          values: ["Security"]
        },
        {
          key: "SEVERITY",
          values: ["Critical", "Important"]
        }
      ]
    }
  ]
})

# Create maintenance window for patching
patch_window = aws_ssm_maintenance_window(:weekly_patching, {
  name: "WeeklyPatchWindow",
  schedule: "cron(0 2 ? * SUN *)",  # Sundays at 2 AM
  duration: 6,
  cutoff: 1,
  description: "Weekly patching maintenance window"
})

# Baselines would be used with maintenance window tasks (separate resources)
```

### Complex Approval Rules
```ruby
# Multi-tier approval system
aws_ssm_patch_baseline(:complex_approval_baseline, {
  name: "ComplexApprovalBaseline",
  operating_system: "WINDOWS",
  description: "Multi-tier patch approval system",
  
  # Immediate approval for critical security patches
  approval_rule: [
    {
      approve_after_days: 0,
      compliance_level: "CRITICAL",
      patch_filter: [
        {
          key: "CLASSIFICATION",
          values: ["SecurityUpdates"]
        },
        {
          key: "MSRC_SEVERITY",
          values: ["Critical"]
        }
      ]
    },
    
    # 7-day approval for important patches
    {
      approve_after_days: 7,
      compliance_level: "HIGH",
      patch_filter: [
        {
          key: "CLASSIFICATION",
          values: ["SecurityUpdates", "CriticalUpdates"]
        },
        {
          key: "MSRC_SEVERITY",
          values: ["Important"]
        }
      ]
    },
    
    # 30-day approval for all other patches
    {
      approve_after_days: 30,
      compliance_level: "MEDIUM",
      enable_non_security: true,
      patch_filter: [
        {
          key: "PATCH_SET",
          values: ["OS"]
        }
      ]
    }
  ],
  
  # Block known problematic patches
  rejected_patches: [
    "KB4012598",  # Known to cause issues
    "KB4019472"   # Compatibility problems
  ],
  rejected_patches_action: "BLOCK"
})
```

## Error Handling

### Operating System Validation
- **Filter Key Validation**: Ensures filter keys are valid for target OS
- **OS-Specific Constraints**: Enforces OS-appropriate filter values
- **Cross-OS Compatibility**: Prevents invalid configurations across platforms

### Approval Rule Validation
- **Mutual Exclusivity**: Prevents conflicting approval methods
- **Date Format Validation**: Ensures proper ISO 8601 date format
- **Rule Completeness**: Validates required rule components

### Configuration Consistency
- **Source Name Format**: Validates repository source naming
- **Patch ID Format**: Basic patch identifier format checking
- **Description Limits**: Enforces description length constraints

## Output Reference Structure

```ruby
outputs: {
  id: "${aws_ssm_patch_baseline.#{name}.id}",
  name: "${aws_ssm_patch_baseline.#{name}.name}",
  arn: "${aws_ssm_patch_baseline.#{name}.arn}",
  created_date: "${aws_ssm_patch_baseline.#{name}.created_date}",
  modified_date: "${aws_ssm_patch_baseline.#{name}.modified_date}",
  description: "${aws_ssm_patch_baseline.#{name}.description}",
  operating_system: "${aws_ssm_patch_baseline.#{name}.operating_system}",
  approved_patches: "${aws_ssm_patch_baseline.#{name}.approved_patches}",
  rejected_patches: "${aws_ssm_patch_baseline.#{name}.rejected_patches}",
  approved_patches_compliance_level: "${aws_ssm_patch_baseline.#{name}.approved_patches_compliance_level}",
  tags_all: "${aws_ssm_patch_baseline.#{name}.tags_all}"
}
```

## Best Practices

### Security
1. **Principle of Least Privilege**: Only approve necessary patches
2. **Security-First**: Prioritize security patches over feature updates
3. **Rejection Strategy**: Use BLOCK for known problematic patches
4. **Compliance Alignment**: Set appropriate compliance levels

### Operational Excellence
1. **Environment Stratification**: Different approval delays per environment
2. **Gradual Rollout**: Test in dev/staging before production
3. **Maintenance Windows**: Coordinate with maintenance window scheduling
4. **Documentation**: Clear descriptions for all baselines

### Platform Management
1. **OS-Specific Baselines**: Create dedicated baselines per operating system
2. **Filter Optimization**: Use appropriate filters for each platform
3. **Repository Management**: Leverage custom repositories for enterprise environments
4. **Version Control**: Track baseline changes through infrastructure as code