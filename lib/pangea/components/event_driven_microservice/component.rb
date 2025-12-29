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

require 'pangea/components/base'
require 'pangea/components/event_driven_microservice/types'
require 'pangea/components/event_driven_microservice/iam'
require 'pangea/components/event_driven_microservice/storage'
require 'pangea/components/event_driven_microservice/functions'
require 'pangea/components/event_driven_microservice/event_sources'
require 'pangea/components/event_driven_microservice/monitoring'
require 'pangea/components/event_driven_microservice/api_gateway'
require 'pangea/components/event_driven_microservice/helpers'
require 'pangea/resources/aws'

module Pangea
  module Components
    # Event-driven microservice with event sourcing, CQRS, and saga orchestration patterns
    # Creates a complete event-driven architecture with Lambda functions, DynamoDB, and EventBridge
    def event_driven_microservice(name, attributes = {})
      include Base
      include Resources::AWS
      include EventDrivenMicroservice::Iam
      include EventDrivenMicroservice::Storage
      include EventDrivenMicroservice::Functions
      include EventDrivenMicroservice::EventSources
      include EventDrivenMicroservice::Monitoring
      include EventDrivenMicroservice::ApiGateway
      include EventDrivenMicroservice::Helpers

      component_attrs = EventDrivenMicroservice::EventDrivenMicroserviceAttributes.new(attributes)
      component_attrs.validate!

      component_tag_set = component_tags('EventDrivenMicroservice', name, component_attrs.tags)
      resources = {}

      # IAM
      resources[:lambda_role] = create_lambda_role(name, component_tag_set)
      resources.merge!(attach_lambda_policies(name, resources[:lambda_role], component_attrs))

      # Storage
      resources[:event_store] = create_event_store(name, component_attrs, component_tag_set)
      resources.merge!(create_cqrs_tables(name, component_attrs, component_tag_set))
      resources[:dead_letter_queue] = create_dead_letter_queue(name, component_attrs, component_tag_set)

      # Lambda functions
      resources[:command_handler] = create_command_handler(name, component_attrs, resources[:lambda_role], component_tag_set)
      resources[:query_handler] = create_query_handler(name, component_attrs, resources[:lambda_role], component_tag_set)
      resources[:event_processor] = create_event_processor(name, component_attrs, resources[:lambda_role], component_tag_set)

      # IAM policy (depends on resources)
      resources[:lambda_policy] = create_lambda_access_policy(name, resources[:lambda_role], resources, component_attrs)

      # Event sources
      handler_refs = {
        command_handler: resources[:command_handler],
        event_processor: resources[:event_processor]
      }
      resources[:event_source_mappings] = create_event_source_mappings(
        name, component_attrs, handler_refs, component_tag_set
      )

      # API Gateway
      api_permission = create_api_gateway_integration(name, component_attrs, resources[:command_handler])
      resources[:api_permission] = api_permission if api_permission

      # Monitoring
      monitoring = create_monitoring_resources(name, component_attrs, resources, component_tag_set)
      resources.merge!(monitoring)

      # Build outputs
      outputs = build_outputs(component_attrs, resources, resources[:event_source_mappings])

      create_component_reference(
        'event_driven_microservice',
        name,
        component_attrs.to_h,
        resources.compact,
        outputs
      )
    end
  end
end
