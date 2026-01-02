# frozen_string_literal: true

module Pangea
  module Components
    module ZeroTrustNetwork
      # Networking resources for Zero Trust Network
      module Networking
        def create_vpc_endpoints(name, attrs, resources)
          services = %w[s3 ec2 ssm logs]

          services.each do |service|
            endpoint_name = component_resource_name(name, :vpc_endpoint, service)
            resources[:vpc_endpoints][service] = aws_vpc_endpoint(endpoint_name, {
              vpc_id: attrs.vpc_ref,
              service_name: "com.amazonaws.#{aws_region}.#{service}",
              vpc_endpoint_type: service == 's3' ? 'Gateway' : 'Interface',
              security_group_ids: service != 's3' ? [resources[:security_groups].values.first.id] : nil,
              subnet_ids: service != 's3' ? attrs.subnet_refs : nil,
              tags: component_tags('zero_trust_network', name, attrs.tags.merge(Service: service))
            })
          end
        end

        def create_flow_logs(name, attrs, resources)
          flow_log_group_name = component_resource_name(name, :flow_logs)
          resources[:cloudwatch_logs][:flow] = aws_cloudwatch_log_group(flow_log_group_name, {
            name: "/aws/vpc/flowlogs/#{name}",
            retention_in_days: attrs.monitoring_config[:log_retention_days],
            tags: component_tags('zero_trust_network', name, attrs.tags)
          })

          resources[:flow_logs][:vpc] = aws_flow_log(:"#{name}_vpc_flow_log", {
            log_destination_type: 'cloud-watch-logs',
            log_destination: resources[:cloudwatch_logs][:flow].arn,
            traffic_type: 'ALL',
            vpc_id: attrs.vpc_ref,
            tags: component_tags('zero_trust_network', name, attrs.tags)
          })
        end
      end
    end
  end
end
