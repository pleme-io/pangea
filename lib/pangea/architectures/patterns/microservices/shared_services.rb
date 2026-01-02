# frozen_string_literal: true

module Pangea
  module Architectures
    module Patterns
      module Microservices
        # Shared platform services (API Gateway, Message Queue, Cache)
        module SharedServices
          def create_shared_services(name, arch_ref, platform_attrs, base_tags)
            shared_services = {}

            if platform_attrs.api_gateway
              shared_services[:api_gateway] = create_api_gateway(name, base_tags)
            end

            shared_services.merge!(create_message_queue(name, platform_attrs, base_tags))

            if platform_attrs.shared_cache
              shared_services[:cache] = create_shared_cache(name, arch_ref, base_tags)
            end

            shared_services
          end

          private

          def create_api_gateway(name, base_tags)
            aws_api_gateway_v2_api(
              architecture_resource_name(name, :api_gateway),
              name: "#{name}-api",
              protocol_type: 'HTTP',
              cors_configuration: {
                allow_credentials: false,
                allow_methods: %w[GET POST PUT DELETE OPTIONS],
                allow_origins: ['*'],
                max_age: 86_400
              },
              tags: base_tags.merge(Tier: 'gateway', Component: 'api-gateway')
            )
          end

          def create_message_queue(name, platform_attrs, base_tags)
            case platform_attrs.message_queue
            when 'sqs'
              {
                message_queue: aws_sqs_queue(
                  architecture_resource_name(name, :message_queue),
                  name: "#{name}-messages",
                  visibility_timeout_seconds: 300,
                  message_retention_seconds: 1_209_600,
                  tags: base_tags.merge(Tier: 'messaging', Component: 'sqs')
                )
              }
            when 'sns'
              {
                message_topic: aws_sns_topic(
                  architecture_resource_name(name, :message_topic),
                  name: "#{name}-events",
                  tags: base_tags.merge(Tier: 'messaging', Component: 'sns')
                )
              }
            else
              {}
            end
          end

          def create_shared_cache(name, arch_ref, base_tags)
            subnet_group = aws_elasticache_subnet_group(
              architecture_resource_name(name, :cache_subnet_group),
              name: "#{name}-cache-subnet-group",
              subnet_ids: arch_ref.network.private_subnet_ids
            )

            aws_elasticache_replication_group(
              architecture_resource_name(name, :shared_cache),
              replication_group_id: "#{name}-cache",
              description: "Shared Redis cache for #{name} platform",
              node_type: 'cache.t3.micro',
              num_cache_clusters: 2,
              port: 6379,
              parameter_group_name: 'default.redis7',
              subnet_group_name: subnet_group.name,
              tags: base_tags.merge(Tier: 'cache', Component: 'redis')
            )
          end
        end
      end
    end
  end
end
