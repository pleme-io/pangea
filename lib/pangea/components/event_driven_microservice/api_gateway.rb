# frozen_string_literal: true

module Pangea
  module Components
    module EventDrivenMicroservice
      # API Gateway integration
      module ApiGateway
        def create_api_gateway_integration(name, component_attrs, command_handler_ref)
          return nil unless component_attrs.api_gateway_enabled && component_attrs.api_gateway_ref

          aws_lambda_permission(
            component_resource_name(name, :api_permission),
            {
              statement_id: 'AllowAPIGateway',
              action: 'lambda:InvokeFunction',
              function_name: command_handler_ref.function_name,
              principal: 'apigateway.amazonaws.com',
              source_arn: "#{component_attrs.api_gateway_ref.execution_arn}/*/*"
            }
          )
        end
      end
    end
  end
end
