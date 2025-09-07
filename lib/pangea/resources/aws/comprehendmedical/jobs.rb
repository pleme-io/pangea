# frozen_string_literal: true

module Pangea
  module Resources
    module AWS
      module ComprehendMedical
        # AWS Comprehend Medical resources for medical text analysis
        # These resources provide natural language processing capabilities
        # specifically designed for extracting medical information from clinical text.
        #
        # @see https://docs.aws.amazon.com/comprehend-medical/
        module Jobs
          # Creates an AWS Comprehend Medical Entities Detection V2 Job
          #
          # @param name [Symbol] The unique name for this resource instance
          # @param attributes [Hash] The configuration options for the entities detection job
          # @option attributes [String] :job_name The name of the entities detection job
          # @option attributes [Hash] :input_data_config Input data configuration (required)
          #   - :s3_bucket [String] The S3 bucket containing input documents
          #   - :s3_key [String] The S3 key prefix for input documents
          # @option attributes [Hash] :output_data_config Output data configuration (required)
          #   - :s3_bucket [String] The S3 bucket for output results
          #   - :s3_key [String] The S3 key prefix for output results
          # @option attributes [String] :data_access_role_arn IAM role ARN for data access (required)
          # @option attributes [String] :language_code The language of the input documents ("en")
          # @option attributes [String] :client_request_token Client token for idempotency
          # @option attributes [String] :kms_key The KMS key ARN for encryption
          #
          # @example Medical entities detection for clinical notes
          #   aws_comprehendmedical_entities_detection_v2_job(:clinical_notes_entities, {
          #     job_name: "clinical-notes-entities-extraction",
          #     input_data_config: {
          #       s3_bucket: "clinical-documents",
          #       s3_key: "patient-notes/"
          #     },
          #     output_data_config: {
          #       s3_bucket: "medical-nlp-results",
          #       s3_key: "entities-extraction/"
          #     },
          #     data_access_role_arn: ref(:aws_iam_role, :comprehend_medical_role, :arn),
          #     language_code: "en",
          #     kms_key: ref(:aws_kms_key, :medical_nlp_encryption, :arn)
          #   })
          #
          # @return [ResourceReference] Reference to the created job
          def aws_comprehendmedical_entities_detection_v2_job(name, attributes = {})
            resource = resource(:aws_comprehendmedical_entities_detection_v2_job, name) do
              job_name attributes[:job_name] if attributes[:job_name]
              input_data_config attributes[:input_data_config] if attributes[:input_data_config]
              output_data_config attributes[:output_data_config] if attributes[:output_data_config]
              data_access_role_arn attributes[:data_access_role_arn] if attributes[:data_access_role_arn]
              language_code attributes[:language_code] if attributes[:language_code]
              client_request_token attributes[:client_request_token] if attributes[:client_request_token]
              kms_key attributes[:kms_key] if attributes[:kms_key]
            end

            ResourceReference.new(
              type: 'aws_comprehendmedical_entities_detection_v2_job',
              name: name,
              resource_attributes: attributes,
              outputs: {
                job_id: "${aws_comprehendmedical_entities_detection_v2_job.#{name}.job_id}",
                job_name: "${aws_comprehendmedical_entities_detection_v2_job.#{name}.job_name}",
                job_status: "${aws_comprehendmedical_entities_detection_v2_job.#{name}.job_status}",
                submit_time: "${aws_comprehendmedical_entities_detection_v2_job.#{name}.submit_time}",
                end_time: "${aws_comprehendmedical_entities_detection_v2_job.#{name}.end_time}"
              }
            )
          end

          # Creates an AWS Comprehend Medical ICD-10-CM Inference Job
          #
          # @param name [Symbol] The unique name for this resource instance
          # @param attributes [Hash] The configuration options for the ICD-10-CM inference job
          # @option attributes [String] :job_name The name of the ICD-10-CM inference job
          # @option attributes [Hash] :input_data_config Input data configuration (required)
          #   - :s3_bucket [String] The S3 bucket containing input documents
          #   - :s3_key [String] The S3 key prefix for input documents
          # @option attributes [Hash] :output_data_config Output data configuration (required)
          #   - :s3_bucket [String] The S3 bucket for output results
          #   - :s3_key [String] The S3 key prefix for output results
          # @option attributes [String] :data_access_role_arn IAM role ARN for data access (required)
          # @option attributes [String] :language_code The language of the input documents ("en")
          # @option attributes [String] :client_request_token Client token for idempotency
          # @option attributes [String] :kms_key The KMS key ARN for encryption
          #
          # @example ICD-10-CM coding for diagnostic text
          #   aws_comprehendmedical_icd10_cm_inference_job(:diagnostic_coding, {
          #     job_name: "diagnostic-icd10-coding",
          #     input_data_config: {
          #       s3_bucket: "diagnostic-reports",
          #       s3_key: "radiology-reports/"
          #     },
          #     output_data_config: {
          #       s3_bucket: "medical-coding-results",
          #       s3_key: "icd10-codes/"
          #     },
          #     data_access_role_arn: ref(:aws_iam_role, :medical_coding_role, :arn),
          #     language_code: "en",
          #     kms_key: ref(:aws_kms_key, :medical_coding_encryption, :arn)
          #   })
          #
          # @return [ResourceReference] Reference to the created job
          def aws_comprehendmedical_icd10_cm_inference_job(name, attributes = {})
            resource = resource(:aws_comprehendmedical_icd10_cm_inference_job, name) do
              job_name attributes[:job_name] if attributes[:job_name]
              input_data_config attributes[:input_data_config] if attributes[:input_data_config]
              output_data_config attributes[:output_data_config] if attributes[:output_data_config]
              data_access_role_arn attributes[:data_access_role_arn] if attributes[:data_access_role_arn]
              language_code attributes[:language_code] if attributes[:language_code]
              client_request_token attributes[:client_request_token] if attributes[:client_request_token]
              kms_key attributes[:kms_key] if attributes[:kms_key]
            end

            ResourceReference.new(
              type: 'aws_comprehendmedical_icd10_cm_inference_job',
              name: name,
              resource_attributes: attributes,
              outputs: {
                job_id: "${aws_comprehendmedical_icd10_cm_inference_job.#{name}.job_id}",
                job_name: "${aws_comprehendmedical_icd10_cm_inference_job.#{name}.job_name}",
                job_status: "${aws_comprehendmedical_icd10_cm_inference_job.#{name}.job_status}",
                submit_time: "${aws_comprehendmedical_icd10_cm_inference_job.#{name}.submit_time}",
                end_time: "${aws_comprehendmedical_icd10_cm_inference_job.#{name}.end_time}"
              }
            )
          end

          # Creates an AWS Comprehend Medical PHI Detection Job
          #
          # @param name [Symbol] The unique name for this resource instance
          # @param attributes [Hash] The configuration options for the PHI detection job
          # @option attributes [String] :job_name The name of the PHI detection job
          # @option attributes [Hash] :input_data_config Input data configuration (required)
          #   - :s3_bucket [String] The S3 bucket containing input documents
          #   - :s3_key [String] The S3 key prefix for input documents
          # @option attributes [Hash] :output_data_config Output data configuration (required)
          #   - :s3_bucket [String] The S3 bucket for output results
          #   - :s3_key [String] The S3 key prefix for output results
          # @option attributes [String] :data_access_role_arn IAM role ARN for data access (required)
          # @option attributes [String] :language_code The language of the input documents ("en")
          # @option attributes [String] :client_request_token Client token for idempotency
          # @option attributes [String] :kms_key The KMS key ARN for encryption
          #
          # @example PHI detection for HIPAA compliance
          #   aws_comprehendmedical_phi_detection_job(:hipaa_phi_detection, {
          #     job_name: "hipaa-phi-detection-clinical-notes",
          #     input_data_config: {
          #       s3_bucket: "clinical-documents-raw",
          #       s3_key: "patient-records/"
          #     },
          #     output_data_config: {
          #       s3_bucket: "phi-detection-results",
          #       s3_key: "detected-phi/"
          #     },
          #     data_access_role_arn: ref(:aws_iam_role, :phi_detection_role, :arn),
          #     language_code: "en",
          #     kms_key: ref(:aws_kms_key, :phi_detection_encryption, :arn)
          #   })
          #
          # @return [ResourceReference] Reference to the created job
          def aws_comprehendmedical_phi_detection_job(name, attributes = {})
            resource = resource(:aws_comprehendmedical_phi_detection_job, name) do
              job_name attributes[:job_name] if attributes[:job_name]
              input_data_config attributes[:input_data_config] if attributes[:input_data_config]
              output_data_config attributes[:output_data_config] if attributes[:output_data_config]
              data_access_role_arn attributes[:data_access_role_arn] if attributes[:data_access_role_arn]
              language_code attributes[:language_code] if attributes[:language_code]
              client_request_token attributes[:client_request_token] if attributes[:client_request_token]
              kms_key attributes[:kms_key] if attributes[:kms_key]
            end

            ResourceReference.new(
              type: 'aws_comprehendmedical_phi_detection_job',
              name: name,
              resource_attributes: attributes,
              outputs: {
                job_id: "${aws_comprehendmedical_phi_detection_job.#{name}.job_id}",
                job_name: "${aws_comprehendmedical_phi_detection_job.#{name}.job_name}",
                job_status: "${aws_comprehendmedical_phi_detection_job.#{name}.job_status}",
                submit_time: "${aws_comprehendmedical_phi_detection_job.#{name}.submit_time}",
                end_time: "${aws_comprehendmedical_phi_detection_job.#{name}.end_time}"
              }
            )
          end

          # Creates an AWS Comprehend Medical RxNorm Inference Job
          #
          # @param name [Symbol] The unique name for this resource instance
          # @param attributes [Hash] The configuration options for the RxNorm inference job
          # @option attributes [String] :job_name The name of the RxNorm inference job
          # @option attributes [Hash] :input_data_config Input data configuration (required)
          #   - :s3_bucket [String] The S3 bucket containing input documents
          #   - :s3_key [String] The S3 key prefix for input documents
          # @option attributes [Hash] :output_data_config Output data configuration (required)
          #   - :s3_bucket [String] The S3 bucket for output results
          #   - :s3_key [String] The S3 key prefix for output results
          # @option attributes [String] :data_access_role_arn IAM role ARN for data access (required)
          # @option attributes [String] :language_code The language of the input documents ("en")
          # @option attributes [String] :client_request_token Client token for idempotency
          # @option attributes [String] :kms_key The KMS key ARN for encryption
          #
          # @example RxNorm medication normalization
          #   aws_comprehendmedical_rx_norm_inference_job(:medication_normalization, {
          #     job_name: "medication-rxnorm-normalization",
          #     input_data_config: {
          #       s3_bucket: "prescription-data",
          #       s3_key: "medication-lists/"
          #     },
          #     output_data_config: {
          #       s3_bucket: "medication-normalization-results",
          #       s3_key: "rxnorm-codes/"
          #     },
          #     data_access_role_arn: ref(:aws_iam_role, :medication_analysis_role, :arn),
          #     language_code: "en",
          #     kms_key: ref(:aws_kms_key, :medication_data_encryption, :arn)
          #   })
          #
          # @return [ResourceReference] Reference to the created job
          def aws_comprehendmedical_rx_norm_inference_job(name, attributes = {})
            resource = resource(:aws_comprehendmedical_rx_norm_inference_job, name) do
              job_name attributes[:job_name] if attributes[:job_name]
              input_data_config attributes[:input_data_config] if attributes[:input_data_config]
              output_data_config attributes[:output_data_config] if attributes[:output_data_config]
              data_access_role_arn attributes[:data_access_role_arn] if attributes[:data_access_role_arn]
              language_code attributes[:language_code] if attributes[:language_code]
              client_request_token attributes[:client_request_token] if attributes[:client_request_token]
              kms_key attributes[:kms_key] if attributes[:kms_key]
            end

            ResourceReference.new(
              type: 'aws_comprehendmedical_rx_norm_inference_job',
              name: name,
              resource_attributes: attributes,
              outputs: {
                job_id: "${aws_comprehendmedical_rx_norm_inference_job.#{name}.job_id}",
                job_name: "${aws_comprehendmedical_rx_norm_inference_job.#{name}.job_name}",
                job_status: "${aws_comprehendmedical_rx_norm_inference_job.#{name}.job_status}",
                submit_time: "${aws_comprehendmedical_rx_norm_inference_job.#{name}.submit_time}",
                end_time: "${aws_comprehendmedical_rx_norm_inference_job.#{name}.end_time}"
              }
            )
          end

          # Creates an AWS Comprehend Medical SNOMED CT Inference Job
          #
          # @param name [Symbol] The unique name for this resource instance
          # @param attributes [Hash] The configuration options for the SNOMED CT inference job
          # @option attributes [String] :job_name The name of the SNOMED CT inference job
          # @option attributes [Hash] :input_data_config Input data configuration (required)
          #   - :s3_bucket [String] The S3 bucket containing input documents
          #   - :s3_key [String] The S3 key prefix for input documents
          # @option attributes [Hash] :output_data_config Output data configuration (required)
          #   - :s3_bucket [String] The S3 bucket for output results
          #   - :s3_key [String] The S3 key prefix for output results
          # @option attributes [String] :data_access_role_arn IAM role ARN for data access (required)
          # @option attributes [String] :language_code The language of the input documents ("en")
          # @option attributes [String] :client_request_token Client token for idempotency
          # @option attributes [String] :kms_key The KMS key ARN for encryption
          #
          # @example SNOMED CT coding for clinical concepts
          #   aws_comprehendmedical_snomed_ct_inference_job(:clinical_concept_coding, {
          #     job_name: "clinical-concept-snomed-coding",
          #     input_data_config: {
          #       s3_bucket: "clinical-notes",
          #       s3_key: "discharge-summaries/"
          #     },
          #     output_data_config: {
          #       s3_bucket: "clinical-coding-results",
          #       s3_key: "snomed-ct-codes/"
          #     },
          #     data_access_role_arn: ref(:aws_iam_role, :clinical_coding_role, :arn),
          #     language_code: "en",
          #     kms_key: ref(:aws_kms_key, :clinical_data_encryption, :arn)
          #   })
          #
          # @return [ResourceReference] Reference to the created job
          def aws_comprehendmedical_snomed_ct_inference_job(name, attributes = {})
            resource = resource(:aws_comprehendmedical_snomed_ct_inference_job, name) do
              job_name attributes[:job_name] if attributes[:job_name]
              input_data_config attributes[:input_data_config] if attributes[:input_data_config]
              output_data_config attributes[:output_data_config] if attributes[:output_data_config]
              data_access_role_arn attributes[:data_access_role_arn] if attributes[:data_access_role_arn]
              language_code attributes[:language_code] if attributes[:language_code]
              client_request_token attributes[:client_request_token] if attributes[:client_request_token]
              kms_key attributes[:kms_key] if attributes[:kms_key]
            end

            ResourceReference.new(
              type: 'aws_comprehendmedical_snomed_ct_inference_job',
              name: name,
              resource_attributes: attributes,
              outputs: {
                job_id: "${aws_comprehendmedical_snomed_ct_inference_job.#{name}.job_id}",
                job_name: "${aws_comprehendmedical_snomed_ct_inference_job.#{name}.job_name}",
                job_status: "${aws_comprehendmedical_snomed_ct_inference_job.#{name}.job_status}",
                submit_time: "${aws_comprehendmedical_snomed_ct_inference_job.#{name}.submit_time}",
                end_time: "${aws_comprehendmedical_snomed_ct_inference_job.#{name}.end_time}"
              }
            )
          end
        end
      end
    end
  end
end