# frozen_string_literal: true

require 'pangea/resources/types'

module Pangea
  module Resources
    module AWS
      module Types
        # Container definition for ECS tasks
        class EcsContainerDefinition < Dry::Struct
          transform_keys(&:to_sym)
          
          # Container identification
          attribute :name, Pangea::Resources::Types::String
          attribute :image, Pangea::Resources::Types::String
          
          # Resource allocation
          attribute? :cpu, Pangea::Resources::Types::Integer.optional
          attribute? :memory, Pangea::Resources::Types::Integer.optional
          attribute? :memory_reservation, Pangea::Resources::Types::Integer.optional
          
          # Port mappings
          attribute :port_mappings, Pangea::Resources::Types::Array.of(
            Pangea::Resources::Types::Hash.schema(
              container_port: Pangea::Resources::Types::Integer.constrained(gteq: 1, lteq: 65535),
              host_port?: Pangea::Resources::Types::Integer.constrained(gteq: 1, lteq: 65535).optional,
              protocol?: Pangea::Resources::Types::String.constrained(included_in: ["tcp", "udp"]).optional,
              name?: Pangea::Resources::Types::String.optional,
              app_protocol?: Pangea::Resources::Types::String.constrained(included_in: ["http", "http2", "grpc"]).optional
            )
          ).default([].freeze)
          
          # Environment variables
          attribute :environment, Pangea::Resources::Types::Array.of(
            Pangea::Resources::Types::Hash.schema(
              name: Pangea::Resources::Types::String,
              value: Pangea::Resources::Types::String
            )
          ).default([].freeze)
          
          # Secrets from Parameter Store or Secrets Manager
          attribute :secrets, Pangea::Resources::Types::Array.of(
            Pangea::Resources::Types::Hash.schema(
              name: Pangea::Resources::Types::String,
              value_from: Pangea::Resources::Types::String
            )
          ).default([].freeze)
          
          # Logging configuration
          attribute? :log_configuration, Pangea::Resources::Types::Hash.schema(
            log_driver: Pangea::Resources::Types::String.constrained(included_in: ["awslogs", "fluentd", "gelf", "json-file", "journald", "logentries", "splunk", "syslog", "awsfirelens"]),
            options?: Pangea::Resources::Types::Hash.optional,
            secret_options?: Pangea::Resources::Types::Array.of(
              Pangea::Resources::Types::Hash.schema(
                name: Pangea::Resources::Types::String,
                value_from: Pangea::Resources::Types::String
              )
            ).optional
          ).optional
          
          # Health check
          attribute? :health_check, Pangea::Resources::Types::Hash.schema(
            command: Pangea::Resources::Types::Array.of(Pangea::Resources::Types::String),
            interval?: Pangea::Resources::Types::Integer.constrained(gteq: 5, lteq: 300).optional,
            timeout?: Pangea::Resources::Types::Integer.constrained(gteq: 2, lteq: 60).optional,
            retries?: Pangea::Resources::Types::Integer.constrained(gteq: 1, lteq: 10).optional,
            start_period?: Pangea::Resources::Types::Integer.constrained(gteq: 0, lteq: 300).optional
          ).optional
          
          # Essential flag
          attribute :essential, Pangea::Resources::Types::Bool.default(true)
          
          # Entry point and command
          attribute :entry_point, Pangea::Resources::Types::Array.of(Pangea::Resources::Types::String).default([].freeze)
          attribute :command, Pangea::Resources::Types::Array.of(Pangea::Resources::Types::String).default([].freeze)
          
          # Working directory
          attribute? :working_directory, Pangea::Resources::Types::String.optional
          
          # Links (deprecated but still supported)
          attribute :links, Pangea::Resources::Types::Array.of(Pangea::Resources::Types::String).default([].freeze)
          
          # Mount points for volumes
          attribute :mount_points, Pangea::Resources::Types::Array.of(
            Pangea::Resources::Types::Hash.schema(
              source_volume: Pangea::Resources::Types::String,
              container_path: Pangea::Resources::Types::String,
              read_only?: Pangea::Resources::Types::Bool.optional
            )
          ).default([].freeze)
          
          # Volumes from other containers
          attribute :volumes_from, Pangea::Resources::Types::Array.of(
            Pangea::Resources::Types::Hash.schema(
              source_container: Pangea::Resources::Types::String,
              read_only?: Pangea::Resources::Types::Bool.optional
            )
          ).default([].freeze)
          
          # Dependencies
          attribute :depends_on, Pangea::Resources::Types::Array.of(
            Pangea::Resources::Types::Hash.schema(
              container_name: Pangea::Resources::Types::String,
              condition: Pangea::Resources::Types::String.constrained(included_in: ["START", "COMPLETE", "SUCCESS", "HEALTHY"])
            )
          ).default([].freeze)
          
          # Linux parameters
          attribute? :linux_parameters, Pangea::Resources::Types::Hash.schema(
            capabilities?: Pangea::Resources::Types::Hash.schema(
              add?: Pangea::Resources::Types::Array.of(Pangea::Resources::Types::String).optional,
              drop?: Pangea::Resources::Types::Array.of(Pangea::Resources::Types::String).optional
            ).optional,
            devices?: Pangea::Resources::Types::Array.of(
              Pangea::Resources::Types::Hash.schema(
                host_path: Pangea::Resources::Types::String,
                container_path?: Pangea::Resources::Types::String.optional,
                permissions?: Pangea::Resources::Types::Array.of(Pangea::Resources::Types::String.constrained(included_in: ["read", "write", "mknod"])).optional
              )
            ).optional,
            init_process_enabled?: Pangea::Resources::Types::Bool.optional,
            max_swap?: Pangea::Resources::Types::Integer.optional,
            shared_memory_size?: Pangea::Resources::Types::Integer.optional,
            swappiness?: Pangea::Resources::Types::Integer.constrained(gteq: 0, lteq: 100).optional,
            tmpfs?: Pangea::Resources::Types::Array.of(
              Pangea::Resources::Types::Hash.schema(
                container_path: Pangea::Resources::Types::String,
                size: Pangea::Resources::Types::Integer,
                mount_options?: Pangea::Resources::Types::Array.of(Pangea::Resources::Types::String).optional
              )
            ).optional
          ).optional
          
          # Ulimits
          attribute :ulimits, Pangea::Resources::Types::Array.of(
            Pangea::Resources::Types::Hash.schema(
              name: Pangea::Resources::Types::String.constrained(included_in: ["core", "cpu", "data", "fsize", "locks", "memlock", "msgqueue", "nice", "nofile", "nproc", "rss", "rtprio", "rttime", "sigpending", "stack"]),
              soft_limit: Pangea::Resources::Types::Integer,
              hard_limit: Pangea::Resources::Types::Integer
            )
          ).default([].freeze)
          
          # User
          attribute? :user, Pangea::Resources::Types::String.optional
          
          # Privileged mode
          attribute :privileged, Pangea::Resources::Types::Bool.default(false)
          
          # Read only root filesystem
          attribute :readonly_root_filesystem, Pangea::Resources::Types::Bool.default(false)
          
          # DNS servers and search domains
          attribute :dns_servers, Pangea::Resources::Types::Array.of(Pangea::Resources::Types::String).default([].freeze)
          attribute :dns_search_domains, Pangea::Resources::Types::Array.of(Pangea::Resources::Types::String).default([].freeze)
          
          # Extra hosts
          attribute :extra_hosts, Pangea::Resources::Types::Array.of(
            Pangea::Resources::Types::Hash.schema(
              hostname: Pangea::Resources::Types::String,
              ip_address: Pangea::Resources::Types::String
            )
          ).default([].freeze)
          
          # Docker security options
          attribute :docker_security_options, Pangea::Resources::Types::Array.of(Pangea::Resources::Types::String).default([].freeze)
          
          # Docker labels
          attribute :docker_labels, Pangea::Resources::Types::Hash.default({})
          
          # System controls
          attribute :system_controls, Pangea::Resources::Types::Array.of(
            Pangea::Resources::Types::Hash.schema(
              namespace: Pangea::Resources::Types::String,
              value: Pangea::Resources::Types::String
            )
          ).default([].freeze)
          
          # FireLens configuration
          attribute? :firelens_configuration, Pangea::Resources::Types::Hash.schema(
            type: Pangea::Resources::Types::String.constrained(included_in: ["fluentd", "fluentbit"]),
            options?: Pangea::Resources::Types::Hash.optional
          ).optional
          
          # Custom validation
          def self.new(attributes = {})
            attrs = super(attributes)
            
            # Validate memory settings
            if attrs.memory_reservation && attrs.memory && attrs.memory_reservation > attrs.memory
              raise Dry::Struct::Error, "memory_reservation cannot be greater than memory"
            end
            
            # Validate image URI format
            unless attrs.image.match?(/^[\w\-\.\/\:]+$/)
              raise Dry::Struct::Error, "Invalid image URI format"
            end
            
            # Validate port mappings for awsvpc mode don't have host_port
            # (This will be checked in task definition based on network mode)
            
            attrs
          end
          
          # Helper to check if using AWS logs
          def using_awslogs?
            log_configuration && log_configuration[:log_driver] == "awslogs"
          end
          
          # Helper to check if container is essential
          def is_essential?
            essential
          end
          
          # Helper to estimate container memory usage
          def estimated_memory_mb
            memory || memory_reservation || 512
          end
        end
        
        # Type-safe attributes for AWS ECS Task Definition
        class EcsTaskDefinitionAttributes < Dry::Struct
          transform_keys(&:to_sym)
          
          # Family name (required)
          attribute :family, Pangea::Resources::Types::String
          
          # Container definitions (required)
          attribute :container_definitions, Pangea::Resources::Types::Array.of(EcsContainerDefinition).constrained(min_size: 1)
          
          # Task role and execution role
          attribute? :task_role_arn, Pangea::Resources::Types::String.optional
          attribute? :execution_role_arn, Pangea::Resources::Types::String.optional
          
          # Network mode
          attribute :network_mode, Pangea::Resources::Types::String.constrained(included_in: ["bridge", "host", "awsvpc", "none"]).default("bridge")
          
          # Launch type requirements
          attribute :requires_compatibilities, Pangea::Resources::Types::Array.of(Pangea::Resources::Types::String.constrained(included_in: ["EC2", "FARGATE", "EXTERNAL"])).default(["EC2"].freeze)
          
          # CPU and Memory (required for Fargate)
          attribute? :cpu, Pangea::Resources::Types::String.optional  # String because it's in CPU units
          attribute? :memory, Pangea::Resources::Types::String.optional  # String because it's in MB
          
          # Volumes
          attribute :volumes, Pangea::Resources::Types::Array.of(
            Pangea::Resources::Types::Hash.schema(
              name: Pangea::Resources::Types::String,
              host?: Pangea::Resources::Types::Hash.schema(
                source_path?: Pangea::Resources::Types::String.optional
              ).optional,
              docker_volume_configuration?: Pangea::Resources::Types::Hash.schema(
                scope?: Pangea::Resources::Types::String.constrained(included_in: ["task", "shared"]).optional,
                autoprovision?: Pangea::Resources::Types::Bool.optional,
                driver?: Pangea::Resources::Types::String.optional,
                driver_opts?: Pangea::Resources::Types::Hash.optional,
                labels?: Pangea::Resources::Types::Hash.optional
              ).optional,
              efs_volume_configuration?: Pangea::Resources::Types::Hash.schema(
                file_system_id: Pangea::Resources::Types::String,
                root_directory?: Pangea::Resources::Types::String.optional,
                transit_encryption?: Pangea::Resources::Types::String.constrained(included_in: ["ENABLED", "DISABLED"]).optional,
                transit_encryption_port?: Pangea::Resources::Types::Integer.optional,
                authorization_config?: Pangea::Resources::Types::Hash.schema(
                  access_point_id?: Pangea::Resources::Types::String.optional,
                  iam?: Pangea::Resources::Types::String.constrained(included_in: ["ENABLED", "DISABLED"]).optional
                ).optional
              ).optional,
              fsx_windows_file_server_volume_configuration?: Pangea::Resources::Types::Hash.schema(
                file_system_id: Pangea::Resources::Types::String,
                root_directory: Pangea::Resources::Types::String,
                authorization_config: Pangea::Resources::Types::Hash.schema(
                  credentials_parameter: Pangea::Resources::Types::String,
                  domain: Pangea::Resources::Types::String
                )
              ).optional
            )
          ).default([].freeze)
          
          # Placement constraints
          attribute :placement_constraints, Pangea::Resources::Types::Array.of(
            Pangea::Resources::Types::Hash.schema(
              type: Pangea::Resources::Types::String.constrained(included_in: ["memberOf"]),
              expression?: Pangea::Resources::Types::String.optional
            )
          ).default([].freeze)
          
          # IPC and PID mode
          attribute? :ipc_mode, Pangea::Resources::Types::String.constrained(included_in: ["host", "task", "none"]).optional
          attribute? :pid_mode, Pangea::Resources::Types::String.constrained(included_in: ["host", "task"]).optional
          
          # Inference accelerators
          attribute :inference_accelerators, Pangea::Resources::Types::Array.of(
            Pangea::Resources::Types::Hash.schema(
              device_name: Pangea::Resources::Types::String,
              device_type: Pangea::Resources::Types::String
            )
          ).default([].freeze)
          
          # Proxy configuration
          attribute? :proxy_configuration, Pangea::Resources::Types::Hash.schema(
            type?: Pangea::Resources::Types::String.constrained(included_in: ["APPMESH"]).optional,
            container_name: Pangea::Resources::Types::String,
            properties?: Pangea::Resources::Types::Array.of(
              Pangea::Resources::Types::Hash.schema(
                name: Pangea::Resources::Types::String,
                value: Pangea::Resources::Types::String
              )
            ).optional
          ).optional
          
          # Runtime platform (for Fargate)
          attribute? :runtime_platform, Pangea::Resources::Types::Hash.schema(
            operating_system_family?: Pangea::Resources::Types::String.constrained(included_in: ["LINUX", "WINDOWS_SERVER_2019_FULL", "WINDOWS_SERVER_2019_CORE", "WINDOWS_SERVER_2022_FULL", "WINDOWS_SERVER_2022_CORE"]).optional,
            cpu_architecture?: Pangea::Resources::Types::String.constrained(included_in: ["X86_64", "ARM64"]).optional
          ).optional
          
          # Ephemeral storage (for Fargate)
          attribute? :ephemeral_storage, Pangea::Resources::Types::Hash.schema(
            size_in_gib: Pangea::Resources::Types::Integer.constrained(gteq: 21, lteq: 200)
          ).optional
          
          # Tags
          attribute :tags, Pangea::Resources::Types::AwsTags.default({})
          
          # Custom validation
          def self.new(attributes = {})
            attrs = super(attributes)
            
            # Validate Fargate requirements
            if attrs.requires_compatibilities.include?("FARGATE")
              unless attrs.cpu && attrs.memory
                raise Dry::Struct::Error, "CPU and memory must be specified for Fargate compatibility"
              end
              
              unless attrs.network_mode == "awsvpc"
                raise Dry::Struct::Error, "Network mode must be 'awsvpc' for Fargate compatibility"
              end
              
              unless attrs.execution_role_arn
                raise Dry::Struct::Error, "Execution role ARN is required for Fargate compatibility"
              end
              
              # Validate Fargate CPU/memory combinations
              valid_combinations = {
                "256" => ["512", "1024", "2048"],
                "512" => ["1024", "2048", "3072", "4096"],
                "1024" => ["2048", "3072", "4096", "5120", "6144", "7168", "8192"],
                "2048" => ["4096", "5120", "6144", "7168", "8192", "9216", "10240", "11264", "12288", "13312", "14336", "15360", "16384"],
                "4096" => ["8192", "9216", "10240", "11264", "12288", "13312", "14336", "15360", "16384", "17408", "18432", "19456", "20480", "21504", "22528", "23552", "24576", "25600", "26624", "27648", "28672", "29696", "30720"],
                "8192" => (16384..61440).step(1024).map(&:to_s),
                "16384" => (32768..122880).step(4096).map(&:to_s)
              }
              
              if valid_combinations[attrs.cpu] && !valid_combinations[attrs.cpu].include?(attrs.memory)
                raise Dry::Struct::Error, "Invalid CPU/memory combination for Fargate: #{attrs.cpu}/#{attrs.memory}"
              end
            end
            
            # Validate network mode restrictions
            if attrs.network_mode == "awsvpc"
              attrs.container_definitions.each do |container|
                container.port_mappings.each do |pm|
                  if pm[:host_port] && pm[:host_port] != pm[:container_port]
                    raise Dry::Struct::Error, "In awsvpc mode, host_port must equal container_port or be omitted"
                  end
                end
              end
            end
            
            # Validate essential containers
            essential_count = attrs.container_definitions.count(&:is_essential?)
            if essential_count == 0
              raise Dry::Struct::Error, "At least one container must be marked as essential"
            end
            
            # Validate volume references
            volume_names = attrs.volumes.map { |v| v[:name] }
            attrs.container_definitions.each do |container|
              container.mount_points.each do |mp|
                unless volume_names.include?(mp[:source_volume])
                  raise Dry::Struct::Error, "Container '#{container.name}' references undefined volume '#{mp[:source_volume]}'"
                end
              end
            end
            
            attrs
          end
          
          # Helper to check if task is Fargate compatible
          def fargate_compatible?
            requires_compatibilities.include?("FARGATE")
          end
          
          # Helper to check if task uses EFS
          def uses_efs?
            volumes.any? { |v| v[:efs_volume_configuration] }
          end
          
          # Helper to calculate total task memory
          def total_memory_mb
            return memory.to_i if memory
            
            container_definitions.sum(&:estimated_memory_mb)
          end
          
          # Helper to estimate hourly cost
          def estimated_hourly_cost
            return 0.0 unless fargate_compatible? && cpu && memory
            
            # Fargate pricing (rough estimates)
            cpu_cost = cpu.to_i * 0.00001406  # Per vCPU per second
            memory_cost = memory.to_i * 0.00000156  # Per GB per second
            
            (cpu_cost + memory_cost) * 3600  # Convert to hourly
          end
          
          # Helper to get main container
          def main_container
            container_definitions.find(&:is_essential?) || container_definitions.first
          end
        end
      end
    end
  end
end