# frozen_string_literal: true

require 'dry-struct'
require 'pangea/resources/types'

module Pangea
  module Resources
    module AWS
      module Types
        # API Gateway Integration attributes with validation
        class ApiGatewayIntegrationAttributes < Dry::Struct
          transform_keys(&:to_sym)
          
          # Core attributes
          attribute :rest_api_id, Pangea::Resources::Types::String
          attribute :resource_id, Pangea::Resources::Types::String
          attribute :http_method, Pangea::Resources::Types::String.constrained(included_in: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS', 'HEAD', 'PATCH', 'ANY'])
          
          # Integration type and configuration
          attribute :type, Pangea::Resources::Types::String.constrained(included_in: ['MOCK', 'HTTP', 'HTTP_PROXY', 'AWS', 'AWS_PROXY'])
          attribute :integration_http_method, Pangea::Resources::Types::String.optional.default(nil)
          attribute :uri, Pangea::Resources::Types::String.optional.default(nil)
          
          # Connection details
          attribute :connection_type, Pangea::Resources::Types::String.default('INTERNET').constrained(included_in: ['INTERNET', 'VPC_LINK'])
          attribute :connection_id, Pangea::Resources::Types::String.optional.default(nil)
          
          # Credentials and caching
          attribute :credentials, Pangea::Resources::Types::String.optional.default(nil)
          attribute :cache_key_parameters, Pangea::Resources::Types::Array.of(Pangea::Resources::Types::String).default([].freeze)
          attribute :cache_namespace, Pangea::Resources::Types::String.optional.default(nil)
          
          # Request configuration
          attribute :request_templates, Pangea::Resources::Types::Hash.map(
            Pangea::Resources::Types::String, Pangea::Resources::Types::String
          ).default({}.freeze)
          
          attribute :request_parameters, Pangea::Resources::Types::Hash.map(
            Pangea::Resources::Types::String, Pangea::Resources::Types::String
          ).default({}.freeze)
          
          # Response passthrough for proxy integrations
          attribute :passthrough_behavior, Pangea::Resources::Types::String.default('WHEN_NO_MATCH').constrained(included_in: ['WHEN_NO_MATCH', 'WHEN_NO_TEMPLATES', 'NEVER'])
          
          # Content handling
          attribute :content_handling, Pangea::Resources::Types::String.optional.default(nil)
          
          # Timeout configuration
          attribute :timeout_milliseconds, Pangea::Resources::Types::Integer.default(29000).constrained(gteq: 50, lteq: 29000)
          
          # Custom validation
          def self.new(attributes)
            attrs = attributes.is_a?(Hash) ? attributes : {}
            
            # Validate integration type combinations
            case attrs[:type]
            when 'HTTP', 'HTTP_PROXY', 'AWS', 'AWS_PROXY'
              if attrs[:uri].nil? || attrs[:uri].empty?
                raise Dry::Struct::Error, "uri is required for #{attrs[:type]} integrations"
              end
            when 'MOCK'
              # URI not required for MOCK integrations
            end
            
            # Validate HTTP method for non-proxy integrations
            if ['HTTP', 'AWS'].include?(attrs[:type]) && attrs[:integration_http_method].nil?
              raise Dry::Struct::Error, "integration_http_method is required for #{attrs[:type]} integrations"
            end
            
            # Validate VPC_LINK connection
            if attrs[:connection_type] == 'VPC_LINK'
              if attrs[:connection_id].nil? || attrs[:connection_id].empty?
                raise Dry::Struct::Error, "connection_id is required when connection_type is VPC_LINK"
              end
            end
            
            # Validate request parameter mapping format
            if attrs[:request_parameters]
              attrs[:request_parameters].each do |integration_param, method_param|
                # Integration parameters should be in format integration.request.{location}.{name}
                unless integration_param.match?(/^integration\.request\.(path|querystring|header|multivalueheader|multivaluequerystring)\..+/)
                  raise Dry::Struct::Error, "Invalid integration parameter format: #{integration_param}"
                end
                
                # Method parameters should reference method.request.* or static values
                unless method_param.match?(/^(method\.request\.|'.*'|".*")/) || method_param == 'context.requestId' || method_param.start_with?('stageVariables.')
                  raise Dry::Struct::Error, "Invalid method parameter reference: #{method_param}"
                end
              end
            end
            
            # Validate content handling types
            if attrs[:content_handling] && !['CONVERT_TO_BINARY', 'CONVERT_TO_TEXT'].include?(attrs[:content_handling])
              raise Dry::Struct::Error, "content_handling must be CONVERT_TO_BINARY or CONVERT_TO_TEXT"
            end
            
            super(attrs)
          end
          
          # Computed properties
          def is_proxy_integration?
            ['HTTP_PROXY', 'AWS_PROXY'].include?(type)
          end
          
          def is_lambda_integration?
            type == 'AWS_PROXY' && uri&.include?('lambda')
          end
          
          def is_http_integration?
            ['HTTP', 'HTTP_PROXY'].include?(type)
          end
          
          def is_aws_service_integration?
            type == 'AWS' && !is_lambda_integration?
          end
          
          def is_mock_integration?
            type == 'MOCK'
          end
          
          def uses_vpc_link?
            connection_type == 'VPC_LINK'
          end
          
          def has_caching?
            !cache_key_parameters.empty? || !cache_namespace.nil?
          end
          
          def requires_iam_role?
            ['AWS', 'AWS_PROXY'].include?(type) && !is_lambda_integration?
          end
          
          # URI pattern detection
          def lambda_function_name
            return nil unless is_lambda_integration?
            
            # Extract function name from ARN or URI
            if uri.include?('lambda:path')
              # Path format: arn:aws:apigateway:region:lambda:path/2015-03-31/functions/arn:aws:lambda:region:account:function:function-name/invocations
              # Look for the nested lambda ARN and extract the last part after the last colon
              nested_match = uri.match(%r{functions/(arn:aws:lambda:[^/]+)/})
              if nested_match
                nested_arn = nested_match[1]
                nested_arn.split(':').last
              else
                # Fallback for direct function reference
                match = uri.match(%r{functions/([^/]+)/})
                match ? match[1] : nil
              end
            elsif uri.include?('arn:aws:lambda')
              # Direct ARN format: arn:aws:lambda:region:account:function:function-name
              uri.split(':').last
            end
          end
          
          def aws_service_name
            return nil unless is_aws_service_integration?
            
            # Extract service from URI
            # Format: arn:aws:apigateway:region:service:action/service_api
            match = uri.match(/arn:aws:apigateway:[^:]+:([^:]+):/)
            match ? match[1] : nil
          end
          
          # Helper methods for common configurations
          def self.lambda_proxy_integration(function_arn, credentials: nil)
            {
              type: 'AWS_PROXY',
              integration_http_method: 'POST',
              uri: "arn:aws:apigateway:${data.aws_region.current.name}:lambda:path/2015-03-31/functions/#{function_arn}/invocations",
              credentials: credentials
            }
          end
          
          def self.lambda_integration(function_arn, credentials: nil, request_templates: {})
            {
              type: 'AWS',
              integration_http_method: 'POST',
              uri: "arn:aws:apigateway:${data.aws_region.current.name}:lambda:path/2015-03-31/functions/#{function_arn}/invocations",
              credentials: credentials,
              request_templates: request_templates
            }
          end
          
          def self.http_proxy_integration(endpoint_url)
            {
              type: 'HTTP_PROXY',
              integration_http_method: 'ANY',
              uri: endpoint_url
            }
          end
          
          def self.http_integration(endpoint_url, http_method, request_templates: {})
            {
              type: 'HTTP',
              integration_http_method: http_method,
              uri: endpoint_url,
              request_templates: request_templates
            }
          end
          
          def self.mock_integration(request_templates: { 'application/json' => '{"statusCode": 200}' })
            {
              type: 'MOCK',
              request_templates: request_templates
            }
          end
          
          def self.s3_integration(bucket_name, credentials:, request_parameters: {})
            {
              type: 'AWS',
              integration_http_method: 'GET',
              uri: "arn:aws:apigateway:${data.aws_region.current.name}:s3:path/#{bucket_name}/{key}",
              credentials: credentials,
              request_parameters: {
                'integration.request.path.key' => 'method.request.path.key'
              }.merge(request_parameters)
            }
          end
          
          def self.dynamodb_integration(table_name, action, credentials:, request_templates: {})
            {
              type: 'AWS',
              integration_http_method: 'POST',
              uri: "arn:aws:apigateway:${data.aws_region.current.name}:dynamodb:action/#{action}",
              credentials: credentials,
              request_templates: {
                'application/json' => {
                  TableName: table_name,
                  Key: {
                    id: {
                      S: '$input.params("id")'
                    }
                  }
                }.to_json
              }.merge(request_templates)
            }
          end
        end
      end
    end
  end
end