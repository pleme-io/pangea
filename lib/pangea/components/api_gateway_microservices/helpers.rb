# frozen_string_literal: true

module Pangea
  module Components
    module ApiGatewayMicroservices
      # Helper methods for API Gateway
      module Helpers
        def create_vpc_links(name, component_attrs)
          vpc_links = {}

          component_attrs.service_endpoints.each do |endpoint|
            next unless endpoint.vpc_link_ref && !vpc_links[endpoint.vpc_link_ref]

            vpc_links[endpoint.vpc_link_ref] = aws_api_gateway_vpc_link(
              component_resource_name(name, :vpc_link, endpoint.name.to_sym),
              {
                name: "#{name}-#{endpoint.name}-link",
                description: "VPC link for #{endpoint.name} service",
                target_arns: [endpoint.nlb_ref.arn]
              }
            )
          end

          vpc_links
        end

        def create_waf_association(name, component_attrs, stage_ref)
          return nil unless component_attrs.waf_acl_ref

          aws_wafv2_web_acl_association(
            component_resource_name(name, :waf_association),
            {
              resource_arn: stage_ref.arn,
              web_acl_arn: component_attrs.waf_acl_ref.arn
            }
          )
        end

        def estimate_api_gateway_cost(attrs)
          cost = 0.0
          cost += api_request_cost
          cost += cache_cluster_cost(attrs)
          cost += 20.0  # Data transfer estimate
          cost += 5.0 if attrs.access_log_destination_arn  # CloudWatch Logs
          cost += 5.0 if attrs.xray_tracing_enabled  # X-Ray tracing
          cost.round(2)
        end

        def build_api_outputs(api_ref, stage_ref, component_attrs, resources)
          {
            api_id: api_ref.id,
            api_name: api_ref.name,
            api_endpoint: "https://#{api_ref.id}.execute-api.${AWS::Region}.amazonaws.com/#{stage_ref.stage_name}",
            stage_name: stage_ref.stage_name,
            service_endpoints: format_service_endpoints(api_ref, stage_ref, component_attrs),
            features: enabled_features(component_attrs, resources),
            api_key_id: resources[:api_key]&.id,
            usage_plan_id: resources[:usage_plan]&.id,
            estimated_monthly_cost: estimate_api_gateway_cost(component_attrs)
          }
        end

        private

        def api_request_cost
          estimated_requests_per_month = 10_000_000
          (estimated_requests_per_month / 1_000_000) * 3.50
        end

        def cache_cluster_cost(attrs)
          return 0.0 unless attrs.cache_cluster_enabled

          cache_costs = {
            '0.5' => 18.0, '1.6' => 144.0, '6.1' => 500.0, '13.5' => 1000.0,
            '28.4' => 2000.0, '58.2' => 4000.0, '118' => 7000.0, '237' => 14_000.0
          }
          cache_costs[attrs.cache_cluster_size] || 18.0
        end

        def format_service_endpoints(api_ref, stage_ref, component_attrs)
          component_attrs.service_endpoints.map do |endpoint|
            {
              name: endpoint.name,
              base_url: "https://#{api_ref.id}.execute-api.${AWS::Region}.amazonaws.com/#{stage_ref.stage_name}/#{endpoint.base_path}"
            }
          end
        end

        def enabled_features(component_attrs, resources)
          [
            ('Rate Limiting' if component_attrs.rate_limit.enabled),
            ("API Versioning (#{component_attrs.versioning.strategy})" if component_attrs.versioning),
            ('CORS Enabled' if component_attrs.cors.enabled),
            ('Request Validation' if resources[:validator]),
            ('Caching' if component_attrs.cache_cluster_enabled),
            ('X-Ray Tracing' if component_attrs.xray_tracing_enabled),
            ('WAF Protection' if component_attrs.waf_acl_ref),
            ('VPC Link Integration' if resources[:vpc_links]&.any?)
          ].compact
        end
      end
    end
  end
end
