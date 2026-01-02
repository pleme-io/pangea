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

require 'dry-struct'
require 'pangea/resources/types'
require_relative 'types/network_analysis'
require_relative 'types/security_analysis'

module Pangea
  module Resources
    module AWS
      module Types
        # Transit Gateway Route resource attributes with validation
        class TransitGatewayRouteAttributes < Dry::Struct
          include NetworkAnalysis
          include SecurityAnalysis

          transform_keys(&:to_sym)

          attribute :destination_cidr_block, Resources::Types::TransitGatewayCidrBlock
          attribute :transit_gateway_route_table_id, Resources::Types::String
          attribute? :blackhole, Resources::Types::Bool.default(false)
          attribute? :transit_gateway_attachment_id, Resources::Types::String.optional

          # Custom validation for route configuration
          def self.new(attributes)
            attrs = attributes.is_a?(Hash) ? attributes : {}
            validate_route_table_id(attrs)
            validate_attachment_id(attrs)
            validate_blackhole_logic(attrs)
            super(attrs)
          end

          class << self
            private

            def validate_route_table_id(attrs)
              return unless attrs[:transit_gateway_route_table_id]
              return if attrs[:transit_gateway_route_table_id].match?(/\Atgw-rtb-[0-9a-f]{8,17}\z/)

              raise Dry::Struct::Error,
                    "Invalid Transit Gateway Route Table ID format: #{attrs[:transit_gateway_route_table_id]}. " \
                    'Expected format: tgw-rtb-xxxxxxxx'
            end

            def validate_attachment_id(attrs)
              return unless attrs[:transit_gateway_attachment_id]
              return if attrs[:transit_gateway_attachment_id].match?(/\Atgw-attach-[0-9a-f]{8,17}\z/)

              raise Dry::Struct::Error,
                    "Invalid Transit Gateway Attachment ID format: #{attrs[:transit_gateway_attachment_id]}. " \
                    'Expected format: tgw-attach-xxxxxxxx'
            end

            def validate_blackhole_logic(attrs)
              if attrs[:blackhole] == true && attrs[:transit_gateway_attachment_id]
                raise Dry::Struct::Error,
                      'Blackhole routes cannot specify a transit_gateway_attachment_id. ' \
                      'Set blackhole: true without attachment_id for traffic drop.'
              end

              return if attrs[:blackhole] == true || attrs[:transit_gateway_attachment_id]

              raise Dry::Struct::Error,
                    'Non-blackhole routes must specify a transit_gateway_attachment_id for traffic forwarding.'
            end
          end
        end
      end
    end
  end
end
