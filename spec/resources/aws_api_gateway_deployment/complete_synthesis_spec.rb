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


require 'spec_helper'
require 'json'

# Mock TerraformSynthesizer for testing
class MockTerraformSynthesizer
  def initialize
    @resources = {}
    @data_sources = {}
    @variables = {}
    @outputs = {}
  end

  def resource(type, name)
    @resources["#{type}.#{name}"] = { type: type, name: name, attributes: {} }
    resource_builder = MockResourceBuilder.new(@resources["#{type}.#{name}"][:attributes])
    yield resource_builder if block_given?
  end
  
  def data(type, name)
    @data_sources["#{type}.#{name}"] = { type: type, name: name, attributes: {} }
    data_builder = MockResourceBuilder.new(@data_sources["#{type}.#{name}"][:attributes])
    yield data_builder if block_given?
  end
  
  def variable(name)
    @variables[name.to_s] = { name: name, attributes: {} }
    variable_builder = MockResourceBuilder.new(@variables[name.to_s][:attributes])
    yield variable_builder if block_given?
  end
  
  def output(name)
    @outputs[name.to_s] = { name: name, attributes: {} }
    output_builder = MockResourceBuilder.new(@outputs[name.to_s][:attributes])
    yield output_builder if block_given?
  end

  def synthesis
    result = {}
    
    if @resources.any?
      result["resource"] = {}
      @resources.each do |key, resource_data|
        type = resource_data[:type].to_s
        name = resource_data[:name].to_s
        result["resource"][type] ||= {}
        result["resource"][type][name] = resource_data[:attributes]
      end
    end
    
    if @data_sources.any?
      result["data"] = {}
      @data_sources.each do |key, data_source|
        type = data_source[:type].to_s
        name = data_source[:name].to_s
        result["data"][type] ||= {}
        result["data"][type][name] = data_source[:attributes]
      end
    end
    
    if @variables.any?
      result["variable"] = {}
      @variables.each do |key, variable|
        name = variable[:name].to_s
        result["variable"][name] = variable[:attributes]
      end
    end
    
    if @outputs.any?
      result["output"] = {}
      @outputs.each do |key, output|
        name = output[:name].to_s
        result["output"][name] = output[:attributes]
      end
    end
    
    result
  end
  
  def get_resources
    @resources
  end
end

class MockResourceBuilder
  def initialize(attributes)
    @attributes = attributes
  end
  
  def method_missing(method_name, *args)
    if args.any?
      @attributes[method_name.to_s] = args.first
    else
      if block_given?
        nested_builder = self.class.new({})
        yield nested_builder
        @attributes[method_name.to_s] = nested_builder.instance_variable_get(:@attributes)
      end
    end
  end
  
  def respond_to_missing?(method_name, include_private = false)
    true
  end
end

RSpec.describe 'aws_api_gateway_deployment synthesis' do
  include Pangea::Resources::AWS
  
  let(:synthesizer) { MockTerraformSynthesizer.new }

  before do
    # Stub the TerraformSynthesizer constant to use our mock
    stub_const('TerraformSynthesizer', MockTerraformSynthesizer)
  end

  describe 'basic synthesis' do
    it 'synthesizes basic deployment correctly' do
      synthesizer.instance_eval do
        aws_api_gateway_deployment(:basic, {
          rest_api_id: 'api-abc123',
          description: 'Basic deployment'
        })
      end

      result = synthesizer.synthesis
      
      expect(result).to have_key("resource")
      expect(result["resource"]).to have_key("aws_api_gateway_deployment")
      expect(result["resource"]["aws_api_gateway_deployment"]).to have_key("basic")
      
      deployment = result["resource"]["aws_api_gateway_deployment"]["basic"]
      expect(deployment["rest_api_id"]).to eq('api-abc123')
      expect(deployment["description"]).to eq('Basic deployment')
      expect(deployment["lifecycle"]["create_before_destroy"]).to be true
    end

    it 'synthesizes deployment with stage correctly' do
      synthesizer.instance_eval do
        aws_api_gateway_deployment(:with_stage, {
          rest_api_id: 'api-abc123',
          stage_name: 'production',
          stage_description: 'Production stage',
          description: 'Production deployment'
        })
      end

      result = synthesizer.synthesis
      deployment = result["resource"]["aws_api_gateway_deployment"]["with_stage"]
      
      expect(deployment["rest_api_id"]).to eq('api-abc123')
      expect(deployment["stage_name"]).to eq('production')
      expect(deployment["stage_description"]).to eq('Production stage')
      expect(deployment["description"]).to eq('Production deployment')
    end

    it 'synthesizes deployment with variables correctly' do
      synthesizer.instance_eval do
        aws_api_gateway_deployment(:with_vars, {
          rest_api_id: 'api-abc123',
          stage_name: 'production',
          variables: {
            'environment' => 'prod',
            'log_level' => 'ERROR',
            'debug_mode' => 'false'
          }
        })
      end

      result = synthesizer.synthesis
      deployment = result["resource"]["aws_api_gateway_deployment"]["with_vars"]
      
      expect(deployment["variables"]).to have_key('environment')
      expect(deployment["variables"]["environment"]).to eq('prod')
      expect(deployment["variables"]["log_level"]).to eq('ERROR')
      expect(deployment["variables"]["debug_mode"]).to eq('false')
    end

    it 'synthesizes deployment with triggers correctly' do
      synthesizer.instance_eval do
        aws_api_gateway_deployment(:with_triggers, {
          rest_api_id: 'api-abc123',
          triggers: {
            'methods' => '${md5(file("methods.tf"))}',
            'integrations' => '${md5(file("integrations.tf"))}',
            'timestamp' => '${timestamp()}'
          }
        })
      end

      result = synthesizer.synthesis
      deployment = result["resource"]["aws_api_gateway_deployment"]["with_triggers"]
      
      expect(deployment["triggers"]).to have_key('methods')
      expect(deployment["triggers"]["methods"]).to eq('${md5(file("methods.tf"))}')
      expect(deployment["triggers"]["integrations"]).to eq('${md5(file("integrations.tf"))}')
      expect(deployment["triggers"]["timestamp"]).to eq('${timestamp()}')
    end
  end

  describe 'canary deployment synthesis' do
    it 'synthesizes basic canary deployment correctly' do
      synthesizer.instance_eval do
        aws_api_gateway_deployment(:canary_basic, {
          rest_api_id: 'api-abc123',
          stage_name: 'production',
          canary_settings: {
            percent_traffic: 25.0
          }
        })
      end

      result = synthesizer.synthesis
      deployment = result["resource"]["aws_api_gateway_deployment"]["canary_basic"]
      
      expect(deployment["canary_settings"]).to have_key("percent_traffic")
      expect(deployment["canary_settings"]["percent_traffic"]).to eq(25.0)
    end

    it 'synthesizes canary deployment with variable overrides correctly' do
      synthesizer.instance_eval do
        aws_api_gateway_deployment(:canary_overrides, {
          rest_api_id: 'api-abc123',
          stage_name: 'production',
          canary_settings: {
            percent_traffic: 10.0,
            stage_variable_overrides: {
              'version' => 'canary',
              'feature_flag' => 'true'
            }
          }
        })
      end

      result = synthesizer.synthesis
      deployment = result["resource"]["aws_api_gateway_deployment"]["canary_overrides"]
      
      expect(deployment["canary_settings"]["percent_traffic"]).to eq(10.0)
      expect(deployment["canary_settings"]["stage_variable_overrides"]).to have_key('version')
      expect(deployment["canary_settings"]["stage_variable_overrides"]["version"]).to eq('canary')
      expect(deployment["canary_settings"]["stage_variable_overrides"]["feature_flag"]).to eq('true')
    end

    it 'synthesizes canary deployment with cache settings correctly' do
      synthesizer.instance_eval do
        aws_api_gateway_deployment(:canary_cache, {
          rest_api_id: 'api-abc123',
          stage_name: 'production',
          canary_settings: {
            percent_traffic: 50.0,
            use_stage_cache: true
          }
        })
      end

      result = synthesizer.synthesis
      deployment = result["resource"]["aws_api_gateway_deployment"]["canary_cache"]
      
      expect(deployment["canary_settings"]["percent_traffic"]).to eq(50.0)
      expect(deployment["canary_settings"]["use_stage_cache"]).to be true
    end

    it 'synthesizes comprehensive canary deployment correctly' do
      synthesizer.instance_eval do
        aws_api_gateway_deployment(:comprehensive_canary, {
          rest_api_id: 'api-abc123',
          stage_name: 'production',
          stage_description: 'Production with canary',
          description: 'Canary deployment for feature testing',
          variables: {
            'environment' => 'prod',
            'base_version' => '1.0.0'
          },
          canary_settings: {
            percent_traffic: 20.0,
            stage_variable_overrides: {
              'canary_version' => '1.1.0',
              'experimental_feature' => 'enabled'
            },
            use_stage_cache: false
          },
          triggers: {
            'api_config' => '${md5(jsonencode(var.api_configuration))}',
            'deployment_time' => '${timestamp()}'
          }
        })
      end

      result = synthesizer.synthesis
      deployment = result["resource"]["aws_api_gateway_deployment"]["comprehensive_canary"]
      
      # Verify all sections are present
      expect(deployment["rest_api_id"]).to eq('api-abc123')
      expect(deployment["stage_name"]).to eq('production')
      expect(deployment["stage_description"]).to eq('Production with canary')
      expect(deployment["description"]).to eq('Canary deployment for feature testing')
      
      # Verify variables
      expect(deployment["variables"]["environment"]).to eq('prod')
      expect(deployment["variables"]["base_version"]).to eq('1.0.0')
      
      # Verify canary settings
      expect(deployment["canary_settings"]["percent_traffic"]).to eq(20.0)
      expect(deployment["canary_settings"]["stage_variable_overrides"]["canary_version"]).to eq('1.1.0')
      expect(deployment["canary_settings"]["stage_variable_overrides"]["experimental_feature"]).to eq('enabled')
      expect(deployment["canary_settings"]["use_stage_cache"]).to be false
      
      # Verify triggers
      expect(deployment["triggers"]["api_config"]).to eq('${md5(jsonencode(var.api_configuration))}')
      expect(deployment["triggers"]["deployment_time"]).to eq('${timestamp()}')
      
      # Verify lifecycle
      expect(deployment["lifecycle"]["create_before_destroy"]).to be true
    end
  end

  describe 'environment-specific deployments' do
    it 'synthesizes development deployment correctly' do
      synthesizer.instance_eval do
        aws_api_gateway_deployment(:development, {
          rest_api_id: 'api-abc123',
          stage_name: 'dev',
          description: 'Development environment deployment',
          variables: {
            'environment' => 'dev',
            'log_level' => 'DEBUG',
            'cache_ttl' => '0'
          }
        })
      end

      result = synthesizer.synthesis
      deployment = result["resource"]["aws_api_gateway_deployment"]["development"]
      
      expect(deployment["stage_name"]).to eq('dev')
      expect(deployment["variables"]["environment"]).to eq('dev')
      expect(deployment["variables"]["log_level"]).to eq('DEBUG')
      expect(deployment["variables"]["cache_ttl"]).to eq('0')
    end

    it 'synthesizes staging deployment correctly' do
      synthesizer.instance_eval do
        aws_api_gateway_deployment(:staging, {
          rest_api_id: 'api-abc123',
          stage_name: 'staging',
          description: 'Staging environment deployment',
          variables: {
            'environment' => 'staging',
            'log_level' => 'INFO',
            'cache_ttl' => '60'
          },
          triggers: {
            'config_hash' => '${md5(file("staging-config.json"))}'
          }
        })
      end

      result = synthesizer.synthesis
      deployment = result["resource"]["aws_api_gateway_deployment"]["staging"]
      
      expect(deployment["stage_name"]).to eq('staging')
      expect(deployment["variables"]["environment"]).to eq('staging')
      expect(deployment["variables"]["log_level"]).to eq('INFO')
      expect(deployment["triggers"]["config_hash"]).to eq('${md5(file("staging-config.json"))}')
    end

    it 'synthesizes production deployment correctly' do
      synthesizer.instance_eval do
        aws_api_gateway_deployment(:production, {
          rest_api_id: 'api-abc123',
          stage_name: 'prod',
          description: 'Production environment deployment',
          variables: {
            'environment' => 'prod',
            'log_level' => 'WARN',
            'cache_ttl' => '300'
          }
        })
      end

      result = synthesizer.synthesis
      deployment = result["resource"]["aws_api_gateway_deployment"]["production"]
      
      expect(deployment["stage_name"]).to eq('prod')
      expect(deployment["variables"]["environment"]).to eq('prod')
      expect(deployment["variables"]["log_level"]).to eq('WARN')
      expect(deployment["variables"]["cache_ttl"]).to eq('300')
    end
  end

  describe 'blue-green deployment synthesis' do
    it 'synthesizes blue-green deployment correctly' do
      synthesizer.instance_eval do
        aws_api_gateway_deployment(:blue_green, {
          rest_api_id: 'api-abc123',
          stage_name: 'production',
          description: 'Blue-green deployment (100% canary)',
          canary_settings: {
            percent_traffic: 100.0,
            stage_variable_overrides: {
              'version' => '2.0.0',
              'migration_complete' => 'true'
            }
          }
        })
      end

      result = synthesizer.synthesis
      deployment = result["resource"]["aws_api_gateway_deployment"]["blue_green"]
      
      expect(deployment["canary_settings"]["percent_traffic"]).to eq(100.0)
      expect(deployment["canary_settings"]["stage_variable_overrides"]["version"]).to eq('2.0.0')
      expect(deployment["canary_settings"]["stage_variable_overrides"]["migration_complete"]).to eq('true')
    end
  end

  describe 'deployment without stage synthesis' do
    it 'synthesizes deployment-only resource correctly' do
      synthesizer.instance_eval do
        aws_api_gateway_deployment(:deployment_only, {
          rest_api_id: 'api-abc123',
          description: 'Deployment snapshot without stage creation'
        })
      end

      result = synthesizer.synthesis
      deployment = result["resource"]["aws_api_gateway_deployment"]["deployment_only"]
      
      expect(deployment["rest_api_id"]).to eq('api-abc123')
      expect(deployment["description"]).to eq('Deployment snapshot without stage creation')
      expect(deployment).not_to have_key("stage_name")
      expect(deployment).not_to have_key("stage_description")
      expect(deployment).not_to have_key("variables")
      expect(deployment).not_to have_key("canary_settings")
    end
  end

  describe 'complex trigger scenarios' do
    it 'synthesizes deployment with complex triggers correctly' do
      synthesizer.instance_eval do
        aws_api_gateway_deployment(:complex_triggers, {
          rest_api_id: 'api-abc123',
          stage_name: 'production',
          triggers: {
            'api_methods' => '${md5(jsonencode([for r in aws_api_gateway_resource.all : r.id]))}',
            'integrations' => '${md5(jsonencode([for i in aws_api_gateway_integration.all : i.id]))}',
            'models' => '${md5(jsonencode(var.api_models))}',
            'git_sha' => '${var.git_commit_sha}',
            'config_version' => '${var.api_config_version}',
            'timestamp' => '${formatdate("YYYY-MM-DD-hhmm", timestamp())}'
          }
        })
      end

      result = synthesizer.synthesis
      deployment = result["resource"]["aws_api_gateway_deployment"]["complex_triggers"]
      
      expect(deployment["triggers"]).to have_key('api_methods')
      expect(deployment["triggers"]).to have_key('integrations')
      expect(deployment["triggers"]).to have_key('models')
      expect(deployment["triggers"]).to have_key('git_sha')
      expect(deployment["triggers"]).to have_key('config_version')
      expect(deployment["triggers"]).to have_key('timestamp')
      
      expect(deployment["triggers"]["git_sha"]).to eq('${var.git_commit_sha}')
      expect(deployment["triggers"]["config_version"]).to eq('${var.api_config_version}')
    end
  end

  describe 'template structure validation' do
    it 'creates valid Terraform JSON structure' do
      synthesizer.instance_eval do
        aws_api_gateway_deployment(:structure_test, {
          rest_api_id: 'api-abc123'
        })
      end

      result = synthesizer.synthesis
      
      # Validate top-level structure
      expect(result).to be_a(Hash)
      expect(result).to have_key("resource")
      
      # Validate resource structure
      expect(result["resource"]).to be_a(Hash)
      expect(result["resource"]).to have_key("aws_api_gateway_deployment")
      
      # Validate resource instance structure  
      expect(result["resource"]["aws_api_gateway_deployment"]).to be_a(Hash)
      expect(result["resource"]["aws_api_gateway_deployment"]).to have_key("structure_test")
      
      # Validate attributes
      deployment = result["resource"]["aws_api_gateway_deployment"]["structure_test"]
      expect(deployment).to be_a(Hash)
      
      # Required attributes should be present
      expect(deployment).to have_key("rest_api_id")
      expect(deployment["rest_api_id"]).to eq('api-abc123')
      
      # Lifecycle should be present
      expect(deployment).to have_key("lifecycle")
      expect(deployment["lifecycle"]).to have_key("create_before_destroy")
      expect(deployment["lifecycle"]["create_before_destroy"]).to be true
    end

    it 'serializes to valid JSON' do
      synthesizer.instance_eval do
        aws_api_gateway_deployment(:json_test, {
          rest_api_id: 'api-abc123',
          stage_name: 'production',
          variables: {
            'complex_config' => '{"nested": {"value": true}, "array": [1, 2, 3]}'
          }
        })
      end

      result = synthesizer.synthesis
      
      # Should be able to serialize to JSON without errors
      expect { JSON.generate(result) }.not_to raise_error
      
      # Verify JSON structure
      json_string = JSON.generate(result)
      parsed_back = JSON.parse(json_string)
      
      expect(parsed_back).to eq(result)
    end
  end

  describe 'multi-deployment scenarios' do
    it 'synthesizes multiple deployments correctly' do
      synthesizer.instance_eval do
        # Development deployment
        aws_api_gateway_deployment(:dev, {
          rest_api_id: 'api-abc123',
          stage_name: 'dev',
          variables: { 'env' => 'dev' }
        })
        
        # Staging deployment
        aws_api_gateway_deployment(:staging, {
          rest_api_id: 'api-abc123',
          stage_name: 'staging',
          variables: { 'env' => 'staging' }
        })
        
        # Production deployment with canary
        aws_api_gateway_deployment(:prod, {
          rest_api_id: 'api-abc123',
          stage_name: 'prod',
          variables: { 'env' => 'prod' },
          canary_settings: {
            percent_traffic: 5.0
          }
        })
      end

      result = synthesizer.synthesis
      deployments = result["resource"]["aws_api_gateway_deployment"]
      
      expect(deployments).to have_key("dev")
      expect(deployments).to have_key("staging") 
      expect(deployments).to have_key("prod")
      
      expect(deployments["dev"]["variables"]["env"]).to eq('dev')
      expect(deployments["staging"]["variables"]["env"]).to eq('staging')
      expect(deployments["prod"]["variables"]["env"]).to eq('prod')
      expect(deployments["prod"]["canary_settings"]["percent_traffic"]).to eq(5.0)
    end
  end
end