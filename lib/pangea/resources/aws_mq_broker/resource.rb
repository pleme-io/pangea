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
require 'pangea/resources/aws_mq_broker/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Create an AWS MQ Broker for message queuing
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] MQ broker attributes
      # @option attributes [String] :broker_name The broker name
      # @option attributes [String] :engine_type ActiveMQ or RabbitMQ
      # @option attributes [String] :engine_version Engine version
      # @option attributes [String] :host_instance_type Instance type
      # @option attributes [Array<Hash>] :users Broker users configuration
      # @option attributes [Boolean] :apply_immediately Apply changes immediately
      # @option attributes [String] :authentication_strategy Authentication strategy
      # @option attributes [Boolean] :auto_minor_version_upgrade Auto upgrade minor versions
      # @option attributes [Hash] :configuration Broker configuration
      # @option attributes [String] :deployment_mode Deployment mode
      # @option attributes [Hash] :encryption_options Encryption settings
      # @option attributes [Hash] :ldap_server_metadata LDAP configuration
      # @option attributes [Hash] :logs Logging configuration
      # @option attributes [Hash] :maintenance_window_start_time Maintenance window
      # @option attributes [Boolean] :publicly_accessible Public accessibility
      # @option attributes [Array<String>] :security_groups Security group IDs
      # @option attributes [String] :storage_type Storage type
      # @option attributes [Array<String>] :subnet_ids Subnet IDs
      # @option attributes [Hash] :tags Resource tags
      # @return [ResourceReference] Reference object with outputs
      def aws_mq_broker(name, attributes = {})
        # Validate attributes using dry-struct
        broker_attrs = Types::Types::MqBrokerAttributes.new(attributes)
        
        # Generate terraform resource block
        resource(:aws_mq_broker, name) do
          broker_name broker_attrs.broker_name
          engine_type broker_attrs.engine_type
          engine_version broker_attrs.engine_version
          host_instance_type broker_attrs.host_instance_type
          
          # Users configuration
          broker_attrs.users.each do |user|
            user do
              username user[:username]
              password user[:password] if user[:password]
              console_access user[:console_access] if user.key?(:console_access)
              groups user[:groups] if user[:groups]
            end
          end
          
          apply_immediately broker_attrs.apply_immediately if broker_attrs.apply_immediately != false
          authentication_strategy broker_attrs.authentication_strategy if broker_attrs.authentication_strategy != 'simple'
          auto_minor_version_upgrade broker_attrs.auto_minor_version_upgrade if broker_attrs.auto_minor_version_upgrade != false
          
          # Configuration
          if broker_attrs.configuration
            configuration do
              id broker_attrs.configuration[:id] if broker_attrs.configuration[:id]
              revision broker_attrs.configuration[:revision] if broker_attrs.configuration[:revision]
            end
          end
          
          deployment_mode broker_attrs.deployment_mode if broker_attrs.deployment_mode != 'SINGLE_INSTANCE'
          
          # Encryption options
          if broker_attrs.encryption_options
            encryption_options do
              kms_key_id broker_attrs.encryption_options[:kms_key_id] if broker_attrs.encryption_options[:kms_key_id]
              use_aws_owned_key broker_attrs.encryption_options[:use_aws_owned_key] if broker_attrs.encryption_options.key?(:use_aws_owned_key)
            end
          end
          
          # LDAP server metadata
          if broker_attrs.ldap_server_metadata
            ldap_server_metadata do
              hosts broker_attrs.ldap_server_metadata[:hosts]
              role_base broker_attrs.ldap_server_metadata[:role_base]
              role_name broker_attrs.ldap_server_metadata[:role_name] if broker_attrs.ldap_server_metadata[:role_name]
              role_search_matching broker_attrs.ldap_server_metadata[:role_search_matching] if broker_attrs.ldap_server_metadata[:role_search_matching]
              role_search_subtree broker_attrs.ldap_server_metadata[:role_search_subtree] if broker_attrs.ldap_server_metadata.key?(:role_search_subtree)
              service_account_password broker_attrs.ldap_server_metadata[:service_account_password]
              service_account_username broker_attrs.ldap_server_metadata[:service_account_username]
              user_base broker_attrs.ldap_server_metadata[:user_base]
              user_role_name broker_attrs.ldap_server_metadata[:user_role_name] if broker_attrs.ldap_server_metadata[:user_role_name]
              user_search_matching broker_attrs.ldap_server_metadata[:user_search_matching] if broker_attrs.ldap_server_metadata[:user_search_matching]
              user_search_subtree broker_attrs.ldap_server_metadata[:user_search_subtree] if broker_attrs.ldap_server_metadata.key?(:user_search_subtree)
            end
          end
          
          # Logs
          if broker_attrs.logs
            logs do
              general broker_attrs.logs[:general] if broker_attrs.logs.key?(:general)
              audit broker_attrs.logs[:audit] if broker_attrs.logs.key?(:audit)
            end
          end
          
          # Maintenance window
          if broker_attrs.maintenance_window_start_time
            maintenance_window_start_time do
              day_of_week broker_attrs.maintenance_window_start_time[:day_of_week]
              time_of_day broker_attrs.maintenance_window_start_time[:time_of_day]
              time_zone broker_attrs.maintenance_window_start_time[:time_zone] if broker_attrs.maintenance_window_start_time[:time_zone]
            end
          end
          
          publicly_accessible broker_attrs.publicly_accessible if broker_attrs.publicly_accessible != false
          security_groups broker_attrs.security_groups if broker_attrs.security_groups
          storage_type broker_attrs.storage_type if broker_attrs.storage_type
          subnet_ids broker_attrs.subnet_ids if broker_attrs.subnet_ids
          
          # Tags
          if broker_attrs.tags&.any?
            tags broker_attrs.tags
          end
        end
        
        # Return resource reference with outputs
        ResourceReference.new(
          type: 'aws_mq_broker',
          name: name,
          resource_attributes: broker_attrs.to_h,
          outputs: {
            id: "${aws_mq_broker.#{name}.id}",
            arn: "${aws_mq_broker.#{name}.arn}",
            broker_name: "${aws_mq_broker.#{name}.broker_name}",
            instances: "${aws_mq_broker.#{name}.instances}",
            console_url: "${aws_mq_broker.#{name}.instances.0.console_url}",
            endpoints: "${aws_mq_broker.#{name}.instances.0.endpoints}"
          }
        )
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)