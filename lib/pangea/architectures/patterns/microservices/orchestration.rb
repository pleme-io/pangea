# frozen_string_literal: true

module Pangea
  module Architectures
    module Patterns
      module Microservices
        # Container orchestration platform (ECS/EKS)
        module Orchestration
          def create_orchestration_platform(name, arch_ref, platform_attrs, base_tags)
            orchestration = {}

            case platform_attrs.orchestrator
            when 'ecs'
              orchestration.merge!(create_ecs_platform(name, arch_ref, base_tags))
            when 'eks'
              orchestration[:cluster] = create_eks_cluster(name, arch_ref, base_tags)
            end

            orchestration[:registry] = create_container_registry(name, base_tags)
            orchestration
          end

          private

          def create_ecs_platform(name, arch_ref, base_tags)
            {
              cluster: aws_ecs_cluster(
                architecture_resource_name(name, :ecs_cluster),
                name: "#{name}-cluster",
                capacity_providers: %w[FARGATE FARGATE_SPOT],
                default_capacity_provider_strategy: [{ capacity_provider: 'FARGATE', weight: 1 }],
                tags: base_tags.merge(Tier: 'orchestration', Component: 'cluster')
              ),
              alb: aws_lb(
                architecture_resource_name(name, :services_alb),
                name: "#{name}-services-alb",
                load_balancer_type: 'application',
                subnets: arch_ref.network.public_subnet_ids,
                tags: base_tags.merge(Tier: 'orchestration', Component: 'load-balancer')
              )
            }
          end

          def create_eks_cluster(name, arch_ref, base_tags)
            aws_eks_cluster(
              architecture_resource_name(name, :eks_cluster),
              name: "#{name}-cluster",
              version: '1.28',
              vpc_config: { subnet_ids: arch_ref.network.all_subnet_ids },
              tags: base_tags.merge(Tier: 'orchestration', Component: 'cluster')
            )
          end

          def create_container_registry(name, base_tags)
            aws_ecr_repository(
              architecture_resource_name(name, :registry),
              name: "#{name}/services",
              image_tag_mutability: 'MUTABLE',
              image_scanning_configuration: { scan_on_push: true },
              tags: base_tags.merge(Tier: 'orchestration', Component: 'registry')
            )
          end
        end
      end
    end
  end
end
