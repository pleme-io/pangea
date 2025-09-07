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
        attribute :port_mappings, Types::Array.of(
          Types::Hash.schema(
            container_port: Types::Integer.constrained(gteq: 1, lteq: 65535),
            host_port?: Types::Integer.constrained(gteq: 1, lteq: 65535).optional,
            protocol?: Types::String.enum("tcp", "udp").optional,
            name?: Types::String.optional,
            app_protocol?: Types::String.enum("http", "http2", "grpc").optional
          )
        ).default([].freeze)
        
        # Environment variables
        attribute :environment, Types::Array.of(
          Types::Hash.schema(
            name: Types::String,
            value: Types::String
          )
        ).default([].freeze)
        
        # Secrets from Parameter Store or Secrets Manager
        attribute :secrets, Types::Array.of(
          Types::Hash.schema(
            name: Types::String,
            value_from: Types::String
          )
        ).default([].freeze)
        
        # Logging configuration
        attribute? :log_configuration, Types::Hash.schema(
          log_driver: Types::String.enum("awslogs", "fluentd", "gelf", "json-file", "journald", "logentries", "splunk", "syslog", "awsfirelens"),
          options?: Types::Hash.optional,
          secret_options?: Types::Array.of(
            Types::Hash.schema(
              name: Types::String,
              value_from: Types::String
            )
          ).optional
        ).optional
        
        # Health check
        attribute? :health_check, Types::Hash.schema(
          command: Types::Array.of(Types::String),
          interval?: Types::Integer.constrained(gteq: 5, lteq: 300).optional,
          timeout?: Types::Integer.constrained(gteq: 2, lteq: 60).optional,
          retries?: Types::Integer.constrained(gteq: 1, lteq: 10).optional,
          start_period?: Types::Integer.constrained(gteq: 0, lteq: 300).optional
        ).optional
        
        # Essential flag
        attribute :essential, Types::Bool.default(true)
        
        # Entry point and command
        attribute :entry_point, Types::Array.of(Types::String).default([].freeze)
        attribute :command, Types::Array.of(Types::String).default([].freeze)
        
        # Working directory
        attribute? :working_directory, Types::String.optional
        
        # Links (deprecated but still supported)
        attribute :links, Types::Array.of(Types::String).default([].freeze)
        
        # Mount points for volumes
        attribute :mount_points, Types::Array.of(
          Types::Hash.schema(
            source_volume: Types::String,
            container_path: Types::String,
            read_only?: Types::Bool.optional
          )
        ).default([].freeze)
        
        # Volumes from other containers
        attribute :volumes_from, Types::Array.of(
          Types::Hash.schema(
            source_container: Types::String,
            read_only?: Types::Bool.optional
          )
        ).default([].freeze)
        
        # Dependencies
        attribute :depends_on, Types::Array.of(
          Types::Hash.schema(
            container_name: Types::String,
            condition: Types::String.enum("START", "COMPLETE", "SUCCESS", "HEALTHY")
          )
        ).default([].freeze)
        
        # Linux parameters
        attribute? :linux_parameters, Types::Hash.schema(
          capabilities?: Types::Hash.schema(
            add?: Types::Array.of(Types::String).optional,
            drop?: Types::Array.of(Types::String).optional
          ).optional,
          devices?: Types::Array.of(
            Types::Hash.schema(
              host_path: Types::String,
              container_path?: Types::String.optional,
              permissions?: Types::Array.of(Types::String.enum("read", "write", "mknod")).optional
            )
          ).optional,
          init_process_enabled?: Types::Bool.optional,
          max_swap?: Types::Integer.optional,
          shared_memory_size?: Types::Integer.optional,
          swappiness?: Types::Integer.constrained(gteq: 0, lteq: 100).optional,
          tmpfs?: Types::Array.of(
            Types::Hash.schema(
              container_path: Types::String,
              size: Types::Integer,
              mount_options?: Types::Array.of(Types::String).optional
            )
          ).optional
        ).optional
        
        # Ulimits
        attribute :ulimits, Types::Array.of(
          Types::Hash.schema(
            name: Types::String.enum("core", "cpu", "data", "fsize", "locks", "memlock", "msgqueue", "nice", "nofile", "nproc", "rss", "rtprio", "rttime", "sigpending", "stack"),
            soft_limit: Types::Integer,
            hard_limit: Types::Integer
          )
        ).default([].freeze)
        
        # User
        attribute? :user, Types::String.optional
        
        # Privileged mode
        attribute :privileged, Types::Bool.default(false)
        
        # Read only root filesystem
        attribute :readonly_root_filesystem, Types::Bool.default(false)
        
        # DNS servers and search domains
        attribute :dns_servers, Types::Array.of(Types::String).default([].freeze)
        attribute :dns_search_domains, Types::Array.of(Types::String).default([].freeze)
        
        # Extra hosts
        attribute :extra_hosts, Types::Array.of(
          Types::Hash.schema(
            hostname: Types::String,
            ip_address: Types::String
          )
        ).default([].freeze)
        
        # Docker security options
        attribute :docker_security_options, Types::Array.of(Types::String).default([].freeze)
        
        # Docker labels
        attribute :docker_labels, Types::Hash.default({})
        
        # System controls
        attribute :system_controls, Types::Array.of(
          Types::Hash.schema(
            namespace: Types::String,
            value: Types::String
          )
        ).default([].freeze)
        
        # FireLens configuration
        attribute? :firelens_configuration, Types::Hash.schema(
          type: Types::String.enum("fluentd", "fluentbit"),
          options?: Types::Hash.optional
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
        attribute :container_definitions, Types::Array.of(EcsContainerDefinition).constrained(min_size: 1)
        
        # Task role and execution role
        attribute? :task_role_arn, Types::String.optional
        attribute? :execution_role_arn, Types::String.optional
        
        # Network mode
        attribute :network_mode, Types::String.enum("bridge", "host", "awsvpc", "none").default("bridge")
        
        # Launch type requirements
        attribute :requires_compatibilities, Types::Array.of(Types::String.enum("EC2", "FARGATE", "EXTERNAL")).default(["EC2"].freeze)
        
        # CPU and Memory (required for Fargate)
        attribute? :cpu, Types::String.optional  # String because it's in CPU units
        attribute? :memory, Types::String.optional  # String because it's in MB
        
        # Volumes
        attribute :volumes, Types::Array.of(
          Types::Hash.schema(
            name: Types::String,
            host?: Types::Hash.schema(
              source_path?: Types::String.optional
            ).optional,
            docker_volume_configuration?: Types::Hash.schema(
              scope?: Types::String.enum("task", "shared").optional,
              autoprovision?: Types::Bool.optional,
              driver?: Types::String.optional,
              driver_opts?: Types::Hash.optional,
              labels?: Types::Hash.optional
            ).optional,
            efs_volume_configuration?: Types::Hash.schema(
              file_system_id: Types::String,
              root_directory?: Types::String.optional,
              transit_encryption?: Types::String.enum("ENABLED", "DISABLED").optional,
              transit_encryption_port?: Types::Integer.optional,
              authorization_config?: Types::Hash.schema(
                access_point_id?: Types::String.optional,
                iam?: Types::String.enum("ENABLED", "DISABLED").optional
              ).optional
            ).optional,
            fsx_windows_file_server_volume_configuration?: Types::Hash.schema(
              file_system_id: Types::String,
              root_directory: Types::String,
              authorization_config: Types::Hash.schema(
                credentials_parameter: Types::String,
                domain: Types::String
              )
            ).optional
          )
        ).default([].freeze)
        
        # Placement constraints
        attribute :placement_constraints, Types::Array.of(
          Types::Hash.schema(
            type: Types::String.enum("memberOf"),
            expression?: Types::String.optional
          )
        ).default([].freeze)
        
        # IPC and PID mode
        attribute? :ipc_mode, Types::String.enum("host", "task", "none").optional
        attribute? :pid_mode, Types::String.enum("host", "task").optional
        
        # Inference accelerators
        attribute :inference_accelerators, Types::Array.of(
          Types::Hash.schema(
            device_name: Types::String,
            device_type: Types::String
          )
        ).default([].freeze)
        
        # Proxy configuration
        attribute? :proxy_configuration, Types::Hash.schema(
          type?: Types::String.enum("APPMESH").optional,
          container_name: Types::String,
          properties?: Types::Array.of(
            Types::Hash.schema(
              name: Types::String,
              value: Types::String
            )
          ).optional
        ).optional
        
        # Runtime platform (for Fargate)
        attribute? :runtime_platform, Types::Hash.schema(
          operating_system_family?: Types::String.enum("LINUX", "WINDOWS_SERVER_2019_FULL", "WINDOWS_SERVER_2019_CORE", "WINDOWS_SERVER_2022_FULL", "WINDOWS_SERVER_2022_CORE").optional,
          cpu_architecture?: Types::String.enum("X86_64", "ARM64").optional
        ).optional
        
        # Ephemeral storage (for Fargate)
        attribute? :ephemeral_storage, Types::Hash.schema(
          size_in_gib: Types::Integer.constrained(gteq: 21, lteq: 200)
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