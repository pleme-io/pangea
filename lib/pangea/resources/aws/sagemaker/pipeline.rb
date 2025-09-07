# frozen_string_literal: true

module Pangea
  module Resources
    module AWS
      module SageMaker
        # AWS SageMaker Pipeline resource
        # This resource manages ML pipelines in Amazon SageMaker Pipelines.
        # Pipelines orchestrate ML workflows with steps for data processing, model training,
        # evaluation, and deployment, enabling automated and reproducible ML operations.
        #
        # @see https://docs.aws.amazon.com/sagemaker/latest/dg/pipelines.html
        module Pipeline
          # Creates an AWS SageMaker Pipeline
          #
          # @param name [Symbol] The unique name for this resource instance
          # @param attributes [Hash] The configuration options for the pipeline
          # @option attributes [String] :pipeline_name The name of the pipeline (required)
          # @option attributes [String] :pipeline_definition The JSON pipeline definition (required)
          # @option attributes [String] :pipeline_definition_s3_location S3 location of the pipeline definition
          # @option attributes [String] :pipeline_display_name The display name of the pipeline
          # @option attributes [String] :pipeline_description A description of the pipeline
          # @option attributes [String] :role_arn The IAM role ARN for the pipeline (required)
          # @option attributes [Hash] :parallelism_configuration Configuration for parallel execution
          #   - :max_parallel_execution_steps [Integer] Maximum number of parallel execution steps
          # @option attributes [Hash<String, String>] :tags A map of tags to assign to the resource
          #
          # @example Basic ML training pipeline
          #   aws_sagemaker_pipeline(:fraud_detection_pipeline, {
          #     pipeline_name: "fraud-detection-training-pipeline",
          #     pipeline_display_name: "Fraud Detection Model Training",
          #     pipeline_description: "End-to-end pipeline for training fraud detection models",
          #     role_arn: ref(:aws_iam_role, :sagemaker_pipeline_execution, :arn),
          #     pipeline_definition: JSON.pretty_generate({
          #       Version: "2020-12-01",
          #       Metadata: {},
          #       Parameters: [
          #         {
          #           Name: "ProcessingInstanceType",
          #           Type: "String",
          #           DefaultValue: "ml.m5.xlarge"
          #         },
          #         {
          #           Name: "TrainingInstanceType", 
          #           Type: "String",
          #           DefaultValue: "ml.m5.2xlarge"
          #         }
          #       ],
          #       Steps: [
          #         {
          #           Name: "DataPreprocessing",
          #           Type: "Processing",
          #           Arguments: {
          #             ProcessingResources: {
          #               ClusterConfig: {
          #                 InstanceType: { Get: "Parameters.ProcessingInstanceType" },
          #                 InstanceCount: 1,
          #                 VolumeSizeInGB: 20
          #               }
          #             },
          #             AppSpecification: {
          #               ImageUri: "246618743249.dkr.ecr.us-east-1.amazonaws.com/sklearn-processing:0.20.0-cpu-py3"
          #             }
          #           }
          #         },
          #         {
          #           Name: "ModelTraining",
          #           Type: "Training",
          #           Arguments: {
          #             TrainingJobName: "fraud-detection-training-job",
          #             AlgorithmSpecification: {
          #               TrainingImage: "246618743249.dkr.ecr.us-east-1.amazonaws.com/xgboost:latest",
          #               TrainingInputMode: "File"
          #             },
          #             ResourceConfig: {
          #               InstanceType: { Get: "Parameters.TrainingInstanceType" },
          #               InstanceCount: 1,
          #               VolumeSizeInGB: 10
          #             }
          #           }
          #         }
          #       ]
          #     })
          #   })
          #
          # @example Advanced pipeline with model evaluation and conditional deployment
          #   aws_sagemaker_pipeline(:customer_churn_pipeline, {
          #     pipeline_name: "customer-churn-mlops-pipeline",
          #     pipeline_display_name: "Customer Churn MLOps Pipeline",
          #     pipeline_description: "Automated pipeline for customer churn prediction with A/B testing",
          #     role_arn: ref(:aws_iam_role, :advanced_ml_pipeline, :arn),
          #     parallelism_configuration: {
          #       max_parallel_execution_steps: 5
          #     },
          #     pipeline_definition_s3_location: "s3://ml-pipelines/definitions/customer-churn-pipeline.json",
          #     tags: {
          #       Project: "CustomerRetention",
          #       Environment: "production",
          #       Team: "MLOps",
          #       PipelineType: "TrainingAndDeployment",
          #       Schedule: "Daily"
          #     }
          #   })
          #
          # @return [ResourceReference] Reference to the created pipeline
          def aws_sagemaker_pipeline(name, attributes = {})
            resource = resource(:aws_sagemaker_pipeline, name) do
              pipeline_name attributes[:pipeline_name] if attributes[:pipeline_name]
              pipeline_definition attributes[:pipeline_definition] if attributes[:pipeline_definition]
              pipeline_definition_s3_location attributes[:pipeline_definition_s3_location] if attributes[:pipeline_definition_s3_location]
              pipeline_display_name attributes[:pipeline_display_name] if attributes[:pipeline_display_name]
              pipeline_description attributes[:pipeline_description] if attributes[:pipeline_description]
              role_arn attributes[:role_arn] if attributes[:role_arn]
              parallelism_configuration attributes[:parallelism_configuration] if attributes[:parallelism_configuration]
              tags attributes[:tags] if attributes[:tags]
            end

            ResourceReference.new(
              type: 'aws_sagemaker_pipeline',
              name: name,
              resource_attributes: attributes,
              outputs: {
                id: "${aws_sagemaker_pipeline.#{name}.id}",
                arn: "${aws_sagemaker_pipeline.#{name}.arn}",
                pipeline_name: "${aws_sagemaker_pipeline.#{name}.pipeline_name}",
                pipeline_status: "${aws_sagemaker_pipeline.#{name}.pipeline_status}",
                creation_time: "${aws_sagemaker_pipeline.#{name}.creation_time}",
                last_modified_time: "${aws_sagemaker_pipeline.#{name}.last_modified_time}",
                created_by: "${aws_sagemaker_pipeline.#{name}.created_by}",
                last_modified_by: "${aws_sagemaker_pipeline.#{name}.last_modified_by}"
              }
            )
          end
        end
      end
    end
  end
end