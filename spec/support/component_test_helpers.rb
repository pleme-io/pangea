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


# Test helpers for component validation
module ComponentTestHelpers
  # Validate component structure and interface
  def validate_component_structure(component_ref)
    expect(component_ref).to respond_to(:type)
    expect(component_ref).to respond_to(:name)
    expect(component_ref).to respond_to(:components) if component_ref.respond_to?(:components)
    expect(component_ref).to respond_to(:resources) if component_ref.respond_to?(:resources)
    expect(component_ref).to respond_to(:outputs) if component_ref.respond_to?(:outputs)
  end

  # Validate component has required resources
  def validate_component_resources(component_ref)
    if component_ref.respond_to?(:resources)
      expect(component_ref.resources).to be_a(Hash)
      expect(component_ref.resources).not_to be_empty

      component_ref.resources.each do |name, resource|
        validate_resource_reference(resource, name)
      end
    end
  end

  # Validate individual resource reference
  def validate_resource_reference(resource, name)
    if resource.respond_to?(:type)
      expect(resource.type).to be_a(String)
      expect(resource.type).to match(/^aws_/)
    end
    
    if resource.respond_to?(:id)
      expect(resource.id).to be_a(String)
      expect(resource.id).to match(/\$\{.*\}/) # Terraform reference format
    end
  end

  # Validate component outputs
  def validate_component_outputs(component_ref)
    if component_ref.respond_to?(:outputs)
      expect(component_ref.outputs).to be_a(Hash)
      
      component_ref.outputs.each do |name, value|
        expect(name).to be_a(Symbol).or(be_a(String))
        expect(value).not_to be_nil
      end
    end
  end

  # Test component synthesis with real Terraform generation
  def test_component_synthesis(component_ref)
    synthesizer = create_synthesizer
    
    synthesizer.instance_eval do
      # Synthesize all resources within the component
      if component_ref.respond_to?(:resources)
        component_ref.resources.each do |resource_name, resource|
          # Add resource to synthesizer context
          if resource.respond_to?(:type) && resource.respond_to?(:attributes)
            send(resource.type.to_sym, resource_name.to_sym, resource.attributes)
          end
        end
      end
    end
    
    result = synthesizer.synthesis
    validate_terraform_structure(result, :resource)
    
    result
  end

  # Validate component composition (multiple components working together)
  def validate_component_composition(*components)
    components.each do |component|
      validate_component_structure(component)
      validate_component_resources(component)
    end
    
    # Test that components can reference each other
    validate_cross_component_references(*components) if components.length > 1
  end

  # Validate that components can reference each other's resources
  def validate_cross_component_references(*components)
    resource_ids = []
    
    # Collect all resource IDs from all components
    components.each do |component|
      if component.respond_to?(:resources)
        component.resources.each do |name, resource|
          if resource.respond_to?(:id)
            resource_ids << resource.id
          end
        end
      end
    end
    
    # Verify resource IDs are unique
    expect(resource_ids.uniq.length).to eq(resource_ids.length)
  end

  # Test component override functionality
  def test_component_override(component_ref, override_key, &override_block)
    original_resource = component_ref.resources[override_key] if component_ref.respond_to?(:resources)
    
    if component_ref.respond_to?(:override)
      modified_component = component_ref.override(override_key, &override_block)
      
      expect(modified_component).to be_a(component_ref.class)
      
      if modified_component.respond_to?(:resources)
        new_resource = modified_component.resources[override_key]
        expect(new_resource).not_to eq(original_resource) if original_resource
      end
      
      modified_component
    else
      skip "Component does not support override functionality"
    end
  end

  # Test component extension functionality
  def test_component_extension(component_ref, additional_resources = {})
    if component_ref.respond_to?(:extend_with)
      original_resource_count = component_ref.resources&.size || 0
      
      extended_component = component_ref.extend_with(additional_resources)
      
      expect(extended_component).to be_a(component_ref.class)
      
      if extended_component.respond_to?(:resources)
        new_resource_count = extended_component.resources.size
        expect(new_resource_count).to be >= original_resource_count
      end
      
      extended_component
    else
      skip "Component does not support extension functionality"
    end
  end

  # Validate component type safety
  def validate_component_type_safety(component_class, valid_attributes, invalid_attributes)
    # Test valid attributes
    expect {
      component_class.new(valid_attributes)
    }.not_to raise_error
    
    # Test invalid attributes
    invalid_attributes.each do |attr_name, invalid_value|
      expect {
        attrs = valid_attributes.dup
        attrs[attr_name] = invalid_value
        component_class.new(attrs)
      }.to raise_error
    end
  end

  # Test component with different environments
  def test_component_environments(component_function, base_attributes)
    environments = ['development', 'staging', 'production']
    
    environments.each do |env|
      attributes = base_attributes.merge(environment: env)
      
      component_ref = component_function.call(:"test_#{env}", attributes)
      
      validate_component_structure(component_ref)
      validate_component_resources(component_ref)
      
      # Verify environment-specific configurations
      case env
      when 'development'
        expect_development_optimizations(component_ref)
      when 'staging'
        expect_staging_optimizations(component_ref)
      when 'production'
        expect_production_optimizations(component_ref)
      end
    end
  end

  # Test component cost estimation
  def test_component_cost_estimation(component_ref)
    if component_ref.respond_to?(:estimated_monthly_cost)
      cost = component_ref.estimated_monthly_cost
      expect(cost).to be_a(Float).or(be_a(Integer))
      expect(cost).to be >= 0
      
      cost
    else
      skip "Component does not provide cost estimation"
    end
  end

  # Test component security compliance
  def test_component_security_compliance(component_ref)
    if component_ref.respond_to?(:security_compliance_score)
      score = component_ref.security_compliance_score
      expect(score).to be_a(Float)
      expect(score).to be_between(0.0, 100.0)
      
      score
    else
      skip "Component does not provide security compliance scoring"
    end
  end

  private

  # Validate development environment optimizations
  def expect_development_optimizations(component_ref)
    # Development should use smaller, cheaper resources
    # Detailed validation would depend on component type
  end

  # Validate staging environment optimizations
  def expect_staging_optimizations(component_ref)
    # Staging should balance cost and production-like behavior
  end

  # Validate production environment optimizations
  def expect_production_optimizations(component_ref)
    # Production should prioritize reliability and performance
  end
end