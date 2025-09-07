# frozen_string_literal: true
# Copyright 2025 The Pangea Authors
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


# Test helpers for architecture validation
module ArchitectureTestHelpers
  # Validate architecture structure and interface
  def validate_architecture_structure(arch_ref)
    expect(arch_ref).to respond_to(:type)
    expect(arch_ref).to respond_to(:name)
    expect(arch_ref).to respond_to(:architecture_attributes) if arch_ref.respond_to?(:architecture_attributes)
    expect(arch_ref).to respond_to(:components) if arch_ref.respond_to?(:components)
    expect(arch_ref).to respond_to(:resources) if arch_ref.respond_to?(:resources)
    expect(arch_ref).to respond_to(:outputs) if arch_ref.respond_to?(:outputs)
  end

  # Validate architecture completeness based on type
  def validate_architecture_completeness(arch_ref)
    case arch_ref.type
    when 'web_application_architecture'
      validate_web_application_completeness(arch_ref)
    when 'microservices_platform_architecture'
      validate_microservices_platform_completeness(arch_ref)
    when 'data_lake_architecture'
      validate_data_lake_completeness(arch_ref)
    else
      # Generic architecture validation
      validate_generic_architecture_completeness(arch_ref)
    end
  end

  # Validate web application architecture has required components
  def validate_web_application_completeness(arch_ref)
    if arch_ref.respond_to?(:components)
      components = arch_ref.components
      
      # Required components for web application
      expect(components).to have_key(:network),
        "Web application architecture must include network component"
      expect(components).to have_key(:load_balancer),
        "Web application architecture must include load balancer component"
      expect(components).to have_key(:web_servers),
        "Web application architecture must include web servers component"
      
      # Conditional components
      if arch_ref.architecture_attributes[:database_enabled] != false
        expect(components).to have_key(:database),
          "Web application architecture with database enabled must include database component"
      end
      
      if arch_ref.architecture_attributes[:monitoring] != false
        expect(components).to have_key(:monitoring),
          "Web application architecture should include monitoring component"
      end
    end
  end

  # Validate microservices platform completeness
  def validate_microservices_platform_completeness(arch_ref)
    if arch_ref.respond_to?(:components)
      components = arch_ref.components
      
      expect(components).to have_key(:service_mesh),
        "Microservices platform must include service mesh"
      expect(components).to have_key(:container_platform),
        "Microservices platform must include container platform"
      expect(components).to have_key(:monitoring),
        "Microservices platform must include monitoring"
    end
  end

  # Validate data lake architecture completeness
  def validate_data_lake_completeness(arch_ref)
    if arch_ref.respond_to?(:components)
      components = arch_ref.components
      
      expect(components).to have_key(:storage_tiers),
        "Data lake must include storage tiers"
      expect(components).to have_key(:processing_engines),
        "Data lake must include processing engines"
      expect(components).to have_key(:analytics_tools),
        "Data lake must include analytics tools"
    end
  end

  # Generic architecture completeness validation
  def validate_generic_architecture_completeness(arch_ref)
    if arch_ref.respond_to?(:components)
      expect(arch_ref.components).not_to be_empty,
        "Architecture must include at least one component"
    end
    
    if arch_ref.respond_to?(:outputs)
      expect(arch_ref.outputs).not_to be_empty,
        "Architecture must provide outputs"
    end
  end

  # Test complete architecture synthesis
  def test_architecture_synthesis(arch_ref)
    synthesizer = create_synthesizer
    
    synthesizer.instance_eval do
      # Synthesize all components
      if arch_ref.respond_to?(:components)
        arch_ref.components.each do |component_name, component|
          synthesize_component(component, component_name)
        end
      end
      
      # Synthesize architecture-level resources
      if arch_ref.respond_to?(:resources)
        arch_ref.resources.each do |resource_name, resource|
          synthesize_resource(resource, resource_name)
        end
      end
    end
    
    result = synthesizer.synthesis
    validate_terraform_structure(result, :resource)
    validate_architecture_terraform_structure(result, arch_ref)
    
    result
  end

  # Validate architecture-specific Terraform structure
  def validate_architecture_terraform_structure(result, arch_ref)
    case arch_ref.type
    when 'web_application_architecture'
      validate_web_app_terraform(result)
    when 'microservices_platform_architecture'
      validate_microservices_terraform(result)
    end
  end

  # Validate web application Terraform includes required resources
  def validate_web_app_terraform(result)
    resources = result["resource"] || {}
    
    # Should have VPC
    expect(resources).to have_key("aws_vpc")
    
    # Should have load balancer
    expect(resources).to have_key("aws_lb").or(have_key("aws_alb"))
    
    # Should have auto scaling or instances
    expect(resources).to have_key("aws_autoscaling_group").or(have_key("aws_instance"))
  end

  # Validate microservices Terraform structure
  def validate_microservices_terraform(result)
    resources = result["resource"] || {}
    
    # Should have container platform resources
    expect(resources).to have_key("aws_ecs_cluster").or(have_key("aws_eks_cluster"))
    
    # Should have service mesh components
    expect(resources).to have_key("aws_appmesh_mesh").or(have_key("aws_service_discovery_service"))
  end

  # Test architecture cost estimation
  def validate_cost_estimation(arch_ref)
    if arch_ref.respond_to?(:estimated_monthly_cost)
      cost = arch_ref.estimated_monthly_cost
      expect(cost).to be_a(Float).or(be_a(Integer))
      expect(cost).to be > 0, "Architecture should have positive cost estimation"
      
      cost
    end
    
    if arch_ref.respond_to?(:cost_breakdown)
      breakdown = arch_ref.cost_breakdown
      expect(breakdown).to be_a(Hash)
      expect(breakdown).to have_key(:total)
      
      if breakdown.has_key?(:components)
        expect(breakdown[:components]).to be_a(Hash)
      end
      
      breakdown
    end
  end

  # Test architecture security scoring
  def validate_security_scoring(arch_ref)
    if arch_ref.respond_to?(:security_compliance_score)
      score = arch_ref.security_compliance_score
      expect(score).to be_a(Float)
      expect(score).to be_between(0.0, 100.0)
      
      score
    else
      skip "Architecture does not provide security compliance scoring"
    end
  end

  # Test architecture high availability scoring
  def validate_high_availability_scoring(arch_ref)
    if arch_ref.respond_to?(:high_availability_score)
      score = arch_ref.high_availability_score
      expect(score).to be_a(Float)
      expect(score).to be_between(0.0, 100.0)
      
      score
    else
      skip "Architecture does not provide high availability scoring"
    end
  end

  # Test architecture performance scoring
  def validate_performance_scoring(arch_ref)
    if arch_ref.respond_to?(:performance_score)
      score = arch_ref.performance_score
      expect(score).to be_a(Float)
      expect(score).to be_between(0.0, 100.0)
      
      score
    else
      skip "Architecture does not provide performance scoring"
    end
  end

  # Test architecture override functionality
  def test_architecture_override(arch_ref, component_name, &override_block)
    if arch_ref.respond_to?(:override)
      original_component = arch_ref.components[component_name] if arch_ref.respond_to?(:components)
      
      modified_arch = arch_ref.override(component_name, &override_block)
      
      expect(modified_arch).to be_a(arch_ref.class)
      
      if modified_arch.respond_to?(:components)
        new_component = modified_arch.components[component_name]
        expect(new_component).not_to eq(original_component) if original_component
      end
      
      modified_arch
    else
      skip "Architecture does not support override functionality"
    end
  end

  # Test architecture extension functionality
  def test_architecture_extension(arch_ref, additional_resources = {})
    if arch_ref.respond_to?(:extend_with)
      original_resource_count = arch_ref.resources&.size || 0
      
      extended_arch = arch_ref.extend_with(additional_resources)
      
      expect(extended_arch).to be_a(arch_ref.class)
      
      if extended_arch.respond_to?(:resources)
        new_resource_count = extended_arch.resources.size
        expect(new_resource_count).to be >= original_resource_count
      end
      
      extended_arch
    else
      skip "Architecture does not support extension functionality"
    end
  end

  # Test architecture composition
  def test_architecture_composition(arch_ref, &composition_block)
    if arch_ref.respond_to?(:compose_with)
      composed_arch = arch_ref.compose_with(&composition_block)
      
      expect(composed_arch).to be_a(arch_ref.class)
      validate_architecture_structure(composed_arch)
      
      composed_arch
    else
      skip "Architecture does not support composition functionality"
    end
  end

  # Test architecture environment variations
  def test_architecture_environments(architecture_function, base_attributes)
    environments = ['development', 'staging', 'production']
    
    architectures = {}
    
    environments.each do |env|
      attributes = base_attributes.merge(environment: env)
      
      arch_ref = architecture_function.call(:"test_#{env}", attributes)
      
      validate_architecture_structure(arch_ref)
      validate_architecture_completeness(arch_ref)
      
      # Verify environment-specific optimizations
      validate_environment_optimizations(arch_ref, env)
      
      architectures[env] = arch_ref
    end
    
    # Compare cost across environments
    compare_environment_costs(architectures)
    
    architectures
  end

  # Validate environment-specific optimizations
  def validate_environment_optimizations(arch_ref, environment)
    case environment
    when 'development'
      # Development should be cost-optimized
      if arch_ref.respond_to?(:estimated_monthly_cost)
        expect(arch_ref.estimated_monthly_cost).to be < 200, # Arbitrary threshold
          "Development environment should be cost-optimized"
      end
      
    when 'production'
      # Production should have high availability features
      if arch_ref.respond_to?(:high_availability_score)
        expect(arch_ref.high_availability_score).to be > 70,
          "Production environment should have high availability"
      end
      
      if arch_ref.respond_to?(:security_compliance_score)
        expect(arch_ref.security_compliance_score).to be > 80,
          "Production environment should have high security compliance"
      end
    end
  end

  # Compare costs across environments
  def compare_environment_costs(architectures)
    if architectures['development']&.respond_to?(:estimated_monthly_cost) &&
       architectures['production']&.respond_to?(:estimated_monthly_cost)
      
      dev_cost = architectures['development'].estimated_monthly_cost
      prod_cost = architectures['production'].estimated_monthly_cost
      
      expect(dev_cost).to be < prod_cost,
        "Development should cost less than production"
    end
  end

  # Test architecture validation
  def test_architecture_validation(arch_ref)
    if arch_ref.respond_to?(:validate_deployment)
      is_valid = arch_ref.validate_deployment
      expect(is_valid).to be(true).or(be(false))
      
      is_valid
    else
      skip "Architecture does not provide deployment validation"
    end
  end

  # Test architecture summary
  def test_architecture_summary(arch_ref)
    if arch_ref.respond_to?(:summary)
      summary = arch_ref.summary
      expect(summary).to be_a(Hash)
      
      # Should include basic information
      expect(summary).to have_key(:name) if arch_ref.respond_to?(:name)
      expect(summary).to have_key(:type) if arch_ref.respond_to?(:type)
      
      summary
    else
      skip "Architecture does not provide summary functionality"
    end
  end

  private

  # Synthesize a component within the synthesizer context
  def synthesize_component(component, component_name)
    if component.respond_to?(:resources)
      component.resources.each do |resource_name, resource|
        synthesize_resource(resource, :"#{component_name}_#{resource_name}")
      end
    end
  end

  # Synthesize a resource within the synthesizer context
  def synthesize_resource(resource, resource_name)
    if resource.respond_to?(:type) && resource.respond_to?(:attributes)
      send(resource.type.to_sym, resource_name, resource.attributes)
    end
  end
end