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


require 'dry-struct'
require 'pangea/resources/types'

module Pangea
  module Resources
    module AWS
      module Types
        # MQ broker engine types
        MqEngineType = String.enum('ActiveMQ', 'RabbitMQ')

        # MQ instance types
        MqInstanceType = String.enum(
          'mq.t2.micro', 'mq.t3.micro',
          'mq.m4.large', 'mq.m5.large', 'mq.m5.xlarge', 'mq.m5.2xlarge', 'mq.m5.4xlarge',
          'mq.c4.large', 'mq.c4.xlarge', 'mq.c5.large', 'mq.c5.xlarge', 'mq.c5.2xlarge', 'mq.c5.4xlarge', 'mq.c5.9xlarge',
          'mq.r4.large', 'mq.r4.xlarge', 'mq.r4.2xlarge', 'mq.r4.4xlarge',
          'mq.r5.large', 'mq.r5.xlarge', 'mq.r5.2xlarge', 'mq.r5.4xlarge', 'mq.r5.12xlarge'
        )

        # MQ deployment mode
        MqDeploymentMode = String.enum('SINGLE_INSTANCE', 'ACTIVE_STANDBY_MULTI_AZ', 'CLUSTER_MULTI_AZ')

        # MQ storage type
        MqStorageType = String.enum('ebs', 'efs')

        # MQ authentication strategy
        MqAuthenticationStrategy = String.enum('simple', 'ldap')

        # MQ day of week
        MqDayOfWeek = String.enum('MONDAY', 'TUESDAY', 'WEDNESDAY', 'THURSDAY', 'FRIDAY', 'SATURDAY', 'SUNDAY')

        # MQ user configuration
        MqUser = Hash.schema(
          username: Resources::Types::String.constrained(size: 1..100),
          password?: Resources::Types::String.constrained(size: 12..250).optional,
          console_access?: Resources::Types::Bool.optional,
          groups?: Resources::Types::Array.of(String).optional
        )

        # MQ encryption options
        MqEncryptionOptions = Hash.schema(
          kms_key_id?: Resources::Types::String.optional,
          use_aws_owned_key?: Resources::Types::Bool.optional
        )

        # MQ maintenance window start time
        MqMaintenanceWindowStartTime = Hash.schema(
          day_of_week: MqDayOfWeek,
          time_of_day: Resources::Types::String.constrained(format: /\A([01]?[0-9]|2[0-3]):[0-5][0-9]\z/),
          time_zone?: Resources::Types::String.optional
        )

        # MQ logs configuration
        MqLogs = Hash.schema(
          general?: Resources::Types::Bool.optional,
          audit?: Resources::Types::Bool.optional
        )

        # MQ LDAP server metadata (for LDAP authentication)
        MqLdapServerMetadata = Hash.schema(
          hosts: Resources::Types::Array.of(String).constrained(min_size: 1),
          role_base: Resources::Types::String,
          role_name?: Resources::Types::String.optional,
          role_search_matching?: Resources::Types::String.optional,
          role_search_subtree?: Resources::Types::Bool.optional,
          service_account_password: Resources::Types::String,
          service_account_username: Resources::Types::String,
          user_base: Resources::Types::String,
          user_role_name?: Resources::Types::String.optional,
          user_search_matching?: Resources::Types::String.optional,
          user_search_subtree?: Resources::Types::Bool.optional
        )

        # MQ Broker resource attributes
        class MqBrokerAttributes < Dry::Struct
          transform_keys(&:to_sym)

          attribute :broker_name, Resources::Types::String.constrained(
            format: /\A[a-zA-Z0-9_-]+\z/,
            size: 1..50
          )

          attribute :engine_type, MqEngineType
          
          attribute :engine_version, Resources::Types::String
          
          attribute :host_instance_type, MqInstanceType
          
          attribute :users, Resources::Types::Array.of(MqUser).constrained(min_size: 1, max_size: 250)

          attribute? :apply_immediately, Resources::Types::Bool.default(false)
          
          attribute? :authentication_strategy, MqAuthenticationStrategy.default('simple')
          
          attribute? :auto_minor_version_upgrade, Resources::Types::Bool.default(false)
          
          attribute? :configuration, Hash.schema(
            id?: Resources::Types::String.optional,
            revision?: Resources::Types::Integer.constrained(gteq: 1).optional
          ).optional
          
          attribute? :deployment_mode, MqDeploymentMode.default('SINGLE_INSTANCE')
          
          attribute? :encryption_options, MqEncryptionOptions.optional
          
          attribute? :ldap_server_metadata, MqLdapServerMetadata.optional
          
          attribute? :logs, MqLogs.optional
          
          attribute? :maintenance_window_start_time, MqMaintenanceWindowStartTime.optional
          
          attribute? :publicly_accessible, Resources::Types::Bool.default(false)
          
          attribute? :security_groups, Resources::Types::Array.of(String).optional
          
          attribute? :storage_type, MqStorageType.optional
          
          attribute? :subnet_ids, Resources::Types::Array.of(String).optional

          attribute? :tags, Resources::Types::AwsTags

          # Custom validation
          def self.new(attributes)
            attrs = attributes.is_a?(Hash) ? attributes : {}

            # Validate deployment mode constraints
            if attrs[:deployment_mode] && attrs[:engine_type]
              case attrs[:engine_type]
              when 'ActiveMQ'
                unless ['SINGLE_INSTANCE', 'ACTIVE_STANDBY_MULTI_AZ'].include?(attrs[:deployment_mode])
                  raise Dry::Struct::Error, "ActiveMQ only supports SINGLE_INSTANCE and ACTIVE_STANDBY_MULTI_AZ deployment modes"
                end
              when 'RabbitMQ'
                unless ['SINGLE_INSTANCE', 'CLUSTER_MULTI_AZ'].include?(attrs[:deployment_mode])
                  raise Dry::Struct::Error, "RabbitMQ only supports SINGLE_INSTANCE and CLUSTER_MULTI_AZ deployment modes"
                end
              end
            end

            # Validate multi-AZ requirements
            if attrs[:deployment_mode] && attrs[:deployment_mode].include?('MULTI_AZ')
              unless attrs[:subnet_ids] && attrs[:subnet_ids].size >= 2
                raise Dry::Struct::Error, "Multi-AZ deployment requires at least 2 subnet IDs"
              end
            end

            # Validate LDAP authentication requirements
            if attrs[:authentication_strategy] == 'ldap'
              unless attrs[:ldap_server_metadata]
                raise Dry::Struct::Error, "ldap_server_metadata is required when authentication_strategy is 'ldap'"
              end
            end

            # Validate storage type constraints
            if attrs[:storage_type] == 'efs' && attrs[:engine_type] != 'RabbitMQ'
              raise Dry::Struct::Error, "EFS storage type is only supported for RabbitMQ brokers"
            end

            super(attrs)
          end
        end
      end
    end
  end
end