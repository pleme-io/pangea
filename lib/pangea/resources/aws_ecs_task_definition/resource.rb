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

require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/aws_ecs_task_definition/types'
require 'pangea/resources/aws_ecs_task_definition/container_definitions'
require 'pangea/resources/aws_ecs_task_definition/volumes'
require 'pangea/resource_registry'
require 'json'

module Pangea
  module Resources
    module AWS
      # Create an AWS ECS Task Definition with type-safe attributes
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] ECS task definition attributes
      # @return [ResourceReference] Reference object with outputs and computed properties
      def aws_ecs_task_definition(name, attributes = {})
        task_attrs = AWS::Types::Types::EcsTaskDefinitionAttributes.new(attributes)

        resource(:aws_ecs_task_definition, name) do
          family task_attrs.family
          container_definitions JSON.pretty_generate(
            EcsTaskDefinition::ContainerDefinitions.build(task_attrs.container_definitions)
          )

          configure_task_roles(self, task_attrs)
          configure_networking(self, task_attrs)
          configure_compute(self, task_attrs)

          EcsTaskDefinition::Volumes.configure(self, task_attrs.volumes)

          configure_placement_constraints(self, task_attrs)
          configure_process_modes(self, task_attrs)
          configure_inference_accelerators(self, task_attrs)
          configure_proxy(self, task_attrs)
          configure_runtime_platform(self, task_attrs)
          configure_ephemeral_storage(self, task_attrs)
          configure_tags(self, task_attrs)
        end

        create_resource_reference(name, task_attrs)
      end

      private

      def configure_task_roles(context, attrs)
        context.task_role_arn attrs.task_role_arn if attrs.task_role_arn
        context.execution_role_arn attrs.execution_role_arn if attrs.execution_role_arn
      end

      def configure_networking(context, attrs)
        context.network_mode attrs.network_mode
        context.requires_compatibilities attrs.requires_compatibilities
      end

      def configure_compute(context, attrs)
        context.cpu attrs.cpu if attrs.cpu
        context.memory attrs.memory if attrs.memory
      end

      def configure_placement_constraints(context, attrs)
        attrs.placement_constraints.each do |constraint|
          context.placement_constraints do
            type constraint[:type]
            expression constraint[:expression] if constraint[:expression]
          end
        end
      end

      def configure_process_modes(context, attrs)
        context.ipc_mode attrs.ipc_mode if attrs.ipc_mode
        context.pid_mode attrs.pid_mode if attrs.pid_mode
      end

      def configure_inference_accelerators(context, attrs)
        attrs.inference_accelerators.each do |accelerator|
          context.inference_accelerators do
            device_name accelerator[:device_name]
            device_type accelerator[:device_type]
          end
        end
      end

      def configure_proxy(context, attrs)
        return unless attrs.proxy_configuration

        context.proxy_configuration do
          type attrs.proxy_configuration[:type] if attrs.proxy_configuration[:type]
          container_name attrs.proxy_configuration[:container_name]
          properties attrs.proxy_configuration[:properties] if attrs.proxy_configuration[:properties]
        end
      end

      def configure_runtime_platform(context, attrs)
        return unless attrs.runtime_platform

        context.runtime_platform do
          operating_system_family attrs.runtime_platform[:operating_system_family] if attrs.runtime_platform[:operating_system_family]
          cpu_architecture attrs.runtime_platform[:cpu_architecture] if attrs.runtime_platform[:cpu_architecture]
        end
      end

      def configure_ephemeral_storage(context, attrs)
        return unless attrs.ephemeral_storage

        context.ephemeral_storage do
          size_in_gib attrs.ephemeral_storage[:size_in_gib]
        end
      end

      def configure_tags(context, attrs)
        return unless attrs.tags.any?

        context.tags do
          attrs.tags.each do |key, value|
            public_send(key, value)
          end
        end
      end

      def create_resource_reference(name, task_attrs)
        ref = ResourceReference.new(
          type: 'aws_ecs_task_definition',
          name: name,
          resource_attributes: task_attrs.to_h,
          outputs: {
            arn: "${aws_ecs_task_definition.#{name}.arn}",
            arn_without_revision: "${aws_ecs_task_definition.#{name}.arn_without_revision}",
            family: "${aws_ecs_task_definition.#{name}.family}",
            revision: "${aws_ecs_task_definition.#{name}.revision}",
            tags_all: "${aws_ecs_task_definition.#{name}.tags_all}",
            id: "${aws_ecs_task_definition.#{name}.id}"
          }
        )

        add_computed_methods(ref, task_attrs)
        ref
      end

      def add_computed_methods(ref, task_attrs)
        ref.define_singleton_method(:fargate_compatible?) { task_attrs.fargate_compatible? }
        ref.define_singleton_method(:uses_efs?) { task_attrs.uses_efs? }
        ref.define_singleton_method(:total_memory_mb) { task_attrs.total_memory_mb }
        ref.define_singleton_method(:estimated_hourly_cost) { task_attrs.estimated_hourly_cost }
        ref.define_singleton_method(:main_container_name) { task_attrs.main_container.name }
        ref.define_singleton_method(:container_names) { task_attrs.container_definitions.map(&:name) }
        ref.define_singleton_method(:essential_container_count) { task_attrs.container_definitions.count(&:is_essential?) }
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)
