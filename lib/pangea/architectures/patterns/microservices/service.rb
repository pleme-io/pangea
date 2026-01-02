# frozen_string_literal: true

module Pangea
  module Architectures
    module Patterns
      module Microservices
        # Individual microservice creation
        module Service
          def create_service_database(name, _arch_ref, platform_ref, service_attrs, base_tags)
            case service_attrs.database_type
            when 'postgresql', 'mysql'
              create_rds_database(name, platform_ref, service_attrs, base_tags)
            when 'dynamodb'
              create_dynamodb_table(name, base_tags)
            end
          end

          def create_service_compute(name, arch_ref, platform_ref, service_attrs, base_tags)
            task_definition = create_task_definition(name, arch_ref, service_attrs, base_tags)
            service = create_ecs_service(name, platform_ref, arch_ref, task_definition, service_attrs, base_tags)
            { task_definition: task_definition, service: service }
          end

          def create_service_security(name, _arch_ref, platform_ref, service_attrs, base_tags)
            {
              service_sg: aws_security_group(
                architecture_resource_name(name, :service_sg),
                name_prefix: "#{name}-service-",
                vpc_id: platform_ref.network.vpc.id,
                ingress_rules: [{
                  from_port: service_attrs.port,
                  to_port: service_attrs.port,
                  protocol: 'tcp',
                  security_groups: [platform_ref.security[:default_sg].id],
                  description: "#{service_attrs.runtime} service port"
                }],
                tags: base_tags.merge(Tier: 'security', Component: 'service-sg')
              )
            }
          end

          def create_service_monitoring(name, _arch_ref, platform_ref, _service_attrs, base_tags)
            {
              log_group: aws_cloudwatch_log_group(
                architecture_resource_name(name, :service_logs),
                name: "/aws/ecs/#{name}",
                retention_in_days: platform_ref.attributes[:log_retention_days] || 30,
                tags: base_tags.merge(Tier: 'monitoring', Component: 'service-logs')
              )
            }
          end

          private

          def create_rds_database(name, platform_ref, service_attrs, base_tags)
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
          end

          def create_dynamodb_table(name, base_tags)
            aws_dynamodb_table(
              architecture_resource_name(name, :dynamodb),
              name: "#{name}-table",
              billing_mode: 'PAY_PER_REQUEST',
              hash_key: 'id',
              attributes: [{ name: 'id', type: 'S' }],
              tags: base_tags.merge(Tier: 'database', Component: 'dynamodb')
            )
          end

          def create_task_definition(name, arch_ref, service_attrs, base_tags)
            aws_ecs_task_definition(
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
          end

          def create_ecs_service(name, platform_ref, arch_ref, task_definition, service_attrs, base_tags)
            aws_ecs_service(
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
          end
        end
      end
    end
  end
end
