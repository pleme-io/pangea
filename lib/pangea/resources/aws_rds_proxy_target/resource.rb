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
require 'pangea/resources/aws_rds_proxy_target/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Create an AWS RDS Proxy Target with type-safe attributes
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] RDS proxy target attributes
      # @return [ResourceReference] Reference object with outputs and computed properties
      def aws_rds_proxy_target(name, attributes = {})
        # Validate attributes using dry-struct
        target_attrs = Types::RdsProxyTargetAttributes.new(attributes)
        
        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_db_proxy_target, name) do
          db_proxy_name target_attrs.db_proxy_name
          target_group_name target_attrs.target_group_name
          
          # Specify either instance or cluster target
          if target_attrs.db_instance_identifier
            db_instance_identifier target_attrs.db_instance_identifier
          elsif target_attrs.db_cluster_identifier
            db_cluster_identifier target_attrs.db_cluster_identifier
          end
        end
        
        # Return resource reference with available outputs
        ResourceReference.new(
          type: 'aws_db_proxy_target',
          name: name,
          resource_attributes: target_attrs.to_h,
          outputs: {
            id: "${aws_db_proxy_target.#{name}.id}",
            endpoint: "${aws_db_proxy_target.#{name}.endpoint}",
            port: "${aws_db_proxy_target.#{name}.port}",
            rds_resource_id: "${aws_db_proxy_target.#{name}.rds_resource_id}",
            target_arn: "${aws_db_proxy_target.#{name}.target_arn}",
            tracked_cluster_id: "${aws_db_proxy_target.#{name}.tracked_cluster_id}",
            type: "${aws_db_proxy_target.#{name}.type}"
          },
          computed_properties: {
            targets_instance: target_attrs.targets_instance?,
            targets_cluster: target_attrs.targets_cluster?,
            target_identifier: target_attrs.target_identifier,
            target_type: target_attrs.target_type
          }
        )
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)