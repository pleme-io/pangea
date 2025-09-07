# frozen_string_literal: true

module Pangea
  module Resources
    module AWS
      module EMRContainers
        # AWS EMR Containers Job Run resource
        # This resource manages EMR on EKS job runs, which are units of work such as
        # Spark applications that you submit to a virtual cluster. Job runs enable
        # distributed data processing at scale using the EMR runtime on Kubernetes.
        #
        # @see https://docs.aws.amazon.com/emr/latest/EMR-on-EKS-DevelopmentGuide/job-runs.html
        module JobRun
          # Creates an AWS EMR Containers Job Run
          #
          # @param name [Symbol] The unique name for this resource instance
          # @param attributes [Hash] The configuration options for the job run
          # @option attributes [String] :virtual_cluster_id The ID of the virtual cluster where the job will run (required)
          # @option attributes [String] :name The name of the job run (required)
          # @option attributes [String] :release_label The Amazon EMR release label to use (required)
          # @option attributes [String] :execution_role_arn The IAM role ARN for the job execution (required)
          # @option attributes [Hash] :job_driver The job driver configuration (required)
          #   - :spark_submit_job_driver [Hash] Spark submit job driver settings
          #     - :entry_point [String] The entry point for the Spark application
          #     - :entry_point_arguments [Array<String>] Arguments for the entry point
          #     - :spark_submit_parameters [String] Additional Spark submit parameters
          # @option attributes [Hash] :configuration_overrides Optional configuration overrides
          #   - :application_configuration [Array<Hash>] Application-specific property overrides
          #   - :monitoring_configuration [Hash] Monitoring settings
          #     - :persistent_app_ui [String] Enable persistent Spark UI ("ENABLED" or "DISABLED")
          #     - :cloud_watch_monitoring_configuration [Hash] CloudWatch monitoring settings
          #       - :log_group_name [String] The CloudWatch log group name
          #       - :log_stream_name_prefix [String] The log stream name prefix
          # @option attributes [Hash<String, String>] :tags A map of tags to assign to the job run
          #
          # @example Basic Spark job run
          #   aws_emrcontainers_job_run(:daily_etl_job, {
          #     virtual_cluster_id: ref(:aws_emrcontainers_virtual_cluster, :data_cluster, :id),
          #     name: "daily-etl-job",
          #     release_label: "emr-6.10.0",
          #     execution_role_arn: ref(:aws_iam_role, :emr_job_execution, :arn),
          #     job_driver: {
          #       spark_submit_job_driver: {
          #         entry_point: "s3://my-bucket/scripts/etl_job.py",
          #         entry_point_arguments: ["--date", "2024-01-15"],
          #         spark_submit_parameters: "--conf spark.executor.instances=10"
          #       }
          #     }
          #   })
          #
          # @example Advanced job run with monitoring
          #   aws_emrcontainers_job_run(:analytics_pipeline, {
          #     virtual_cluster_id: ref(:aws_emrcontainers_virtual_cluster, :analytics_cluster, :id),
          #     name: "customer-analytics-pipeline",
          #     release_label: "emr-6.15.0",
          #     execution_role_arn: ref(:aws_iam_role, :emr_analytics_role, :arn),
          #     job_driver: {
          #       spark_submit_job_driver: {
          #         entry_point: "s3://analytics-code/pipelines/customer_insights.jar",
          #         entry_point_arguments: ["--input", "s3://data-lake/customers/", "--output", "s3://analytics-results/"],
          #         spark_submit_parameters: "--class com.company.analytics.CustomerInsights --conf spark.sql.adaptive.enabled=true"
          #       }
          #     },
          #     configuration_overrides: {
          #       application_configuration: [
          #         {
          #           classification: "spark-defaults",
          #           properties: {
          #             "spark.dynamicAllocation.enabled" => "true",
          #             "spark.kubernetes.memoryOverheadFactor" => "0.2"
          #           }
          #         }
          #       ],
          #       monitoring_configuration: {
          #         persistent_app_ui: "ENABLED",
          #         cloud_watch_monitoring_configuration: {
          #           log_group_name: "/aws/emr-containers/analytics",
          #           log_stream_name_prefix: "customer-insights"
          #         }
          #       }
          #     },
          #     tags: {
          #       Pipeline: "CustomerAnalytics",
          #       Schedule: "Daily",
          #       Team: "DataScience"
          #     }
          #   })
          #
          # @return [ResourceReference] Reference to the created job run
          def aws_emrcontainers_job_run(name, attributes = {})
            resource = resource(:aws_emrcontainers_job_run, name) do
              virtual_cluster_id attributes[:virtual_cluster_id] if attributes[:virtual_cluster_id]
              name attributes[:name] if attributes[:name]
              release_label attributes[:release_label] if attributes[:release_label]
              execution_role_arn attributes[:execution_role_arn] if attributes[:execution_role_arn]
              job_driver attributes[:job_driver] if attributes[:job_driver]
              configuration_overrides attributes[:configuration_overrides] if attributes[:configuration_overrides]
              tags attributes[:tags] if attributes[:tags]
            end

            ResourceReference.new(
              type: 'aws_emrcontainers_job_run',
              name: name,
              resource_attributes: attributes,
              outputs: {
                id: "${aws_emrcontainers_job_run.#{name}.id}",
                arn: "${aws_emrcontainers_job_run.#{name}.arn}",
                state: "${aws_emrcontainers_job_run.#{name}.state}",
                state_details: "${aws_emrcontainers_job_run.#{name}.state_details}",
                created_at: "${aws_emrcontainers_job_run.#{name}.created_at}",
                created_by: "${aws_emrcontainers_job_run.#{name}.created_by}",
                finished_at: "${aws_emrcontainers_job_run.#{name}.finished_at}"
              }
            )
          end
        end
      end
    end
  end
end