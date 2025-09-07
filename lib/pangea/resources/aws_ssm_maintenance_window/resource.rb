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
require 'pangea/resources/aws_ssm_maintenance_window/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Create an AWS Systems Manager Maintenance Window with type-safe attributes
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] SSM maintenance window attributes
      # @return [ResourceReference] Reference object with outputs and computed properties
      def aws_ssm_maintenance_window(name, attributes = {})
        # Validate attributes using dry-struct
        window_attrs = Types::SsmMaintenanceWindowAttributes.new(attributes)
        
        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_ssm_maintenance_window, name) do
          maintenance_window_name window_attrs.name
          schedule window_attrs.schedule
          duration window_attrs.duration
          cutoff window_attrs.cutoff
          allow_unassociated_targets window_attrs.allow_unassociated_targets
          enabled window_attrs.enabled

          # Optional date range
          if window_attrs.start_date
            start_date window_attrs.start_date
          end

          if window_attrs.end_date
            end_date window_attrs.end_date
          end

          # Schedule configuration
          if window_attrs.schedule_timezone
            schedule_timezone window_attrs.schedule_timezone
          end

          if window_attrs.schedule_offset
            schedule_offset window_attrs.schedule_offset
          end

          # Description
          if window_attrs.description
            description window_attrs.description
          end

          # Apply tags if present
          if window_attrs.tags.any?
            tags do
              window_attrs.tags.each do |key, value|
                public_send(key, value)
              end
            end
          end
        end
        
        # Return resource reference with available outputs
        ResourceReference.new(
          type: 'aws_ssm_maintenance_window',
          name: name,
          resource_attributes: window_attrs.to_h,
          outputs: {
            id: "${aws_ssm_maintenance_window.#{name}.id}",
            name: "${aws_ssm_maintenance_window.#{name}.name}",
            arn: "${aws_ssm_maintenance_window.#{name}.arn}",
            created_date: "${aws_ssm_maintenance_window.#{name}.created_date}",
            modified_date: "${aws_ssm_maintenance_window.#{name}.modified_date}",
            enabled: "${aws_ssm_maintenance_window.#{name}.enabled}",
            schedule: "${aws_ssm_maintenance_window.#{name}.schedule}",
            schedule_timezone: "${aws_ssm_maintenance_window.#{name}.schedule_timezone}",
            duration: "${aws_ssm_maintenance_window.#{name}.duration}",
            cutoff: "${aws_ssm_maintenance_window.#{name}.cutoff}",
            description: "${aws_ssm_maintenance_window.#{name}.description}",
            tags_all: "${aws_ssm_maintenance_window.#{name}.tags_all}"
          },
          computed_properties: {
            is_enabled: window_attrs.is_enabled?,
            is_disabled: window_attrs.is_disabled?,
            uses_cron_schedule: window_attrs.uses_cron_schedule?,
            uses_rate_schedule: window_attrs.uses_rate_schedule?,
            has_start_date: window_attrs.has_start_date?,
            has_end_date: window_attrs.has_end_date?,
            has_timezone: window_attrs.has_timezone?,
            has_schedule_offset: window_attrs.has_schedule_offset?,
            has_description: window_attrs.has_description?,
            allows_unassociated_targets: window_attrs.allows_unassociated_targets?,
            duration_hours: window_attrs.duration_hours,
            cutoff_hours: window_attrs.cutoff_hours,
            effective_execution_time_hours: window_attrs.effective_execution_time_hours,
            schedule_type: window_attrs.schedule_type,
            parsed_schedule_info: window_attrs.parsed_schedule_info,
            estimated_monthly_executions: window_attrs.estimated_monthly_executions
          }
        )
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)