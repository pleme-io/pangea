# frozen_string_literal: true

module Pangea
  module Resources
    module AWS
      module EMRContainers
        # AWS EMR Containers Managed Endpoint resource
        # This resource manages EMR on EKS managed endpoints, which are EMR Studio Workspaces
        # running on EMR on EKS. Managed endpoints enable interactive workloads and notebooks
        # for data exploration, visualization, and debugging on your virtual clusters.
        #
        # @see https://docs.aws.amazon.com/emr/latest/EMR-on-EKS-DevelopmentGuide/managed-endpoints.html
        module ManagedEndpoint
          # Creates an AWS EMR Containers Managed Endpoint
          #
          # @param name [Symbol] The unique name for this resource instance
          # @param attributes [Hash] The configuration options for the managed endpoint
          # @option attributes [String] :name The name of the managed endpoint (required)
          # @option attributes [String] :virtual_cluster_id The ID of the virtual cluster for this endpoint (required)
          # @option attributes [String] :type The type of managed endpoint (required, e.g., "JUPYTER_ENTERPRISE_GATEWAY")
          # @option attributes [String] :release_label The Amazon EMR release label to use (required)
          # @option attributes [String] :execution_role_arn The IAM role ARN for the endpoint (required)
          # @option attributes [Hash] :configuration_overrides Optional configuration overrides
          #   - :application_configuration [Array<Hash>] Application-specific property overrides
          #   - :monitoring_configuration [Hash] Monitoring configuration settings
          # @option attributes [String] :certificate_arn The certificate ARN for TLS security configuration
          # @option attributes [Hash<String, String>] :tags A map of tags to assign to the resource
          #
          # @example Basic Jupyter endpoint for data exploration
          #   aws_emrcontainers_managed_endpoint(:data_exploration_endpoint, {
          #     name: "data-exploration-jupyter",
          #     virtual_cluster_id: ref(:aws_emrcontainers_virtual_cluster, :analytics_cluster, :id),
          #     type: "JUPYTER_ENTERPRISE_GATEWAY",
          #     release_label: "emr-6.10.0",
          #     execution_role_arn: ref(:aws_iam_role, :emr_notebook_role, :arn)
          #   })
          #
          # @example Production notebook endpoint with custom configuration
          #   aws_emrcontainers_managed_endpoint(:ml_notebook_endpoint, {
          #     name: "ml-team-notebooks",
          #     virtual_cluster_id: ref(:aws_emrcontainers_virtual_cluster, :ml_cluster, :id),
          #     type: "JUPYTER_ENTERPRISE_GATEWAY",
          #     release_label: "emr-6.15.0",
          #     execution_role_arn: ref(:aws_iam_role, :ml_notebook_execution, :arn),
          #     certificate_arn: ref(:aws_acm_certificate, :notebook_tls, :arn),
          #     configuration_overrides: {
          #       application_configuration: [
          #         {
          #           classification: "jupyter-kernel-overrides",
          #           properties: {
          #             "spark.executor.memory" => "4g",
          #             "spark.executor.cores" => "2",
          #             "spark.kubernetes.executor.request.cores" => "1800m"
          #           }
          #         },
          #         {
          #           classification: "spark-defaults",
          #           properties: {
          #             "spark.dynamicAllocation.enabled" => "true",
          #             "spark.dynamicAllocation.minExecutors" => "1",
          #             "spark.dynamicAllocation.maxExecutors" => "10"
          #           }
          #         }
          #       ],
          #       monitoring_configuration: {
          #         persistent_app_ui: "ENABLED",
          #         cloud_watch_monitoring_configuration: {
          #           log_group_name: "/aws/emr-containers/notebooks",
          #           log_stream_name_prefix: "ml-team"
          #         }
          #       }
          #     },
          #     tags: {
          #       Team: "MachineLearning",
          #       Environment: "production",
          #       Purpose: "InteractiveAnalytics"
          #     }
          #   })
          #
          # @return [ResourceReference] Reference to the created managed endpoint
          def aws_emrcontainers_managed_endpoint(name, attributes = {})
            resource = resource(:aws_emrcontainers_managed_endpoint, name) do
              name attributes[:name] if attributes[:name]
              virtual_cluster_id attributes[:virtual_cluster_id] if attributes[:virtual_cluster_id]
              type attributes[:type] if attributes[:type]
              release_label attributes[:release_label] if attributes[:release_label]
              execution_role_arn attributes[:execution_role_arn] if attributes[:execution_role_arn]
              configuration_overrides attributes[:configuration_overrides] if attributes[:configuration_overrides]
              certificate_arn attributes[:certificate_arn] if attributes[:certificate_arn]
              tags attributes[:tags] if attributes[:tags]
            end

            ResourceReference.new(
              type: 'aws_emrcontainers_managed_endpoint',
              name: name,
              resource_attributes: attributes,
              outputs: {
                id: "${aws_emrcontainers_managed_endpoint.#{name}.id}",
                arn: "${aws_emrcontainers_managed_endpoint.#{name}.arn}",
                endpoint: "${aws_emrcontainers_managed_endpoint.#{name}.endpoint}",
                state: "${aws_emrcontainers_managed_endpoint.#{name}.state}",
                type: "${aws_emrcontainers_managed_endpoint.#{name}.type}",
                server_url: "${aws_emrcontainers_managed_endpoint.#{name}.server_url}",
                created_at: "${aws_emrcontainers_managed_endpoint.#{name}.created_at}"
              }
            )
          end
        end
      end
    end
  end
end