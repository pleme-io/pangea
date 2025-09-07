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


require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/aws_athena_workgroup/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Create an AWS Athena Workgroup with type-safe attributes
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] Athena Workgroup attributes
      # @return [ResourceReference] Reference object with outputs and computed properties
      def aws_athena_workgroup(name, attributes = {})
        # Validate attributes using dry-struct
        workgroup_attrs = Types::AthenaWorkgroupAttributes.new(attributes)
        
        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_athena_workgroup, name) do
          # Required attributes
          workgroup_name = workgroup_attrs.name
          
          # Optional description
          description workgroup_attrs.description if workgroup_attrs.description
          
          # State
          state workgroup_attrs.state
          
          # Force destroy
          force_destroy workgroup_attrs.force_destroy
          
          # Configuration block
          if workgroup_attrs.configuration
            configuration do
              config = workgroup_attrs.configuration
              
              # Result configuration
              if config[:result_configuration]
                result_configuration do
                  result_config = config[:result_configuration]
                  
                  output_location result_config[:output_location] if result_config[:output_location]
                  expected_bucket_owner result_config[:expected_bucket_owner] if result_config[:expected_bucket_owner]
                  
                  # Encryption configuration
                  if result_config[:encryption_configuration]
                    encryption_configuration do
                      encryption_option result_config[:encryption_configuration][:encryption_option]
                      kms_key_id result_config[:encryption_configuration][:kms_key_id] if result_config[:encryption_configuration][:kms_key_id]
                    end
                  end
                  
                  # ACL configuration
                  if result_config[:acl_configuration]
                    acl_configuration do
                      s3_acl_option result_config[:acl_configuration][:s3_acl_option]
                    end
                  end
                end
              end
              
              # Execution settings
              enforce_workgroup_configuration config[:enforce_workgroup_configuration] if config.key?(:enforce_workgroup_configuration)
              publish_cloudwatch_metrics_enabled config[:publish_cloudwatch_metrics_enabled] if config.key?(:publish_cloudwatch_metrics_enabled)
              bytes_scanned_cutoff_per_query config[:bytes_scanned_cutoff_per_query] if config[:bytes_scanned_cutoff_per_query]
              requester_pays_enabled config[:requester_pays_enabled] if config.key?(:requester_pays_enabled)
              
              # Engine version
              if config[:engine_version]
                engine_version do
                  selected_engine_version config[:engine_version][:selected_engine_version] if config[:engine_version][:selected_engine_version]
                end
              end
              
              # Execution role
              execution_role config[:execution_role] if config[:execution_role]
              
              # Customer content encryption
              if config[:customer_content_encryption_configuration]
                customer_content_encryption_configuration do
                  kms_key_id config[:customer_content_encryption_configuration][:kms_key_id]
                end
              end
            end
          end
          
          # Apply tags if present
          if workgroup_attrs.tags.any?
            tags do
              workgroup_attrs.tags.each do |key, value|
                public_send(key, value)
              end
            end
          end
        end
        
        # Return resource reference with available outputs
        ResourceReference.new(
          type: 'aws_athena_workgroup',
          name: name,
          resource_attributes: workgroup_attrs.to_h,
          outputs: {
            id: "${aws_athena_workgroup.#{name}.id}",
            arn: "${aws_athena_workgroup.#{name}.arn}",
            configuration: "${aws_athena_workgroup.#{name}.configuration}"
          },
          computed_properties: {
            enabled: workgroup_attrs.enabled?,
            has_output_location: workgroup_attrs.has_output_location?,
            enforces_configuration: workgroup_attrs.enforces_configuration?,
            cloudwatch_metrics_enabled: workgroup_attrs.cloudwatch_metrics_enabled?,
            encryption_type: workgroup_attrs.encryption_type,
            uses_kms: workgroup_attrs.uses_kms?,
            has_query_limits: workgroup_attrs.has_query_limits?,
            query_limit_gb: workgroup_attrs.query_limit_gb,
            estimated_monthly_cost_usd: workgroup_attrs.estimated_monthly_cost_usd
          }
        )
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)