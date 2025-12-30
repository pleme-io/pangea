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
        module ApiGatewayIntegrationValidators
          module_function

          def validate_attributes(attrs)
            validate_integration_type(attrs)
            validate_http_method(attrs)
            validate_vpc_link(attrs)
            validate_request_parameters(attrs)
            validate_content_handling(attrs)
          end

          def validate_integration_type(attrs)
            case attrs[:type]
            when 'HTTP', 'HTTP_PROXY', 'AWS', 'AWS_PROXY'
              if attrs[:uri].nil? || attrs[:uri].empty?
                raise Dry::Struct::Error, "uri is required for #{attrs[:type]} integrations"
              end
            when 'MOCK'
              # URI not required for MOCK integrations
            end
          end

          def validate_http_method(attrs)
            if ['HTTP', 'AWS'].include?(attrs[:type]) && attrs[:integration_http_method].nil?
              raise Dry::Struct::Error, "integration_http_method is required for #{attrs[:type]} integrations"
            end
          end

          def validate_vpc_link(attrs)
            if attrs[:connection_type] == 'VPC_LINK'
              if attrs[:connection_id].nil? || attrs[:connection_id].empty?
                raise Dry::Struct::Error, 'connection_id is required when connection_type is VPC_LINK'
              end
            end
          end

          def validate_request_parameters(attrs)
            return unless attrs[:request_parameters]

            attrs[:request_parameters].each do |integration_param, method_param|
              validate_integration_param_format(integration_param)
              validate_method_param_reference(method_param)
            end
          end

          def validate_integration_param_format(integration_param)
            valid_format = /^integration\.request\.(path|querystring|header|multivalueheader|multivaluequerystring)\..+/
            unless integration_param.match?(valid_format)
              raise Dry::Struct::Error, "Invalid integration parameter format: #{integration_param}"
            end
          end

          def validate_method_param_reference(method_param)
            valid_references = [
              method_param.match?(/^method\.request\./),
              method_param.match?(/^'.*'$/),
              method_param.match?(/^".*"$/),
              method_param == 'context.requestId',
              method_param.start_with?('stageVariables.')
            ]
            unless valid_references.any?
              raise Dry::Struct::Error, "Invalid method parameter reference: #{method_param}"
            end
          end

          def validate_content_handling(attrs)
            return unless attrs[:content_handling]

            valid_values = ['CONVERT_TO_BINARY', 'CONVERT_TO_TEXT']
            unless valid_values.include?(attrs[:content_handling])
              raise Dry::Struct::Error, 'content_handling must be CONVERT_TO_BINARY or CONVERT_TO_TEXT'
            end
          end
        end
      end
    end
  end
end
