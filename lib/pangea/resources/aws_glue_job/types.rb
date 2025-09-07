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
      # Type-safe attributes for AWS Glue Job resources
      class GlueJobAttributes < Dry::Struct
        # Job name (required)
        attribute :name, Resources::Types::String
        
        # IAM role ARN (required)
        attribute :role_arn, Resources::Types::String
        
        # Job description
        attribute :description, Resources::Types::String.optional
        
        # Glue version
        attribute :glue_version, Resources::Types::String.enum("0.9", "1.0", "2.0", "3.0", "4.0").optional
        
        # Job command
        attribute :command, Resources::Types::Hash.schema(
          script_location: Types::String,
          name?: Types::String.enum("glueetl", "gluestreaming", "pythonshell").optional,
          python_version?: Types::String.enum("2", "3", "3.6", "3.9").optional,
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
        attribute :worker_type, Resources::Types::String.enum("Standard", "G.1X", "G.2X", "G.025X", "G.4X", "G.8X", "Z.2X").optional
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
          
          # Validate job name format
          unless attrs.name =~ /\A[a-zA-Z_][a-zA-Z0-9_-]*\z/
            raise Dry::Struct::Error, "Job name must start with letter or underscore and contain only alphanumeric characters, underscores, and hyphens"
          end
          
          # Validate job name length
          if attrs.name.length > 255
            raise Dry::Struct::Error, "Job name must be 255 characters or less"
          end
          
          # Validate role ARN format
          unless attrs.role_arn.match(/\Aarn:aws:iam::\d{12}:role\//)
            raise Dry::Struct::Error, "Role ARN must be in format arn:aws:iam::account:role/role-name"
          end
          
          # Validate script location format
          script_location = attrs.command[:script_location]
          unless script_location.match(/\As3:\/\//)
            raise Dry::Struct::Error, "Script location must be an S3 URL (s3://bucket/path)"
          end
          
          # Validate worker configuration compatibility
          if attrs.worker_type && !attrs.number_of_workers
            raise Dry::Struct::Error, "number_of_workers is required when worker_type is specified"
          end
          
          if attrs.number_of_workers && !attrs.worker_type
            raise Dry::Struct::Error, "worker_type is required when number_of_workers is specified"
          end
          
          # Validate max_capacity vs worker configuration
          if attrs.max_capacity && (attrs.worker_type || attrs.number_of_workers)
            raise Dry::Struct::Error, "max_capacity cannot be used with worker_type/number_of_workers configuration"
          end
          
          # Validate timeout range
          if attrs.timeout && (attrs.timeout < 1 || attrs.timeout > 2880)
            raise Dry::Struct::Error, "Timeout must be between 1 and 2880 minutes (48 hours)"
          end

          attrs
        end

        # Check if job uses modern worker configuration
        def uses_worker_configuration?
          worker_type && number_of_workers
        end

        # Check if job is streaming
        def is_streaming_job?
          command[:name] == "gluestreaming"
        end

        # Check if job is Python shell
        def is_python_shell_job?
          command[:name] == "pythonshell"
        end

        # Check if job is ETL
        def is_etl_job?
          command[:name].nil? || command[:name] == "glueetl"
        end

        # Get effective Glue version (with defaults)
        def effective_glue_version
          glue_version || (is_python_shell_job? ? "1.0" : "2.0")
        end

        # Get effective Python version
        def effective_python_version
          command[:python_version] || (effective_glue_version >= "2.0" ? "3" : "2")
        end

        # Calculate estimated DPU capacity
        def estimated_dpu_capacity
          if uses_worker_configuration?
            case worker_type
            when "Standard"
              number_of_workers * 1.0
            when "G.1X"
              number_of_workers * 1.0
            when "G.2X"
              number_of_workers * 2.0
            when "G.025X"
              number_of_workers * 0.25
            when "G.4X"
              number_of_workers * 4.0
            when "G.8X"
              number_of_workers * 8.0
            when "Z.2X"
              number_of_workers * 2.0
            else
              number_of_workers * 1.0
            end
          elsif max_capacity
            max_capacity
          elsif is_python_shell_job?
            0.0625 # Python shell default
          else
            2.0 # ETL job default
          end
        end

        # Estimate hourly cost based on DPU usage
        def estimated_hourly_cost_usd
          dpu_capacity = estimated_dpu_capacity
          
          # AWS Glue pricing (approximate, varies by region)
          cost_per_dpu_hour = if is_python_shell_job?
            0.44 # Python shell DPU-Hour
          else
            0.44 # ETL/Streaming DPU-Hour
          end
          
          (dpu_capacity * cost_per_dpu_hour).round(4)
        end

        # Check if job configuration is optimal
        def configuration_warnings
          warnings = []
          
          if glue_version && glue_version < "2.0"
            warnings << "Consider upgrading to Glue 2.0+ for better performance and features"
          end
          
          if !uses_worker_configuration? && !max_capacity && !is_python_shell_job?
            warnings << "Consider specifying worker configuration for better resource control"
          end
          
          if timeout && timeout > 1440
            warnings << "Very long timeout (>24h) may indicate job optimization opportunities"
          end
          
          if is_streaming_job? && !default_arguments.key?("--enable-metrics")
            warnings << "Consider enabling CloudWatch metrics for streaming jobs"
          end
          
          warnings
        end

        # Generate common default arguments based on job type
        def self.default_arguments_for_job_type(job_type, options = {})
          base_args = {
            "--job-language" => "python",
            "--enable-metrics" => "",
            "--enable-continuous-cloudwatch-log" => "true"
          }
          
          case job_type.to_s
          when "etl"
            base_args.merge({
              "--enable-job-insights" => "true",
              "--enable-auto-scaling" => "true"
            })
          when "streaming"
            base_args.merge({
              "--enable-metrics" => "",
              "--continuous-log-logStream" => options[:log_stream] || "glue-streaming-job",
              "--window-size" => options[:window_size] || "100",
              "--checkpoint-location" => options[:checkpoint_location] || "s3://bucket/checkpoints/"
            })
          when "pythonshell"
            {
              "--job-language" => "python",
              "--python-modules-installer-option" => options[:python_modules] || ""
            }
          else
            base_args
          end
        end
        
        # Generate worker configuration recommendations
        def self.worker_recommendations_for_workload(workload_type, data_size_gb = nil)
          case workload_type.to_s
          when "small_etl"
            { worker_type: "G.1X", number_of_workers: 2 }
          when "medium_etl"
            { worker_type: "G.1X", number_of_workers: 10 }
          when "large_etl"
            { worker_type: "G.2X", number_of_workers: 20 }
          when "memory_intensive"
            { worker_type: "Z.2X", number_of_workers: 10 }
          when "streaming"
            { worker_type: "G.1X", number_of_workers: 2 }
          when "python_shell"
            # Python shell doesn't use worker configuration
            {}
          else
            # Default configuration
            { worker_type: "G.1X", number_of_workers: 5 }
          end
        end
      end
    end
      end
    end
  end
end