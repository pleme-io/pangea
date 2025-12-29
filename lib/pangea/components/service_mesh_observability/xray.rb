# frozen_string_literal: true

module Pangea
  module Components
    module ServiceMeshObservability
      # X-Ray tracing configuration
      module Xray
        def create_xray_encryption(name, component_attrs, component_tag_set)
          return nil unless component_attrs.xray_enabled && component_attrs.xray_encryption_config[:type] == 'KMS'

          aws_xray_encryption_config(
            component_resource_name(name, :xray_encryption),
            {
              type: 'KMS',
              key_id: component_attrs.xray_encryption_config[:key_id] || 'alias/aws/xray'
            }
          )
        end

        def create_sampling_rules(name, component_attrs, component_tag_set)
          sampling_rules = {}

          component_attrs.services.each do |service|
            sampling_rules[service.name.to_sym] = aws_xray_sampling_rule(
              component_resource_name(name, :sampling_rule, service.name.to_sym),
              {
                rule_name: "#{name}-#{service.name}-sampling",
                priority: 9000,
                version: 1,
                reservoir_size: 1,
                fixed_rate: component_attrs.tracing.sampling_rate,
                url_path: '*',
                host: '*',
                http_method: '*',
                service_type: '*',
                service_name: service.name,
                resource_arn: '*',
                attributes: { namespace: service.namespace },
                tags: component_tag_set
              }
            )
          end

          sampling_rules
        end

        def create_xray_group(name, component_attrs, component_tag_set)
          aws_xray_group(
            component_resource_name(name, :xray_group),
            {
              group_name: component_attrs.mesh_name,
              filter_expression: "service(\"#{component_attrs.services.map(&:name).join('" OR "')}\")",
              insights_configuration: component_attrs.xray_insights_enabled ? {
                insights_enabled: true,
                notifications_enabled: component_attrs.alerting.enabled
              } : nil,
              tags: component_tag_set
            }.compact
          )
        end
      end
    end
  end
end
