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
        # AWS Step Functions Activity attributes with validation
        class SfnActivityAttributes < Dry::Struct
          transform_keys(&:to_sym)
          
          # Core attributes
          attribute :name, Resources::Types::String
          
          # Optional attributes
          attribute? :tags, Resources::Types::Hash.optional
          
          # Custom validation
          def self.new(attributes)
            attrs = attributes.is_a?(Hash) ? attributes : {}
            
            # Validate activity name format
            if attrs[:name]
              validate_activity_name(attrs[:name])
            end
            
            super(attrs)
          end
          
          def self.validate_activity_name(name)
            # Activity names must be 1-80 characters
            if name.length < 1 || name.length > 80
              raise Dry::Struct::Error, "Activity name must be between 1 and 80 characters"
            end
            
            # Must contain only alphanumeric, hyphens, and underscores
            unless name.match?(/^[a-zA-Z0-9\-_]+$/)
              raise Dry::Struct::Error, "Activity name can only contain letters, numbers, hyphens, and underscores"
            end
            
            # Cannot start or end with hyphen
            if name.start_with?('-') || name.end_with?('-')
              raise Dry::Struct::Error, "Activity name cannot start or end with a hyphen"
            end
            
            true
          end
          
          # Computed properties
          def is_valid_name?
            return false unless name
            
            begin
              self.class.validate_activity_name(name)
              true
            rescue Dry::Struct::Error
              false
            end
          end
          
          def estimated_arn(region, account_id)
            "arn:aws:states:#{region}:#{account_id}:activity:#{name}"
          end
          
          # Activity naming patterns
          def self.activity_name_patterns
            {
              data_processing: "data-processing-activity",
              file_processing: "file-processing-activity", 
              image_processing: "image-processing-activity",
              email_sending: "email-sending-activity",
              report_generation: "report-generation-activity",
              data_validation: "data-validation-activity",
              backup_task: "backup-task-activity",
              cleanup_task: "cleanup-task-activity",
              monitoring_check: "monitoring-check-activity",
              health_check: "health-check-activity",
              batch_job: "batch-job-activity",
              etl_process: "etl-process-activity",
              ml_training: "ml-training-activity",
              ml_inference: "ml-inference-activity",
              api_integration: "api-integration-activity"
            }
          end
          
          # Common activity configurations
          def self.data_processing_activity(name_suffix = "")
            suffix = name_suffix.empty? ? "" : "-#{name_suffix}"
            "data-processing-activity#{suffix}"
          end
          
          def self.worker_activity(worker_type, environment = nil)
            base_name = "#{worker_type}-worker-activity"
            environment ? "#{base_name}-#{environment}" : base_name
          end
          
          def self.batch_activity(batch_type)
            "#{batch_type}-batch-activity"
          end
          
          def self.integration_activity(service_name, action)
            "#{service_name}-#{action}-activity"
          end
        end
      end
    end
  end
end