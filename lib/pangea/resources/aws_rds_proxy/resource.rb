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
require 'pangea/resources/aws_rds_proxy/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Create an AWS RDS Proxy with type-safe attributes
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] RDS proxy attributes
      # @return [ResourceReference] Reference object with outputs and computed properties
      def aws_rds_proxy(name, attributes = {})
        # Validate attributes using dry-struct
        proxy_attrs = Types::RdsProxyAttributes.new(attributes)
        
        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_db_proxy, name) do
          name proxy_attrs.db_proxy_name
          engine_family proxy_attrs.engine_family
          role_arn proxy_attrs.role_arn
          vpc_subnet_ids proxy_attrs.vpc_subnet_ids
          
          # Optional VPC security groups
          vpc_security_group_ids proxy_attrs.vpc_security_group_ids if proxy_attrs.vpc_security_group_ids && proxy_attrs.vpc_security_group_ids.any?
          
          # Authentication configurations
          proxy_attrs.auth.each do |auth_config|
            auth do
              auth_scheme auth_config.auth_scheme
              client_password_auth_type auth_config.client_password_auth_type if auth_config.client_password_auth_type
              description auth_config.description if auth_config.description
              iam_auth auth_config.iam_auth
              secret_arn auth_config.secret_arn
              username auth_config.username if auth_config.username
            end
          end
          
          # Connection and security settings
          require_tls proxy_attrs.require_tls
          idle_client_timeout proxy_attrs.idle_client_timeout
          debug_logging proxy_attrs.debug_logging
          
          # Apply tags if present
          if proxy_attrs.tags.any?
            tags do
              proxy_attrs.tags.each do |key, value|
                public_send(key, value)
              end
            end
          end
        end
        
        # Return resource reference with available outputs
        ResourceReference.new(
          type: 'aws_db_proxy',
          name: name,
          resource_attributes: proxy_attrs.to_h,
          outputs: {
            id: "${aws_db_proxy.#{name}.id}",
            arn: "${aws_db_proxy.#{name}.arn}",
            name: "${aws_db_proxy.#{name}.name}",
            engine_family: "${aws_db_proxy.#{name}.engine_family}",
            endpoint: "${aws_db_proxy.#{name}.endpoint}",
            role_arn: "${aws_db_proxy.#{name}.role_arn}",
            vpc_subnet_ids: "${aws_db_proxy.#{name}.vpc_subnet_ids}",
            vpc_security_group_ids: "${aws_db_proxy.#{name}.vpc_security_group_ids}",
            require_tls: "${aws_db_proxy.#{name}.require_tls}",
            idle_client_timeout: "${aws_db_proxy.#{name}.idle_client_timeout}",
            debug_logging: "${aws_db_proxy.#{name}.debug_logging}",
            tags: "${aws_db_proxy.#{name}.tags}",
            tags_all: "${aws_db_proxy.#{name}.tags_all}"
          },
          computed_properties: {
            is_mysql: proxy_attrs.is_mysql?,
            is_postgresql: proxy_attrs.is_postgresql?,
            requires_tls: proxy_attrs.requires_tls?,
            debug_logging_enabled: proxy_attrs.debug_logging_enabled?,
            uses_iam_auth: proxy_attrs.uses_iam_auth?,
            is_highly_available: proxy_attrs.is_highly_available?,
            auth_config_count: proxy_attrs.auth_config_count,
            idle_timeout_hours: proxy_attrs.idle_timeout_hours,
            secrets_manager_arns: proxy_attrs.secrets_manager_arns,
            has_security_groups: proxy_attrs.has_security_groups?,
            configuration_summary: proxy_attrs.configuration_summary,
            estimated_monthly_cost: proxy_attrs.estimated_monthly_cost,
            supported_database_engines: proxy_attrs.supported_database_engines
          }
        )
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)