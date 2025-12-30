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
        class KinesisAnalyticsApplicationAttributes
          # Validation methods for Kinesis Analytics Application
          module Validation
            IAM_ROLE_ARN_PATTERN = /\Aarn:aws:iam::\d{12}:role\/[a-zA-Z0-9_\+\=\,\.\@\-]+\z/.freeze

            def self.valid_iam_role_arn?(arn)
              arn.match?(IAM_ROLE_ARN_PATTERN)
            end

            def self.validate_attributes(attrs)
              validate_service_execution_role(attrs[:service_execution_role])
              validate_runtime_configuration(attrs[:runtime_environment], attrs[:application_configuration])
              validate_code_content(attrs[:application_configuration])
              validate_sql_configuration(attrs[:application_configuration])
            end

            def self.validate_service_execution_role(role_arn)
              return unless role_arn && !valid_iam_role_arn?(role_arn)

              raise Dry::Struct::Error, "Invalid service execution role ARN: #{role_arn}"
            end

            def self.validate_runtime_configuration(runtime, app_config)
              return unless runtime && app_config

              if runtime == 'SQL-1_0' && !app_config[:sql_application_configuration]
                raise Dry::Struct::Error, 'SQL-1_0 runtime requires sql_application_configuration'
              end

              return unless runtime.start_with?('FLINK')
              return if app_config[:flink_application_configuration] || app_config[:application_code_configuration]

              raise Dry::Struct::Error,
                    'Flink runtime requires flink_application_configuration and/or application_code_configuration'
            end

            def self.validate_code_content(app_config)
              code_config = app_config&.dig(:application_code_configuration)
              return unless code_config

              content = code_config[:code_content]
              content_type = code_config[:code_content_type]

              case content_type
              when 'PLAINTEXT'
                raise Dry::Struct::Error, 'PLAINTEXT code content type requires text_content' unless content[:text_content]
              when 'ZIPFILE'
                return if content[:zip_file_content] || content[:s3_content_location]

                raise Dry::Struct::Error, 'ZIPFILE code content type requires zip_file_content or s3_content_location'
              end
            end

            def self.validate_sql_configuration(app_config)
              sql_config = app_config&.dig(:sql_application_configuration)
              return unless sql_config

              validate_sql_inputs(sql_config[:inputs])
              validate_sql_outputs(sql_config[:outputs])
            end

            def self.validate_sql_inputs(inputs)
              return unless inputs

              inputs.each do |input|
                next if input[:kinesis_streams_input] || input[:kinesis_firehose_input]

                raise Dry::Struct::Error,
                      "SQL input '#{input[:name_prefix]}' must have either kinesis_streams_input or kinesis_firehose_input"
              end
            end

            def self.validate_sql_outputs(outputs)
              return unless outputs

              outputs.each do |output|
                next if output[:kinesis_streams_output] || output[:kinesis_firehose_output] || output[:lambda_output]

                raise Dry::Struct::Error,
                      "SQL output '#{output[:name]}' must have a destination " \
                      '(kinesis_streams_output, kinesis_firehose_output, or lambda_output)'
              end
            end
          end
        end
      end
    end
  end
end
