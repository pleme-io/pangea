# AWS IoT Certificate Resource - Claude Documentation

## Resource Overview

The `aws_iot_certificate` resource manages AWS IoT certificates with comprehensive validation, security analysis, and lifecycle management capabilities. It supports multiple certificate creation methods with intelligent recommendations for each approach.

## Type-Safe Implementation

### Certificate Creation Methods

```ruby
class IotCertificateAttributes < Dry::Struct
  attribute :active, Types::Bool.default(true)                    # Certificate status
  attribute? :csr, Types::String.optional                        # Customer CSR
  attribute? :certificate_pem, Types::String.optional            # Custom certificate
  attribute? :ca_certificate_pem, Types::String.optional         # CA chain certificate
  attribute :tags, Types::AwsTags.default({})                    # Resource tags
end
```

### Advanced Validation Logic

```ruby
def self.new(attributes = {})
  # Validate certificate creation method exclusivity
  has_csr = attrs.csr && !attrs.csr.empty?
  has_cert_pem = attrs.certificate_pem && !attrs.certificate_pem.empty?
  
  if has_csr && has_cert_pem
    raise Dry::Struct::Error, "Cannot specify both CSR and certificate_pem"
  end
  
  # Validate CA certificate requirements
  if has_ca_cert && !has_cert_pem
    raise Dry::Struct::Error, "ca_certificate_pem requires certificate_pem"
  end
  
  # PEM format validation
  validate_pem_formats(attrs)
end
```

### Intelligent Security Assessment

```ruby
def security_assessment
  assessment = { creation_method: creation_method, security_level: "standard" }
  
  case creation_method
  when :aws_generated
    assessment[:security_level] = "high"
    assessment[:notes] = [
      "AWS-generated certificates use secure key generation",
      "Private key never leaves AWS"
    ]
  when :csr
    assessment[:security_level] = "high" 
    assessment[:notes] = [
      "Private key remains under your control",
      "CSR ensures proper key ownership"
    ]
  when :certificate_pem
    assessment[:security_level] = "medium"
    assessment[:notes] = [
      "External certificate management required",
      "Ensure proper private key protection"
    ]
  end
  
  assessment
end
```

## Enterprise PKI Integration Patterns

### Multi-Tier Certificate Architecture

```ruby
template :enterprise_pki_certificates do
  # Root CA certificate (bring your own)
  root_ca_cert = aws_iot_certificate(:root_ca, {
    active: true,
    certificate_pem: load_root_ca_certificate(),
    tags: {
      certificate_tier: "root_ca",
      validity_years: "10",
      key_length: "4096"
    }
  })

  # Intermediate CA certificates
  intermediate_ca_cert = aws_iot_certificate(:intermediate_ca, {
    active: true,
    certificate_pem: load_intermediate_ca_certificate(),
    ca_certificate_pem: load_root_ca_certificate(),
    tags: {
      certificate_tier: "intermediate_ca",
      validity_years: "5",
      issuer: "RootCA"
    }
  })

  # End-entity device certificates
  device_cert = aws_iot_certificate(:device_cert, {
    active: true,
    certificate_pem: load_device_certificate(),
    ca_certificate_pem: load_full_ca_chain(),
    tags: {
      certificate_tier: "end_entity",
      validity_years: "1",
      device_class: "industrial_sensor"
    }
  })
end
```

### High-Security CSR-Based Certificates

```ruby
template :high_security_certificates do
  # Generate CSR with customer-managed private keys
  secure_device_cert = aws_iot_certificate(:secure_device, {
    active: true,
    csr: generate_secure_csr({
      key_length: 4096,
      hash_algorithm: "SHA-256",
      subject: "CN=SecureDevice001,O=MyCompany,C=US"
    }),
    tags: {
      security_level: "high",
      key_management: "customer_hsm",
      compliance: "fips_140_2_level_3"
    }
  })

  output :security_analysis do
    value secure_device_cert.security_assessment
  end
end
```

## Certificate Lifecycle Management

### Automated Rotation Strategy

```ruby
template :certificate_rotation_management do
  # Current active certificate
  active_cert = aws_iot_certificate(:active_cert, {
    active: true,
    tags: {
      rotation_id: "gen_001",
      created_date: "2024-01-01",
      expires_date: "2025-01-01",
      next_rotation: "2024-11-01"
    }
  })

  # Pre-provisioned rotation certificate
  rotation_cert = aws_iot_certificate(:rotation_cert, {
    active: false,  # Inactive until rotation
    tags: {
      rotation_id: "gen_002", 
      role: "rotation_standby",
      activation_date: "2024-11-01"
    }
  })

  output :rotation_orchestration do
    value {
      active_certificate: {
        id: active_cert.certificate_id,
        lifecycle_recommendations: active_cert.lifecycle_recommendations
      },
      rotation_certificate: {
        id: rotation_cert.certificate_id,
        integration_requirements: rotation_cert.integration_requirements
      },
      rotation_process: [
        "Monitor active certificate expiration",
        "Activate rotation certificate 30 days before expiry",
        "Update device configurations with new certificate",
        "Validate device connectivity and authentication",
        "Deactivate expired certificate",
        "Generate next rotation certificate"
      ]
    }
  end
end
```

### Certificate Chain Validation

```ruby
template :certificate_chain_validation do
  validated_cert = aws_iot_certificate(:validated_device, {
    active: true,
    certificate_pem: device_certificate_pem,
    ca_certificate_pem: complete_certificate_chain,
    tags: {
      validation_status: "chain_verified",
      trust_anchor: "corporate_root_ca",
      chain_depth: "3"
    }
  })

  output :chain_validation_results do
    value {
      certificate_id: validated_cert.certificate_id,
      compliance_info: validated_cert.compliance_info,
      security_assessment: validated_cert.security_assessment,
      operational_metrics: validated_cert.operational_metrics
    }
  end
end
```

## Compliance and Audit Integration

### SOX-Compliant Certificate Management

```ruby
template :sox_compliant_certificates do
  financial_device_cert = aws_iot_certificate(:financial_device, {
    active: true,
    tags: {
      compliance_framework: "sox",
      data_classification: "financial",
      audit_retention: "7_years",
      change_approval_required: "true",
      access_logging: "enhanced"
    }
  })

  output :sox_compliance_report do
    value {
      certificate_id: financial_device_cert.certificate_id,
      compliance_info: financial_device_cert.compliance_info,
      audit_requirements: [
        "All certificate operations logged in CloudTrail",
        "Certificate access monitored and alerted", 
        "Annual certificate validation and renewal",
        "Immutable audit trail maintained"
      ]
    }
  end
end
```

### HIPAA-Compliant IoT Certificates

```ruby
template :hipaa_compliant_certificates do
  medical_device_cert = aws_iot_certificate(:medical_device, {
    active: true,
    csr: generate_hipaa_compliant_csr(),
    tags: {
      compliance_framework: "hipaa",
      data_classification: "phi",
      encryption_required: "aes_256",
      key_escrow: "required"
    }
  })

  output :hipaa_compliance_assessment do
    value {
      certificate_assessment: medical_device_cert.security_assessment,
      hipaa_requirements: [
        "Certificate-based device authentication mandatory",
        "Private keys must be securely managed",
        "Certificate rotation before 1-year expiration",
        "Access controls and audit trails required"
      ]
    }
  end
end
```

## Integration with Device Provisioning

### Just-in-Time Certificate Provisioning

```ruby
template :jit_certificate_provisioning do
  # Template certificate for device provisioning
  provisioning_template_cert = aws_iot_certificate(:provisioning_template, {
    active: true,
    tags: {
      provisioning_role: "template",
      device_class: "sensor",
      auto_provision: "enabled"
    }
  })

  # Individual device certificates created during provisioning
  device_cert = aws_iot_certificate(:provisioned_device, {
    active: true,
    tags: {
      provisioning_role: "device",
      provisioned_from: provisioning_template_cert.certificate_id,
      provisioning_date: "2024-01-01"
    }
  })

  output :provisioning_workflow do
    value {
      template_certificate: provisioning_template_cert.certificate_id,
      device_certificate: device_cert.certificate_id,
      integration_requirements: device_cert.integration_requirements
    }
  end
end
```

## Performance and Cost Optimization

### Certificate Performance Analysis

```ruby
def operational_metrics
  {
    creation_time: creation_time_estimate,
    validation_time: validation_time_estimate,
    activation_time: "Immediate upon creation",
    revocation_time: "Immediate when status changed to INACTIVE",
    throughput: certificate_throughput_analysis,
    cost_impact: certificate_cost_analysis
  }
end

private

def creation_time_estimate
  case creation_method
  when :aws_generated then "< 1 second"
  when :csr then "< 5 seconds" 
  when :certificate_pem then "< 10 seconds for validation"
  end
end
```

### Multi-Region Certificate Strategy

```ruby
template :multi_region_certificates do
  regions = ["us-east-1", "eu-west-1", "ap-southeast-1"]
  
  regions.each do |region|
    aws_iot_certificate(:"#{region.gsub('-', '_')}_cert", {
      active: true,
      tags: {
        region: region,
        geo_compliance: get_regional_compliance(region),
        data_residency: "required"
      }
    })
  end
end
```

This resource provides enterprise-grade certificate management with comprehensive security analysis, compliance support, and intelligent lifecycle management for large-scale IoT deployments.