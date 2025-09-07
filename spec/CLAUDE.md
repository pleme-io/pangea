# Pangea Testing Framework

## Overview

Pangea's testing framework provides comprehensive test coverage for all three abstraction layers: resources, components, and architectures. The testing system emphasizes real synthesis validation to ensure that all generated Terraform configurations are valid and production-ready.

## Testing Architecture Principles

### 1. Directory-Per-Entity Rule
**CRITICAL REQUIREMENT**: Each resource function, component, and architecture MUST have its own dedicated testing directory.

```
spec/
├── resources/
│   ├── aws_vpc/                    # One directory per resource function
│   │   ├── resource_spec.rb
│   │   ├── synthesis_spec.rb
│   │   └── integration_spec.rb
│   ├── aws_subnet/                 # One directory per resource function
│   │   ├── resource_spec.rb
│   │   ├── synthesis_spec.rb
│   │   └── integration_spec.rb
│   └── [every resource gets its own directory]
├── components/
│   ├── secure_vpc/                 # One directory per component
│   │   ├── component_spec.rb
│   │   ├── synthesis_spec.rb
│   │   └── integration_spec.rb
│   ├── application_load_balancer/  # One directory per component
│   │   ├── component_spec.rb
│   │   ├── synthesis_spec.rb
│   │   └── integration_spec.rb
│   └── [every component gets its own directory]
└── architectures/
    ├── web_application_architecture/  # One directory per architecture
    │   ├── architecture_spec.rb
    │   ├── synthesis_spec.rb
    │   ├── integration_spec.rb
    │   └── scenario_spec.rb
    └── [every architecture gets its own directory]
```

### 2. Real Synthesis Testing Requirement
**MANDATORY**: All resource tests MUST utilize the terraform-synthesizer and test with real synthesis. No mocking or stubbing of the synthesis process is permitted for resource-level tests.

- **Resource Tests**: Must generate actual Terraform JSON and validate structure
- **Component Tests**: Must synthesize all underlying resources and validate composition
- **Architecture Tests**: Must synthesize complete infrastructure stacks and validate orchestration

### 3. Test Development Methodology
**CRITICAL REQUIREMENT**: When developing tests, each resource, component, or architecture must be fully tested one by one before moving on to the next. Do not attempt to test multiple entities simultaneously.

- **Sequential Development**: Complete all tests for a single resource/component/architecture before starting the next
- **Full Coverage Per Entity**: Each entity must have all required test files (resource_spec.rb, synthesis_spec.rb, integration_spec.rb) fully implemented
- **Validation Before Progression**: Ensure all tests pass for the current entity before moving to the next
- **No Parallel Development**: Avoid developing tests for multiple entities concurrently

This approach ensures:
- Complete test coverage for each entity
- Easier debugging when issues arise
- Clear understanding of each entity's behavior
- Consistent quality across all tests

### 4. Test File Structure per Directory

Each entity directory follows a consistent structure:

#### Resource Function Directories
```
spec/resources/aws_vpc/
├── resource_spec.rb      # Resource function behavior tests
├── synthesis_spec.rb     # Real Terraform synthesis validation
└── integration_spec.rb   # Cross-resource integration tests
```

#### Component Directories
```
spec/components/secure_vpc/
├── component_spec.rb     # Component behavior and composition tests
├── synthesis_spec.rb     # Component synthesis with all resources
└── integration_spec.rb   # Component integration with other components
```

#### Architecture Directories
```
spec/architectures/web_application_architecture/
├── architecture_spec.rb   # Architecture behavior and orchestration
├── synthesis_spec.rb      # Full architecture synthesis validation
├── integration_spec.rb    # Multi-architecture integration tests
└── scenario_spec.rb       # Real-world deployment scenarios
```

## Testing Levels and Requirements

### Level 1: Resource Function Testing

**Purpose**: Validate individual resource functions generate correct Terraform configurations

**Requirements**:
1. **Real Synthesis**: Must use `TerraformSynthesizer` to generate actual Terraform JSON
2. **Structure Validation**: Verify generated Terraform structure matches expected format
3. **Attribute Validation**: Ensure all resource attributes are correctly mapped
4. **Reference Validation**: Test resource reference generation and usage
5. **Type Safety**: Validate dry-struct attribute validation works correctly

**Example Test Structure**:
```ruby
RSpec.describe "aws_vpc resource function" do
  include Pangea::Resources::AWS
  
  describe "synthesis validation" do
    it "generates valid Terraform JSON" do
      synthesizer = TerraformSynthesizer.new
      
      # Real synthesis - no mocking allowed
      synthesizer.instance_eval do
        aws_vpc(:test_vpc, {
          cidr_block: "10.0.0.0/16",
          enable_dns_hostnames: true,
          enable_dns_support: true
        })
      end
      
      result = synthesizer.synthesis
      
      # Validate actual Terraform structure
      expect(result).to have_key("resource")
      expect(result["resource"]).to have_key("aws_vpc")
      expect(result["resource"]["aws_vpc"]).to have_key("test_vpc")
      
      vpc_config = result["resource"]["aws_vpc"]["test_vpc"]
      expect(vpc_config["cidr_block"]).to eq("10.0.0.0/16")
      expect(vpc_config["enable_dns_hostnames"]).to eq(true)
    end
  end
end
```

### Level 2: Component Testing

**Purpose**: Validate component composition and resource orchestration

**Requirements**:
1. **Component Behavior**: Test component function logic and composition
2. **Resource Synthesis**: Verify all underlying resources synthesize correctly
3. **Reference Composition**: Test resource reference passing between resources
4. **Override Testing**: Validate component override capabilities
5. **Integration**: Test component-to-component integration

**Example Test Structure**:
```ruby
RSpec.describe "secure_vpc component" do
  include Pangea::Components
  
  describe "component synthesis" do
    it "synthesizes all component resources correctly" do
      component_ref = secure_vpc(:test_secure_vpc, {
        cidr_block: "10.0.0.0/16",
        availability_zones: ["us-east-1a", "us-east-1b"],
        enable_flow_logs: true
      })
      
      # Validate component structure
      expect(component_ref).to be_a(ComponentReference)
      expect(component_ref.type).to eq('secure_vpc')
      
      # Test resource synthesis through component
      synthesizer = TerraformSynthesizer.new
      synthesizer.instance_eval do
        # Component should generate multiple resources
        component_ref.resources.each do |name, resource|
          case resource
          when ResourceReference
            # Synthesize individual resources
          end
        end
      end
      
      result = synthesizer.synthesis
      
      # Validate all expected resources are present
      expect(result["resource"]).to have_key("aws_vpc")
      expect(result["resource"]).to have_key("aws_flow_log") if component_ref.resources[:flow_logs]
    end
  end
end
```

### Level 3: Architecture Testing

**Purpose**: Validate complete infrastructure architecture deployment

**Requirements**:
1. **Architecture Orchestration**: Test architecture composition and configuration
2. **Complete Synthesis**: Validate entire architecture synthesizes to valid Terraform
3. **Environment Testing**: Test environment-specific defaults and configurations
4. **Override System**: Validate architecture override and extension capabilities
5. **Cost Estimation**: Test cost calculation accuracy
6. **Security Scoring**: Validate security compliance scoring
7. **Multi-Architecture Integration**: Test architecture-to-architecture composition

**Example Test Structure**:
```ruby
RSpec.describe "web_application_architecture" do
  include Pangea::Architectures
  
  describe "architecture synthesis" do
    it "synthesizes complete web application infrastructure" do
      architecture_ref = web_application_architecture(:test_web_app, {
        domain_name: "test.example.com",
        environment: "production",
        auto_scaling: { min: 2, max: 5 }
      })
      
      # Validate architecture structure
      expect(architecture_ref).to be_a(ArchitectureReference)
      expect(architecture_ref.type).to eq('web_application_architecture')
      
      # Test complete infrastructure synthesis
      synthesizer = TerraformSynthesizer.new
      synthesizer.instance_eval do
        # Architecture should orchestrate all components and resources
        architecture_ref.components.each do |name, component|
          # Synthesize each component's resources
        end
        
        architecture_ref.resources.each do |name, resource|
          # Synthesize architecture-level resources
        end
      end
      
      result = synthesizer.synthesis
      
      # Validate complete infrastructure is present
      expect(result["resource"]).to have_key("aws_vpc")           # Network
      expect(result["resource"]).to have_key("aws_lb")            # Load balancer
      expect(result["resource"]).to have_key("aws_autoscaling_group") # Compute
      expect(result["resource"]).to have_key("aws_db_instance")   # Database
    end
  end
end
```

## Test Categories and Specifications

### Synthesis Tests (`synthesis_spec.rb`)
**Purpose**: Validate Terraform JSON generation and structure

**Requirements**:
- Use real `TerraformSynthesizer` instance
- Generate actual Terraform JSON output  
- Validate JSON structure matches Terraform specification
- Test all configuration parameters are correctly mapped
- Verify resource dependencies and references are correctly generated

### Integration Tests (`integration_spec.rb`)
**Purpose**: Validate cross-entity interactions and dependencies

**Requirements**:
- Test resource-to-resource references
- Validate component-to-component composition
- Test architecture-to-architecture integration
- Verify dependency ordering in generated Terraform
- Test override and extension mechanisms

### Scenario Tests (`scenario_spec.rb` - Architectures only)
**Purpose**: Validate real-world deployment scenarios

**Requirements**:
- Test complete environment deployments (dev, staging, production)
- Validate multi-architecture compositions
- Test disaster recovery scenarios
- Verify scaling and performance configurations
- Test security and compliance configurations

## Test Helpers and Utilities

### Synthesis Test Helpers
```ruby
module SynthesisTestHelpers
  def synthesize_and_validate(entity_type, &block)
    synthesizer = TerraformSynthesizer.new
    synthesizer.instance_eval(&block)
    result = synthesizer.synthesis
    
    validate_terraform_structure(result, entity_type)
    result
  end
  
  def validate_terraform_structure(result, entity_type)
    expect(result).to be_a(Hash)
    expect(result).to have_key("resource") if entity_type != :data_source
    
    # Additional structure validation based on entity type
  end
  
  def validate_resource_references(result)
    # Validate all resource references are properly formatted
    # e.g., "${aws_vpc.main.id}" format validation
  end
end
```

### Component Test Helpers
```ruby
module ComponentTestHelpers
  def validate_component_structure(component_ref)
    expect(component_ref).to respond_to(:type)
    expect(component_ref).to respond_to(:name)
    expect(component_ref).to respond_to(:resources)
    expect(component_ref).to respond_to(:outputs)
  end
  
  def validate_component_resources(component_ref)
    expect(component_ref.resources).to be_a(Hash)
    expect(component_ref.resources).not_to be_empty
    
    component_ref.resources.each do |name, resource|
      expect(resource).to respond_to(:type) if resource.respond_to?(:type)
    end
  end
end
```

### Architecture Test Helpers
```ruby
module ArchitectureTestHelpers
  def validate_architecture_structure(arch_ref)
    expect(arch_ref).to respond_to(:type)
    expect(arch_ref).to respond_to(:name)
    expect(arch_ref).to respond_to(:components)
    expect(arch_ref).to respond_to(:resources)
    expect(arch_ref).to respond_to(:outputs)
  end
  
  def validate_architecture_completeness(arch_ref)
    # Validate architecture has all required tiers
    case arch_ref.type
    when 'web_application_architecture'
      expect(arch_ref.components).to have_key(:network)
      expect(arch_ref.components).to have_key(:load_balancer)
      expect(arch_ref.components).to have_key(:web_servers)
      expect(arch_ref.components).to have_key(:database) if arch_ref.architecture_attributes[:database_enabled]
    end
  end
  
  def validate_cost_estimation(arch_ref)
    expect(arch_ref.estimated_monthly_cost).to be_a(Float)
    expect(arch_ref.estimated_monthly_cost).to be > 0
    
    cost_breakdown = arch_ref.cost_breakdown
    expect(cost_breakdown).to have_key(:components)
    expect(cost_breakdown).to have_key(:resources)
    expect(cost_breakdown).to have_key(:total)
  end
  
  def validate_security_scoring(arch_ref)
    score = arch_ref.security_compliance_score
    expect(score).to be_a(Float)
    expect(score).to be_between(0.0, 100.0)
  end
end
```

## Test Organization and Naming

### File Naming Conventions
- `resource_spec.rb`: Resource function behavior tests
- `synthesis_spec.rb`: Terraform synthesis validation tests
- `integration_spec.rb`: Cross-entity integration tests  
- `scenario_spec.rb`: Real-world scenario tests (architectures only)

### Test Group Organization
```ruby
RSpec.describe "EntityName" do
  describe "basic functionality" do
    # Basic behavior tests
  end
  
  describe "synthesis validation" do
    # Real Terraform synthesis tests
  end
  
  describe "attribute validation" do
    # Type safety and validation tests
  end
  
  describe "integration" do
    # Integration with other entities
  end
  
  describe "error handling" do
    # Error conditions and edge cases
  end
end
```

## Test Data and Fixtures

### Test Configuration Files
```ruby
# spec/support/test_configurations.rb
module TestConfigurations
  VPC_CONFIG = {
    cidr_block: "10.0.0.0/16",
    enable_dns_hostnames: true,
    enable_dns_support: true
  }.freeze
  
  WEB_APP_CONFIG = {
    domain_name: "test.example.com",
    environment: "production",
    auto_scaling: { min: 2, max: 5 },
    database_engine: "mysql"
  }.freeze
end
```

### Terraform Validation Fixtures
```ruby
# spec/fixtures/terraform_structures.rb
module TerraformStructures
  AWS_VPC_STRUCTURE = {
    "resource" => {
      "aws_vpc" => {
        String => {
          "cidr_block" => String,
          "enable_dns_hostnames" => [TrueClass, FalseClass],
          "enable_dns_support" => [TrueClass, FalseClass]
        }
      }
    }
  }.freeze
end
```

## Continuous Integration Requirements

### Test Execution Order
1. **Resource Synthesis Tests**: Validate individual resource generation
2. **Component Synthesis Tests**: Validate component composition
3. **Architecture Synthesis Tests**: Validate complete architecture orchestration
4. **Integration Tests**: Validate cross-entity interactions
5. **Scenario Tests**: Validate real-world deployment patterns

### Coverage Requirements
- **Resource Functions**: 100% synthesis validation coverage
- **Components**: 100% component behavior and synthesis coverage
- **Architectures**: 100% architecture orchestration and synthesis coverage
- **Integration**: All documented integration patterns must be tested

### Performance Requirements
- **Resource Tests**: Must complete within 5 seconds per resource
- **Component Tests**: Must complete within 15 seconds per component
- **Architecture Tests**: Must complete within 30 seconds per architecture
- **Full Test Suite**: Must complete within 10 minutes

## Testing Best Practices

### 1. Real Synthesis Validation
- Always use actual `TerraformSynthesizer` instances
- Never mock synthesis behavior for resource tests
- Validate actual generated Terraform JSON structure
- Test with realistic configuration values

### 2. Comprehensive Coverage  
- Test all documented configuration parameters
- Test error conditions and edge cases
- Validate type safety and attribute validation
- Test override and extension mechanisms

### 3. Environment Testing
- Test environment-specific defaults (dev, staging, production)
- Validate environment-appropriate resource sizing
- Test environment-specific security configurations
- Validate cost implications across environments

### 4. Integration Validation
- Test resource reference passing
- Validate component composition patterns
- Test architecture-to-architecture integration
- Verify dependency ordering in generated configurations

### 5. Performance and Scalability
- Test with realistic resource counts
- Validate synthesis performance with complex architectures
- Test memory usage with large configurations
- Validate concurrent synthesis operations

This testing framework ensures that every resource function, component, and architecture in Pangea is thoroughly validated with real synthesis testing, providing confidence that all generated Terraform configurations are production-ready and correctly structured.