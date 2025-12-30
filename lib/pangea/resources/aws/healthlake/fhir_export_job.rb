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
      module HealthLake
        # AWS HealthLake FHIR Export Job resources
        # Manages bulk export of FHIR data from HealthLake datastores.
        module FHIRExportJob
          # Creates an AWS HealthLake FHIR Export Job
          #
          # @param name [Symbol] The unique name for this resource instance
          # @param attributes [Hash] The configuration options for the export job
          # @option attributes [String] :job_name The name of the export job
          # @option attributes [String] :datastore_id The ID of the FHIR datastore (required)
          # @option attributes [Hash] :output_data_config Output data configuration (required)
          #   - :s3_configuration [Hash] S3 output configuration
          #     - :s3_uri [String] The S3 URI for output
          #     - :kms_key_id [String] KMS key for encryption
          # @option attributes [String] :data_access_role_arn IAM role ARN for data access (required)
          # @option attributes [String] :client_token Client token for idempotency
          #
          # @example Export clinical data for analytics
          #   aws_healthlake_fhir_export_job(:clinical_data_export, {
          #     job_name: "clinical-data-export-2024",
          #     datastore_id: ref(:aws_healthlake_fhir_datastore, :clinical_data_store, :datastore_id),
          #     data_access_role_arn: ref(:aws_iam_role, :healthlake_export_role, :arn),
          #     output_data_config: {
          #       s3_configuration: {
          #         s3_uri: "s3://clinical-data-exports/fhir-export/",
          #         kms_key_id: ref(:aws_kms_key, :clinical_data_encryption, :arn)
          #       }
          #     }
          #   })
          #
          # @return [ResourceReference] Reference to the created export job
          def aws_healthlake_fhir_export_job(name, attributes = {})
            resource = resource(:aws_healthlake_fhir_export_job, name) do
              job_name attributes[:job_name] if attributes[:job_name]
              datastore_id attributes[:datastore_id] if attributes[:datastore_id]
              output_data_config attributes[:output_data_config] if attributes[:output_data_config]
              data_access_role_arn attributes[:data_access_role_arn] if attributes[:data_access_role_arn]
              client_token attributes[:client_token] if attributes[:client_token]
            end

            ResourceReference.new(
              type: 'aws_healthlake_fhir_export_job',
              name: name,
              resource_attributes: attributes,
              outputs: {
                job_id: "${aws_healthlake_fhir_export_job.#{name}.job_id}",
                job_status: "${aws_healthlake_fhir_export_job.#{name}.job_status}",
                submit_time: "${aws_healthlake_fhir_export_job.#{name}.submit_time}",
                end_time: "${aws_healthlake_fhir_export_job.#{name}.end_time}"
              }
            )
          end
        end
      end
    end
  end
end
