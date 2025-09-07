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
require 'pangea/resources/aws_rds_cluster_endpoint/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Create an AWS RDS Cluster Endpoint with type-safe attributes
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] RDS cluster endpoint attributes
      # @return [ResourceReference] Reference object with outputs and computed properties
      def aws_rds_cluster_endpoint(name, attributes = {})
        # Validate attributes using dry-struct
        endpoint_attrs = Types::RdsClusterEndpointAttributes.new(attributes)
        
        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_rds_cluster_endpoint, name) do
          cluster_identifier endpoint_attrs.cluster_identifier
          cluster_endpoint_identifier endpoint_attrs.cluster_endpoint_identifier
          custom_endpoint_type endpoint_attrs.custom_endpoint_type
          
          # Static members configuration
          if endpoint_attrs.static_members.any?
            static_members endpoint_attrs.static_members.map(&:db_instance_identifier)
          end
          
          # Excluded members configuration
          if endpoint_attrs.excluded_members.any?
            excluded_members endpoint_attrs.excluded_members.map(&:db_instance_identifier)
          end
          
          # Apply tags if present
          if endpoint_attrs.tags.any?
            tags do
              endpoint_attrs.tags.each do |key, value|
                public_send(key, value)
              end
            end
          end
        end
        
        # Return resource reference with available outputs
        ResourceReference.new(
          type: 'aws_rds_cluster_endpoint',
          name: name,
          resource_attributes: endpoint_attrs.to_h,
          outputs: {
            id: "${aws_rds_cluster_endpoint.#{name}.id}",
            arn: "${aws_rds_cluster_endpoint.#{name}.arn}",
            cluster_identifier: "${aws_rds_cluster_endpoint.#{name}.cluster_identifier}",
            cluster_endpoint_identifier: "${aws_rds_cluster_endpoint.#{name}.cluster_endpoint_identifier}",
            custom_endpoint_type: "${aws_rds_cluster_endpoint.#{name}.custom_endpoint_type}",
            endpoint: "${aws_rds_cluster_endpoint.#{name}.endpoint}",
            static_members: "${aws_rds_cluster_endpoint.#{name}.static_members}",
            excluded_members: "${aws_rds_cluster_endpoint.#{name}.excluded_members}",
            tags: "${aws_rds_cluster_endpoint.#{name}.tags}",
            tags_all: "${aws_rds_cluster_endpoint.#{name}.tags_all}"
          },
          computed_properties: {
            is_reader: endpoint_attrs.is_reader?,
            is_writer: endpoint_attrs.is_writer?,
            is_any: endpoint_attrs.is_any?,
            has_static_members: endpoint_attrs.has_static_members?,
            has_excluded_members: endpoint_attrs.has_excluded_members?,
            static_member_db_ids: endpoint_attrs.static_member_db_ids,
            excluded_member_db_ids: endpoint_attrs.excluded_member_db_ids,
            uses_custom_member_config: endpoint_attrs.uses_custom_member_config?,
            configuration_summary: endpoint_attrs.configuration_summary,
            estimated_monthly_cost: endpoint_attrs.estimated_monthly_cost
          }
        )
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)