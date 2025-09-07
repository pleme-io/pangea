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
        # AWS HealthLake resources for healthcare data management
        # These resources manage FHIR-compliant healthcare data storage, transformation,
        # and analytics for clinical and medical research applications.
        #
        # @see https://docs.aws.amazon.com/healthlake/
        module FHIRDatastore
          # Creates an AWS HealthLake FHIR Datastore
          #
          # @param name [Symbol] The unique name for this resource instance
          # @param attributes [Hash] The configuration options for the FHIR datastore
          # @option attributes [String] :datastore_name The name of the FHIR datastore
          # @option attributes [String] :datastore_type_version The FHIR version for the datastore (required, "R4")
          # @option attributes [Hash] :preload_data_config Configuration for preloading data
          #   - :preload_data_type [String] Type of preload data ("SYNTHEA")
          # @option attributes [Hash] :sse_configuration Server-side encryption configuration
          #   - :kms_encryption_config [Hash] KMS encryption settings
          #     - :cmk_type [String] The type of customer master key ("CUSTOMER_MANAGED_KMS_KEY" or "AWS_OWNED_KMS_KEY")
          #     - :kms_key_id [String] The KMS key ID for encryption
          # @option attributes [Hash] :identity_provider_configuration Identity provider configuration
          #   - :authorization_strategy [String] Authorization strategy ("SMART_ON_FHIR_V1" or "AWS_AUTH")
          #   - :fine_grained_authorization_enabled [Boolean] Enable fine-grained authorization
          #   - :metadata [String] Identity provider metadata
          #   - :idp_lambda_arn [String] Lambda function ARN for custom identity provider
          # @option attributes [Hash<String, String>] :tags A map of tags to assign to the resource
          #
          # @example Basic FHIR datastore for clinical data
          #   aws_healthlake_fhir_datastore(:clinical_data_store, {
          #     datastore_name: "clinical-fhir-datastore",
          #     datastore_type_version: "R4",
          #     sse_configuration: {
          #       kms_encryption_config: {
          #         cmk_type: "AWS_OWNED_KMS_KEY"
          #       }
          #     },
          #     tags: {
          #       Purpose: "ClinicalData",
          #       Compliance: "HIPAA",
          #       Environment: "production"
          #     }
          #   })
          #
          # @example Advanced FHIR datastore with SMART on FHIR
          #   aws_healthlake_fhir_datastore(:research_data_store, {
          #     datastore_name: "medical-research-fhir-datastore",
          #     datastore_type_version: "R4",
          #     preload_data_config: {
          #       preload_data_type: "SYNTHEA"
          #     },
          #     sse_configuration: {
          #       kms_encryption_config: {
          #         cmk_type: "CUSTOMER_MANAGED_KMS_KEY",
          #         kms_key_id: ref(:aws_kms_key, :healthlake_encryption, :arn)
          #       }
          #     },
          #     identity_provider_configuration: {
          #       authorization_strategy: "SMART_ON_FHIR_V1",
          #       fine_grained_authorization_enabled: true,
          #       idp_lambda_arn: ref(:aws_lambda_function, :fhir_auth_handler, :arn)
          #     },
          #     tags: {
          #       Purpose: "MedicalResearch",
          #       DataType: "SyntheticPatientData",
          #       ResearchStudy: "COVID19Outcomes",
          #       Compliance: "HIPAA"
          #     }
          #   })
          #
          # @return [ResourceReference] Reference to the created FHIR datastore
          def aws_healthlake_fhir_datastore(name, attributes = {})
            resource = resource(:aws_healthlake_fhir_datastore, name) do
              datastore_name attributes[:datastore_name] if attributes[:datastore_name]
              datastore_type_version attributes[:datastore_type_version] if attributes[:datastore_type_version]
              preload_data_config attributes[:preload_data_config] if attributes[:preload_data_config]
              sse_configuration attributes[:sse_configuration] if attributes[:sse_configuration]
              identity_provider_configuration attributes[:identity_provider_configuration] if attributes[:identity_provider_configuration]
              tags attributes[:tags] if attributes[:tags]
            end

            ResourceReference.new(
              type: 'aws_healthlake_fhir_datastore',
              name: name,
              resource_attributes: attributes,
              outputs: {
                datastore_arn: "${aws_healthlake_fhir_datastore.#{name}.datastore_arn}",
                datastore_id: "${aws_healthlake_fhir_datastore.#{name}.datastore_id}",
                datastore_endpoint: "${aws_healthlake_fhir_datastore.#{name}.datastore_endpoint}",
                datastore_status: "${aws_healthlake_fhir_datastore.#{name}.datastore_status}",
                created_at: "${aws_healthlake_fhir_datastore.#{name}.created_at}"
              }
            )
          end

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

          # Creates an AWS HealthLake FHIR Import Job
          #
          # @param name [Symbol] The unique name for this resource instance
          # @param attributes [Hash] The configuration options for the import job
          # @option attributes [String] :job_name The name of the import job
          # @option attributes [String] :datastore_id The ID of the FHIR datastore (required)
          # @option attributes [Hash] :input_data_config Input data configuration (required)
          #   - :s3_uri [String] The S3 URI containing FHIR data to import
          # @option attributes [Hash] :job_output_data_config Output data configuration
          #   - :s3_configuration [Hash] S3 output configuration
          #     - :s3_uri [String] The S3 URI for job outputs
          #     - :kms_key_id [String] KMS key for encryption
          # @option attributes [String] :data_access_role_arn IAM role ARN for data access (required)
          # @option attributes [String] :client_token Client token for idempotency
          #
          # @example Import FHIR data from research study
          #   aws_healthlake_fhir_import_job(:research_data_import, {
          #     job_name: "covid19-research-data-import",
          #     datastore_id: ref(:aws_healthlake_fhir_datastore, :research_data_store, :datastore_id),
          #     data_access_role_arn: ref(:aws_iam_role, :healthlake_import_role, :arn),
          #     input_data_config: {
          #       s3_uri: "s3://medical-research-data/covid19-fhir-bundle/"
          #     },
          #     job_output_data_config: {
          #       s3_configuration: {
          #         s3_uri: "s3://healthlake-import-results/covid19-import/",
          #         kms_key_id: ref(:aws_kms_key, :research_data_encryption, :arn)
          #       }
          #     }
          #   })
          #
          # @return [ResourceReference] Reference to the created import job
          def aws_healthlake_fhir_import_job(name, attributes = {})
            resource = resource(:aws_healthlake_fhir_import_job, name) do
              job_name attributes[:job_name] if attributes[:job_name]
              datastore_id attributes[:datastore_id] if attributes[:datastore_id]
              input_data_config attributes[:input_data_config] if attributes[:input_data_config]
              job_output_data_config attributes[:job_output_data_config] if attributes[:job_output_data_config]
              data_access_role_arn attributes[:data_access_role_arn] if attributes[:data_access_role_arn]
              client_token attributes[:client_token] if attributes[:client_token]
            end

            ResourceReference.new(
              type: 'aws_healthlake_fhir_import_job',
              name: name,
              resource_attributes: attributes,
              outputs: {
                job_id: "${aws_healthlake_fhir_import_job.#{name}.job_id}",
                job_status: "${aws_healthlake_fhir_import_job.#{name}.job_status}",
                submit_time: "${aws_healthlake_fhir_import_job.#{name}.submit_time}",
                end_time: "${aws_healthlake_fhir_import_job.#{name}.end_time}"
              }
            )
          end
        end
      end
    end
  end
end