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
require_relative 'types/shared_schemas'
require_relative 'types/s3_destinations'
require_relative 'types/search_destinations'
require_relative 'types/other_destinations'
require_relative 'types/source_and_encryption'

module Pangea
  module Resources
    module AWS
      module Types
        # Kinesis Firehose Delivery Stream resource attributes with validation
        class KinesisFirehoseDeliveryStreamAttributes < Dry::Struct
          transform_keys(&:to_sym)

          attribute :name, String
          attribute :destination, String.enum(
            'extended_s3', 's3', 'redshift', 'elasticsearch', 'amazonopensearch',
            'splunk', 'http_endpoint', 'snowflake'
          )

          # S3 destination configurations
          attribute :s3_configuration, FirehoseS3Destinations::S3Configuration.optional
          attribute :extended_s3_configuration, FirehoseS3Destinations::ExtendedS3Configuration.optional

          # Search destination configurations
          attribute :elasticsearch_configuration, FirehoseSearchDestinations::ElasticsearchConfiguration.optional
          attribute :amazonopensearch_configuration, FirehoseSearchDestinations::AmazonOpensearchConfiguration.optional

          # Other destination configurations
          attribute :redshift_configuration, FirehoseOtherDestinations::RedshiftConfiguration.optional
          attribute :splunk_configuration, FirehoseOtherDestinations::SplunkConfiguration.optional
          attribute :http_endpoint_configuration, FirehoseOtherDestinations::HttpEndpointConfiguration.optional

          # Source and encryption configurations
          attribute :kinesis_source_configuration, FirehoseSourceAndEncryption::KinesisSourceConfiguration.optional
          attribute :server_side_encryption, FirehoseSourceAndEncryption::ServerSideEncryption.optional

          attribute :tags, Resources::Types::AwsTags

          # Custom validation
          def self.new(attributes)
            attrs = attributes.is_a?(Hash) ? attributes : {}
            validate_destination_config!(attrs)
            validate_encryption_config!(attrs)
            validate_source_arns!(attrs)
            super(attrs)
          end

          def self.validate_destination_config!(attrs)
            destination = attrs[:destination]
            config_key = destination_config_key(destination)
            return unless config_key && !attrs[config_key]

            raise Dry::Struct::Error, "#{config_key} is required when destination is '#{destination}'"
          end

          def self.destination_config_key(destination)
            {
              's3' => :s3_configuration,
              'extended_s3' => :extended_s3_configuration,
              'redshift' => :redshift_configuration,
              'elasticsearch' => :elasticsearch_configuration,
              'amazonopensearch' => :amazonopensearch_configuration,
              'splunk' => :splunk_configuration,
              'http_endpoint' => :http_endpoint_configuration
            }[destination]
          end

          def self.validate_encryption_config!(attrs)
            return unless attrs[:server_side_encryption]&.dig(:enabled)

            sse_config = attrs[:server_side_encryption]
            return unless sse_config[:key_type] == 'CUSTOMER_MANAGED_CMK' && !sse_config[:key_arn]

            raise Dry::Struct::Error, "key_arn is required when key_type is 'CUSTOMER_MANAGED_CMK'"
          end

          def self.validate_source_arns!(attrs)
            return unless attrs[:kinesis_source_configuration]

            validate_arn!(attrs[:kinesis_source_configuration][:kinesis_stream_arn], 'kinesis')
            validate_arn!(attrs[:kinesis_source_configuration][:role_arn], 'iam')
          end

          def self.validate_arn!(arn, service)
            pattern = arn_pattern(service)
            return if arn.match?(pattern)

            raise Dry::Struct::Error, "Invalid #{service} ARN format: #{arn}"
          end

          def self.arn_pattern(service)
            case service
            when 'kinesis' then /\Aarn:aws:kinesis:[a-z0-9-]+:\d{12}:stream\/[a-zA-Z0-9_-]+\z/
            when 'iam' then /\Aarn:aws:iam::\d{12}:role\/[a-zA-Z0-9_\+\=\,\.\@\-]+\z/
            when 's3' then /\Aarn:aws:s3:::[a-z0-9.-]+\z/
            else /\Aarn:aws:[a-z0-9-]+:[a-z0-9-]*:\d{12}:.+\z/
            end
          end

          # Computed properties
          def has_data_transformation?
            config = destination_config
            config&.dig(:processing_configuration, :enabled) == true
          end

          def has_format_conversion?
            destination == 'extended_s3' &&
              extended_s3_configuration&.dig(:data_format_conversion_configuration, :enabled) == true
          end

          def backup_enabled?
            backup_mode = destination_config&.dig(:s3_backup_mode)
            backup_enabled_values.include?(backup_mode)
          end

          def is_encrypted?
            server_side_encryption&.dig(:enabled) == true
          end

          def uses_customer_managed_key?
            is_encrypted? && server_side_encryption&.dig(:key_type) == 'CUSTOMER_MANAGED_CMK'
          end

          def has_kinesis_source?
            !kinesis_source_configuration.nil?
          end

          def estimated_monthly_cost_usd
            "Variable - depends on data volume and destination"
          end

          private

          def destination_config
            public_send("#{destination}_configuration".to_sym) if respond_to?("#{destination}_configuration")
          end

          def backup_enabled_values
            %w[Enabled AllDocuments AllEvents AllData]
          end
        end
      end
    end
  end
end
