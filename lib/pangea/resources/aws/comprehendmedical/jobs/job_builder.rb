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
      module ComprehendMedical
        module Jobs
          # Shared helper for building Comprehend Medical job resources
          # All job types share the same attributes and output structure
          module JobBuilder
            # Standard attributes shared by all Comprehend Medical jobs
            JOB_ATTRIBUTES = %i[
              job_name
              input_data_config
              output_data_config
              data_access_role_arn
              language_code
              client_request_token
              kms_key
            ].freeze

            # Standard outputs shared by all Comprehend Medical jobs
            JOB_OUTPUTS = %i[job_id job_name job_status submit_time end_time].freeze

            private

            # Builds a Comprehend Medical job resource with common attributes
            #
            # @param resource_type [Symbol] The Terraform resource type
            # @param name [Symbol] The unique name for this resource instance
            # @param attributes [Hash] The configuration options for the job
            # @return [ResourceReference] Reference to the created job
            def build_comprehendmedical_job(resource_type, name, attributes)
              resource(resource_type, name) do
                JOB_ATTRIBUTES.each do |attr|
                  send(attr, attributes[attr]) if attributes[attr]
                end
              end

              ResourceReference.new(
                type: resource_type.to_s,
                name: name,
                resource_attributes: attributes,
                outputs: build_job_outputs(resource_type, name)
              )
            end

            # Builds the standard outputs hash for a job resource
            #
            # @param resource_type [Symbol] The Terraform resource type
            # @param name [Symbol] The resource name
            # @return [Hash] The outputs hash
            def build_job_outputs(resource_type, name)
              JOB_OUTPUTS.each_with_object({}) do |output, hash|
                hash[output] = "${#{resource_type}.#{name}.#{output}}"
              end
            end
          end
        end
      end
    end
  end
end
