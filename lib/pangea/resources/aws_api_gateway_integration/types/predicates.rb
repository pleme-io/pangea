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
        module ApiGatewayIntegrationPredicates
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
        end
      end
    end
  end
end
