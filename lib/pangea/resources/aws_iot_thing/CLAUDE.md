# AWS IoT Thing Resource - Claude Documentation

## Resource Overview

The `aws_iot_thing` resource manages AWS IoT Things, which represent physical devices or logical entities in AWS IoT Core. This resource provides comprehensive type safety and validation for IoT device management.

## Type-Safe Implementation

### Core Type Structure

```ruby
class IotThingAttributes < Dry::Struct
  attribute :thing_name, Types::IotThingName              # Required: 1-128 chars, alphanumeric + :_-
  attribute? :thing_type_name, Types::IotThingTypeName.optional  # Optional: Thing type association
  attribute :attribute_payload, Types::Hash.schema(       # Attribute configuration
    attributes?: Types::IotThingAttributes.optional,      # Key-value pairs (max 50)
    merge?: Types::Bool.optional                          # Merge behavior
  ).default({ attributes: {}, merge: false }.freeze)
end
```

### Validation Features

1. **Name Validation**: Enforces AWS IoT thing naming rules
2. **Attribute Limits**: Validates maximum 50 attributes per thing
3. **Reserved Names**: Prevents use of reserved attribute names
4. **Merge Logic**: Validates merge behavior with attributes

### Computed Properties

The resource provides intelligent computed properties:

```ruby
def attribute_count                    # Number of attributes
def has_attribute?(key)               # Check for specific attribute
def get_attribute(key)                # Retrieve attribute value
def has_type?                         # Check if thing has type
def fleet_indexing_ready?             # Optimization check
def estimated_storage_bytes           # Storage usage estimate
def security_recommendations         # Security analysis
def required_permissions             # IAM permission list
```

## IoT Device Management Patterns

### 1. Basic Device Registration

```ruby
# Simple device registration
device = aws_iot_thing(:basic_sensor, {
  thing_name: "temp-sensor-001"
})
```

### 2. Typed Device with Attributes

```ruby
# Device with comprehensive metadata
smart_device = aws_iot_thing(:smart_thermostat, {
  thing_name: "thermostat-living-room",
  thing_type_name: "SmartThermostat",
  attribute_payload: {
    attributes: {
      location: "living_room",
      model: "ThermoStat_Pro_v2",
      firmware_version: "1.2.3",
      capabilities: "heating,cooling,scheduling"
    }
  }
})
```

### 3. Fleet Management

```ruby
# Industrial sensor fleet
template :sensor_fleet do
  zones = %w[north south east west]
  
  zones.each_with_index do |zone, index|
    (1..5).each do |sensor_id|
      aws_iot_thing(:"#{zone}_sensor_#{sensor_id}", {
        thing_name: "#{zone}-zone-sensor-#{sensor_id.to_s.rjust(2, '0')}",
        thing_type_name: "IndustrialSensor",
        attribute_payload: {
          attributes: {
            zone: zone,
            sensor_type: "temperature_pressure",
            installation_batch: "batch_2024_q1",
            maintenance_schedule: "quarterly"
          }
        }
      })
    end
  end
end
```

## Security and Compliance Features

### Automatic Security Analysis

The resource performs security analysis and provides recommendations:

```ruby
def security_recommendations
  recommendations = []
  
  # Check for thing type usage
  recommendations << "Consider creating a thing type" unless has_type?
  
  # Validate attribute usage
  recommendations << "Add attributes for fleet indexing" if attribute_count == 0
  
  # Check naming conventions
  unless thing_name.match?(/\A[a-zA-Z][a-zA-Z0-9_-]*\z/)
    recommendations << "Use consistent naming convention"
  end
  
  # Scan for sensitive data patterns
  if attribute_payload[:attributes]
    sensitive_patterns = %w[password secret key token credential]
    sensitive_attrs = attribute_payload[:attributes].keys.select do |key|
      sensitive_patterns.any? { |pattern| key.to_s.downcase.include?(pattern) }
    end
    
    unless sensitive_attrs.empty?
      recommendations << "Avoid sensitive data in attributes: #{sensitive_attrs.join(', ')}"
    end
  end
  
  recommendations
end
```

### IAM Permission Management

```ruby
def required_permissions
  permissions = [
    "iot:UpdateThing",
    "iot:DescribeThing", 
    "iot:DeleteThing"
  ]
  
  permissions << "iot:ListThingPrincipals" if has_type?
  permissions << "iot:UpdateThingAttribute" if attribute_count > 0
  
  permissions
end
```

## Industrial IoT Patterns

### Manufacturing Equipment

```ruby
template :manufacturing_line do
  # CNC Machine
  cnc = aws_iot_thing(:cnc_machine_001, {
    thing_name: "cnc-machine-line-1-station-1",
    thing_type_name: "CNC_Machine",
    attribute_payload: {
      attributes: {
        line_number: "1",
        station_number: "1", 
        machine_type: "CNC_Lathe",
        manufacturer: "ACME_Industrial",
        model: "CL-5000",
        serial_number: "CL5000-2024-001",
        max_spindle_speed: "5000",
        tool_capacity: "12",
        maintenance_hours: "500"
      }
    }
  })

  # Quality Control Scanner
  qc_scanner = aws_iot_thing(:qc_scanner_001, {
    thing_name: "qc-scanner-line-1-end",
    thing_type_name: "QualityScanner",
    attribute_payload: {
      attributes: {
        line_number: "1",
        scanner_type: "optical_3d",
        resolution: "0.1mm",
        scan_speed: "30_parts_per_minute",
        calibration_date: "2024-03-01"
      }
    }
  })
end
```

### Smart Building Management

```ruby
template :smart_building do
  # Building-wide systems
  building_systems = [
    {
      name: "hvac_main",
      type: "HVAC_System",
      attributes: {
        building_zone: "main",
        system_type: "central_air",
        capacity: "100_ton",
        efficiency_rating: "SEER_16"
      }
    },
    {
      name: "lighting_controller",
      type: "LightingController", 
      attributes: {
        control_zones: "12",
        dimming_capability: "true",
        schedule_modes: "occupancy,daylight,manual"
      }
    }
  ]

  building_systems.each do |system|
    aws_iot_thing(system[:name].to_sym, {
      thing_name: system[:name].gsub('_', '-'),
      thing_type_name: system[:type],
      attribute_payload: {
        attributes: system[:attributes].merge({
          building_id: "corporate_hq",
          installation_date: "2024-01-01",
          warranty_expires: "2027-01-01"
        })
      }
    })
  end
end
```

## Fleet Indexing and Search Optimization

### Searchable Attribute Design

```ruby
# Optimized for fleet indexing
template :searchable_fleet do
  aws_iot_thing(:optimized_sensor, {
    thing_name: "sensor-environmental-lobby-001",
    thing_type_name: "EnvironmentalSensor",
    attribute_payload: {
      attributes: {
        # Location hierarchy for searching
        building: "headquarters",
        floor: "1",
        room: "lobby",
        zone: "north",
        
        # Device characteristics
        sensor_types: "temperature,humidity,air_quality,light",
        accuracy: "high",
        calibration_status: "current",
        
        # Operational data
        installation_date: "2024-01-15",
        last_maintenance: "2024-03-01",
        next_maintenance: "2024-06-01",
        firmware_version: "2.1.4",
        
        # Management tags
        cost_center: "facilities",
        responsible_team: "building_ops",
        criticality: "medium"
      }
    }
  })
end
```

### Dynamic Fleet Queries

The attributes support complex IoT fleet indexing queries:

```sql
-- Find all sensors in a specific building
SELECT * FROM AWS_Things WHERE attributes.building = 'headquarters'

-- Find devices due for maintenance
SELECT * FROM AWS_Things WHERE attributes.next_maintenance < '2024-04-01'

-- Find high-accuracy environmental sensors
SELECT * FROM AWS_Things 
WHERE thingTypeName = 'EnvironmentalSensor' 
AND attributes.accuracy = 'high'
```

## Integration with Other IoT Resources

### Certificate Management Integration

```ruby
template :secure_device_provisioning do
  # Create the thing
  secure_device = aws_iot_thing(:secure_gateway, {
    thing_name: "secure-gateway-001",
    thing_type_name: "SecureGateway",
    attribute_payload: {
      attributes: {
        security_level: "enterprise",
        encryption_required: "true",
        certificate_rotation: "annual"
      }
    }
  })

  # Output thing name for certificate attachment
  output :device_name_for_cert do
    value secure_device.thing_name
    description "Device name for certificate attachment"
  end
end
```

### Topic Rule Integration

```ruby
template :data_collection_pipeline do
  # Data collection device
  collector = aws_iot_thing(:data_collector, {
    thing_name: "data-collector-production-001",
    thing_type_name: "DataCollector",
    attribute_payload: {
      attributes: {
        data_frequency: "every_30_seconds",
        data_format: "protobuf",
        compression: "lz4",
        batch_size: "100"
      }
    }
  })

  # Define topic patterns based on device attributes
  output :device_telemetry_topic do
    value "production/telemetry/${collector.thing_name}/+"
  end

  output :device_command_topic do
    value "production/commands/${collector.thing_name}"
  end
end
```

## Validation and Error Handling

### Comprehensive Type Validation

```ruby
# The type system catches common errors:

# Invalid thing name (starts with $)
aws_iot_thing(:invalid, {
  thing_name: "$invalid-name"  # ERROR: Cannot start with '$'
})

# Too many attributes
aws_iot_thing(:overloaded, {
  thing_name: "valid-name",
  attribute_payload: {
    attributes: Hash[(1..51).map { |i| ["attr_#{i}", "value"] }]  # ERROR: Max 50 attributes
  }
})

# Reserved attribute name
aws_iot_thing(:reserved, {
  thing_name: "valid-name", 
  attribute_payload: {
    attributes: {
      thingName: "reserved"  # ERROR: Reserved attribute name
    }
  }
})
```

### Runtime Validation

```ruby
def self.new(attributes = {})
  attrs = super(attributes)
  
  # Validate merge logic
  if attrs.attribute_payload[:merge] && 
     (!attrs.attribute_payload[:attributes] || attrs.attribute_payload[:attributes].empty?)
    raise Dry::Struct::Error, "Cannot set merge: true without providing attributes"
  end
  
  attrs
end
```

This resource provides enterprise-grade IoT device management with comprehensive type safety, security analysis, and optimization for AWS IoT Core fleet management operations.