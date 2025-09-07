# frozen_string_literal: true

module Pangea
  module Resources
    module AWS
      module EMRContainers
        # AWS EMR Containers Job Template resource
        # This resource manages job templates that define standard configurations for EMR on EKS jobs.
        # Templates enable consistent job configurations, simplify job submission, and enforce
        # organizational standards for data processing workloads.
        #
        # @see https://docs.aws.amazon.com/emr/latest/EMR-on-EKS-DevelopmentGuide/job-templates.html
        module JobTemplate
          # Creates an AWS EMR Containers Job Template
          #
          # @param name [Symbol] The unique name for this resource instance
          # @param attributes [Hash] The configuration options for the job template
          # @option attributes [String] :name The name of the job template (required)
          # @option attributes [Hash] :job_template_data The template data configuration (required)
          #   - :execution_role_arn [String] The IAM role ARN for job execution
          #   - :release_label [String] The Amazon EMR release label
          #   - :job_driver [Hash] The job driver configuration
          #   - :configuration_overrides [Hash] Optional configuration overrides
          #   - :parameter_configuration [Hash] Parameters that can be provided when using the template
          # @option attributes [String] :kms_key_arn The KMS key ARN for encryption
          # @option attributes [Hash<String, String>] :tags A map of tags to assign to the resource
          #
          # @example Basic Spark job template
          #   aws_emrcontainers_job_template(:etl_template, {
          #     name: "standard-etl-job-template",
          #     job_template_data: {
          #       execution_role_arn: ref(:aws_iam_role, :emr_job_execution, :arn),
          #       release_label: "emr-6.10.0",
          #       job_driver: {
          #         spark_submit_job_driver: {
          #           entry_point: "s3://my-bucket/scripts/{{ EntryPoint }}",
          #           spark_submit_parameters: "--conf spark.executor.instances={{ ExecutorInstances }}"
          #         }
          #       },
          #       parameter_configuration: {
          #         "EntryPoint": {
          #           type: "STRING",
          #           default_value: "etl_main.py"
          #         },
          #         "ExecutorInstances": {
          #           type: "NUMBER",
          #           default_value: "5"
          #         }
          #       }
          #     }
          #   })
          #
          # @example Advanced ML training job template
          #   aws_emrcontainers_job_template(:ml_training_template, {
          #     name: "ml-model-training-template",
          #     job_template_data: {
          #       execution_role_arn: ref(:aws_iam_role, :ml_job_execution, :arn),
          #       release_label: "emr-6.15.0",
          #       job_driver: {
          #         spark_submit_job_driver: {
          #           entry_point: "s3://ml-artifacts/training/{{ ModelType }}/train.py",
          #           entry_point_arguments: [
          #             "--input-path", "{{ InputPath }}",
          #             "--output-path", "{{ OutputPath }}",
          #             "--model-name", "{{ ModelName }}",
          #             "--hyperparameters", "{{ Hyperparameters }}"
          #           ],
          #           spark_submit_parameters: "--conf spark.executor.memory={{ ExecutorMemory }} --conf spark.executor.cores={{ ExecutorCores }}"
          #         }
          #       },
          #       configuration_overrides: {
          #         application_configuration: [
          #           {
          #             classification: "spark-defaults",
          #             properties: {
          #               "spark.sql.adaptive.enabled" => "true",
          #               "spark.sql.adaptive.coalescePartitions.enabled" => "true",
          #               "spark.kubernetes.executor.podTemplateFile" => "s3://ml-configs/executor-pod-template.yaml"
          #             }
          #           }
          #         ],
          #         monitoring_configuration: {
          #           persistent_app_ui: "ENABLED",
          #           cloud_watch_monitoring_configuration: {
          #             log_group_name: "/aws/emr-containers/ml-training",
          #             log_stream_name_prefix: "{{ ModelName }}"
          #           }
          #         }
          #       },
          #       parameter_configuration: {
          #         "ModelType": {
          #           type: "STRING",
          #           default_value: "xgboost"
          #         },
          #         "InputPath": {
          #           type: "STRING"
          #         },
          #         "OutputPath": {
          #           type: "STRING"
          #         },
          #         "ModelName": {
          #           type: "STRING"
          #         },
          #         "Hyperparameters": {
          #           type: "STRING",
          #           default_value: "{}"
          #         },
          #         "ExecutorMemory": {
          #           type: "STRING",
          #           default_value: "4g"
          #         },
          #         "ExecutorCores": {
          #           type: "NUMBER",
          #           default_value: "2"
          #         }
          #       }
          #     },
          #     kms_key_arn: ref(:aws_kms_key, :ml_encryption, :arn),
          #     tags: {
          #       Purpose: "MLTraining",
          #       Team: "DataScience",
          #       TemplateVersion: "2.0"
          #     }
          #   })
          #
          # @return [ResourceReference] Reference to the created job template
          def aws_emrcontainers_job_template(name, attributes = {})
            resource = resource(:aws_emrcontainers_job_template, name) do
              name attributes[:name] if attributes[:name]
              job_template_data attributes[:job_template_data] if attributes[:job_template_data]
              kms_key_arn attributes[:kms_key_arn] if attributes[:kms_key_arn]
              tags attributes[:tags] if attributes[:tags]
            end

            ResourceReference.new(
              type: 'aws_emrcontainers_job_template',
              name: name,
              resource_attributes: attributes,
              outputs: {
                id: "${aws_emrcontainers_job_template.#{name}.id}",
                arn: "${aws_emrcontainers_job_template.#{name}.arn}",
                created_at: "${aws_emrcontainers_job_template.#{name}.created_at}",
                created_by: "${aws_emrcontainers_job_template.#{name}.created_by}"
              }
            )
          end
        end
      end
    end
  end
end