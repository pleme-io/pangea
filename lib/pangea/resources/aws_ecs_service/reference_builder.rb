# frozen_string_literal: true

# Copyright 2025 The Pangea Authors. Licensed under Apache 2.0.

require 'pangea/resources/reference'

module Pangea
  module Resources
    module AWS
      module EcsServiceReferenceBuilder
        OUTPUTS = %i[
          id name cluster iam_role desired_count launch_type
          platform_version task_definition load_balancers
          service_registries tags_all
        ].freeze

        # Build a ResourceReference for an ECS service
        # @param name [Symbol] The resource name
        # @param service_attrs [EcsServiceAttributes] The validated attributes
        # @return [ResourceReference] Reference with outputs and computed properties
        def self.build(name, service_attrs)
          ref = ResourceReference.new(
            type: 'aws_ecs_service',
            name: name,
            resource_attributes: service_attrs.to_h,
            outputs: build_outputs(name)
          )

          define_computed_properties(ref, service_attrs)
          ref
        end

        # Build output interpolations for all standard outputs
        def self.build_outputs(name)
          OUTPUTS.each_with_object({}) do |output, hash|
            hash[output] = "${aws_ecs_service.#{name}.#{output}}"
          end
        end

        # Define computed property methods on the reference
        def self.define_computed_properties(ref, attrs)
          ref.define_singleton_method(:using_fargate?) { attrs.using_fargate? }
          ref.define_singleton_method(:load_balanced?) { attrs.load_balanced? }
          ref.define_singleton_method(:service_discovery_enabled?) { attrs.service_discovery_enabled? }
          ref.define_singleton_method(:service_connect_enabled?) { attrs.service_connect_enabled? }
          ref.define_singleton_method(:estimated_monthly_cost) { attrs.estimated_monthly_cost }
          ref.define_singleton_method(:deployment_safe?) { attrs.deployment_safe? }
          ref.define_singleton_method(:is_daemon_service?) { attrs.scheduling_strategy == "DAEMON" }
        end
      end
    end
  end
end
