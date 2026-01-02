# frozen_string_literal: true

# Copyright 2025 The Pangea Authors. Licensed under Apache 2.0.

require_relative 'container_definition'

module Pangea
  module Resources
    module AWS
      module Types
        class EcsTaskDefinitionAttributes < Dry::Struct
          transform_keys(&:to_sym)

          attribute :family, Pangea::Resources::Types::String
          attribute :container_definitions, Pangea::Resources::Types::Array.of(EcsContainerDefinition).constrained(min_size: 1)
          attribute? :task_role_arn, Pangea::Resources::Types::String.optional
          attribute? :execution_role_arn, Pangea::Resources::Types::String.optional
          attribute :network_mode, Pangea::Resources::Types::String.constrained(included_in: %w[bridge host awsvpc none]).default('bridge')
          attribute :requires_compatibilities, Pangea::Resources::Types::Array.of(
            Pangea::Resources::Types::String.constrained(included_in: %w[EC2 FARGATE EXTERNAL])
          ).default(['EC2'].freeze)
          attribute? :cpu, Pangea::Resources::Types::String.optional
          attribute? :memory, Pangea::Resources::Types::String.optional

          attribute :volumes, Pangea::Resources::Types::Array.of(Pangea::Resources::Types::Hash).default([].freeze)
          attribute :placement_constraints, Pangea::Resources::Types::Array.of(
            Pangea::Resources::Types::Hash.schema(type: Pangea::Resources::Types::String.constrained(included_in: ['memberOf']), expression?: Pangea::Resources::Types::String.optional)
          ).default([].freeze)

          attribute? :ipc_mode, Pangea::Resources::Types::String.constrained(included_in: %w[host task none]).optional
          attribute? :pid_mode, Pangea::Resources::Types::String.constrained(included_in: %w[host task]).optional
          attribute :inference_accelerators, Pangea::Resources::Types::Array.of(
            Pangea::Resources::Types::Hash.schema(device_name: Pangea::Resources::Types::String, device_type: Pangea::Resources::Types::String)
          ).default([].freeze)
          attribute? :proxy_configuration, Pangea::Resources::Types::Hash.optional
          attribute? :runtime_platform, Pangea::Resources::Types::Hash.optional
          attribute? :ephemeral_storage, Pangea::Resources::Types::Hash.schema(size_in_gib: Pangea::Resources::Types::Integer.constrained(gteq: 21, lteq: 200)).optional
          attribute :tags, Pangea::Resources::Types::AwsTags.default({}.freeze)

          FARGATE_CPU_MEMORY = {
            '256' => %w[512 1024 2048],
            '512' => %w[1024 2048 3072 4096],
            '1024' => %w[2048 3072 4096 5120 6144 7168 8192],
            '2048' => (4096..16384).step(1024).map(&:to_s),
            '4096' => (8192..30720).step(1024).map(&:to_s),
            '8192' => (16_384..61_440).step(1024).map(&:to_s),
            '16384' => (32_768..122_880).step(4096).map(&:to_s)
          }.freeze

          def self.new(attributes = {})
            attrs = super(attributes)
            validate_fargate_requirements(attrs) if attrs.requires_compatibilities.include?('FARGATE')
            validate_awsvpc_port_mappings(attrs) if attrs.network_mode == 'awsvpc'
            raise Dry::Struct::Error, 'At least one container must be marked as essential' if attrs.container_definitions.count(&:is_essential?).zero?
            validate_volume_references(attrs)
            attrs
          end

          def self.validate_fargate_requirements(attrs)
            raise Dry::Struct::Error, 'CPU and memory must be specified for Fargate compatibility' unless attrs.cpu && attrs.memory
            raise Dry::Struct::Error, "Network mode must be 'awsvpc' for Fargate compatibility" unless attrs.network_mode == 'awsvpc'
            raise Dry::Struct::Error, 'Execution role ARN is required for Fargate compatibility' unless attrs.execution_role_arn
            return unless FARGATE_CPU_MEMORY[attrs.cpu] && !FARGATE_CPU_MEMORY[attrs.cpu].include?(attrs.memory)
            raise Dry::Struct::Error, "Invalid CPU/memory combination for Fargate: #{attrs.cpu}/#{attrs.memory}"
          end

          def self.validate_awsvpc_port_mappings(attrs)
            attrs.container_definitions.each do |container|
              container.port_mappings.each do |pm|
                next unless pm[:host_port] && pm[:host_port] != pm[:container_port]
                raise Dry::Struct::Error, 'In awsvpc mode, host_port must equal container_port or be omitted'
              end
            end
          end

          def self.validate_volume_references(attrs)
            volume_names = attrs.volumes.map { |v| v[:name] }
            attrs.container_definitions.each do |container|
              container.mount_points.each do |mp|
                next if volume_names.include?(mp[:source_volume])
                raise Dry::Struct::Error, "Container '#{container.name}' references undefined volume '#{mp[:source_volume]}'"
              end
            end
          end

          def fargate_compatible? = requires_compatibilities.include?('FARGATE')
          def uses_efs? = volumes.any? { |v| v[:efs_volume_configuration] }
          def total_memory_mb = memory&.to_i || container_definitions.sum(&:estimated_memory_mb)

          def estimated_hourly_cost
            return 0.0 unless fargate_compatible? && cpu && memory
            (cpu.to_i * 0.00001406 + memory.to_i * 0.00000156) * 3600
          end

          def main_container = container_definitions.find(&:is_essential?) || container_definitions.first
        end
      end
    end
  end
end
