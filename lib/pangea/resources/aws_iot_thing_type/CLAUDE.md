# AWS IoT Thing Type Resource - Claude Documentation

## Resource Overview

The `aws_iot_thing_type` resource manages AWS IoT Thing Types, which serve as templates for organizing and categorizing IoT devices with similar characteristics. This resource provides comprehensive type safety, fleet indexing optimization, and intelligent recommendations for IoT device management.

## Type-Safe Implementation

### Core Type Structure

```ruby
class IotThingTypeAttributes < Dry::Struct
  attribute :thing_type_name, Types::IotThingTypeName                      # Required: PascalCase name
  attribute? :thing_type_properties, Types::IotThingTypeProperties.optional # Description + searchable attrs
  attribute :tags, Types::AwsTags.default({})                             # Resource tags
end

# Thing Type Properties Schema
Types::IotThingTypeProperties = Hash.schema(
  description?: String.constrained(max_size: 2028).optional,              # Descriptive text
  searchable_attributes?: Array.of(                                        # Fleet indexing attributes
    String.constrained(format: /\A[a-zA-Z0-9_-]{1,128}\z/)
  ).constrained(max_size: 3).optional                                     # Max 3 searchable attributes
)
```

### Advanced Validation Features

```ruby
def self.new(attributes = {})
  attrs = super(attributes)
  
  # Validate searchable attributes limit
  if attrs.thing_type_properties&.dig(:searchable_attributes)
    searchable = attrs.thing_type_properties[:searchable_attributes]
    if searchable.length > 3
      raise Dry::Struct::Error, "Thing type cannot have more than 3 searchable attributes"
    end
  end
  
  attrs
end
```

### Intelligent Computed Properties

The resource provides comprehensive analysis and recommendations:

```ruby
def recommended_thing_attributes              # Suggests attributes for things of this type
def security_recommendations               # Security best practices analysis
def example_thing_configuration            # Generates example thing configuration
def cost_impact_analysis                   # Analyzes cost implications
def compatibility_check(other_type_name)   # Checks compatibility with other types
def fleet_indexing_optimized?              # Optimization validation
```

## Fleet Management Patterns

### 1. Industrial Equipment Classification

```ruby
template :industrial_equipment_types do
  # Manufacturing equipment
  cnc_machine_type = aws_iot_thing_type(:cnc_machine, {
    thing_type_name: "CNC_Machine",
    thing_type_properties: {
      description: "Computer Numerical Control machines for precision manufacturing",
      searchable_attributes: ["line_number", "machine_type", "manufacturer"]
    },
    tags: {
      category: "manufacturing",
      criticality: "high",
      maintenance_tier: "critical"
    }
  })

  # Quality control equipment
  qc_scanner_type = aws_iot_thing_type(:quality_scanner, {
    thing_type_name: "QualityScanner",
    thing_type_properties: {
      description: "Automated optical inspection systems for quality control",
      searchable_attributes: ["scanner_type", "resolution", "line_number"]
    },
    tags: {
      category: "quality_control",
      automation_level: "fully_automated"
    }
  })
  
  # Output example configurations for each type
  output :cnc_example_config do
    value cnc_machine_type.example_thing_configuration
    description "Example configuration for CNC machines"
  end
end
```

### 2. Smart Building Device Taxonomy

```ruby
template :smart_building_taxonomy do
  # HVAC Systems
  hvac_type = aws_iot_thing_type(:hvac_controller, {
    thing_type_name: "HVAC_Controller",
    thing_type_properties: {
      description: "Intelligent HVAC systems with zone control and energy optimization",
      searchable_attributes: ["building_zone", "system_type", "energy_rating"]
    },
    tags: {
      building_system: "hvac",
      energy_management: "enabled",
      automation: "smart"
    }
  })

  # Lighting Systems  
  lighting_type = aws_iot_thing_type(:lighting_controller, {
    thing_type_name: "LightingController",
    thing_type_properties: {
      description: "Smart lighting systems with occupancy sensing and daylight harvesting",
      searchable_attributes: ["control_zones", "sensor_types", "building_floor"]
    },
    tags: {
      building_system: "lighting",
      energy_management: "enabled",
      occupancy_aware: "true"
    }
  })

  # Security Access Control
  access_control_type = aws_iot_thing_type(:access_controller, {
    thing_type_name: "AccessController",
    thing_type_properties: {
      description: "Physical access control systems with multi-factor authentication",
      searchable_attributes: ["access_level", "authentication_methods", "building_zone"]
    },
    tags: {
      building_system: "security",
      compliance: "required",
      audit_trail: "enabled"
    }
  })
end
```

### 3. Multi-Tier Sensor Hierarchy

```ruby
template :sensor_hierarchy do
  # Base environmental sensor
  base_env_sensor = aws_iot_thing_type(:base_environmental, {
    thing_type_name: "BaseEnvironmentalSensor",
    thing_type_properties: {
      description: "Foundation template for environmental monitoring devices",
      searchable_attributes: ["location", "measurement_types", "accuracy_class"]
    },
    tags: {
      sensor_category: "environmental",
      tier: "base"
    }
  })

  # Specialized air quality sensor
  air_quality_sensor = aws_iot_thing_type(:air_quality, {
    thing_type_name: "AirQualitySensor",
    thing_type_properties: {
      description: "Advanced air quality monitoring with particulate and gas detection",
      searchable_attributes: ["pollutant_types", "measurement_range", "location"]
    },
    tags: {
      sensor_category: "environmental",
      tier: "specialized",
      parent_type: "BaseEnvironmentalSensor"
    }
  })

  # Industrial-grade temperature sensor
  industrial_temp_sensor = aws_iot_thing_type(:industrial_temperature, {
    thing_type_name: "IndustrialTemperatureSensor", 
    thing_type_properties: {
      description: "High-precision temperature sensors for industrial processes",
      searchable_attributes: ["temperature_range", "process_type", "calibration_class"]
    },
    tags: {
      sensor_category: "environmental",
      tier: "industrial",
      parent_type: "BaseEnvironmentalSensor"
    }
  })
end
```

## Fleet Indexing and Search Optimization

### Strategic Searchable Attribute Selection

```ruby
template :optimized_fleet_indexing do
  # Optimized for location-based queries
  location_optimized = aws_iot_thing_type(:location_sensor, {
    thing_type_name: "LocationOptimizedSensor",
    thing_type_properties: {
      description: "Sensors optimized for location-based fleet management",
      # Strategic selection for common location queries
      searchable_attributes: ["building", "floor", "zone"]
    }
  })

  # Optimized for operational status queries  
  status_optimized = aws_iot_thing_type(:status_sensor, {
    thing_type_name: "StatusOptimizedSensor",
    thing_type_properties: {
      description: "Sensors optimized for operational status monitoring",
      # Strategic selection for status and maintenance queries
      searchable_attributes: ["status", "last_maintenance", "criticality"]
    }
  })

  # Multi-purpose optimization
  balanced_optimization = aws_iot_thing_type(:balanced_sensor, {
    thing_type_name: "BalancedSensor",
    thing_type_properties: {
      description: "Balanced optimization for diverse query patterns",
      # Balanced selection covering location, status, and type
      searchable_attributes: ["location", "device_type", "status"]
    }
  })
end
```

### Fleet Query Pattern Examples

With optimized thing types, enable powerful fleet queries:

```sql
-- Location-based fleet management
SELECT * FROM AWS_Things 
WHERE thingTypeName = 'LocationOptimizedSensor' 
AND attributes.building = 'headquarters' 
AND attributes.floor = '3'

-- Operational status monitoring
SELECT * FROM AWS_Things 
WHERE thingTypeName = 'StatusOptimizedSensor' 
AND attributes.status = 'active'
AND attributes.criticality = 'high'

-- Maintenance planning queries
SELECT * FROM AWS_Things 
WHERE thingTypeName = 'StatusOptimizedSensor' 
AND attributes.last_maintenance < '2024-01-01'
```

## Intelligent Recommendations System

### Automatic Configuration Recommendations

```ruby
def recommended_thing_attributes
  recommendations = []
  
  # Core device information
  recommendations.concat(%w[model manufacturer serial_number firmware_version])
  
  # Location context (if not already searchable)
  unless searchable_attributes_list.include?('location')
    recommendations.concat(%w[location installation_date])
  end
  
  # Operational metadata
  recommendations.concat(%w[last_maintenance next_maintenance status])
  
  # Include all searchable attributes as recommended
  recommendations.concat(searchable_attributes_list)
  
  recommendations.uniq.sort
end
```

### Security Analysis and Recommendations

```ruby
def security_recommendations
  recommendations = []
  
  # Documentation completeness
  recommendations << "Add description for better organization" unless has_description?
  
  # Fleet indexing optimization
  recommendations << "Define searchable attributes for fleet indexing" unless has_searchable_attributes?
  
  # Naming convention validation
  unless thing_type_name.match?(/\A[A-Z][a-zA-Z0-9_]*\z/)
    recommendations << "Use PascalCase naming convention for thing types"
  end
  
  # Descriptiveness check
  if thing_type_name.length < 5
    recommendations << "Consider more descriptive thing type names"
  end
  
  recommendations
end
```

### Example Thing Configuration Generation

```ruby
def example_thing_configuration
  example_attrs = {}
  
  # Generate realistic example values based on recommendations
  recommended_thing_attributes.each do |attr|
    case attr
    when 'model'
      example_attrs[:model] = "#{thing_type_name}_v1"
    when 'manufacturer'
      example_attrs[:manufacturer] = "ACME Corp"
    when 'serial_number'
      example_attrs[:serial_number] = "SN001234"
    when 'firmware_version'
      example_attrs[:firmware_version] = "1.0.0"
    when 'location'
      example_attrs[:location] = "facility_01"
    when 'status'
      example_attrs[:status] = "active"
    else
      example_attrs[attr.to_sym] = "example_value"
    end
  end
  
  # Return complete thing configuration
  {
    thing_name: "#{thing_type_name.downcase.gsub(/[^a-z0-9]/, '_')}_001",
    thing_type_name: thing_type_name,
    attribute_payload: {
      attributes: example_attrs
    }
  }
end
```

## Cost Impact Analysis

### Comprehensive Cost Analysis

```ruby
def cost_impact_analysis
  impact = {}
  
  # Base thing type costs
  impact[:thing_type_cost] = "minimal"
  impact[:thing_type_note] = "Thing types have no direct cost"
  
  # Fleet indexing cost implications
  if has_searchable_attributes?
    impact[:indexing_cost] = "low_to_medium"
    impact[:indexing_note] = "Searchable attributes enable fleet indexing - charges apply per indexed thing"
    impact[:indexing_details] = {
      attributes_count: searchable_attribute_count,
      estimated_per_thing_monthly: "$0.0014 per thing per searchable attribute"
    }
  else
    impact[:indexing_cost] = "none"
    impact[:indexing_note] = "No searchable attributes = no indexing costs"
  end
  
  # Per-thing costs
  impact[:per_thing_cost] = "standard"
  impact[:per_thing_note] = "Each thing created with this type follows standard IoT Core pricing"
  
  impact
end
```

## Enterprise Integration Patterns

### Multi-Region Type Management

```ruby
template :global_thing_types do
  # Global device type with regional variations
  global_gateway = aws_iot_thing_type(:global_gateway, {
    thing_type_name: "GlobalIoTGateway",
    thing_type_properties: {
      description: "Standardized IoT gateways deployed globally with regional configurations",
      searchable_attributes: ["region", "deployment_type", "capacity_tier"]
    },
    tags: {
      scope: "global",
      standardized: "true",
      regions: "us-east-1,eu-west-1,ap-southeast-1"
    }
  })

  # Regional specialization
  industrial_gateway = aws_iot_thing_type(:industrial_gateway, {
    thing_type_name: "IndustrialGateway",
    thing_type_properties: {
      description: "Industrial-grade gateways for manufacturing environments",
      searchable_attributes: ["industrial_protocol", "hazard_rating", "certification"]
    },
    tags: {
      scope: "regional",
      environment: "industrial",
      parent_type: "GlobalIoTGateway"
    }
  })
end
```

### Compliance and Audit Integration

```ruby
template :compliance_aware_types do
  # Medical device type
  medical_device = aws_iot_thing_type(:medical_device, {
    thing_type_name: "MedicalDeviceType",
    thing_type_properties: {
      description: "FDA-compliant medical monitoring devices with audit trails",
      searchable_attributes: ["device_class", "fda_approval", "patient_safety_critical"]
    },
    tags: {
      compliance: "fda_510k",
      data_classification: "phi",
      audit_retention: "7_years",
      encryption_required: "true"
    }
  })

  # Financial services device
  financial_device = aws_iot_thing_type(:financial_device, {
    thing_type_name: "FinancialServiceDevice",
    thing_type_properties: {
      description: "PCI DSS compliant devices for financial transaction processing",
      searchable_attributes: ["compliance_level", "transaction_type", "security_zone"]
    },
    tags: {
      compliance: "pci_dss",
      data_classification: "financial",
      security_level: "high",
      audit_trail: "mandatory"
    }
  })
end
```

## Advanced Validation and Compatibility

### Type Compatibility Analysis

```ruby
def compatibility_check(other_type_name)
  checks = {}
  
  # Name similarity analysis
  similarity = calculate_similarity(thing_type_name.downcase, other_type_name.downcase)
  
  if similarity > 0.7
    checks[:name_conflict] = "high"
    checks[:name_warning] = "Thing type names are very similar, consider unique naming"
  else
    checks[:name_conflict] = "none"
  end
  
  # Searchable attribute overlap analysis
  if has_searchable_attributes?
    checks[:attribute_strategy] = "Consider attribute naming consistency across related types"
  end
  
  checks
end
```

### Migration and Versioning Support

```ruby
template :versioned_thing_types do
  # Version 1.0 - Legacy
  sensor_v1 = aws_iot_thing_type(:sensor_legacy, {
    thing_type_name: "IndustrialSensor_v1",
    thing_type_properties: {
      description: "Legacy industrial sensors - maintenance mode only",
      searchable_attributes: ["location", "type"]
    },
    tags: {
      version: "1.0",
      lifecycle: "maintenance",
      migration_target: "IndustrialSensor_v2"
    }
  })

  # Version 2.0 - Current
  sensor_v2 = aws_iot_thing_type(:sensor_current, {
    thing_type_name: "IndustrialSensor_v2",
    thing_type_properties: {
      description: "Enhanced industrial sensors with predictive maintenance and edge analytics",
      searchable_attributes: ["location", "type", "maintenance_status"]
    },
    tags: {
      version: "2.0",
      lifecycle: "active",
      features: "predictive_maintenance,edge_analytics",
      predecessor: "IndustrialSensor_v1"
    }
  })

  # Output migration guidance
  output :migration_recommendations do
    value {
      from_type: sensor_v1.thing_type_name,
      to_type: sensor_v2.thing_type_name,
      new_features: ["maintenance_status searchable attribute", "predictive maintenance support"],
      migration_steps: [
        "Update device firmware to support new attributes",
        "Migrate existing things to new type",
        "Update fleet indexing queries",
        "Deprecate old type after migration complete"
      ]
    }
  end
end
```

This resource provides enterprise-grade IoT device taxonomy management with comprehensive type safety, intelligent recommendations, and advanced fleet management capabilities for large-scale IoT deployments.