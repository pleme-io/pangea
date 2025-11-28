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
require 'pangea/resources/cloudflare_zone_settings_override/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    # Cloudflare Zone Settings Override resource module
    module CloudflareZoneSettingsOverride
      # Create a Cloudflare Zone Settings Override with type-safe attributes
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] Zone settings attributes
      # @return [ResourceReference] Reference object with outputs and computed properties
      def cloudflare_zone_settings_override(name, attributes = {})
        # Validate attributes using dry-struct
        settings_attrs = Cloudflare::Types::ZoneSettingsOverrideAttributes.new(attributes)

        # Generate terraform resource block via terraform-synthesizer
        resource(:cloudflare_zone_settings_override, name) do
          zone_id settings_attrs.zone_id

          # Add settings if present
          if settings_attrs.settings
            settings do
              settings_attrs.settings.each do |setting_name, setting_value|
                if setting_value.is_a?(Hash)
                  public_send(setting_name) do
                    setting_value.each do |k, v|
                      public_send(k, v)
                    end
                  end
                else
                  public_send(setting_name, setting_value)
                end
              end
            end
          end
        end

        # Return resource reference with available outputs
        ResourceReference.new(
          type: 'cloudflare_zone_settings_override',
          name: name,
          resource_attributes: settings_attrs.to_h,
          outputs: {
            id: "${cloudflare_zone_settings_override.#{name}.id}",
            initial_settings: "${cloudflare_zone_settings_override.#{name}.initial_settings}",
            initial_settings_read_at: "${cloudflare_zone_settings_override.#{name}.initial_settings_read_at}",
            readonly_settings: "${cloudflare_zone_settings_override.#{name}.readonly_settings}"
          }
        )
      end
    end

    # Extend Cloudflare module
    module Cloudflare
      include CloudflareZoneSettingsOverride
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register_module(Pangea::Resources::Cloudflare)
