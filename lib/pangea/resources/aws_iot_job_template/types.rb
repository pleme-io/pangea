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
    # AWS IoT Job Template Types
    # 
    # Job templates define reusable job configurations for device fleet management.
    # They enable consistent job deployment across device groups with standardized
    # parameters, timeouts, and retry policies.
    module AwsIotJobTemplateTypes
      # Timeout configuration for job execution
      class TimeoutConfig < Dry::Struct
        schema schema.strict

        # Timeout for job execution in minutes
        attribute :in_progress_timeout_in_minutes, Resources::Types::Integer.optional
      end

      # Job execution rollout configuration
      class JobExecutionsRolloutConfig < Dry::Struct
        schema schema.strict

        # Maximum number of job executions per minute
        attribute :maximum_per_minute, Resources::Types::Integer.optional
      end

      # Abort criteria for job execution
      class AbortConfig < Dry::Struct
        schema schema.strict

        class CriteriaList < Dry::Struct
          schema schema.strict

          # Failure type that triggers abort
          attribute :failure_type, Resources::Types::String.enum('FAILED', 'REJECTED', 'TIMED_OUT', 'ALL')

          # Action to take when criteria is met
          attribute :action, Resources::Types::String.enum('CANCEL')

          # Threshold percentage for triggering abort
          attribute :threshold_percentage, Resources::Types::Float.constrained(gteq: 0.0, lteq: 100.0)

          # Minimum number of things for percentage calculation
          attribute :min_number_of_executed_things, Resources::Types::Integer
        end

        # List of abort criteria
        attribute :criteria_list, Resources::Types::Array.of(CriteriaList)
      end

      # Main attributes for IoT job template resource
      class Attributes < Dry::Struct
        schema schema.strict

        # ID/name of the job template
        attribute :job_template_id, Resources::Types::String

        # Human readable description
        attribute :description, Resources::Types::String

        # Job document (JSON string defining the job)
        attribute :job_document, Resources::Types::String.optional

        # S3 URL for job document (alternative to job_document)
        attribute :document_source, Resources::Types::String.optional

        # Presigned URL configuration
        class PresignedUrlConfig < Dry::Struct
          schema schema.strict

          # IAM role ARN for presigned URL generation
          attribute :role_arn, Resources::Types::String.optional

          # Expiration time in seconds
          attribute :expires_in_sec, Resources::Types::Integer.optional
        end

        attribute? :presigned_url_config, PresignedUrlConfig.optional

        # Job execution rollout configuration
        attribute? :job_executions_rollout_config, JobExecutionsRolloutConfig.optional

        # Abort configuration for failed jobs
        attribute? :abort_config, AbortConfig.optional

        # Timeout configuration
        attribute? :timeout_config, TimeoutConfig.optional

        # Resource tags
        attribute :tags, Resources::Types::Hash.map(Types::String, Types::String).optional
      end

      # Output attributes from job template resource
      class Outputs < Dry::Struct
        schema schema.strict

        # The job template ARN
        attribute :arn, Resources::Types::String

        # The job template ID
        attribute :job_template_id, Resources::Types::String
      end
    end
  end
end