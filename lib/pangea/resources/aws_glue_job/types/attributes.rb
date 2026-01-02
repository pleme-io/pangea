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

module Pangea
  module Resources
    module AWS
      module Types
        # Type-safe attributes for AWS Glue Job resources
        class GlueJobAttributes < Dry::Struct
          extend GlueJobClassMethods
          extend GlueJobValidation
          include GlueJobInstanceMethods

          # Job name (required)
          attribute :name, Resources::Types::String

          # IAM role ARN (required)
          attribute :role_arn, Resources::Types::String

          # Job description
          attribute :description, Resources::Types::String.optional

          # Glue version
          attribute :glue_version, Resources::Types::String.enum('0.9', '1.0', '2.0', '3.0', '4.0').optional

          # Job command
          attribute :command, Resources::Types::Hash.schema(
            script_location: Types::String,
            name?: Types::String.enum('glueetl', 'gluestreaming', 'pythonshell').optional,
            python_version?: Types::String.enum('2', '3', '3.6', '3.9').optional,
            runtime?: Types::String.optional
          )

          # Default job arguments
          attribute :default_arguments, Resources::Types::Hash.map(Types::String, Types::String).default({}.freeze)

          # Non-overridable arguments
          attribute :non_overridable_arguments, Resources::Types::Hash.map(Types::String, Types::String).default({}.freeze)

          # Job connections
          attribute :connections, Resources::Types::Array.of(Types::String).default([].freeze)

          # Maximum capacity (DPUs)
          attribute :max_capacity, Resources::Types::Float.optional

          # Worker configuration for Glue 2.0+
          attribute :worker_type, Resources::Types::String.enum('Standard', 'G.1X', 'G.2X', 'G.025X', 'G.4X', 'G.8X', 'Z.2X').optional
          attribute :number_of_workers, Resources::Types::Integer.optional

          # Job timeout in minutes
          attribute :timeout, Resources::Types::Integer.optional

          # Maximum retries
          attribute :max_retries, Resources::Types::Integer.optional

          # Security configuration
          attribute :security_configuration, Resources::Types::String.optional

          # Notification properties
          attribute :notification_property, Resources::Types::Hash.schema(
            notify_delay_after?: Types::Integer.optional
          ).optional

          # Execution properties
          attribute :execution_property, Resources::Types::Hash.schema(
            max_concurrent_runs?: Types::Integer.constrained(gteq: 1, lteq: 1000).optional
          ).default({}.freeze)

          # Tags
          attribute :tags, Resources::Types::AwsTags.default({}.freeze)

          # Custom validation
          def self.new(attributes = {})
            attrs = super(attributes)
            validate_job_name(attrs.name)
            validate_role_arn(attrs.role_arn)
            validate_script_location(attrs.command)
            validate_worker_configuration(attrs)
            validate_timeout(attrs.timeout)
            attrs
          end
        end
      end
    end
  end
end
