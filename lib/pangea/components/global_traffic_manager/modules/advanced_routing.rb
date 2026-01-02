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
      # Advanced routing: canary and blue-green deployments
      module AdvancedRouting
        def create_advanced_routing_resources(name, attrs, resources, tags)
          has_canary = attrs.advanced_routing.canary_deployment.any?
          has_blue_green = attrs.advanced_routing.blue_green_deployment.any?
          return unless has_canary || has_blue_green

          routing_resources = {}
          create_canary_routing(name, attrs, tags, routing_resources) if has_canary
          create_blue_green_routing(name, attrs, resources, routing_resources) if has_blue_green
          resources[:advanced_routing] = routing_resources
        end

        private

        def create_canary_routing(name, attrs, tags, routing_resources)
          canary_config = attrs.advanced_routing.canary_deployment

          canary_lambda_ref = aws_lambda_function(
            component_resource_name(name, :canary_router),
            {
              function_name: "#{name}-canary-router",
              role: 'arn:aws:iam::ACCOUNT:role/LambdaEdgeRole',
              handler: 'index.handler',
              runtime: 'nodejs18.x',
              timeout: 5,
              memory_size: 128,
              environment: {
                variables: {
                  CANARY_PERCENTAGE: canary_config[:percentage].to_s,
                  CANARY_ENDPOINT: canary_config[:endpoint],
                  STABLE_ENDPOINT: canary_config[:stable_endpoint]
                }
              },
              code: { zip_file: generate_canary_router_code(canary_config) },
              tags: tags
            }
          )
          routing_resources[:canary_lambda] = canary_lambda_ref
        end

        def create_blue_green_routing(name, attrs, resources, routing_resources)
          bg_config = attrs.advanced_routing.blue_green_deployment

          %w[blue green].each do |color|
            endpoint = attrs.endpoints.find { |e| e.metadata[:deployment] == color }
            next unless endpoint

            bg_record_ref = aws_route53_record(
              component_resource_name(name, :bg_record, color.to_sym),
              {
                zone_id: resources[:hosted_zone].zone_id,
                name: "#{color}.#{attrs.domain_name}",
                type: 'A',
                ttl: '60',
                records: [endpoint.endpoint_id],
                weighted_routing_policy: { weight: bg_config["#{color}_weight".to_sym] || 0 },
                set_identifier: "bg-#{color}"
              }
            )
            routing_resources["bg_#{color}".to_sym] = bg_record_ref
          end
        end
      end
    end
  end
end
