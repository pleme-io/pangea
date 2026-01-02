# frozen_string_literal: true

module Pangea
  module Components
    module ApiGatewayMicroservices
      # CORS preflight OPTIONS method creation
      module Cors
        def create_cors_preflight(api_ref, parent_resource, path_part, cors_config)
          return nil unless cors_config.enabled

          method_ref = aws_api_gateway_method(
            component_resource_name_for_cors(path_part, :method),
            {
              rest_api_id: api_ref.id,
              resource_id: parent_resource.id,
              http_method: 'OPTIONS',
              authorization: 'NONE'
            }
          )

          integration_ref = aws_api_gateway_integration(
            component_resource_name_for_cors(path_part, :integration),
            cors_mock_integration(api_ref, parent_resource)
          )

          response_ref = aws_api_gateway_method_response(
            component_resource_name_for_cors(path_part, :response),
            cors_method_response(api_ref, parent_resource, cors_config)
          )

          integration_response_ref = aws_api_gateway_integration_response(
            component_resource_name_for_cors(path_part, :integration_response),
            cors_integration_response(api_ref, parent_resource, cors_config)
          )

          {
            method: method_ref,
            integration: integration_ref,
            response: response_ref,
            integration_response: integration_response_ref
          }
        end

        private

        def component_resource_name_for_cors(path_part, type)
          component_resource_name(@current_name, type, "#{path_part}_options".to_sym)
        end

        def cors_mock_integration(api_ref, parent_resource)
          {
            rest_api_id: api_ref.id,
            resource_id: parent_resource.id,
            http_method: 'OPTIONS',
            type: 'MOCK',
            request_templates: { 'application/json' => '{"statusCode": 200}' }
          }
        end

        def cors_method_response(api_ref, parent_resource, cors_config)
          {
            rest_api_id: api_ref.id,
            resource_id: parent_resource.id,
            http_method: 'OPTIONS',
            status_code: '200',
            response_parameters: {
              'method.response.header.Access-Control-Allow-Headers' => true,
              'method.response.header.Access-Control-Allow-Methods' => true,
              'method.response.header.Access-Control-Allow-Origin' => true,
              'method.response.header.Access-Control-Max-Age' => true,
              'method.response.header.Access-Control-Allow-Credentials' => cors_config.allow_credentials
            }
          }
        end

        def cors_integration_response(api_ref, parent_resource, cors_config)
          {
            rest_api_id: api_ref.id,
            resource_id: parent_resource.id,
            http_method: 'OPTIONS',
            status_code: '200',
            response_parameters: {
              'method.response.header.Access-Control-Allow-Headers' => "'#{cors_config.allow_headers.join(',')}'",
              'method.response.header.Access-Control-Allow-Methods' => "'#{cors_config.allow_methods.join(',')}'",
              'method.response.header.Access-Control-Allow-Origin' => "'#{cors_config.allow_origins.first}'",
              'method.response.header.Access-Control-Max-Age' => "'#{cors_config.max_age}'",
              'method.response.header.Access-Control-Allow-Credentials' => "'#{cors_config.allow_credentials}'"
            }
          }
        end
      end
    end
  end
end
