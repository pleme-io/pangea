# frozen_string_literal: true
# Copyright 2025 The Pangea Authors

require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/hcloud_load_balancer_service/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module HcloudLoadBalancerService
      # Create Load Balancer Service
      def hcloud_load_balancer_service(name, attributes = {})
        lbs_attrs = Hetzner::Types::LoadBalancerServiceAttributes.new(attributes)

        resource(:hcloud_load_balancer_service, name) do
          load_balancer_id lbs_attrs.load_balancer_id
          protocol lbs_attrs.protocol
          listen_port lbs_attrs.listen_port if lbs_attrs.listen_port
          destination_port lbs_attrs.destination_port if lbs_attrs.destination_port
          proxyprotocol lbs_attrs.proxyprotocol

          if lbs_attrs.http
            http do
              lbs_attrs.http.each do |key, value|
                public_send(key, value)
              end
            end
          end

          if lbs_attrs.health_check
            health_check do
              protocol lbs_attrs.health_check[:protocol] if lbs_attrs.health_check[:protocol]
              port lbs_attrs.health_check[:port] if lbs_attrs.health_check[:port]
              interval lbs_attrs.health_check[:interval] if lbs_attrs.health_check[:interval]
              timeout lbs_attrs.health_check[:timeout] if lbs_attrs.health_check[:timeout]
              retries lbs_attrs.health_check[:retries] if lbs_attrs.health_check[:retries]

              if lbs_attrs.health_check[:http]
                http do
                  lbs_attrs.health_check[:http].each do |k, v|
                    public_send(k, v)
                  end
                end
              end
            end
          end
        end

        ResourceReference.new(
          type: 'hcloud_load_balancer_service',
          name: name,
          resource_attributes: lbs_attrs.to_h,
          outputs: {
            id: "${hcloud_load_balancer_service.#{name}.id}",
            load_balancer_id: "${hcloud_load_balancer_service.#{name}.load_balancer_id}",
            protocol: "${hcloud_load_balancer_service.#{name}.protocol}",
            listen_port: "${hcloud_load_balancer_service.#{name}.listen_port}"
          }
        )
      end
    end

    module Hetzner
      include HcloudLoadBalancerService
    end
  end
end

Pangea::ResourceRegistry.register_module(Pangea::Resources::Hetzner)
