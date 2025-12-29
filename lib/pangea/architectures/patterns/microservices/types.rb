# frozen_string_literal: true

require 'dry-struct'
require 'pangea/resources/types'

module Pangea
  module Architectures
    module Patterns
      module Microservices
        # Microservices platform attributes
        class MicroservicesPlatformAttributes < Dry::Struct
          transform_keys(&:to_sym)

          # Platform configuration
          attribute :platform_name, Types::String
          attribute :environment, Types::String.default('development').enum('development', 'staging', 'production')
          attribute :vpc_cidr, Types::String.default('10.0.0.0/16')
          attribute :availability_zones, Types::Array.of(Types::String).default(['us-east-1a', 'us-east-1b', 'us-east-1c'].freeze)

          # Service mesh configuration
          attribute :service_mesh, Types::String.default('istio').enum('istio', 'consul', 'linkerd', 'none')
          attribute :service_discovery, Types::Bool.default(true)
          attribute :circuit_breaker, Types::Bool.default(true)
          attribute :distributed_tracing, Types::Bool.default(true)

          # Container orchestration
          attribute :orchestrator, Types::String.default('ecs').enum('ecs', 'eks', 'fargate')
          attribute :container_registry, Types::String.default('ecr')

          # Shared services
          attribute :api_gateway, Types::Bool.default(true)
          attribute :shared_database, Types::Bool.default(false)
          attribute :message_queue, Types::String.default('sqs').enum('sqs', 'sns', 'kafka', 'none')
          attribute :shared_cache, Types::Bool.default(true)

          # Observability
          attribute :centralized_logging, Types::Bool.default(true)
          attribute :metrics_collection, Types::Bool.default(true)
          attribute :log_retention_days, Types::Integer.default(30)

          # Security
          attribute :mutual_tls, Types::Bool.default(false)
          attribute :rbac_enabled, Types::Bool.default(true)
          attribute :secrets_management, Types::Bool.default(true)

          attribute :tags, Types::Hash.default({}.freeze)
        end

        # Individual microservice attributes
        class MicroserviceAttributes < Dry::Struct
          transform_keys(&:to_sym)

          # Service configuration
          attribute :service_name, Types::String
          attribute :runtime, Types::String.default('nodejs').enum('nodejs', 'python', 'java', 'golang', 'ruby', 'csharp')
          attribute :port, Types::Integer.default(3000)
          attribute :health_check_path, Types::String.default('/health')

          # Scaling configuration
          attribute :min_instances, Types::Integer.default(1)
          attribute :max_instances, Types::Integer.default(10)
          attribute :desired_instances, Types::Integer.default(2)
          attribute :cpu_threshold, Types::Integer.default(70)
          attribute :memory_threshold, Types::Integer.default(80)

          # Database configuration
          attribute :database_type, Types::String.default('postgresql').enum('postgresql', 'mysql', 'mongodb', 'dynamodb', 'none')
          attribute :database_size, Types::String.default('db.t3.micro')
          attribute :cache_enabled, Types::Bool.default(false)

          # Security configuration
          attribute :security_level, Types::String.default('medium').enum('low', 'medium', 'high')
          attribute :expose_publicly, Types::Bool.default(false)

          # Dependencies
          attribute :depends_on, Types::Array.of(Types::String).default([].freeze)
          attribute :external_apis, Types::Array.of(Types::String).default([].freeze)

          attribute :tags, Types::Hash.default({}.freeze)
        end
      end
    end
  end
end
