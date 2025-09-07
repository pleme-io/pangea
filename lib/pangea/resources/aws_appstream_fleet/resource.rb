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
require 'pangea/resources/aws_appstream_fleet/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Create an AWS AppStream Fleet with type-safe attributes
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] AppStream Fleet attributes
      # @return [ResourceReference] Reference object with outputs and computed properties
      def aws_appstream_fleet(name, attributes = {})
        # Validate attributes using dry-struct
        fleet_attrs = Types::Types::AppstreamFleetAttributes.new(attributes)
        
        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_appstream_fleet, name) do
          name fleet_attrs.name
          instance_type fleet_attrs.instance_type
          fleet_type fleet_attrs.fleet_type
          
          # Compute capacity
          compute_capacity do
            desired_instances fleet_attrs.compute_capacity.desired_instances
          end
          
          # Optional description and display name
          description fleet_attrs.description if fleet_attrs.description
          display_name fleet_attrs.display_name if fleet_attrs.display_name
          
          # Image configuration
          if fleet_attrs.image_name
            image_name fleet_attrs.image_name
          elsif fleet_attrs.image_arn
            image_arn fleet_attrs.image_arn
          end
          
          # VPC configuration
          if fleet_attrs.vpc_config
            vpc_config do
              subnet_ids fleet_attrs.vpc_config.subnet_ids
              security_group_ids fleet_attrs.vpc_config.security_group_ids if fleet_attrs.vpc_config.security_group_ids
            end
          end
          
          # Domain join configuration
          if fleet_attrs.domain_join_info
            domain_join_info do
              directory_name fleet_attrs.domain_join_info.directory_name
              if fleet_attrs.domain_join_info.organizational_unit_distinguished_name
                organizational_unit_distinguished_name fleet_attrs.domain_join_info.organizational_unit_distinguished_name
              end
            end
          end
          
          # Network and timeout settings
          enable_default_internet_access fleet_attrs.enable_default_internet_access
          idle_disconnect_timeout_in_seconds fleet_attrs.idle_disconnect_timeout_in_seconds
          disconnect_timeout_in_seconds fleet_attrs.disconnect_timeout_in_seconds
          max_user_duration_in_seconds fleet_attrs.max_user_duration_in_seconds
          stream_view fleet_attrs.stream_view
          
          # Apply tags if present
          if fleet_attrs.tags.any?
            tags do
              fleet_attrs.tags.each do |key, value|
                public_send(key, value)
              end
            end
          end
        end
        
        # Return resource reference with available outputs
        ResourceReference.new(
          type: 'aws_appstream_fleet',
          name: name,
          resource_attributes: fleet_attrs.to_h,
          outputs: {
            id: "${aws_appstream_fleet.#{name}.id}",
            arn: "${aws_appstream_fleet.#{name}.arn}",
            state: "${aws_appstream_fleet.#{name}.state}",
            created_time: "${aws_appstream_fleet.#{name}.created_time}",
            name: fleet_attrs.name,
            instance_type: fleet_attrs.instance_type,
            fleet_type: fleet_attrs.fleet_type
          },
          computed_properties: {
            always_on: fleet_attrs.always_on?,
            on_demand: fleet_attrs.on_demand?,
            max_concurrent_sessions: fleet_attrs.max_concurrent_sessions,
            estimated_monthly_cost: fleet_attrs.estimated_monthly_cost,
            multi_az: fleet_attrs.vpc_config&.multi_az?,
            domain_joined: !fleet_attrs.domain_join_info.nil?,
            internet_enabled: fleet_attrs.enable_default_internet_access
          }
        )
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)