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


require 'pangea/resources/types'

module Pangea
  module Resources
    module AWS
      module Types
      # Type-safe attributes for AWS Athena Workgroup resources
      class AthenaWorkgroupAttributes < Dry::Struct
        # Workgroup name (required)
        attribute :name, Resources::Types::String
        
        # Workgroup description
        attribute :description, Resources::Types::String.optional
        
        # State of the workgroup
        attribute :state, Resources::Types::String.enum("ENABLED", "DISABLED").default("ENABLED")
        
        # Force destroy workgroup and contents
        attribute :force_destroy, Resources::Types::Bool.default(false)
        
        # Workgroup configuration
        attribute :configuration, Resources::Types::Hash.schema(
          # Query result configuration
          result_configuration?: Types::Hash.schema(
            output_location?: Types::String.optional,
            encryption_configuration?: Types::Hash.schema(
              encryption_option: Types::String.enum("SSE_S3", "SSE_KMS", "CSE_KMS"),
              kms_key_id?: Types::String.optional
            ).optional,
            expected_bucket_owner?: Types::String.optional,
            acl_configuration?: Types::Hash.schema(
              s3_acl_option: Types::String.enum("BUCKET_OWNER_FULL_CONTROL")
            ).optional
          ).optional,
          
          # Execution configuration
          enforce_workgroup_configuration?: Types::Bool.optional,
          publish_cloudwatch_metrics_enabled?: Types::Bool.optional,
          bytes_scanned_cutoff_per_query?: Types::Integer.optional,
          requester_pays_enabled?: Types::Bool.optional,
          
          # Engine version
          engine_version?: Types::Hash.schema(
            selected_engine_version?: Types::String.optional,
            effective_engine_version?: Types::String.optional
          ).optional,
          
          # Result configuration override
          result_configuration_updates?: Types::Hash.schema(
            output_location?: Types::String.optional,
            remove_output_location?: Types::Bool.optional,
            encryption_configuration?: Types::Hash.schema(
              encryption_option: Types::String.enum("SSE_S3", "SSE_KMS", "CSE_KMS"),
              kms_key_id?: Types::String.optional
            ).optional,
            remove_encryption_configuration?: Types::Bool.optional
          ).optional,
          
          # Execution role
          execution_role?: Types::String.optional,
          
          # Customer content encryption
          customer_content_encryption_configuration?: Types::Hash.schema(
            kms_key_id: Types::String
          ).optional
        ).optional
        
        # Tags
        attribute :tags, Resources::Types::AwsTags.default({}.freeze)

        # Custom validation
        def self.new(attributes = {})
          attrs = super(attributes)
          
          # Validate workgroup name format
          unless attrs.name =~ /\A[a-zA-Z0-9_-]+\z/
            raise Dry::Struct::Error, "Workgroup name must contain only alphanumeric characters, hyphens, and underscores"
          end
          
          # Validate workgroup name length
          if attrs.name.length > 128
            raise Dry::Struct::Error, "Workgroup name must be 128 characters or less"
          end
          
          # Validate configuration dependencies
          if attrs.configuration
            config = attrs.configuration
            
            # Validate KMS key for KMS encryption
            if config[:result_configuration] && 
               config[:result_configuration][:encryption_configuration] &&
               ["SSE_KMS", "CSE_KMS"].include?(config[:result_configuration][:encryption_configuration][:encryption_option]) &&
               config[:result_configuration][:encryption_configuration][:kms_key_id].nil?
              raise Dry::Struct::Error, "KMS key ID required for KMS encryption"
            end
            
            # Validate bytes scanned cutoff
            if config[:bytes_scanned_cutoff_per_query] && config[:bytes_scanned_cutoff_per_query] < 10_000_000
              raise Dry::Struct::Error, "Bytes scanned cutoff must be at least 10MB (10000000 bytes)"
            end
          end

          attrs
        end

        # Check if workgroup is enabled
        def enabled?
          state == "ENABLED"
        end

        # Check if workgroup has output location
        def has_output_location?
          configuration && 
          configuration[:result_configuration] && 
          configuration[:result_configuration][:output_location]
        end

        # Check if workgroup enforces configuration
        def enforces_configuration?
          configuration && configuration[:enforce_workgroup_configuration] == true
        end

        # Check if CloudWatch metrics are enabled
        def cloudwatch_metrics_enabled?
          configuration && configuration[:publish_cloudwatch_metrics_enabled] == true
        end

        # Get encryption type
        def encryption_type
          return nil unless configuration && 
                           configuration[:result_configuration] && 
                           configuration[:result_configuration][:encryption_configuration]
          
          configuration[:result_configuration][:encryption_configuration][:encryption_option]
        end

        # Check if using KMS encryption
        def uses_kms?
          ["SSE_KMS", "CSE_KMS"].include?(encryption_type)
        end

        # Check if workgroup has query limits
        def has_query_limits?
          configuration && configuration[:bytes_scanned_cutoff_per_query]
        end

        # Calculate query limit in GB
        def query_limit_gb
          return nil unless has_query_limits?
          configuration[:bytes_scanned_cutoff_per_query] / 1_073_741_824.0
        end

        # Estimate monthly cost based on configuration
        def estimated_monthly_cost_usd
          # Base cost: $5 per TB scanned
          # Assume average queries based on workgroup type
          avg_tb_per_month = case name
                            when /primary|default/i
                              2.0
                            when /development|dev/i
                              0.5
                            when /production|prod/i
                              5.0
                            else
                              1.0
                            end
          
          # Reduce estimate if query limits are set
          if has_query_limits?
            max_tb_per_query = query_limit_gb / 1024.0
            avg_tb_per_month = [avg_tb_per_month, max_tb_per_query * 1000].min
          end
          
          avg_tb_per_month * 5.0
        end

        # Generate default configuration for workgroup types
        def self.default_configuration_for_type(type, s3_output_location)
          base_config = {
            result_configuration: {
              output_location: s3_output_location
            },
            enforce_workgroup_configuration: true,
            publish_cloudwatch_metrics_enabled: true
          }
          
          case type.to_s
          when "production"
            base_config.merge({
              result_configuration: base_config[:result_configuration].merge({
                encryption_configuration: {
                  encryption_option: "SSE_KMS"
                }
              }),
              bytes_scanned_cutoff_per_query: 1_073_741_824_000, # 1TB limit
              engine_version: {
                selected_engine_version: "Athena engine version 3"
              }
            })
          when "development"
            base_config.merge({
              bytes_scanned_cutoff_per_query: 10_737_418_240, # 10GB limit
              enforce_workgroup_configuration: false
            })
          when "cost_optimized"
            base_config.merge({
              bytes_scanned_cutoff_per_query: 1_073_741_824, # 1GB limit
              requester_pays_enabled: true,
              result_configuration: base_config[:result_configuration].merge({
                encryption_configuration: {
                  encryption_option: "SSE_S3"
                }
              })
            })
          when "analytics"
            base_config.merge({
              engine_version: {
                selected_engine_version: "Athena engine version 3"
              },
              result_configuration: base_config[:result_configuration].merge({
                encryption_configuration: {
                  encryption_option: "SSE_KMS"
                }
              })
            })
          else
            base_config
          end
        end
      end
    end
      end
    end
  end
end