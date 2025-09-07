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


require_relative 'types'
require 'pangea/resources/base'

module Pangea
  module Resources
    # AWS IoT Job Template Resource
    # 
    # Job templates provide reusable job configurations for device management operations
    # like firmware updates, configuration changes, or data collection tasks.
    # They enable consistent job deployment across device fleets.
    #
    # @example Firmware update job template
    #   job_document = JSON.generate({
    #     "version" => "1.0",
    #     "steps" => [{
    #       "action" => {
    #         "name" => "FIRMWARE_UPDATE",
    #         "parameters" => {
    #           "firmwareUrl" => "${aws:iot:parameter:firmwareUrl}",
    #           "version" => "${aws:iot:parameter:version}"
    #         }
    #       }
    #     }]
    #   })
    #   
    #   aws_iot_job_template(:firmware_update, {
    #     job_template_id: "FirmwareUpdateTemplate",
    #     description: "Template for device firmware updates",
    #     job_document: job_document,
    #     timeout_config: {
    #       in_progress_timeout_in_minutes: 30
    #     },
    #     job_executions_rollout_config: {
    #       maximum_per_minute: 10
    #     }
    #   })
    #
    # @example Job template with abort conditions
    #   aws_iot_job_template(:critical_update, {
    #     job_template_id: "CriticalSystemUpdate",
    #     description: "Critical system update with abort conditions",
    #     document_source: "s3://my-bucket/jobs/critical-update.json",
    #     abort_config: {
    #       criteria_list: [{
    #         failure_type: "FAILED",
    #         action: "CANCEL",
    #         threshold_percentage: 10.0,
    #         min_number_of_executed_things: 5
    #       }]
    #     }
    #   })
    module AwsIotJobTemplate
      include AwsIotJobTemplateTypes

      # Creates an AWS IoT job template for reusable device management jobs
      #
      # @param name [Symbol] Logical name for the job template resource
      # @param attributes [Hash] Job template configuration attributes
      # @return [Reference] Resource reference for use in other resources
      def aws_iot_job_template(name, attributes = {})
        validated_attributes = Attributes[attributes]
        
        resource :aws_iot_job_template, name do
          job_template_id validated_attributes.job_template_id
          description validated_attributes.description
          job_document validated_attributes.job_document if validated_attributes.job_document
          document_source validated_attributes.document_source if validated_attributes.document_source

          if validated_attributes.presigned_url_config
            presigned_url_config do
              role_arn validated_attributes.presigned_url_config.role_arn if validated_attributes.presigned_url_config.role_arn
              expires_in_sec validated_attributes.presigned_url_config.expires_in_sec if validated_attributes.presigned_url_config.expires_in_sec
            end
          end

          if validated_attributes.job_executions_rollout_config
            job_executions_rollout_config do
              maximum_per_minute validated_attributes.job_executions_rollout_config.maximum_per_minute if validated_attributes.job_executions_rollout_config.maximum_per_minute
            end
          end

          if validated_attributes.abort_config
            abort_config do
              criteria_list validated_attributes.abort_config.criteria_list.map do |criteria|
                {
                  "failure_type" => criteria.failure_type,
                  "action" => criteria.action,
                  "threshold_percentage" => criteria.threshold_percentage,
                  "min_number_of_executed_things" => criteria.min_number_of_executed_things
                }
              end
            end
          end

          if validated_attributes.timeout_config
            timeout_config do
              in_progress_timeout_in_minutes validated_attributes.timeout_config.in_progress_timeout_in_minutes if validated_attributes.timeout_config.in_progress_timeout_in_minutes
            end
          end

          tags validated_attributes.tags if validated_attributes.tags
        end

        Reference.new(
          type: :aws_iot_job_template,
          name: name,
          attributes: Outputs.new(
            arn: "${aws_iot_job_template.#{name}.arn}",
            job_template_id: "${aws_iot_job_template.#{name}.job_template_id}"
          )
        )
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)