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
require 'pangea/resources/aws_api_gateway_deployment/resource'
require 'pangea/resources/aws_api_gateway_deployment/types'

RSpec.describe 'aws_api_gateway_deployment resource function' do
  let(:test_class) do
    Class.new do
      include Pangea::Resources::AWS
      
      def initialize
        @resources = []
      end
      
      def resource(type, name)
        resource_data = { type: type, name: name, attributes: {} }
        @resources << resource_data
        yield MockResourceBuilder.new(resource_data[:attributes]) if block_given?
        resource_data
      end
      
      def get_resources
        @resources
      end
    end
  end
  
  let(:mock_resource_builder) do
    Class.new do
      def initialize(attributes)
        @attributes = attributes
      end
      
      def method_missing(method_name, *args)
        if args.any?
          @attributes[method_name] = args.first
        end
        
        if block_given?
          nested_builder = self.class.new({})
          yield nested_builder
          @attributes[method_name] = nested_builder.instance_variable_get(:@attributes)
        end
      end
      
      def respond_to_missing?(method_name, include_private = false)
        true
      end
    end
  end
  
  before do
    stub_const('MockResourceBuilder', mock_resource_builder)
  end

  let(:test_instance) { test_class.new }
  
  describe 'AWS API Gateway Deployment Types::ApiGatewayDeploymentAttributes' do
    describe 'basic attribute validation' do
      it 'creates deployment with required attributes' do
        attrs = Pangea::Resources::AWS::Types::ApiGatewayDeploymentAttributes.new({
          rest_api_id: 'api-123'
        })
        
        expect(attrs.rest_api_id).to eq('api-123')
        expect(attrs.stage_name).to be_nil
        expect(attrs.description).to be_nil
        expect(attrs.variables).to eq({})
        expect(attrs.triggers).to eq({})
      end
      
      it 'applies default values correctly' do
        attrs = Pangea::Resources::AWS::Types::ApiGatewayDeploymentAttributes.new({
          rest_api_id: 'api-123'
        })
        
        expect(attrs.variables).to eq({})
        expect(attrs.triggers).to eq({})
        expect(attrs.canary_settings).to be_nil
        expect(attrs.stage_name).to be_nil
        expect(attrs.description).to be_nil
        expect(attrs.stage_description).to be_nil
      end
      
      it 'creates deployment with stage' do
        attrs = Pangea::Resources::AWS::Types::ApiGatewayDeploymentAttributes.new({
          rest_api_id: 'api-123',
          stage_name: 'production',
          stage_description: 'Production stage',
          description: 'Production deployment'
        })
        
        expect(attrs.stage_name).to eq('production')
        expect(attrs.stage_description).to eq('Production stage')
        expect(attrs.description).to eq('Production deployment')
        expect(attrs.creates_stage?).to be true
      end
      
      it 'creates deployment with variables' do
        attrs = Pangea::Resources::AWS::Types::ApiGatewayDeploymentAttributes.new({
          rest_api_id: 'api-123',
          stage_name: 'production',
          variables: {
            'environment' => 'prod',
            'log_level' => 'ERROR',
            'cache_ttl' => '300'
          }
        })
        
        expect(attrs.variables).to have_key('environment')
        expect(attrs.variables['environment']).to eq('prod')
        expect(attrs.has_stage_variables?).to be true
      end
      
      it 'creates deployment with triggers' do
        attrs = Pangea::Resources::AWS::Types::ApiGatewayDeploymentAttributes.new({
          rest_api_id: 'api-123',
          triggers: {
            'methods' => '${md5(file("methods.tf"))}',
            'integrations' => '${md5(file("integrations.tf"))}',
            'timestamp' => '${timestamp()}'
          }
        })
        
        expect(attrs.triggers).to have_key('methods')
        expect(attrs.triggers).to have_key('integrations')
        expect(attrs.triggers).to have_key('timestamp')
      end
    end
    
    describe 'canary deployment validation' do
      it 'creates canary deployment with valid settings' do
        attrs = Pangea::Resources::AWS::Types::ApiGatewayDeploymentAttributes.new({
          rest_api_id: 'api-123',
          stage_name: 'production',
          canary_settings: {
            percent_traffic: 25.0,
            stage_variable_overrides: {
              'version' => 'canary'
            },
            use_stage_cache: false
          }
        })
        
        expect(attrs.has_canary?).to be true
        expect(attrs.canary_percentage).to eq(25.0)
        expect(attrs.canary_settings[:percent_traffic]).to eq(25.0)
        expect(attrs.canary_settings[:stage_variable_overrides]).to have_key('version')
      end
      
      it 'validates canary traffic percentage bounds' do
        expect {
          Pangea::Resources::AWS::Types::ApiGatewayDeploymentAttributes.new({
            rest_api_id: 'api-123',
            stage_name: 'production',
            canary_settings: {
              percent_traffic: -10.0
            }
          })
        }.to raise_error(Dry::Struct::Error, /between 0.0 and 100.0/)
        
        expect {
          Pangea::Resources::AWS::Types::ApiGatewayDeploymentAttributes.new({
            rest_api_id: 'api-123',
            stage_name: 'production',
            canary_settings: {
              percent_traffic: 150.0
            }
          })
        }.to raise_error(Dry::Struct::Error, /between 0.0 and 100.0/)
      end
      
      it 'validates canary stage variable overrides type' do
        expect {
          Pangea::Resources::AWS::Types::ApiGatewayDeploymentAttributes.new({
            rest_api_id: 'api-123',
            stage_name: 'production',
            canary_settings: {
              percent_traffic: 25.0,
              stage_variable_overrides: 'invalid'
            }
          })
        }.to raise_error(Dry::Struct::Error, /must be a hash/)
      end
      
      it 'validates canary use_stage_cache type' do
        expect {
          Pangea::Resources::AWS::Types::ApiGatewayDeploymentAttributes.new({
            rest_api_id: 'api-123',
            stage_name: 'production',
            canary_settings: {
              percent_traffic: 25.0,
              use_stage_cache: 'invalid'
            }
          })
        }.to raise_error(Dry::Struct::Error, /must be a boolean/)
      end
    end
    
    describe 'stage name validation' do
      it 'accepts valid stage names' do
        valid_names = ['prod', 'production', 'dev', 'staging', 'qa_v2', 'beta_123']
        
        valid_names.each do |name|
          expect {
            Pangea::Resources::AWS::Types::ApiGatewayDeploymentAttributes.new({
              rest_api_id: 'api-123',
              stage_name: name
            })
          }.not_to raise_error
        end
      end
      
      it 'rejects stage names with invalid characters' do
        invalid_names = ['prod-1', 'stage!', 'test@dev', 'stage.name']
        
        invalid_names.each do |name|
          expect {
            Pangea::Resources::AWS::Types::ApiGatewayDeploymentAttributes.new({
              rest_api_id: 'api-123',
              stage_name: name
            })
          }.to raise_error(Dry::Struct::Error, /alphanumeric characters and underscores/)
        end
      end
      
      it 'rejects reserved stage names' do
        expect {
          Pangea::Resources::AWS::Types::ApiGatewayDeploymentAttributes.new({
            rest_api_id: 'api-123',
            stage_name: 'test'
          })
        }.to raise_error(Dry::Struct::Error, /reserved by API Gateway/)
      end
    end
    
    describe 'stage variable validation' do
      it 'accepts valid variable names' do
        attrs = Pangea::Resources::AWS::Types::ApiGatewayDeploymentAttributes.new({
          rest_api_id: 'api-123',
          variables: {
            'env' => 'prod',
            'log_level' => 'ERROR',
            'feature_flag_123' => 'true',
            'backend_url' => 'https://api.example.com'
          }
        })
        
        expect(attrs.variables).to have_key('env')
        expect(attrs.variables).to have_key('log_level')
        expect(attrs.variables).to have_key('feature_flag_123')
      end
      
      it 'rejects variable names with invalid characters' do
        expect {
          Pangea::Resources::AWS::Types::ApiGatewayDeploymentAttributes.new({
            rest_api_id: 'api-123',
            variables: {
              'invalid-name' => 'value'
            }
          })
        }.to raise_error(Dry::Struct::Error, /alphanumeric characters and underscores/)
      end
    end
    
    describe 'computed properties' do
      it 'detects stage creation correctly' do
        without_stage = Pangea::Resources::AWS::Types::ApiGatewayDeploymentAttributes.new({
          rest_api_id: 'api-123'
        })
        
        with_stage = Pangea::Resources::AWS::Types::ApiGatewayDeploymentAttributes.new({
          rest_api_id: 'api-123',
          stage_name: 'production'
        })
        
        expect(without_stage.creates_stage?).to be false
        expect(with_stage.creates_stage?).to be true
      end
      
      it 'detects canary deployment correctly' do
        standard = Pangea::Resources::AWS::Types::ApiGatewayDeploymentAttributes.new({
          rest_api_id: 'api-123'
        })
        
        zero_canary = Pangea::Resources::AWS::Types::ApiGatewayDeploymentAttributes.new({
          rest_api_id: 'api-123',
          canary_settings: {
            percent_traffic: 0.0
          }
        })
        
        active_canary = Pangea::Resources::AWS::Types::ApiGatewayDeploymentAttributes.new({
          rest_api_id: 'api-123',
          canary_settings: {
            percent_traffic: 25.0
          }
        })
        
        expect(standard.has_canary?).to be false
        expect(zero_canary.has_canary?).to be false
        expect(active_canary.has_canary?).to be true
        expect(active_canary.canary_percentage).to eq(25.0)
      end
      
      it 'detects stage variables correctly' do
        without_vars = Pangea::Resources::AWS::Types::ApiGatewayDeploymentAttributes.new({
          rest_api_id: 'api-123'
        })
        
        with_vars = Pangea::Resources::AWS::Types::ApiGatewayDeploymentAttributes.new({
          rest_api_id: 'api-123',
          variables: {
            'env' => 'prod'
          }
        })
        
        expect(without_vars.has_stage_variables?).to be false
        expect(with_vars.has_stage_variables?).to be true
      end
    end
    
    describe 'helper methods' do
      it 'provides common stage names' do
        stage_names = Pangea::Resources::AWS::Types::ApiGatewayDeploymentAttributes.common_stage_names
        
        expect(stage_names).to have_key(:development)
        expect(stage_names).to have_key(:staging)
        expect(stage_names).to have_key(:production)
        expect(stage_names[:production]).to eq('prod')
      end
      
      it 'provides common stage variables' do
        variables = Pangea::Resources::AWS::Types::ApiGatewayDeploymentAttributes.common_stage_variables
        
        expect(variables).to have_key(:environment)
        expect(variables).to have_key(:lambda_alias)
        expect(variables).to have_key(:debug_mode)
      end
      
      it 'provides common triggers' do
        triggers = Pangea::Resources::AWS::Types::ApiGatewayDeploymentAttributes.common_triggers
        
        expect(triggers).to have_key(:methods)
        expect(triggers).to have_key(:integrations)
        expect(triggers).to have_key(:timestamp)
      end
      
      it 'builds description with metadata' do
        attrs = Pangea::Resources::AWS::Types::ApiGatewayDeploymentAttributes.new({
          rest_api_id: 'api-123',
          description: 'Base deployment'
        })
        
        description = attrs.build_description_with_metadata({
          'version' => '1.2.3',
          'commit' => 'abc123'
        })
        
        expect(description).to include('Base deployment')
        expect(description).to include('version: 1.2.3')
        expect(description).to include('commit: abc123')
      end
    end
  end
  
  describe 'aws_api_gateway_deployment resource function' do
    it 'creates basic deployment resource' do
      result = test_instance.aws_api_gateway_deployment(:basic_deployment, {
        rest_api_id: 'api-123',
        description: 'Basic deployment'
      })
      
      expect(result).to be_a(Pangea::Resources::ResourceReference)
      expect(result.type).to eq('aws_api_gateway_deployment')
      expect(result.name).to eq(:basic_deployment)
      
      resources = test_instance.get_resources
      expect(resources.size).to eq(1)
      
      resource_data = resources.first
      expect(resource_data[:type]).to eq(:aws_api_gateway_deployment)
      expect(resource_data[:name]).to eq(:basic_deployment)
      expect(resource_data[:attributes][:rest_api_id]).to eq('api-123')
      expect(resource_data[:attributes][:description]).to eq('Basic deployment')
    end
    
    it 'creates deployment with stage' do
      result = test_instance.aws_api_gateway_deployment(:stage_deployment, {
        rest_api_id: 'api-123',
        stage_name: 'production',
        stage_description: 'Production stage',
        description: 'Production deployment'
      })
      
      expect(result.creates_stage?).to be true
      
      resources = test_instance.get_resources
      resource_data = resources.first
      expect(resource_data[:attributes][:stage_name]).to eq('production')
      expect(resource_data[:attributes][:stage_description]).to eq('Production stage')
    end
    
    it 'creates deployment with variables' do
      result = test_instance.aws_api_gateway_deployment(:var_deployment, {
        rest_api_id: 'api-123',
        stage_name: 'production',
        variables: {
          'environment' => 'prod',
          'log_level' => 'ERROR'
        }
      })
      
      expect(result.has_stage_variables?).to be true
      
      resources = test_instance.get_resources
      resource_data = resources.first
      expect(resource_data[:attributes][:variables]).to have_key('environment')
      expect(resource_data[:attributes][:variables]).to have_key('log_level')
    end
    
    it 'creates canary deployment' do
      result = test_instance.aws_api_gateway_deployment(:canary_deployment, {
        rest_api_id: 'api-123',
        stage_name: 'production',
        canary_settings: {
          percent_traffic: 25.0,
          stage_variable_overrides: {
            'version' => 'canary'
          },
          use_stage_cache: false
        }
      })
      
      expect(result.has_canary?).to be true
      expect(result.canary_percentage).to eq(25.0)
      expect(result.deployment_type).to eq('canary')
      
      canary_config = result.canary_configuration
      expect(canary_config[:enabled]).to be true
      expect(canary_config[:percent_traffic]).to eq(25.0)
      expect(canary_config[:variable_overrides]).to have_key('version')
    end
    
    it 'creates blue-green deployment' do
      result = test_instance.aws_api_gateway_deployment(:blue_green, {
        rest_api_id: 'api-123',
        stage_name: 'production',
        canary_settings: {
          percent_traffic: 100.0,
          stage_variable_overrides: {
            'version' => 'new'
          }
        }
      })
      
      expect(result.has_canary?).to be true
      expect(result.canary_percentage).to eq(100.0)
      expect(result.deployment_type).to eq('blue_green')
    end
    
    it 'creates deployment with triggers' do
      result = test_instance.aws_api_gateway_deployment(:triggered_deployment, {
        rest_api_id: 'api-123',
        triggers: {
          'methods' => '${md5(file("methods.tf"))}',
          'integrations' => '${md5(file("integrations.tf"))}'
        }
      })
      
      trigger_names = result.trigger_names
      expect(trigger_names).to include('methods')
      expect(trigger_names).to include('integrations')
      
      resources = test_instance.get_resources
      resource_data = resources.first
      expect(resource_data[:attributes][:triggers]).to have_key('methods')
      expect(resource_data[:attributes][:triggers]).to have_key('integrations')
    end
    
    it 'provides comprehensive computed properties' do
      result = test_instance.aws_api_gateway_deployment(:comprehensive, {
        rest_api_id: 'api-123',
        stage_name: 'production',
        description: 'Production deployment',
        variables: {
          'env' => 'prod',
          'debug' => 'false'
        },
        canary_settings: {
          percent_traffic: 10.0
        }
      })
      
      # Test all computed properties
      expect(result.creates_stage?).to be true
      expect(result.has_canary?).to be true
      expect(result.has_stage_variables?).to be true
      expect(result.canary_percentage).to eq(10.0)
      expect(result.deployment_type).to eq('canary')
      
      # Test stage configuration
      stage_config = result.stage_configuration
      expect(stage_config[:name]).to eq('production')
      expect(stage_config[:variables]).to have_key('env')
      expect(stage_config[:canary][:enabled]).to be true
      
      # Test deployment metadata
      metadata = result.deployment_metadata
      expect(metadata[:type]).to eq('canary')
      expect(metadata[:creates_stage]).to be true
      expect(metadata[:has_canary]).to be true
      expect(metadata[:variable_count]).to eq(2)
      
      # Test variable and trigger names
      expect(result.variable_names).to include('env')
      expect(result.variable_names).to include('debug')
      
      # Test environment detection
      expect(result.is_production_deployment?).to be true
      expect(result.is_development_deployment?).to be false
    end
    
    it 'detects environment types correctly' do
      prod_result = test_instance.aws_api_gateway_deployment(:prod, {
        rest_api_id: 'api-123',
        stage_name: 'production'
      })
      
      dev_result = test_instance.aws_api_gateway_deployment(:dev, {
        rest_api_id: 'api-123',
        stage_name: 'development'
      })
      
      expect(prod_result.is_production_deployment?).to be true
      expect(prod_result.is_development_deployment?).to be false
      
      expect(dev_result.is_production_deployment?).to be false
      expect(dev_result.is_development_deployment?).to be true
    end
    
    it 'provides correct stage URL for deployments with stages' do
      with_stage = test_instance.aws_api_gateway_deployment(:with_stage, {
        rest_api_id: 'api-123',
        stage_name: 'production'
      })
      
      without_stage = test_instance.aws_api_gateway_deployment(:without_stage, {
        rest_api_id: 'api-123'
      })
      
      expect(with_stage.stage_url).to include('${aws_api_gateway_deployment.with_stage.invoke_url}')
      expect(without_stage.stage_url).to be_nil
    end
    
    it 'has comprehensive outputs' do
      result = test_instance.aws_api_gateway_deployment(:output_test, {
        rest_api_id: 'api-123'
      })
      
      expected_outputs = [
        :id, :rest_api_id, :stage_name, :stage_description,
        :description, :variables, :canary_settings, :triggers,
        :invoke_url, :execution_arn, :created_date
      ]
      
      expected_outputs.each do |output|
        expect(result.outputs).to have_key(output)
      end
    end
    
    it 'includes lifecycle management in terraform' do
      result = test_instance.aws_api_gateway_deployment(:lifecycle_test, {
        rest_api_id: 'api-123'
      })
      
      resources = test_instance.get_resources
      resource_data = resources.first
      expect(resource_data[:attributes][:lifecycle][:create_before_destroy]).to be true
    end
  end
end