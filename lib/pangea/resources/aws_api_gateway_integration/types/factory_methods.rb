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

module Pangea
  module Resources
    module AWS
      module Types
        module ApiGatewayIntegrationFactoryMethods
          def lambda_proxy_integration(function_arn, credentials: nil)
            {
              type: 'AWS_PROXY',
              integration_http_method: 'POST',
              uri: "arn:aws:apigateway:${data.aws_region.current.name}:lambda:path/2015-03-31/functions/#{function_arn}/invocations",
              credentials: credentials
            }
          end

          def lambda_integration(function_arn, credentials: nil, request_templates: {})
            {
              type: 'AWS',
              integration_http_method: 'POST',
              uri: "arn:aws:apigateway:${data.aws_region.current.name}:lambda:path/2015-03-31/functions/#{function_arn}/invocations",
              credentials: credentials,
              request_templates: request_templates
            }
          end

          def http_proxy_integration(endpoint_url)
            {
              type: 'HTTP_PROXY',
              integration_http_method: 'ANY',
              uri: endpoint_url
            }
          end

          def http_integration(endpoint_url, http_method, request_templates: {})
            {
              type: 'HTTP',
              integration_http_method: http_method,
              uri: endpoint_url,
              request_templates: request_templates
            }
          end

          def mock_integration(request_templates: { 'application/json' => '{"statusCode": 200}' })
            {
              type: 'MOCK',
              request_templates: request_templates
            }
          end

          def s3_integration(bucket_name, credentials:, request_parameters: {})
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

          def dynamodb_integration(table_name, action, credentials:, request_templates: {})
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
