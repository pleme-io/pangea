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
require 'pangea/resources/aws_rds_cluster_parameter_group/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Create an AWS RDS Cluster Parameter Group with type-safe attributes
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] RDS cluster parameter group attributes
      # @return [ResourceReference] Reference object with outputs and computed properties
      def aws_rds_cluster_parameter_group(name, attributes = {})
        # Validate attributes using dry-struct
        pg_attrs = Types::RdsClusterParameterGroupAttributes.new(attributes)
        
        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_rds_cluster_parameter_group, name) do
          name pg_attrs.name if pg_attrs.name
          name_prefix pg_attrs.name_prefix if pg_attrs.name_prefix
          family pg_attrs.family
          description pg_attrs.description
          
          # Parameters configuration
          if pg_attrs.parameter.any?
            pg_attrs.parameter.each do |param|
              parameter do
                name param.name
                value param.terraform_value
                apply_method param.apply_method if param.apply_method != "pending-reboot"
              end
            end
          end
          
          # Apply tags if present
          if pg_attrs.tags.any?
            tags do
              pg_attrs.tags.each do |key, value|
                public_send(key, value)
              end
            end
          end
        end
        
        # Return resource reference with available outputs
        ResourceReference.new(
          type: 'aws_rds_cluster_parameter_group',
          name: name,
          resource_attributes: pg_attrs.to_h,
          outputs: {
            id: "${aws_rds_cluster_parameter_group.#{name}.id}",
            arn: "${aws_rds_cluster_parameter_group.#{name}.arn}",
            name: "${aws_rds_cluster_parameter_group.#{name}.name}",
            family: "${aws_rds_cluster_parameter_group.#{name}.family}",
            description: "${aws_rds_cluster_parameter_group.#{name}.description}",
            tags: "${aws_rds_cluster_parameter_group.#{name}.tags}",
            tags_all: "${aws_rds_cluster_parameter_group.#{name}.tags_all}"
          },
          computed_properties: {
            engine_type: pg_attrs.engine_type,
            engine_version: pg_attrs.engine_version,
            is_mysql_family: pg_attrs.is_mysql_family?,
            is_postgresql_family: pg_attrs.is_postgresql_family?,
            parameter_count: pg_attrs.parameter.count,
            parameter_names: pg_attrs.parameter_names,
            has_immediate_parameters: pg_attrs.has_immediate_parameters?,
            has_reboot_parameters: pg_attrs.has_reboot_parameters?,
            immediate_parameter_count: pg_attrs.immediate_parameters.count,
            reboot_parameter_count: pg_attrs.reboot_parameters.count,
            configuration_summary: pg_attrs.configuration_summary
          }
        )
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)