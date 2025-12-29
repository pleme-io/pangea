# frozen_string_literal: true

module Pangea
  module Architectures
    module Patterns
      module Microservices
        # Service mesh infrastructure (Istio, Consul)
        module ServiceMesh
          def create_service_mesh(name, arch_ref, platform_attrs, base_tags)
            case platform_attrs.service_mesh
            when 'istio'
              create_istio_mesh(name, platform_attrs)
            when 'consul'
              create_consul_mesh(name, arch_ref, base_tags)
            else
              {}
            end
          end

          private

          def create_istio_mesh(name, platform_attrs)
            {
              control_plane: {
                type: 'istio_control_plane',
                name: "#{name}-istio",
                distributed_tracing: platform_attrs.distributed_tracing,
                circuit_breaker: platform_attrs.circuit_breaker,
                mutual_tls: platform_attrs.mutual_tls
              }
            }
          end

          def create_consul_mesh(name, arch_ref, base_tags)
            {
              consul_server: aws_instance(
                architecture_resource_name(name, :consul_server),
                ami: 'ami-0c55b159cbfafe1f0',
                instance_type: 't3.small',
                subnet_id: arch_ref.network.private_subnets.first.id,
                tags: base_tags.merge(Tier: 'service-mesh', Component: 'consul-server')
              )
            }
          end
        end
      end
    end
  end
end
