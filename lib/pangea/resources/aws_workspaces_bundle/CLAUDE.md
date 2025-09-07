# AWS WorkSpaces Bundle - Implementation Notes

## Resource Overview

The `aws_workspaces_bundle` resource creates custom Amazon WorkSpaces bundles that define the combination of compute resources, storage, and software image used when launching WorkSpaces. Custom bundles allow organizations to standardize desktop configurations.

## Architectural Considerations

### Bundle Components
1. **Compute Type**: Defines CPU, memory, and GPU resources
2. **Storage Configuration**: Root and user volume specifications
3. **Image**: Base AMI with pre-installed software and configurations
4. **Metadata**: Name, description, and tags

### Bundle Hierarchy
```
AWS-Provided Bundles (wsb-xxxxxxxxx)
    ↓
Custom Images (wsi-xxxxxxxxx) 
    ↓
Custom Bundles (wsb-xxxxxxxxx)
    ↓
WorkSpace Instances
```

## Implementation Details

### Image ID Validation

```ruby
attribute :image_id, Resources::Types::String.constrained(
  format: /\Awsi-[a-z0-9]{9}\z/
)
```

Ensures only valid WorkSpaces image IDs are accepted.

### Compute Type Specifications

The implementation provides detailed hardware specifications:

```ruby
def vcpus
  case name
  when 'VALUE' then 1
  when 'STANDARD' then 2
  when 'PERFORMANCE' then 2
  when 'POWER' then 4
  when 'POWERPRO' then 8
  when 'GRAPHICS' then 8
  when 'GRAPHICSPRO' then 16
  end
end
```

### Storage Validation

Minimum storage requirements are enforced based on compute type:

```ruby
min_storage = case compute_name
             when 'VALUE' then 10
             when 'STANDARD' then 10
             when 'PERFORMANCE' then 10
             when 'POWER' then 100
             when 'POWERPRO' then 100
             when 'GRAPHICS' then 100
             when 'GRAPHICSPRO' then 100
             else 10
             end
```

### Cost Estimation

```ruby
def estimated_monthly_cost
  base = case compute_type.name
        when 'VALUE' then 21
        when 'STANDARD' then 25
        # ... other types
        end
  
  storage_cost = total_storage_gb * 0.10
  base + storage_cost
end
```

## Advanced Usage Patterns

### 1. Department-Specific Bundle Creation
```ruby
def create_department_bundle(department, base_image_id)
  config = case department
           when :engineering
             {
               bundle_name: "Engineering-Bundle-v#{Time.now.strftime('%Y%m')}",
               bundle_description: "Engineering tools and IDEs",
               compute_type: { name: "POWER" },
               user_storage: { capacity: "200" },
               root_storage: { capacity: "150" }
             }
           when :design
             {
               bundle_name: "Creative-Bundle-v#{Time.now.strftime('%Y%m')}",
               bundle_description: "Creative suite and design tools",
               compute_type: { name: "GRAPHICS" },
               user_storage: { capacity: "500" },
               root_storage: { capacity: "200" }
             }
           when :finance
             {
               bundle_name: "Finance-Bundle-v#{Time.now.strftime('%Y%m')}",
               bundle_description: "Financial analysis tools",
               compute_type: { name: "PERFORMANCE" },
               user_storage: { capacity: "100" },
               root_storage: { capacity: "100" }
             }
           else
             {
               bundle_name: "Standard-Bundle-v#{Time.now.strftime('%Y%m')}",
               bundle_description: "Standard office applications",
               compute_type: { name: "STANDARD" },
               user_storage: { capacity: "50" }
             }
           end
  
  aws_workspaces_bundle(:"#{department}_bundle", config.merge(
    image_id: base_image_id,
    tags: {
      Department: department.to_s.capitalize,
      CreatedDate: Time.now.strftime('%Y-%m-%d'),
      ImageVersion: "1.0"
    }
  ))
end
```

### 2. Tiered Bundle Strategy
```ruby
def create_tiered_bundles(base_image_id)
  tiers = {
    basic: {
      bundle_name: "Basic-Tier-Bundle",
      bundle_description: "Entry-level desktop for basic tasks",
      compute_type: { name: "VALUE" },
      user_storage: { capacity: "10" }
    },
    standard: {
      bundle_name: "Standard-Tier-Bundle",
      bundle_description: "Standard desktop for office workers",
      compute_type: { name: "STANDARD" },
      user_storage: { capacity: "50" },
      root_storage: { capacity: "80" }
    },
    professional: {
      bundle_name: "Professional-Tier-Bundle",
      bundle_description: "Professional desktop for power users",
      compute_type: { name: "PERFORMANCE" },
      user_storage: { capacity: "100" },
      root_storage: { capacity: "100" }
    },
    developer: {
      bundle_name: "Developer-Tier-Bundle",
      bundle_description: "High-performance desktop for developers",
      compute_type: { name: "POWER" },
      user_storage: { capacity: "200" },
      root_storage: { capacity: "150" }
    },
    creative: {
      bundle_name: "Creative-Tier-Bundle",
      bundle_description: "Graphics-enabled desktop for designers",
      compute_type: { name: "GRAPHICS" },
      user_storage: { capacity: "500" },
      root_storage: { capacity: "200" }
    }
  }
  
  tiers.map do |tier_name, config|
    aws_workspaces_bundle(:"#{tier_name}_tier", config.merge(
      image_id: base_image_id,
      tags: {
        Tier: tier_name.to_s.capitalize,
        MonthlyEstimate: calculate_tier_cost(config)
      }
    ))
  end
end
```

### 3. Compliance-Focused Bundles
```ruby
def create_compliance_bundle(compliance_type, secure_image_id)
  base_config = {
    image_id: secure_image_id,
    tags: {
      Compliance: compliance_type.to_s.upcase,
      SecurityLevel: "High",
      LastAudit: Time.now.strftime('%Y-%m-%d')
    }
  }
  
  case compliance_type
  when :hipaa
    aws_workspaces_bundle(:hipaa_compliant, base_config.merge(
      bundle_name: "HIPAA-Compliant-Bundle",
      bundle_description: "HIPAA-compliant desktop with encryption and security tools",
      compute_type: { name: "PERFORMANCE" },
      user_storage: { capacity: "100" },
      root_storage: { capacity: "150" }  # Extra space for security software
    ))
  when :pci_dss
    aws_workspaces_bundle(:pci_compliant, base_config.merge(
      bundle_name: "PCI-DSS-Compliant-Bundle",
      bundle_description: "PCI-DSS compliant desktop for payment processing",
      compute_type: { name: "STANDARD" },
      user_storage: { capacity: "50" },
      root_storage: { capacity: "120" }  # Space for compliance tools
    ))
  when :fedramp
    aws_workspaces_bundle(:fedramp_compliant, base_config.merge(
      bundle_name: "FedRAMP-Compliant-Bundle",
      bundle_description: "FedRAMP-compliant desktop for government use",
      compute_type: { name: "POWER" },
      user_storage: { capacity: "200" },
      root_storage: { capacity: "200" }  # Extensive logging and monitoring
    ))
  end
end
```

## Image Management Strategies

### Image Versioning Pattern
```ruby
def create_versioned_bundle(image_version, image_id)
  version_date = Time.now.strftime('%Y%m%d')
  
  aws_workspaces_bundle(:versioned_bundle, {
    bundle_name: "Corporate-Desktop-v#{image_version}-#{version_date}",
    bundle_description: "Corporate standard desktop image version #{image_version}",
    image_id: image_id,
    compute_type: { name: "STANDARD" },
    user_storage: { capacity: "50" },
    tags: {
      ImageVersion: image_version,
      ReleaseDate: version_date,
      PreviousVersion: get_previous_version(image_version),
      ChangeLog: "See confluence/desktop-images/v#{image_version}"
    }
  })
end
```

### Multi-Region Bundle Deployment
```ruby
def deploy_bundle_multi_region(bundle_config, image_mappings)
  regions = image_mappings.keys
  
  regions.map do |region|
    # Each region needs its own image ID
    regional_config = bundle_config.merge(
      image_id: image_mappings[region],
      tags: bundle_config[:tags].merge(
        Region: region,
        GlobalBundleId: generate_global_bundle_id()
      )
    )
    
    # Deploy to specific region
    aws_workspaces_bundle(:"bundle_#{region}", regional_config)
  end
end
```

## Performance Optimization

### GPU-Optimized Bundles
```ruby
def create_gpu_optimized_bundle(workload_type, gpu_image_id)
  case workload_type
  when :cad_2d
    aws_workspaces_bundle(:cad_2d_bundle, {
      bundle_name: "CAD-2D-Optimized",
      bundle_description: "Optimized for 2D CAD applications",
      image_id: gpu_image_id,
      compute_type: { name: "GRAPHICS" },
      user_storage: { capacity: "200" },
      root_storage: { capacity: "150" }
    })
  when :cad_3d
    aws_workspaces_bundle(:cad_3d_bundle, {
      bundle_name: "CAD-3D-Optimized",
      bundle_description: "Optimized for 3D CAD and rendering",
      image_id: gpu_image_id,
      compute_type: { name: "GRAPHICSPRO" },
      user_storage: { capacity: "500" },
      root_storage: { capacity: "200" }
    })
  when :video_editing
    aws_workspaces_bundle(:video_bundle, {
      bundle_name: "Video-Editing-Optimized",
      bundle_description: "Optimized for video editing and production",
      image_id: gpu_image_id,
      compute_type: { name: "GRAPHICSPRO" },
      user_storage: { capacity: "1000" },
      root_storage: { capacity: "250" }
    })
  end
end
```

## Bundle Lifecycle Management

### States and Transitions
```
CREATING → AVAILABLE → IN_USE
            ↓
         ERROR → RETRY → AVAILABLE
```

### Bundle Retirement Process
```ruby
def retire_bundle(old_bundle, new_bundle)
  # 1. Create new bundle
  # 2. Test with pilot users
  # 3. Migrate users gradually
  # 4. Mark old bundle for deletion
  # 5. Delete after all migrations complete
  
  # Tag old bundle as deprecated
  update_bundle_tags(old_bundle.id, {
    Status: "DEPRECATED",
    ReplacedBy: new_bundle.bundle_id,
    DeprecationDate: Time.now.strftime('%Y-%m-%d'),
    RemovalDate: (Time.now + 90.days).strftime('%Y-%m-%d')
  })
end
```

## Best Practices

### 1. Image Preparation
- Start with minimal base image
- Install only required software
- Remove temporary files and logs
- Run Windows/Linux optimization scripts
- Disable unnecessary services
- Configure security settings

### 2. Bundle Naming Conventions
```ruby
# Format: [Purpose]-[ComputeType]-[Version]-[Date]
"Engineering-Power-v2-20240115"
"Finance-Standard-v1-20240115"
"Creative-Graphics-v3-20240115"
```

### 3. Storage Sizing
- Add 20-30% buffer for growth
- Consider application cache requirements
- Account for user profile data
- Plan for Windows updates/patches

### 4. Cost Management
- Regular utilization reviews
- Right-size compute types
- Implement bundle lifecycle policies
- Track bundle-to-user mappings

## Monitoring and Metrics

### Key Metrics to Track
- Bundle creation success rate
- Bundle utilization by type
- Storage usage patterns
- Performance metrics by compute type
- Cost per bundle type

### CloudWatch Integration
```ruby
# Monitor bundle usage
custom_metric(:bundle_usage, {
  namespace: "WorkSpaces/Bundles",
  metric_name: "BundleUtilization",
  dimensions: {
    BundleId: bundle.bundle_id,
    ComputeType: bundle.compute_type_name
  }
})
```

## Troubleshooting

### Common Issues

1. **Bundle Creation Fails**
   - Verify image exists and is available
   - Check image is in AVAILABLE state
   - Ensure proper permissions
   - Validate storage configurations

2. **Performance Issues**
   - Review compute type selection
   - Check storage IOPS limits
   - Monitor CPU/memory usage
   - Consider upgrading bundle

3. **Image Compatibility**
   - Ensure image OS matches requirements
   - Verify software licensing
   - Check driver compatibility
   - Test GPU functionality for graphics bundles