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
require 'pangea/resources/aws_rds_proxy_default_target_group/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Create an AWS RDS Proxy Default Target Group with type-safe attributes
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] RDS proxy default target group attributes
      # @return [ResourceReference] Reference object with outputs and computed properties
      def aws_rds_proxy_default_target_group(name, attributes = {})
        # Validate attributes using dry-struct
        target_group_attrs = Types::RdsProxyDefaultTargetGroupAttributes.new(attributes)
        
        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_db_proxy_default_target_group, name) do
          db_proxy_name target_group_attrs.db_proxy_name
          
          # Connection pool configuration
          if target_group_attrs.connection_pool_config
            connection_pool_config do
              max_connections_percent target_group_attrs.connection_pool_config.max_connections_percent
              max_idle_connections_percent target_group_attrs.connection_pool_config.max_idle_connections_percent
              session_pinning_filters target_group_attrs.connection_pool_config.session_pinning_filters if target_group_attrs.connection_pool_config.session_pinning_filters.any?
              init_query target_group_attrs.connection_pool_config.init_query if target_group_attrs.connection_pool_config.init_query
            end
          end
        end
        
        # Return resource reference with available outputs
        ResourceReference.new(
          type: 'aws_db_proxy_default_target_group',
          name: name,
          resource_attributes: target_group_attrs.to_h,
          outputs: {
            id: "${aws_db_proxy_default_target_group.#{name}.id}",
            arn: "${aws_db_proxy_default_target_group.#{name}.arn}",
            name: "${aws_db_proxy_default_target_group.#{name}.name}",
            db_proxy_name: "${aws_db_proxy_default_target_group.#{name}.db_proxy_name}"
          },
          computed_properties: {
            has_connection_pool_config: target_group_attrs.has_connection_pool_config?,
            effective_max_connections_percent: target_group_attrs.effective_max_connections_percent,
            effective_max_idle_connections_percent: target_group_attrs.effective_max_idle_connections_percent
          }
        )
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)