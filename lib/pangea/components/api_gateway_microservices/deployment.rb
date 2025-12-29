# frozen_string_literal: true

require 'json'

module Pangea
  module Components
    module ApiGatewayMicroservices
      # Deployment, stage, and method settings
      module Deployment
        def create_deployment_resources(name, api_ref, component_attrs, service_methods, service_integrations, component_tag_set)
          deployment_ref = create_deployment(name, api_ref, component_attrs, service_methods, service_integrations)
          stage_ref = create_stage(name, api_ref, component_attrs, deployment_ref, component_tag_set)
          method_settings_ref = create_method_settings(name, api_ref, component_attrs, stage_ref)

          { deployment: deployment_ref, stage: stage_ref, method_settings: method_settings_ref }
        end

        private

        def create_deployment(name, api_ref, component_attrs, service_methods, service_integrations)
          aws_api_gateway_deployment(
            component_resource_name(name, :deployment),
            {
              rest_api_id: api_ref.id,
              description: component_attrs.deployment_description || "Deployment for #{component_attrs.api_name}",
              stage_description: "Stage: #{component_attrs.stage_name}",
              depends_on: deployment_dependencies(service_methods, service_integrations)
            }
          )
        end

        def deployment_dependencies(service_methods, service_integrations)
          service_methods.values.flat_map { |methods| methods.values.map(&:terraform_address) } +
            service_integrations.values.flat_map { |integrations| integrations.values.map { |i| i[:integration].terraform_address } }
        end

        def create_stage(name, api_ref, component_attrs, deployment_ref, tags)
          stage_attrs = {
            deployment_id: deployment_ref.id,
            rest_api_id: api_ref.id,
            stage_name: component_attrs.stage_name,
            xray_tracing_enabled: component_attrs.xray_tracing_enabled,
            cache_cluster_enabled: component_attrs.cache_cluster_enabled,
            cache_cluster_size: component_attrs.cache_cluster_enabled ? component_attrs.cache_cluster_size : nil,
            description: "Production stage for #{component_attrs.api_name}",
            tags: tags
          }.compact

          add_access_logging(stage_attrs, component_attrs)

          aws_api_gateway_stage(component_resource_name(name, :stage), stage_attrs)
        end

        def add_access_logging(stage_attrs, component_attrs)
          return unless component_attrs.access_log_destination_arn

          stage_attrs[:access_log_settings] = {
            destination_arn: component_attrs.access_log_destination_arn,
            format: component_attrs.access_log_format || default_log_format
          }
        end

        def default_log_format
          JSON.generate({
            requestId: '$context.requestId',
            extendedRequestId: '$context.extendedRequestId',
            ip: '$context.identity.sourceIp',
            caller: '$context.identity.caller',
            user: '$context.identity.user',
            requestTime: '$context.requestTime',
            httpMethod: '$context.httpMethod',
            resourcePath: '$context.resourcePath',
            status: '$context.status',
            protocol: '$context.protocol',
            responseLength: '$context.responseLength'
          })
        end

        def create_method_settings(name, api_ref, component_attrs, stage_ref)
          aws_api_gateway_method_settings(
            component_resource_name(name, :method_settings),
            {
              rest_api_id: api_ref.id,
              stage_name: stage_ref.stage_name,
              method_path: '*/*',
              settings: {
                metrics_enabled: component_attrs.metrics_enabled,
                logging_level: component_attrs.logging_level,
                data_trace_enabled: component_attrs.data_trace_enabled,
                throttling_burst_limit: component_attrs.rate_limit.burst_limit,
                throttling_rate_limit: component_attrs.rate_limit.rate_limit,
                caching_enabled: component_attrs.cache_cluster_enabled,
                cache_ttl_in_seconds: component_attrs.cache_ttl,
                cache_data_encrypted: component_attrs.cache_cluster_enabled
              }
            }
          )
        end
      end
    end
  end
end
