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

module Pangea
  module Resources
    module AWS
      module Types
        # Validation methods for Kinesis Firehose Delivery Stream attributes
        module FirehoseValidation
          DESTINATION_CONFIG_MAP = {
            's3' => :s3_configuration,
            'extended_s3' => :extended_s3_configuration,
            'redshift' => :redshift_configuration,
            'elasticsearch' => :elasticsearch_configuration,
            'amazonopensearch' => :amazonopensearch_configuration,
            'splunk' => :splunk_configuration,
            'http_endpoint' => :http_endpoint_configuration
          }.freeze

          ARN_PATTERNS = {
            'kinesis' => /\Aarn:aws:kinesis:[a-z0-9-]+:\d{12}:stream\/[a-zA-Z0-9_-]+\z/,
            'iam' => /\Aarn:aws:iam::\d{12}:role\/[a-zA-Z0-9_\+\=\,\.\@\-]+\z/,
            's3' => /\Aarn:aws:s3:::[a-z0-9.-]+\z/,
            'default' => /\Aarn:aws:[a-z0-9-]+:[a-z0-9-]*:\d{12}:.+\z/
          }.freeze

          def self.validate_destination_config!(attrs)
            destination = attrs[:destination]
            config_key = DESTINATION_CONFIG_MAP[destination]
            return unless config_key && !attrs[config_key]

            raise Dry::Struct::Error, "#{config_key} is required when destination is '#{destination}'"
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
            pattern = ARN_PATTERNS[service] || ARN_PATTERNS['default']
            return if arn.match?(pattern)

            raise Dry::Struct::Error, "Invalid #{service} ARN format: #{arn}"
          end
        end
      end
    end
  end
end
