# frozen_string_literal: true

module Pangea
  module Components
    module ApiGatewayMicroservices
      # API Gateway method and integration creation
      module Methods
        def create_method_and_integration(name, api_ref, endpoint, method_config, method_resource_ref,
                                          component_attrs, validator_ref, vpc_links, methods, integrations)
          method_ref = create_api_method(name, api_ref, endpoint, method_config, method_resource_ref, component_attrs, validator_ref)
          methods[method_config.method.downcase.to_sym] = method_ref

          integration_ref = create_integration(name, api_ref, endpoint, method_config, method_resource_ref, vpc_links)
          method_response_ref = create_method_response(name, api_ref, endpoint, method_config, method_resource_ref, component_attrs)
          integration_response_ref = create_integration_response(name, api_ref, endpoint, method_config, method_resource_ref, component_attrs)

          integrations[method_config.method.downcase.to_sym] = {
            integration: integration_ref,
            response: method_response_ref,
            integration_response: integration_response_ref
          }
        end

        private

        def create_api_method(name, api_ref, endpoint, method_config, method_resource_ref, component_attrs, validator_ref)
          aws_api_gateway_method(
            component_resource_name(name, :method, "#{endpoint.name}_#{method_config.method.downcase}".to_sym),
            {
              rest_api_id: api_ref.id,
              resource_id: method_resource_ref.id,
              http_method: method_config.method,
              authorization: component_attrs.authorizer_ref ? 'CUSTOM' : method_config.authorization,
              authorizer_id: component_attrs.authorizer_ref&.id,
              api_key_required: method_config.api_key_required || component_attrs.require_api_key,
              request_validator_id: method_config.request_validator || validator_ref.id,
              request_models: method_config.request_models.empty? ? nil : method_config.request_models,
              request_parameters: method_config.request_parameters.empty? ? nil : method_config.request_parameters
            }.compact
          )
        end

        def create_integration(name, api_ref, endpoint, method_config, method_resource_ref, vpc_links)
          integration_uri = resolve_integration_uri(endpoint)

          aws_api_gateway_integration(
            component_resource_name(name, :integration, "#{endpoint.name}_#{method_config.method.downcase}".to_sym),
            integration_attributes(api_ref, endpoint, method_config, method_resource_ref, integration_uri, vpc_links)
          )
        end

        def resolve_integration_uri(endpoint)
          uri = endpoint.integration.uri
          return uri unless endpoint.integration.connection_type == 'VPC_LINK'

          uri.gsub(%r{https?://[^/]+}, "http://#{endpoint.nlb_ref.dns_name}")
        end

        def integration_attributes(api_ref, endpoint, method_config, method_resource_ref, integration_uri, vpc_links)
          {
            rest_api_id: api_ref.id,
            resource_id: method_resource_ref.id,
            http_method: method_config.method,
            type: endpoint.integration.type,
            integration_http_method: endpoint.integration.http_method,
            uri: integration_uri,
            connection_type: endpoint.integration.connection_type,
            connection_id: endpoint.vpc_link_ref ? vpc_links[endpoint.vpc_link_ref].id : endpoint.integration.connection_id,
            timeout_in_millis: endpoint.integration.timeout_milliseconds,
            content_handling: endpoint.integration.content_handling,
            passthrough_behavior: endpoint.integration.passthrough_behavior,
            cache_key_parameters: endpoint.integration.cache_key_parameters.empty? ? nil : endpoint.integration.cache_key_parameters,
            cache_namespace: endpoint.integration.cache_namespace,
            request_templates: endpoint.transformation.request_templates.empty? ? nil : endpoint.transformation.request_templates,
            request_parameters: endpoint.transformation.response_parameters.empty? ? nil : endpoint.transformation.response_parameters
          }.compact
        end

        def create_method_response(name, api_ref, endpoint, method_config, method_resource_ref, component_attrs)
          aws_api_gateway_method_response(
            component_resource_name(name, :response, "#{endpoint.name}_#{method_config.method.downcase}".to_sym),
            {
              rest_api_id: api_ref.id,
              resource_id: method_resource_ref.id,
              http_method: method_config.method,
              status_code: '200',
              response_models: endpoint.transformation.response_models.empty? ? nil : endpoint.transformation.response_models,
              response_parameters: component_attrs.cors.enabled ? { 'method.response.header.Access-Control-Allow-Origin' => true } : nil
            }.compact
          )
        end

        def create_integration_response(name, api_ref, endpoint, method_config, method_resource_ref, component_attrs)
          aws_api_gateway_integration_response(
            component_resource_name(name, :integration_response, "#{endpoint.name}_#{method_config.method.downcase}".to_sym),
            {
              rest_api_id: api_ref.id,
              resource_id: method_resource_ref.id,
              http_method: method_config.method,
              status_code: '200',
              response_templates: endpoint.transformation.response_templates.empty? ? nil : endpoint.transformation.response_templates,
              response_parameters: component_attrs.cors.enabled ? {
                'method.response.header.Access-Control-Allow-Origin' => "'#{component_attrs.cors.allow_origins.first}'"
              } : nil
            }.compact
          )
        end
      end
    end
  end
end
