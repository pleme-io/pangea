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


require 'dry-struct'
require 'pangea/resources/types'

module Pangea
  module Resources
    module AWS
      module Types
        # SageMaker Model container image URIs - validates ECR and public registries
        SageMakerModelImage = String.constrained(
          format: /\A(\d{12}\.dkr\.ecr\.[a-z0-9-]+\.amazonaws\.com\/|763104351884\.dkr\.ecr\.[a-z0-9-]+\.amazonaws\.com\/|public\.ecr\.aws\/)/
        )
        
        # SageMaker Model execution role validation
        SageMakerModelExecutionRole = String.constrained(
          format: /\Aarn:aws:iam::\d{12}:role\/[a-zA-Z0-9_+=,.@-]+\z/
        )
        
        # SageMaker Model container definition
        SageMakerModelContainer = Hash.schema(
          image: SageMakerModelImage,
          model_data_url?: String.optional,
          container_hostname?: String.optional,
          environment?: Hash.map(String, String).optional,
          model_package_name?: String.optional,
          inference_specification_name?: String.optional,
          image_config?: Hash.schema(
            repository_access_mode: String.enum('Platform', 'Vpc'),
            repository_auth_config?: Hash.schema(
              repository_credentials_provider_arn: String
            ).optional
          ).optional,
          multi_model_config?: Hash.schema(
            model_cache_setting?: String.enum('Enabled', 'Disabled').optional
          ).optional
        )
        
        # SageMaker Model VPC configuration
        SageMakerModelVpcConfig = Hash.schema(
          security_group_ids: Array.of(String).constrained(min_size: 1, max_size: 5),
          subnets: Array.of(String).constrained(min_size: 1, max_size: 16)
        )
        
        # SageMaker Model inference execution configuration
        SageMakerModelInferenceExecutionConfig = Hash.schema(
          mode: String.enum('Serial', 'Direct')
        )
        
        # SageMaker Model attributes with comprehensive ML model validation
        class SageMakerModelAttributes < Dry::Struct
          transform_keys(&:to_sym)
          
          # Required attributes
          attribute :model_name, Resources::Types::String.constrained(
            min_size: 1,
            max_size: 63,
            format: /\A[a-zA-Z0-9][a-zA-Z0-9\-]*[a-zA-Z0-9]\z/
          )
          attribute :execution_role_arn, SageMakerModelExecutionRole
          
          # Container configuration - either primary_container OR containers (multi-container)
          attribute :primary_container, SageMakerModelContainer.optional
          attribute :containers, Resources::Types::Array.of(SageMakerModelContainer).optional
          
          # Optional attributes
          attribute :vpc_config, SageMakerModelVpcConfig.optional
          attribute :enable_network_isolation, Resources::Types::Bool.default(false)
          attribute :inference_execution_config, SageMakerModelInferenceExecutionConfig.optional
          attribute :tags, Resources::Types::AwsTags
          
          # Custom validation for SageMaker Model
          def self.new(attributes)
            attrs = attributes.is_a?(Hash) ? attributes : {}
            
            # Validate model name uniqueness requirements
            if attrs[:model_name]
              reserved_prefixes = ['aws', 'sagemaker', 'amazon']
              if reserved_prefixes.any? { |prefix| attrs[:model_name].downcase.start_with?(prefix) }
                raise Dry::Struct::Error, "Model name cannot start with reserved prefixes: #{reserved_prefixes.join(', ')}"
              end
            end
            
            # Validate container configuration - must have either primary_container OR containers
            primary_container = attrs[:primary_container]
            containers = attrs[:containers]
            
            if primary_container && containers
              raise Dry::Struct::Error, "Cannot specify both primary_container and containers. Use containers for multi-container models."
            end
            
            if !primary_container && (!containers || containers.empty?)
              raise Dry::Struct::Error, "Must specify either primary_container (single container) or containers (multi-container)"
            end
            
            # Validate multi-container configuration
            if containers && containers.size > 1
              # Validate container hostnames are unique
              hostnames = containers.filter_map { |c| c[:container_hostname] }
              if hostnames.size != containers.size
                raise Dry::Struct::Error, "All containers in multi-container model must have unique container_hostname"
              end
              
              if hostnames.uniq.size != hostnames.size
                raise Dry::Struct::Error, "Container hostnames must be unique across all containers"
              end
            end
            
            # Validate container configuration details
            all_containers = []
            all_containers << primary_container if primary_container
            all_containers.concat(containers || [])
            
            all_containers.each_with_index do |container, index|
              validate_container_config(container, index)
            end
            
            # Validate VPC configuration if network isolation is enabled
            if attrs[:enable_network_isolation] && attrs[:vpc_config]
              raise Dry::Struct::Error, "vpc_config cannot be specified when enable_network_isolation is true"
            end
            
            # Validate inference execution mode for multi-container models
            if containers && containers.size > 1 && attrs[:inference_execution_config]
              execution_mode = attrs[:inference_execution_config][:mode]
              if execution_mode == 'Serial' && containers.size > 5
                raise Dry::Struct::Error, "Serial inference execution mode supports maximum 5 containers"
              end
            end
            
            super(attrs)
          end
          
          # Validate individual container configuration
          def self.validate_container_config(container, index)
            # Validate model data URL format
            if container[:model_data_url]
              unless container[:model_data_url] =~ /\As3:\/\/[a-z0-9][a-z0-9\-\.]{1,61}[a-z0-9]\//
                raise Dry::Struct::Error, "Container #{index}: model_data_url must be a valid S3 URL"
              end
            end
            
            # Validate environment variables
            if container[:environment]
              container[:environment].each do |key, value|
                unless key =~ /\A[a-zA-Z_][a-zA-Z0-9_]*\z/
                  raise Dry::Struct::Error, "Container #{index}: Invalid environment variable name '#{key}'"
                end
                
                if value.length > 2048
                  raise Dry::Struct::Error, "Container #{index}: Environment variable '#{key}' value exceeds 2048 characters"
                end
              end
            end
            
            # Validate model package configuration
            if container[:model_package_name] && container[:model_data_url]
              raise Dry::Struct::Error, "Container #{index}: Cannot specify both model_package_name and model_data_url"
            end
            
            # Validate container hostname format
            if container[:container_hostname]
              unless container[:container_hostname] =~ /\A[a-zA-Z0-9][a-zA-Z0-9\-]*[a-zA-Z0-9]\z/
                raise Dry::Struct::Error, "Container #{index}: Invalid container_hostname format"
              end
            end
          end
          
          # Computed properties
          def estimated_monthly_cost
            # Model registration and storage costs
            base_cost = 0.0 # Model registration is free
            
            # Estimate based on model storage (if using S3)
            storage_cost = estimate_model_storage_cost
            
            # Multi-model endpoint additional costs
            multi_model_cost = uses_multi_model_endpoint? ? 10.0 : 0.0
            
            base_cost + storage_cost + multi_model_cost
          end
          
          def estimate_model_storage_cost
            total_models = 0
            
            if primary_container&.dig(:model_data_url)
              total_models += 1
            end
            
            if containers
              containers.each do |container|
                total_models += 1 if container[:model_data_url]
              end
            end
            
            # Assume average 1GB per model, $0.023 per GB per month for S3
            total_models * 1.0 * 0.023
          end
          
          def is_multi_container_model?
            containers && containers.size > 1
          end
          
          def uses_multi_model_endpoint?
            return false unless primary_container
            primary_container.dig(:multi_model_config, :model_cache_setting) == 'Enabled'
          end
          
          def has_vpc_configuration?
            !vpc_config.nil?
          end
          
          def uses_network_isolation?
            enable_network_isolation
          end
          
          def uses_model_packages?
            all_containers = []
            all_containers << primary_container if primary_container
            all_containers.concat(containers || [])
            
            all_containers.any? { |c| c[:model_package_name] }
          end
          
          def uses_custom_images?
            all_containers = []
            all_containers << primary_container if primary_container
            all_containers.concat(containers || [])
            
            all_containers.any? { |c| !c[:image].include?('763104351884.dkr.ecr') }
          end
          
          def has_environment_variables?
            all_containers = []
            all_containers << primary_container if primary_container
            all_containers.concat(containers || [])
            
            all_containers.any? { |c| c[:environment] && c[:environment].any? }
          end
          
          def container_count
            return 1 if primary_container
            return containers.size if containers
            0
          end
          
          def total_environment_variables
            all_containers = []
            all_containers << primary_container if primary_container  
            all_containers.concat(containers || [])
            
            all_containers.sum { |c| c[:environment]&.size || 0 }
          end
          
          # Model serving configuration analysis
          def inference_configuration
            if is_multi_container_model?
              {
                type: 'multi-container',
                container_count: container_count,
                execution_mode: inference_execution_config&.dig(:mode) || 'Serial',
                supports_direct_invocation: inference_execution_config&.dig(:mode) == 'Direct'
              }
            else
              {
                type: 'single-container',
                container_count: 1,
                multi_model_endpoint: uses_multi_model_endpoint?
              }
            end
          end
          
          # Security assessment
          def security_score
            score = 0
            score += 20 if has_vpc_configuration?
            score += 25 if uses_network_isolation?
            score += 10 if uses_model_packages?
            score += 15 if !uses_custom_images? # AWS managed images are more secure
            score += 10 if vpc_config && vpc_config[:security_group_ids].size >= 2 # Defense in depth
            
            [score, 100].min
          end
          
          def compliance_status
            issues = []
            issues << "No VPC configuration for network security" unless has_vpc_configuration?
            issues << "Network isolation not enabled" unless uses_network_isolation?
            issues << "Using custom container images" if uses_custom_images?
            issues << "Large number of environment variables (#{total_environment_variables})" if total_environment_variables > 20
            
            {
              status: issues.empty? ? 'compliant' : 'needs_attention',
              issues: issues
            }
          end
          
          # Model capability summary
          def model_summary
            {
              model_name: model_name,
              model_type: is_multi_container_model? ? 'multi-container' : 'single-container',
              container_count: container_count,
              uses_vpc: has_vpc_configuration?,
              network_isolated: uses_network_isolation?,
              multi_model_endpoint: uses_multi_model_endpoint?,
              estimated_monthly_cost: estimated_monthly_cost,
              security_score: security_score,
              inference_config: inference_configuration
            }
          end
        end
      end
    end
  end
end