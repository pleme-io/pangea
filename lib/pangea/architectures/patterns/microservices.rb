# frozen_string_literal: true
# Copyright 2025 The Pangea Authors
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


require 'dry-struct'
require 'pangea/resources/types'
require 'pangea/architectures/base'

module Pangea
  module Architectures
    module Patterns
      # Microservices Architecture - Service mesh platform with individual services
      module Microservices
        include Base
        
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
        
        # Create a complete microservices platform
        #
        # @param name [Symbol] Platform name
        # @param attributes [Hash] Platform configuration
        # @return [ArchitectureReference] Complete platform reference
        def microservices_platform_architecture(name, attributes = {})
          # Validate and set defaults
          platform_attrs = MicroservicesPlatformAttributes.new(attributes)
          arch_ref = create_architecture_reference('microservices_platform', name, platform_attrs.to_h)
          
          # Generate platform tags
          base_tags = architecture_tags(arch_ref, {
            Platform: platform_attrs.platform_name,
            Environment: platform_attrs.environment,
            ServiceMesh: platform_attrs.service_mesh
          }.merge(platform_attrs.tags))
          
          # 1. Create network foundation
          arch_ref.network = vpc_with_subnets(
            architecture_resource_name(name, :platform_network),
            vpc_cidr: platform_attrs.vpc_cidr,
            availability_zones: platform_attrs.availability_zones,
            attributes: {
              vpc_tags: base_tags.merge(Tier: 'network'),
              public_subnet_tags: base_tags.merge(Tier: 'public', Purpose: 'load-balancers'),
              private_subnet_tags: base_tags.merge(Tier: 'private', Purpose: 'services')
            }
          )
          
          # 2. Create container orchestration platform
          orchestration = create_orchestration_platform(name, arch_ref, platform_attrs, base_tags)
          arch_ref.compute = orchestration
          
          # 3. Create shared services
          shared_services = create_shared_services(name, arch_ref, platform_attrs, base_tags)
          arch_ref.storage = shared_services
          
          # 4. Create service mesh (if enabled)
          if platform_attrs.service_mesh != 'none'
            service_mesh = create_service_mesh(name, arch_ref, platform_attrs, base_tags)
            arch_ref.network[:service_mesh] = service_mesh
          end
          
          # 5. Create observability stack
          observability = create_observability_stack(name, arch_ref, platform_attrs, base_tags)
          arch_ref.monitoring = observability
          
          # 6. Create security services
          security_services = create_security_services(name, arch_ref, platform_attrs, base_tags)
          arch_ref.security = security_services
          
          arch_ref
        end
        
        # Create an individual microservice within the platform
        #
        # @param name [Symbol] Service name
        # @param platform_ref [ArchitectureReference] Platform reference
        # @param attributes [Hash] Service configuration
        # @return [ArchitectureReference] Service reference
        def microservice_architecture(name, platform_ref:, attributes: {})
          # Validate attributes
          service_attrs = MicroserviceAttributes.new(attributes.merge(service_name: name.to_s))
          arch_ref = create_architecture_reference('microservice', name, service_attrs.to_h)
          
          # Generate service tags
          base_tags = architecture_tags(arch_ref, {
            Service: service_attrs.service_name,
            Runtime: service_attrs.runtime,
            SecurityLevel: service_attrs.security_level,
            Platform: platform_ref.name.to_s
          }.merge(service_attrs.tags))
          
          # 1. Create service database (if enabled)
          if service_attrs.database_type != 'none'
            database = create_service_database(name, arch_ref, platform_ref, service_attrs, base_tags)
            arch_ref.database = database
          end
          
          # 2. Create service compute resources
          compute = create_service_compute(name, arch_ref, platform_ref, service_attrs, base_tags)
          arch_ref.compute = compute
          
          # 3. Create service-specific security
          security = create_service_security(name, arch_ref, platform_ref, service_attrs, base_tags)
          arch_ref.security = security
          
          # 4. Create service monitoring
          monitoring = create_service_monitoring(name, arch_ref, platform_ref, service_attrs, base_tags)
          arch_ref.monitoring = monitoring
          
          arch_ref
        end
        
        private
        
        # Create ECS/EKS cluster and supporting infrastructure
        def create_orchestration_platform(name, arch_ref, platform_attrs, base_tags)
          orchestration = {}
          
          case platform_attrs.orchestrator
          when 'ecs'
            # ECS Cluster
            orchestration[:cluster] = aws_ecs_cluster(
              architecture_resource_name(name, :ecs_cluster),
              name: "#{name}-cluster",
              capacity_providers: ['FARGATE', 'FARGATE_SPOT'],
              default_capacity_provider_strategy: [
                {
                  capacity_provider: 'FARGATE',
                  weight: 1
                }
              ],
              tags: base_tags.merge(Tier: 'orchestration', Component: 'cluster')
            )
            
            # Application Load Balancer for services
            orchestration[:alb] = aws_lb(
              architecture_resource_name(name, :services_alb),
              name: "#{name}-services-alb",
              load_balancer_type: 'application',
              subnets: arch_ref.network.public_subnet_ids,
              tags: base_tags.merge(Tier: 'orchestration', Component: 'load-balancer')
            )
            
          when 'eks'
            # EKS Cluster (simplified)
            orchestration[:cluster] = aws_eks_cluster(
              architecture_resource_name(name, :eks_cluster),
              name: "#{name}-cluster",
              version: '1.28',
              vpc_config: {
                subnet_ids: arch_ref.network.all_subnet_ids
              },
              tags: base_tags.merge(Tier: 'orchestration', Component: 'cluster')
            )
          end
          
          # Container Registry
          orchestration[:registry] = aws_ecr_repository(
            architecture_resource_name(name, :registry),
            name: "#{name}/services",
            image_tag_mutability: 'MUTABLE',
            image_scanning_configuration: {
              scan_on_push: true
            },
            tags: base_tags.merge(Tier: 'orchestration', Component: 'registry')
          )
          
          orchestration
        end
        
        # Create shared services like API Gateway, SQS, etc.
        def create_shared_services(name, arch_ref, platform_attrs, base_tags)
          shared_services = {}
          
          # API Gateway
          if platform_attrs.api_gateway
            shared_services[:api_gateway] = aws_api_gateway_v2_api(
              architecture_resource_name(name, :api_gateway),
              name: "#{name}-api",
              protocol_type: 'HTTP',
              cors_configuration: {
                allow_credentials: false,
                allow_methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
                allow_origins: ['*'],
                max_age: 86400
              },
              tags: base_tags.merge(Tier: 'gateway', Component: 'api-gateway')
            )
          end
          
          # Message Queue
          case platform_attrs.message_queue
          when 'sqs'
            shared_services[:message_queue] = aws_sqs_queue(
              architecture_resource_name(name, :message_queue),
              name: "#{name}-messages",
              visibility_timeout_seconds: 300,
              message_retention_seconds: 1209600,  # 14 days
              tags: base_tags.merge(Tier: 'messaging', Component: 'sqs')
            )
          when 'sns'
            shared_services[:message_topic] = aws_sns_topic(
              architecture_resource_name(name, :message_topic),
              name: "#{name}-events",
              tags: base_tags.merge(Tier: 'messaging', Component: 'sns')
            )
          end
          
          # Shared cache
          if platform_attrs.shared_cache
            shared_services[:cache] = aws_elasticache_replication_group(
              architecture_resource_name(name, :shared_cache),
              replication_group_id: "#{name}-cache",
              description: "Shared Redis cache for #{name} platform",
              node_type: 'cache.t3.micro',
              num_cache_clusters: 2,
              port: 6379,
              parameter_group_name: 'default.redis7',
              subnet_group_name: aws_elasticache_subnet_group(
                architecture_resource_name(name, :cache_subnet_group),
                name: "#{name}-cache-subnet-group",
                subnet_ids: arch_ref.network.private_subnet_ids
              ).name,
              tags: base_tags.merge(Tier: 'cache', Component: 'redis')
            )
          end
          
          shared_services
        end
        
        # Create service mesh infrastructure
        def create_service_mesh(name, arch_ref, platform_attrs, base_tags)
          service_mesh = {}
          
          case platform_attrs.service_mesh
          when 'istio'
            # Service mesh control plane (simplified representation)
            service_mesh[:control_plane] = {
              type: 'istio_control_plane',
              name: "#{name}-istio",
              distributed_tracing: platform_attrs.distributed_tracing,
              circuit_breaker: platform_attrs.circuit_breaker,
              mutual_tls: platform_attrs.mutual_tls
            }
          when 'consul'
            # Consul service mesh
            service_mesh[:consul_server] = aws_instance(
              architecture_resource_name(name, :consul_server),
              ami: 'ami-0c55b159cbfafe1f0',  # Would use Consul AMI
              instance_type: 't3.small',
              subnet_id: arch_ref.network.private_subnets.first.id,
              tags: base_tags.merge(Tier: 'service-mesh', Component: 'consul-server')
            )
          end
          
          service_mesh
        end
        
        # Create observability infrastructure
        def create_observability_stack(name, arch_ref, platform_attrs, base_tags)
          observability = {}
          
          # Centralized logging
          if platform_attrs.centralized_logging
            observability[:log_group] = aws_cloudwatch_log_group(
              architecture_resource_name(name, :platform_logs),
              name: "/aws/platform/#{name}",
              retention_in_days: platform_attrs.log_retention_days,
              tags: base_tags.merge(Tier: 'observability', Component: 'logs')
            )
          end
          
          # Metrics collection
          if platform_attrs.metrics_collection
            observability[:dashboard] = aws_cloudwatch_dashboard(
              architecture_resource_name(name, :platform_dashboard),
              dashboard_name: "#{name.to_s.gsub('_', '-')}-Platform-Dashboard",
              dashboard_body: generate_platform_dashboard_body(name, arch_ref, platform_attrs)
            )
          end
          
          # Distributed tracing (X-Ray)
          if platform_attrs.distributed_tracing
            observability[:tracing] = aws_xray_sampling_rule(
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
          
          observability
        end
        
        # Create platform security services
        def create_security_services(name, arch_ref, platform_attrs, base_tags)
          security = {}
          
          # Secrets management
          if platform_attrs.secrets_management
            security[:secrets_key] = aws_kms_key(
              architecture_resource_name(name, :secrets_key),
              description: "KMS key for #{name} platform secrets",
              tags: base_tags.merge(Tier: 'security', Component: 'kms')
            )
          end
          
          # Default security group for services
          security[:default_sg] = aws_security_group(
            architecture_resource_name(name, :default_sg),
            name_prefix: "#{name}-default-",
            vpc_id: arch_ref.network.vpc.id,
            ingress_rules: [
              {
                from_port: 0,
                to_port: 65535,
                protocol: 'tcp',
                self: true,
                description: 'All traffic within security group'
              }
            ],
            egress_rules: [
              {
                from_port: 0,
                to_port: 0,
                protocol: '-1',
                cidr_blocks: ['0.0.0.0/0'],
                description: 'All outbound traffic'
              }
            ],
            tags: base_tags.merge(Tier: 'security', Component: 'default-sg')
          )
          
          security
        end
        
        # Create database for individual microservice
        def create_service_database(name, arch_ref, platform_ref, service_attrs, base_tags)
          case service_attrs.database_type
          when 'postgresql', 'mysql'
            aws_db_instance(
              architecture_resource_name(name, :database),
              identifier: "#{name}-#{service_attrs.database_type}",
              engine: service_attrs.database_type == 'postgresql' ? 'postgres' : 'mysql',
              instance_class: service_attrs.database_size,
              allocated_storage: 20,
              storage_encrypted: service_attrs.security_level == 'high',
              
              db_name: name.to_s.gsub(/[^a-zA-Z0-9]/, ''),
              username: 'admin',
              manage_master_user_password: true,
              
              vpc_security_group_ids: [platform_ref.security[:default_sg].id],
              db_subnet_group_name: create_db_subnet_group(name, platform_ref, base_tags).name,
              
              tags: base_tags.merge(Tier: 'database', Component: service_attrs.database_type)
            )
          when 'dynamodb'
            aws_dynamodb_table(
              architecture_resource_name(name, :dynamodb),
              name: "#{name}-table",
              billing_mode: 'PAY_PER_REQUEST',
              hash_key: 'id',
              attributes: [
                { name: 'id', type: 'S' }
              ],
              tags: base_tags.merge(Tier: 'database', Component: 'dynamodb')
            )
          end
        end
        
        # Create ECS service for microservice
        def create_service_compute(name, arch_ref, platform_ref, service_attrs, base_tags)
          # Task definition
          task_definition = aws_ecs_task_definition(
            architecture_resource_name(name, :task_def),
            family: "#{name}-task",
            network_mode: 'awsvpc',
            requires_compatibilities: ['FARGATE'],
            cpu: '256',
            memory: '512',
            execution_role_arn: create_task_execution_role(name, base_tags).arn,
            
            container_definitions: generate_container_definition(name, arch_ref, service_attrs),
            
            tags: base_tags.merge(Tier: 'compute', Component: 'task-definition')
          )
          
          # ECS Service
          service = aws_ecs_service(
            architecture_resource_name(name, :service),
            name: "#{name}-service",
            cluster: platform_ref.compute[:cluster].id,
            task_definition: task_definition.arn,
            desired_count: service_attrs.desired_instances,
            launch_type: 'FARGATE',
            
            network_configuration: {
              subnets: platform_ref.network.private_subnet_ids,
              security_groups: [arch_ref.security[:service_sg].id],
              assign_public_ip: service_attrs.expose_publicly
            },
            
            tags: base_tags.merge(Tier: 'compute', Component: 'service')
          )
          
          { task_definition: task_definition, service: service }
        end
        
        # Create service-specific security group
        def create_service_security(name, arch_ref, platform_ref, service_attrs, base_tags)
          service_sg = aws_security_group(
            architecture_resource_name(name, :service_sg),
            name_prefix: "#{name}-service-",
            vpc_id: platform_ref.network.vpc.id,
            ingress_rules: [
              {
                from_port: service_attrs.port,
                to_port: service_attrs.port,
                protocol: 'tcp',
                security_groups: [platform_ref.security[:default_sg].id],
                description: "#{service_attrs.runtime} service port"
              }
            ],
            tags: base_tags.merge(Tier: 'security', Component: 'service-sg')
          )
          
          { service_sg: service_sg }
        end
        
        # Create service monitoring resources
        def create_service_monitoring(name, arch_ref, platform_ref, service_attrs, base_tags)
          log_group = aws_cloudwatch_log_group(
            architecture_resource_name(name, :service_logs),
            name: "/aws/ecs/#{name}",
            retention_in_days: platform_ref.attributes[:log_retention_days] || 30,
            tags: base_tags.merge(Tier: 'monitoring', Component: 'service-logs')
          )
          
          { log_group: log_group }
        end
        
        # Helper methods
        def create_db_subnet_group(name, platform_ref, base_tags)
          aws_db_subnet_group(
            architecture_resource_name(name, :db_subnet_group),
            name: "#{name}-db-subnet-group",
            subnet_ids: platform_ref.network.private_subnet_ids,
            tags: base_tags.merge(Tier: 'database', Component: 'subnet-group')
          )
        end
        
        def create_task_execution_role(name, base_tags)
          aws_iam_role(
            architecture_resource_name(name, :execution_role),
            name: "#{name}-execution-role",
            assume_role_policy: jsonencode({
              Version: '2012-10-17',
              Statement: [
                {
                  Action: 'sts:AssumeRole',
                  Effect: 'Allow',
                  Principal: {
                    Service: 'ecs-tasks.amazonaws.com'
                  }
                }
              ]
            }),
            managed_policy_arns: [
              'arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy'
            ],
            tags: base_tags.merge(Tier: 'security', Component: 'execution-role')
          )
        end
        
        def generate_container_definition(name, arch_ref, service_attrs)
          jsonencode([
            {
              name: name.to_s,
              image: "#{name}:latest",
              portMappings: [
                {
                  containerPort: service_attrs.port,
                  protocol: 'tcp'
                }
              ],
              environment: [
                {
                  name: 'SERVICE_NAME',
                  value: service_attrs.service_name
                },
                {
                  name: 'SERVICE_PORT',
                  value: service_attrs.port.to_s
                }
              ],
              logConfiguration: {
                logDriver: 'awslogs',
                options: {
                  'awslogs-group': "/aws/ecs/#{name}",
                  'awslogs-region': 'us-east-1',
                  'awslogs-stream-prefix': 'ecs'
                }
              },
              healthCheck: {
                command: ["CMD-SHELL", "curl -f http://localhost:#{service_attrs.port}#{service_attrs.health_check_path} || exit 1"],
                interval: 30,
                timeout: 5,
                retries: 3,
                startPeriod: 60
              }
            }
          ])
        end
        
        def generate_platform_dashboard_body(name, arch_ref, platform_attrs)
          jsonencode({
            widgets: [
              {
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
              }
            ]
          })
        end
      end
    end
  end
end