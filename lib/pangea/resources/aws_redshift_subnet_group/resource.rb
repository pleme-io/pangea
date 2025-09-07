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
require 'pangea/resources/aws_redshift_subnet_group/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Create an AWS Redshift Subnet Group with type-safe attributes
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] Redshift Subnet Group attributes
      # @return [ResourceReference] Reference object with outputs and computed properties
      def aws_redshift_subnet_group(name, attributes = {})
        # Validate attributes using dry-struct
        subnet_group_attrs = Types::RedshiftSubnetGroupAttributes.new(attributes)
        
        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_redshift_subnet_group, name) do
          # Required attributes
          subnet_group_name = subnet_group_attrs.name
          subnet_ids subnet_group_attrs.subnet_ids
          
          # Optional description
          description subnet_group_attrs.generated_description
          
          # Apply tags if present
          if subnet_group_attrs.tags.any?
            tags do
              subnet_group_attrs.tags.each do |key, value|
                public_send(key, value)
              end
            end
          end
        end
        
        # Return resource reference with available outputs
        ResourceReference.new(
          type: 'aws_redshift_subnet_group',
          name: name,
          resource_attributes: subnet_group_attrs.to_h,
          outputs: {
            id: "${aws_redshift_subnet_group.#{name}.id}",
            name: "${aws_redshift_subnet_group.#{name}.name}",
            arn: "${aws_redshift_subnet_group.#{name}.arn}"
          },
          computed_properties: {
            multi_az_capable: subnet_group_attrs.multi_az_capable?,
            has_redundancy: subnet_group_attrs.has_redundancy?,
            subnet_count: subnet_group_attrs.subnet_count,
            estimated_az_count: subnet_group_attrs.estimated_az_count,
            production_grade: subnet_group_attrs.production_grade?
          }
        )
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)