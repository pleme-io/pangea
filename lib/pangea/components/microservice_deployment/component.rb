# frozen_string_literal: true

# Copyright 2025 The Pangea Authors. Licensed under Apache 2.0.

require 'pangea/components/base'
require 'pangea/components/microservice_deployment/types'
require 'pangea/resources/aws'
require_relative 'component/logging'
require_relative 'component/container_definitions'
require_relative 'component/service'
require_relative 'component/autoscaling'
require_relative 'component/monitoring'
require_relative 'component/outputs'

module Pangea
  module Components
    include MicroserviceDeploymentComponent::Logging
    include MicroserviceDeploymentComponent::ContainerDefinitions
    include MicroserviceDeploymentComponent::Service
    include MicroserviceDeploymentComponent::Autoscaling
    include MicroserviceDeploymentComponent::Monitoring
    include MicroserviceDeploymentComponent::Outputs

    def microservice_deployment(name, attributes = {})
      include Base
      include Resources::AWS

      component_attrs = MicroserviceDeployment::MicroserviceDeploymentAttributes.new(attributes)
      component_attrs.validate!
      component_tag_set = component_tags('MicroserviceDeployment', name, component_attrs.tags)

      resources = {}

      log_group_ref = create_log_group(name, component_attrs, component_tag_set)
      resources[:log_group] = log_group_ref
      resources[:log_streams] = create_log_streams(name, component_attrs, log_group_ref)

      container_defs = build_container_definitions(component_attrs, log_group_ref)

      task_def_ref = create_task_definition(name, component_attrs, container_defs, component_tag_set)
      resources[:task_definition] = task_def_ref

      sd_service_ref = create_service_discovery(name, component_attrs, component_tag_set)
      resources[:service_discovery] = sd_service_ref if sd_service_ref

      service_registry = build_service_registry(sd_service_ref, component_attrs, container_defs)
      load_balancers = build_load_balancers(component_attrs, container_defs)

      service_ref = create_ecs_service(name, component_attrs, task_def_ref, load_balancers, service_registry, component_tag_set)
      resources[:service] = service_ref

      resources.merge!(configure_autoscaling(name, component_attrs, service_ref))
      resources[:alarms] = create_cloudwatch_alarms(name, component_attrs, service_ref, component_tag_set)

      xray_rule = create_xray_sampling_rule(name, component_attrs, component_tag_set)
      resources[:xray_sampling_rule] = xray_rule if xray_rule

      outputs = calculate_outputs(service_ref, task_def_ref, log_group_ref, component_attrs, load_balancers)
      create_component_reference('microservice_deployment', name, component_attrs.to_h, resources, outputs)
    end
  end
end
