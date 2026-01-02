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
        module ApiGatewayIntegrationUriHelpers
          # Extract Lambda function name from integration URI
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

          # Extract AWS service name from integration URI
          def aws_service_name
            return nil unless is_aws_service_integration?

            # Extract service from URI
            # Format: arn:aws:apigateway:region:service:action/service_api
            match = uri.match(/arn:aws:apigateway:[^:]+:([^:]+):/)
            match ? match[1] : nil
          end
        end
      end
    end
  end
end
