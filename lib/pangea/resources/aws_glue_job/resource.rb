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
require 'pangea/resources/aws_glue_job/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Create an AWS Glue Job with type-safe attributes
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] Glue Job attributes
      # @return [ResourceReference] Reference object with outputs and computed properties
      def aws_glue_job(name, attributes = {})
        # Validate attributes using dry-struct
        job_attrs = Types::GlueJobAttributes.new(attributes)
        
        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_glue_job, name) do
          # Required attributes
          job_name = job_attrs.name
          role_arn job_attrs.role_arn
          
          # Description
          description job_attrs.description if job_attrs.description
          
          # Glue version
          glue_version job_attrs.glue_version if job_attrs.glue_version
          
          # Command configuration
          command do
            script_location job_attrs.command[:script_location]
            name job_attrs.command[:name] if job_attrs.command[:name]
            python_version job_attrs.command[:python_version] if job_attrs.command[:python_version]
            runtime job_attrs.command[:runtime] if job_attrs.command[:runtime]
          end
          
          # Default arguments
          if job_attrs.default_arguments.any?
            default_arguments do
              job_attrs.default_arguments.each do |key, value|
                public_send(key.gsub(/[^a-zA-Z0-9_]/, '_').downcase, value)
              end
            end
          end
          
          # Non-overridable arguments
          if job_attrs.non_overridable_arguments.any?
            non_overridable_arguments do
              job_attrs.non_overridable_arguments.each do |key, value|
                public_send(key.gsub(/[^a-zA-Z0-9_]/, '_').downcase, value)
              end
            end
          end
          
          # Connections
          if job_attrs.connections.any?
            connections job_attrs.connections
          end
          
          # Capacity configuration - use either max_capacity OR worker configuration
          if job_attrs.uses_worker_configuration?
            worker_type job_attrs.worker_type
            number_of_workers job_attrs.number_of_workers
          elsif job_attrs.max_capacity
            max_capacity job_attrs.max_capacity
          end
          
          # Job configuration
          timeout job_attrs.timeout if job_attrs.timeout
          max_retries job_attrs.max_retries if job_attrs.max_retries
          security_configuration job_attrs.security_configuration if job_attrs.security_configuration
          
          # Notification properties
          if job_attrs.notification_property
            notification_property do
              np = job_attrs.notification_property
              notify_delay_after np[:notify_delay_after] if np[:notify_delay_after]
            end
          end
          
          # Execution properties
          if job_attrs.execution_property.any?
            execution_property do
              ep = job_attrs.execution_property
              max_concurrent_runs ep[:max_concurrent_runs] if ep[:max_concurrent_runs]
            end
          end
          
          # Apply tags if present
          if job_attrs.tags.any?
            tags do
              job_attrs.tags.each do |key, value|
                public_send(key, value)
              end
            end
          end
        end
        
        # Return resource reference with available outputs
        ResourceReference.new(
          type: 'aws_glue_job',
          name: name,
          resource_attributes: job_attrs.to_h,
          outputs: {
            id: "${aws_glue_job.#{name}.id}",
            name: "${aws_glue_job.#{name}.name}",
            arn: "${aws_glue_job.#{name}.arn}",
            max_capacity: "${aws_glue_job.#{name}.max_capacity}",
            worker_type: "${aws_glue_job.#{name}.worker_type}",
            number_of_workers: "${aws_glue_job.#{name}.number_of_workers}"
          },
          computed_properties: {
            uses_worker_configuration: job_attrs.uses_worker_configuration?,
            is_streaming_job: job_attrs.is_streaming_job?,
            is_python_shell_job: job_attrs.is_python_shell_job?,
            is_etl_job: job_attrs.is_etl_job?,
            effective_glue_version: job_attrs.effective_glue_version,
            effective_python_version: job_attrs.effective_python_version,
            estimated_dpu_capacity: job_attrs.estimated_dpu_capacity,
            estimated_hourly_cost_usd: job_attrs.estimated_hourly_cost_usd,
            configuration_warnings: job_attrs.configuration_warnings
          }
        )
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)