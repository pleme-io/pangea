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


require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/cloudflare_page_rule/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    # Cloudflare Page Rule resource module
    module CloudflarePageRule
      # Create a Cloudflare Page Rule with type-safe attributes
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] Page rule attributes
      # @return [ResourceReference] Reference object with outputs and computed properties
      def cloudflare_page_rule(name, attributes = {})
        # Validate attributes using dry-struct
        rule_attrs = Cloudflare::Types::PageRuleAttributes.new(attributes)

        # Generate terraform resource block via terraform-synthesizer
        resource(:cloudflare_page_rule, name) do
          zone_id rule_attrs.zone_id
          target rule_attrs.target
          priority rule_attrs.priority
          status rule_attrs.status

          # Add actions
          actions do
            rule_attrs.actions.each do |action_name, action_value|
              if action_value.is_a?(Hash)
                public_send(action_name) do
                  action_value.each do |k, v|
                    public_send(k, v)
                  end
                end
              else
                public_send(action_name, action_value)
              end
            end
          end
        end

        # Return resource reference with available outputs
        ResourceReference.new(
          type: 'cloudflare_page_rule',
          name: name,
          resource_attributes: rule_attrs.to_h,
          outputs: {
            id: "${cloudflare_page_rule.#{name}.id}"
          }
        )
      end
    end

    # Extend Cloudflare module
    module Cloudflare
      include CloudflarePageRule
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register_module(Pangea::Resources::Cloudflare)
