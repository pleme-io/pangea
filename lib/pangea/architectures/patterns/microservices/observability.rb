# frozen_string_literal: true

module Pangea
  module Architectures
    module Patterns
      module Microservices
        # Observability infrastructure (logging, metrics, tracing)
        module Observability
          def create_observability_stack(name, arch_ref, platform_attrs, base_tags)
            observability = {}

            if platform_attrs.centralized_logging
              observability[:log_group] = create_platform_logs(name, platform_attrs, base_tags)
            end

            if platform_attrs.metrics_collection
              observability[:dashboard] = create_platform_dashboard(name, arch_ref, platform_attrs)
            end

            if platform_attrs.distributed_tracing
              observability[:tracing] = create_tracing_rule(name)
            end

            observability
          end

          private

          def create_platform_logs(name, platform_attrs, base_tags)
            aws_cloudwatch_log_group(
              architecture_resource_name(name, :platform_logs),
              name: "/aws/platform/#{name}",
              retention_in_days: platform_attrs.log_retention_days,
              tags: base_tags.merge(Tier: 'observability', Component: 'logs')
            )
          end

          def create_platform_dashboard(name, arch_ref, platform_attrs)
            aws_cloudwatch_dashboard(
              architecture_resource_name(name, :platform_dashboard),
              dashboard_name: "#{name.to_s.gsub('_', '-')}-Platform-Dashboard",
              dashboard_body: generate_platform_dashboard_body(name, arch_ref, platform_attrs)
            )
          end

          def create_tracing_rule(name)
            aws_xray_sampling_rule(
              architecture_resource_name(name, :tracing_rule),
              rule_name: "#{name}-default-sampling",
              priority: 9000,
              fixed_rate: 0.1,
              reservoir_size: 1,
              service_name: '*',
              service_type: '*',
              host: '*',
              http_method: '*',
              url_path: '*',
              version: 1
            )
          end

          def generate_platform_dashboard_body(name, arch_ref, _platform_attrs)
            jsonencode({
              widgets: [{
                type: 'metric',
                properties: {
                  metrics: [
                    ['AWS/ECS', 'CPUUtilization', 'ClusterName', arch_ref.compute[:cluster].name],
                    ['AWS/ECS', 'MemoryUtilization', 'ClusterName', arch_ref.compute[:cluster].name]
                  ],
                  period: 300,
                  stat: 'Average',
                  region: 'us-east-1',
                  title: 'Platform Resource Utilization'
                }
              }]
            })
          end
        end
      end
    end
  end
end
