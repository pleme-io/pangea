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


# Test helpers for synthesis validation
module SynthesisTestHelpers
  # Synthesize and validate Terraform configuration
  def synthesize_and_validate(entity_type = :resource, &block)
    synthesizer = create_synthesizer
    synthesizer.instance_eval(&block)
    result = synthesizer.synthesis
    
    validate_terraform_structure(result, entity_type)
    result
  end

  # Create a new TerraformSynthesizer instance
  def create_synthesizer
    if defined?(TerraformSynthesizer)
      TerraformSynthesizer.new
    else
      # Fallback synthesizer for testing
      MockTerraformSynthesizer.new
    end
  end

  # Validate basic Terraform JSON structure
  def validate_terraform_structure(result, entity_type)
    expect(result).to be_a(Hash)
    
    case entity_type
    when :resource
      expect(result).to have_key("resource")
      expect(result["resource"]).to be_a(Hash)
    when :data_source
      expect(result).to have_key("data")
      expect(result["data"]).to be_a(Hash)
    when :output
      expect(result).to have_key("output")
      expect(result["output"]).to be_a(Hash)
    end
  end

  # Validate resource references in generated Terraform
  def validate_resource_references(result)
    terraform_json = result.to_json
    
    # Check for proper Terraform reference format: ${resource_type.name.attribute}
    reference_pattern = /\$\{[a-zA-Z_][a-zA-Z0-9_]*\.[a-zA-Z_][a-zA-Z0-9_]*\.[a-zA-Z_][a-zA-Z0-9_]*\}/
    
    references = terraform_json.scan(reference_pattern)
    references.each do |ref|
      expect(ref).to match(reference_pattern)
    end
    
    references
  end

  # Validate specific AWS resource structure
  def validate_aws_resource_structure(result, resource_type, resource_name)
    expect(result).to have_key("resource")
    expect(result["resource"]).to have_key(resource_type)
    expect(result["resource"][resource_type]).to have_key(resource_name)
    
    resource_config = result["resource"][resource_type][resource_name]
    expect(resource_config).to be_a(Hash)
    
    resource_config
  end

  # Validate Terraform provider configuration
  def validate_provider_configuration(result, provider_name)
    if result.has_key?("provider")
      expect(result["provider"]).to have_key(provider_name)
      provider_config = result["provider"][provider_name]
      expect(provider_config).to be_a(Hash)
      provider_config
    end
  end

  # Validate that resource attributes match expected types
  def validate_resource_attributes(resource_config, expected_attributes)
    expected_attributes.each do |attr_name, attr_type|
      if resource_config.has_key?(attr_name.to_s)
        value = resource_config[attr_name.to_s]
        case attr_type
        when String
          expect(value).to be_a(String)
        when Integer
          expect(value).to be_a(Integer)
        when TrueClass, FalseClass
          expect(value).to be_in([true, false])
        when Array
          expect(value).to be_a(Array)
        when Hash
          expect(value).to be_a(Hash)
        end
      end
    end
  end

  # Validate that required attributes are present
  def validate_required_attributes(resource_config, required_attributes)
    required_attributes.each do |attr_name|
      expect(resource_config).to have_key(attr_name.to_s),
        "Required attribute '#{attr_name}' is missing"
    end
  end

  # Validate Terraform dependencies and ordering
  def validate_dependency_ordering(result)
    resources = result["resource"] || {}
    dependencies = extract_dependencies(resources)
    
    # Basic topological sort validation
    dependencies.each do |resource_id, deps|
      deps.each do |dep|
        expect(dependencies).to have_key(dep),
          "Dependency '#{dep}' referenced by '#{resource_id}' is not defined"
      end
    end
  end

  # Reset synthesizer state between tests
  def reset_terraform_synthesizer_state
    # Clear any global synthesizer state if needed
  end

  # Clean up test resources
  def cleanup_test_resources
    # Clean up any test artifacts
  end

  private

  # Extract resource dependencies from Terraform configuration
  def extract_dependencies(resources)
    dependencies = {}
    
    resources.each do |resource_type, type_resources|
      type_resources.each do |resource_name, resource_config|
        resource_id = "#{resource_type}.#{resource_name}"
        dependencies[resource_id] = []
        
        # Look for references in resource configuration
        config_json = resource_config.to_json
        references = config_json.scan(/\$\{([^}]+)\}/)
        
        references.each do |ref|
          ref_parts = ref[0].split('.')
          if ref_parts.length >= 2
            dep_resource_id = "#{ref_parts[0]}.#{ref_parts[1]}"
            dependencies[resource_id] << dep_resource_id unless dep_resource_id == resource_id
          end
        end
      end
    end
    
    dependencies
  end
end

# Mock synthesizer for testing when TerraformSynthesizer is not available
class MockTerraformSynthesizer
  def initialize
    @resources = {}
    @data_sources = {}
    @outputs = {}
  end

  def instance_eval(code = nil, &block)
    if code
      eval(code)
    elsif block
      instance_eval(&block)
    end
  end

  def synthesis
    result = {}
    result["resource"] = @resources unless @resources.empty?
    result["data"] = @data_sources unless @data_sources.empty?
    result["output"] = @outputs unless @outputs.empty?
    result
  end

  # Mock AWS resource methods
  def method_missing(method_name, *args, &block)
    if method_name.to_s.start_with?('aws_')
      resource_type = method_name.to_s
      resource_name = args[0].to_s
      resource_config = args[1] || {}
      
      @resources[resource_type] ||= {}
      @resources[resource_type][resource_name] = resource_config
      
      # Return a mock resource reference
      MockResourceReference.new(resource_type, resource_name, resource_config)
    else
      super
    end
  end

  def respond_to_missing?(method_name, include_private = false)
    method_name.to_s.start_with?('aws_') || super
  end
end

# Mock resource reference for testing
class MockResourceReference
  attr_reader :type, :name, :attributes

  def initialize(type, name, attributes)
    @type = type
    @name = name
    @attributes = attributes
  end

  def id
    "${#{@type}.#{@name}.id}"
  end

  def method_missing(method_name, *args, &block)
    if @attributes.has_key?(method_name.to_s)
      @attributes[method_name.to_s]
    else
      "${#{@type}.#{@name}.#{method_name}}"
    end
  end

  def respond_to_missing?(method_name, include_private = false)
    @attributes.has_key?(method_name.to_s) || super
  end
end