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
  module Components
    module GlobalTrafficManager
      # Edge function resources for CloudFront Lambda@Edge
      module EdgeFunctions
        def create_edge_functions(_name, attrs, _tags)
          edge_functions = []

          edge_functions << security_headers_function if security_headers_enabled?(attrs)
          edge_functions << request_router_function if request_routing_enabled?(attrs)

          edge_functions
        end

        private

        def security_headers_enabled?(attrs)
          attrs.security.ddos_protection || attrs.security.waf_enabled
        end

        def request_routing_enabled?(attrs)
          attrs.advanced_routing.request_routing_rules.any?
        end

        def security_headers_function
          {
            event_type: 'origin-response',
            lambda_arn: 'arn:aws:lambda:us-east-1:ACCOUNT:function:security-headers:1'
          }
        end

        def request_router_function
          {
            event_type: 'viewer-request',
            lambda_arn: 'arn:aws:lambda:us-east-1:ACCOUNT:function:request-router:1'
          }
        end
      end
    end
  end
end
