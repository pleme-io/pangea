# frozen_string_literal: true

module Pangea
  module Architectures
    module Patterns
      module Microservices
        # Helper methods for microservices architecture
        module Helpers
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
                Statement: [{
                  Action: 'sts:AssumeRole',
                  Effect: 'Allow',
                  Principal: { Service: 'ecs-tasks.amazonaws.com' }
                }]
              }),
              managed_policy_arns: [
                'arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy'
              ],
              tags: base_tags.merge(Tier: 'security', Component: 'execution-role')
            )
          end

          def generate_container_definition(name, _arch_ref, service_attrs)
            jsonencode([{
              name: name.to_s,
              image: "#{name}:latest",
              portMappings: [{ containerPort: service_attrs.port, protocol: 'tcp' }],
              environment: [
                { name: 'SERVICE_NAME', value: service_attrs.service_name },
                { name: 'SERVICE_PORT', value: service_attrs.port.to_s }
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
            }])
          end
        end
      end
    end
  end
end
