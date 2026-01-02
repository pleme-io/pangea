# frozen_string_literal: true

module Pangea
  module Components
    module ZeroTrustNetwork
      # Endpoint management for Zero Trust Network
      module Endpoints
        def create_endpoints(name, attrs, resources)
          attrs.endpoints.each { |endpoint| create_endpoint(name, attrs, resources, endpoint) }
        end

        private

        def create_endpoint(name, attrs, resources, endpoint)
          endpoint_name = component_resource_name(name, :endpoint, endpoint[:name])
          policy_document = endpoint[:policy_document] || generate_endpoint_policy(endpoint, attrs)

          resources[:verified_access_endpoints][endpoint[:name]] = aws_verifiedaccess_endpoint(endpoint_name, {
            verified_access_group_id: resources[:verified_access_groups][:main].id,
            description: "Endpoint: #{endpoint[:name]}",
            endpoint_type: endpoint[:type],
            attachment_type: 'vpc',
            domain_certificate_arn: endpoint_certificate(endpoint, name, attrs, resources),
            endpoint_domain_prefix: endpoint[:domain_name] ? endpoint[:name] : nil,
            security_group_ids: [resources[:security_groups].values.first.id],
            policy_document: policy_document,
            network_interface_options: network_interface_options(endpoint),
            tags: component_tags('zero_trust_network', name, attrs.tags.merge(EndpointName: endpoint[:name]))
          })
        end

        def endpoint_certificate(endpoint, name, attrs, resources)
          return nil unless endpoint[:domain_name]

          create_certificate(endpoint[:domain_name], name, attrs, resources)
        end

        def network_interface_options(endpoint)
          return nil unless endpoint[:type] == 'network'

          { port: endpoint[:port], protocol: endpoint[:protocol] }
        end
      end
    end
  end
end
