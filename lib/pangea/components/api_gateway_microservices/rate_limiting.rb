# frozen_string_literal: true

module Pangea
  module Components
    module ApiGatewayMicroservices
      # Usage plan and API key creation
      module RateLimiting
        def create_rate_limiting_resources(name, api_ref, component_attrs, stage_ref, component_tag_set)
          return {} unless component_attrs.rate_limit.enabled

          usage_plan_ref = create_usage_plan(name, api_ref, component_attrs, stage_ref, component_tag_set)
          api_key_ref = create_api_key(name, component_attrs, component_tag_set)
          usage_plan_key_ref = create_usage_plan_key(name, api_key_ref, usage_plan_ref)

          {
            usage_plan: usage_plan_ref,
            api_key: api_key_ref,
            usage_plan_key: usage_plan_key_ref
          }
        end

        private

        def create_usage_plan(name, api_ref, component_attrs, stage_ref, tags)
          aws_api_gateway_usage_plan(
            component_resource_name(name, :usage_plan),
            {
              name: "#{name}-usage-plan",
              description: "Usage plan for #{component_attrs.api_name}",
              api_stages: [{ api_id: api_ref.id, stage: stage_ref.stage_name }],
              throttle: {
                burst_limit: component_attrs.rate_limit.burst_limit,
                rate_limit: component_attrs.rate_limit.rate_limit
              },
              quota: usage_plan_quota(component_attrs),
              tags: tags
            }.compact
          )
        end

        def usage_plan_quota(component_attrs)
          return nil unless component_attrs.rate_limit.quota_limit

          {
            limit: component_attrs.rate_limit.quota_limit,
            period: component_attrs.rate_limit.quota_period
          }
        end

        def create_api_key(name, component_attrs, tags)
          aws_api_gateway_api_key(
            component_resource_name(name, :api_key),
            {
              name: "#{name}-api-key",
              description: "API key for #{component_attrs.api_name}",
              enabled: true,
              tags: tags
            }
          )
        end

        def create_usage_plan_key(name, api_key_ref, usage_plan_ref)
          aws_api_gateway_usage_plan_key(
            component_resource_name(name, :usage_plan_key),
            {
              key_id: api_key_ref.id,
              key_type: 'API_KEY',
              usage_plan_id: usage_plan_ref.id
            }
          )
        end
      end
    end
  end
end
