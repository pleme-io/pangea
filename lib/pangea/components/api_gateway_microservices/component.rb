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
require 'pangea/components/api_gateway_microservices/types'
require 'pangea/components/api_gateway_microservices/cors'
require 'pangea/components/api_gateway_microservices/resources'
require 'pangea/components/api_gateway_microservices/methods'
require 'pangea/components/api_gateway_microservices/deployment'
require 'pangea/components/api_gateway_microservices/rate_limiting'
require 'pangea/components/api_gateway_microservices/monitoring'
require 'pangea/components/api_gateway_microservices/helpers'
require 'pangea/resources/aws'

module Pangea
  module Components
    # API Gateway with multiple microservice integrations, advanced routing, and enterprise features
    # Creates a complete API Gateway setup with rate limiting, versioning, CORS, and transformations
    def api_gateway_microservices(name, attributes = {})
      include Base
      include Resources::AWS
      include ApiGatewayMicroservices::Cors
      include ApiGatewayMicroservices::Resources
      include ApiGatewayMicroservices::Methods
      include ApiGatewayMicroservices::Deployment
      include ApiGatewayMicroservices::RateLimiting
      include ApiGatewayMicroservices::Monitoring
      include ApiGatewayMicroservices::Helpers

      component_attrs = ApiGatewayMicroservices::ApiGatewayMicroservicesAttributes.new(attributes)
      component_attrs.validate!

      component_tag_set = component_tags('ApiGatewayMicroservices', name, component_attrs.tags)
      resources = {}

      # Create REST API
      resources[:api] = create_rest_api(name, component_attrs, component_tag_set)
      resources[:validator] = create_request_validator(name, resources[:api])

      # Create VPC Links
      vpc_links = create_vpc_links(name, component_attrs)
      resources[:vpc_links] = vpc_links unless vpc_links.empty?

      # Create service resources and methods
      service_result = create_service_resources(name, resources[:api], component_attrs, resources[:validator], vpc_links)
      resources.merge!(service_result)

      # Create deployment and stage
      deployment_result = create_deployment_resources(
        name, resources[:api], component_attrs,
        resources[:service_methods], resources[:service_integrations], component_tag_set
      )
      resources.merge!(deployment_result)

      # Create rate limiting resources
      rate_limit_result = create_rate_limiting_resources(
        name, resources[:api], component_attrs, resources[:stage], component_tag_set
      )
      resources.merge!(rate_limit_result)

      # Create alarms
      resources[:alarms] = create_api_alarms(name, resources[:api], resources[:stage], component_tag_set)

      # Associate WAF
      waf_association = create_waf_association(name, component_attrs, resources[:stage])
      resources[:waf_association] = waf_association if waf_association

      # Build outputs
      outputs = build_api_outputs(resources[:api], resources[:stage], component_attrs, resources)

      create_component_reference(
        'api_gateway_microservices',
        name,
        component_attrs.to_h,
        resources,
        outputs
      )
    end

    private

    def create_rest_api(name, component_attrs, tags)
      aws_api_gateway_rest_api(
        component_resource_name(name, :api),
        {
          name: component_attrs.api_name,
          description: component_attrs.api_description,
          endpoint_configuration: {
            types: [component_attrs.endpoint_type],
            vpc_endpoint_ids: component_attrs.vpc_endpoint_ids.empty? ? nil : component_attrs.vpc_endpoint_ids
          }.compact,
          binary_media_types: component_attrs.binary_media_types,
          minimum_compression_size: component_attrs.minimum_compression_size,
          api_key_source: component_attrs.api_key_source,
          tags: tags
        }.compact
      )
    end

    def create_request_validator(name, api_ref)
      aws_api_gateway_request_validator(
        component_resource_name(name, :validator),
        {
          name: "#{name}-validator",
          rest_api_id: api_ref.id,
          validate_request_body: true,
          validate_request_parameters: true
        }
      )
    end
  end
end
