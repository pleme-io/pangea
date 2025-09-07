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
require 'pangea/resources/aws_lambda_function/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Create an AWS Lambda function with type-safe attributes
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] Lambda function attributes
      # @return [ResourceReference] Reference object with outputs and computed properties
      def aws_lambda_function(name, attributes = {})
        # Validate attributes using dry-struct
        lambda_attrs = AWS::Types::Types::LambdaFunctionAttributes.new(attributes)
        
        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_lambda_function, name) do
          function_name lambda_attrs.function_name
          role lambda_attrs.role
          
          # Package type determines code configuration
          if lambda_attrs.package_type == 'Image'
            package_type 'Image'
            image_uri lambda_attrs.image_uri
            
            # Image config if present
            if lambda_attrs.image_config
              image_config do
                entry_point lambda_attrs.image_config[:entry_point] if lambda_attrs.image_config[:entry_point]
                command lambda_attrs.image_config[:command] if lambda_attrs.image_config[:command]
                working_directory lambda_attrs.image_config[:working_directory] if lambda_attrs.image_config[:working_directory]
              end
            end
          else
            handler lambda_attrs.handler
            runtime lambda_attrs.runtime
            
            # Code source
            if lambda_attrs.filename
              filename lambda_attrs.filename
            elsif lambda_attrs.s3_bucket
              s3_bucket lambda_attrs.s3_bucket
              s3_key lambda_attrs.s3_key
              s3_object_version lambda_attrs.s3_object_version if lambda_attrs.s3_object_version
            end
          end
          
          # Common attributes
          description lambda_attrs.description if lambda_attrs.description
          timeout lambda_attrs.timeout
          memory_size lambda_attrs.memory_size
          publish lambda_attrs.publish
          
          # Architectures
          architectures lambda_attrs.architectures
          
          # Reserved concurrent executions
          reserved_concurrent_executions lambda_attrs.reserved_concurrent_executions if lambda_attrs.reserved_concurrent_executions
          
          # Layers
          layers lambda_attrs.layers if lambda_attrs.layers.any?
          
          # Environment variables
          if lambda_attrs.environment && lambda_attrs.environment[:variables]
            environment do
              variables do
                lambda_attrs.environment[:variables].each do |key, value|
                  public_send(key, value)
                end
              end
            end
          end
          
          # VPC configuration
          if lambda_attrs.vpc_config
            vpc_config do
              subnet_ids lambda_attrs.vpc_config[:subnet_ids]
              security_group_ids lambda_attrs.vpc_config[:security_group_ids]
            end
          end
          
          # Dead letter queue
          if lambda_attrs.dead_letter_config
            dead_letter_config do
              target_arn lambda_attrs.dead_letter_config[:target_arn]
            end
          end
          
          # File system configs (EFS)
          if lambda_attrs.file_system_config.any?
            lambda_attrs.file_system_config.each do |fs_config|
              file_system_config do
                arn fs_config[:arn]
                local_mount_path fs_config[:local_mount_path]
              end
            end
          end
          
          # Tracing configuration
          if lambda_attrs.tracing_config
            tracing_config do
              mode lambda_attrs.tracing_config[:mode]
            end
          end
          
          # KMS key for environment encryption
          kms_key_arn lambda_attrs.kms_key_arn if lambda_attrs.kms_key_arn
          
          # Code signing
          code_signing_config_arn lambda_attrs.code_signing_config_arn if lambda_attrs.code_signing_config_arn
          
          # Ephemeral storage
          if lambda_attrs.ephemeral_storage
            ephemeral_storage do
              size lambda_attrs.ephemeral_storage[:size]
            end
          end
          
          # Snap start (Java only)
          if lambda_attrs.snap_start
            snap_start do
              apply_on lambda_attrs.snap_start[:apply_on]
            end
          end
          
          # Logging configuration
          if lambda_attrs.logging_config
            logging_config do
              log_format lambda_attrs.logging_config[:log_format] if lambda_attrs.logging_config[:log_format]
              log_group lambda_attrs.logging_config[:log_group] if lambda_attrs.logging_config[:log_group]
              system_log_level lambda_attrs.logging_config[:system_log_level] if lambda_attrs.logging_config[:system_log_level]
              application_log_level lambda_attrs.logging_config[:application_log_level] if lambda_attrs.logging_config[:application_log_level]
            end
          end
          
          # Tags
          if lambda_attrs.tags.any?
            tags do
              lambda_attrs.tags.each do |key, value|
                public_send(key, value)
              end
            end
          end
        end
        
        # Return resource reference with available outputs
        ref = ResourceReference.new(
          type: 'aws_lambda_function',
          name: name,
          resource_attributes: lambda_attrs.to_h,
          outputs: {
            # Core outputs
            arn: "${aws_lambda_function.#{name}.arn}",
            function_name: "${aws_lambda_function.#{name}.function_name}",
            qualified_arn: "${aws_lambda_function.#{name}.qualified_arn}",
            qualified_invoke_arn: "${aws_lambda_function.#{name}.qualified_invoke_arn}",
            invoke_arn: "${aws_lambda_function.#{name}.invoke_arn}",
            version: "${aws_lambda_function.#{name}.version}",
            last_modified: "${aws_lambda_function.#{name}.last_modified}",
            source_code_hash: "${aws_lambda_function.#{name}.source_code_hash}",
            source_code_size: "${aws_lambda_function.#{name}.source_code_size}",
            
            # Configuration outputs
            role: "${aws_lambda_function.#{name}.role}",
            handler: "${aws_lambda_function.#{name}.handler}",
            runtime: "${aws_lambda_function.#{name}.runtime}",
            timeout: "${aws_lambda_function.#{name}.timeout}",
            memory_size: "${aws_lambda_function.#{name}.memory_size}",
            
            # Additional outputs
            signing_job_arn: "${aws_lambda_function.#{name}.signing_job_arn}",
            signing_profile_version_arn: "${aws_lambda_function.#{name}.signing_profile_version_arn}"
          }
        )
        
        # Add computed properties via method delegation
        ref.define_singleton_method(:estimated_monthly_cost) { lambda_attrs.estimated_monthly_cost }
        ref.define_singleton_method(:requires_vpc?) { lambda_attrs.requires_vpc? }
        ref.define_singleton_method(:has_dlq?) { lambda_attrs.has_dlq? }
        ref.define_singleton_method(:uses_efs?) { lambda_attrs.uses_efs? }
        ref.define_singleton_method(:is_container_based?) { lambda_attrs.is_container_based? }
        ref.define_singleton_method(:supports_snap_start?) { lambda_attrs.supports_snap_start? }
        ref.define_singleton_method(:architecture) { lambda_attrs.architecture }
        
        ref
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)