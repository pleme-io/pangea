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
require_relative 'types/propagation_insights'
require_relative 'types/security_concerns'
require_relative 'types/troubleshooting_support'

module Pangea
  module Resources
    module AWS
      module Types
        # Transit Gateway Route Table Propagation resource attributes with validation
        class TransitGatewayRouteTablePropagationAttributes < Dry::Struct
          include PropagationInsights
          include SecurityConcerns
          include TroubleshootingSupport

          transform_keys(&:to_sym)

          attribute :transit_gateway_attachment_id, Resources::Types::String
          attribute :transit_gateway_route_table_id, Resources::Types::String

          # Custom validation for propagation configuration
          def self.new(attributes)
            attrs = attributes.is_a?(Hash) ? attributes : {}

            # Validate attachment ID format
            if attrs[:transit_gateway_attachment_id] && !attrs[:transit_gateway_attachment_id].match?(/\Atgw-attach-[0-9a-f]{8,17}\z/)
              raise Dry::Struct::Error, "Invalid Transit Gateway Attachment ID format: #{attrs[:transit_gateway_attachment_id]}. Expected format: tgw-attach-xxxxxxxx"
            end

            # Validate route table ID format
            if attrs[:transit_gateway_route_table_id] && !attrs[:transit_gateway_route_table_id].match?(/\Atgw-rtb-[0-9a-f]{8,17}\z/)
              raise Dry::Struct::Error, "Invalid Transit Gateway Route Table ID format: #{attrs[:transit_gateway_route_table_id]}. Expected format: tgw-rtb-xxxxxxxx"
            end

            super(attrs)
          end
        end
      end
    end
  end
end
