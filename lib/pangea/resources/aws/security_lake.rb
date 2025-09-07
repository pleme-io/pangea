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


require_relative 'security_lake/data_lake'
require_relative 'security_lake/custom_log_source'
require_relative 'security_lake/aws_log_source'
require_relative 'security_lake/subscriber'
require_relative 'security_lake/subscriber_notification'
require_relative 'security_lake/data_lake_exception_subscription'
require_relative 'security_lake/organization_configuration'

module Pangea
  module Resources
    module AWS
      # AWS Security Lake service module
      # Provides type-safe resource functions for Security Lake centralized security data management
      module SecurityLake
        # Creates a Security Lake data lake for centralized security data storage
        #
        # @param name [Symbol] Unique name for the data lake resource
        # @param attributes [Hash] Configuration attributes for the data lake
        # @return [SecurityLake::DataLake::DataLakeReference] Reference to the created data lake
        def aws_securitylake_data_lake(name, attributes = {})
          resource = SecurityLake::DataLake.new(
            name: name,
            synthesizer: synthesizer,
            attributes: SecurityLake::DataLake::Attributes.new(attributes)
          )
          resource.synthesize
          resource.reference
        end

        # Creates a custom log source for Security Lake
        #
        # @param name [Symbol] Unique name for the custom log source resource
        # @param attributes [Hash] Configuration attributes for the custom log source
        # @return [SecurityLake::CustomLogSource::CustomLogSourceReference] Reference to the created log source
        def aws_securitylake_custom_log_source(name, attributes = {})
          resource = SecurityLake::CustomLogSource.new(
            name: name,
            synthesizer: synthesizer,
            attributes: SecurityLake::CustomLogSource::Attributes.new(attributes)
          )
          resource.synthesize
          resource.reference
        end

        # Enables AWS native log sources for Security Lake
        #
        # @param name [Symbol] Unique name for the AWS log source resource
        # @param attributes [Hash] Configuration attributes for the AWS log source
        # @return [SecurityLake::AwsLogSource::AwsLogSourceReference] Reference to the created log source
        def aws_securitylake_aws_log_source(name, attributes = {})
          resource = SecurityLake::AwsLogSource.new(
            name: name,
            synthesizer: synthesizer,
            attributes: SecurityLake::AwsLogSource::Attributes.new(attributes)
          )
          resource.synthesize
          resource.reference
        end

        # Creates a Security Lake subscriber for data access
        #
        # @param name [Symbol] Unique name for the subscriber resource
        # @param attributes [Hash] Configuration attributes for the subscriber
        # @return [SecurityLake::Subscriber::SubscriberReference] Reference to the created subscriber
        def aws_securitylake_subscriber(name, attributes = {})
          resource = SecurityLake::Subscriber.new(
            name: name,
            synthesizer: synthesizer,
            attributes: SecurityLake::Subscriber::Attributes.new(attributes)
          )
          resource.synthesize
          resource.reference
        end

        # Configures notifications for Security Lake subscribers
        #
        # @param name [Symbol] Unique name for the subscriber notification resource
        # @param attributes [Hash] Configuration attributes for the notification
        # @return [SecurityLake::SubscriberNotification::SubscriberNotificationReference] Reference to the created notification
        def aws_securitylake_subscriber_notification(name, attributes = {})
          resource = SecurityLake::SubscriberNotification.new(
            name: name,
            synthesizer: synthesizer,
            attributes: SecurityLake::SubscriberNotification::Attributes.new(attributes)
          )
          resource.synthesize
          resource.reference
        end

        # Creates an exception subscription for Security Lake error handling
        #
        # @param name [Symbol] Unique name for the exception subscription resource
        # @param attributes [Hash] Configuration attributes for the exception subscription
        # @return [SecurityLake::DataLakeExceptionSubscription::DataLakeExceptionSubscriptionReference] Reference to the created subscription
        def aws_securitylake_data_lake_exception_subscription(name, attributes = {})
          resource = SecurityLake::DataLakeExceptionSubscription.new(
            name: name,
            synthesizer: synthesizer,
            attributes: SecurityLake::DataLakeExceptionSubscription::Attributes.new(attributes)
          )
          resource.synthesize
          resource.reference
        end

        # Configures Security Lake for AWS Organizations
        #
        # @param name [Symbol] Unique name for the organization configuration resource
        # @param attributes [Hash] Configuration attributes for the organization settings
        # @return [SecurityLake::OrganizationConfiguration::OrganizationConfigurationReference] Reference to the created configuration
        def aws_securitylake_organization_configuration(name, attributes = {})
          resource = SecurityLake::OrganizationConfiguration.new(
            name: name,
            synthesizer: synthesizer,
            attributes: SecurityLake::OrganizationConfiguration::Attributes.new(attributes)
          )
          resource.synthesize
          resource.reference
        end
      end
    end
  end
end