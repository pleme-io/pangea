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
require 'pangea/resources/aws_neptune_cluster_instance/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Provides a Neptune Cluster Instance resource.
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] Resource attributes
      # @return [ResourceReference] Reference object with outputs and computed properties
      def aws_neptune_cluster_instance(name, attributes = {})
        # Validate attributes using dry-struct
        attrs = Types::NeptuneClusterInstanceAttributes.new(attributes)
        
        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_neptune_cluster_instance, name) do
          identifier attrs.identifier if attrs.identifier
          cluster_identifier attrs.cluster_identifier if attrs.cluster_identifier
          instance_class attrs.instance_class if attrs.instance_class
          engine attrs.engine if attrs.engine
          engine_version attrs.engine_version if attrs.engine_version
          availability_zone attrs.availability_zone if attrs.availability_zone
          preferred_maintenance_window attrs.preferred_maintenance_window if attrs.preferred_maintenance_window
          apply_immediately attrs.apply_immediately if attrs.apply_immediately
          auto_minor_version_upgrade attrs.auto_minor_version_upgrade if attrs.auto_minor_version_upgrade
          promotion_tier attrs.promotion_tier if attrs.promotion_tier
          neptune_parameter_group_name attrs.neptune_parameter_group_name if attrs.neptune_parameter_group_name
          
          # Apply tags if present
          if attrs.tags.any?
            tags do
              attrs.tags.each do |key, value|
                public_send(key, value)
              end
            end
          end
        end
        
        # Return resource reference with available outputs
        ResourceReference.new(
          type: 'aws_neptune_cluster_instance',
          name: name,
          resource_attributes: attrs.to_h,
          outputs: {
            id: "${aws_neptune_cluster_instance.#{name}.id}",
            arn: "${aws_neptune_cluster_instance.#{name}.arn}",
            dbi_resource_id: "${aws_neptune_cluster_instance.#{name}.dbi_resource_id}",
            endpoint: "${aws_neptune_cluster_instance.#{name}.endpoint}",
            port: "${aws_neptune_cluster_instance.#{name}.port}",
            status: "${aws_neptune_cluster_instance.#{name}.status}",
            storage_encrypted: "${aws_neptune_cluster_instance.#{name}.storage_encrypted}",
            kms_key_id: "${aws_neptune_cluster_instance.#{name}.kms_key_id}",
            writer: "${aws_neptune_cluster_instance.#{name}.writer}"
          },
          computed_properties: {
            # Computed properties from type definitions
          }
        )
      end
    end
  end
end


# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)