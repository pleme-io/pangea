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
        # Validators for AWS Config Config Rule attributes
        module ConfigConfigRuleValidators
          VALID_OWNERS = %w[AWS AWS_CONFIG_RULE CUSTOM_LAMBDA CUSTOM_POLICY].freeze
          VALID_FREQUENCIES = %w[One_Hour Three_Hours Six_Hours Twelve_Hours TwentyFour_Hours].freeze
          LAMBDA_ARN_PATTERN = /\Aarn:aws:lambda:[^:]+:\d{12}:function:/.freeze
          NAME_PATTERN = /\A[a-zA-Z0-9_-]+\z/.freeze

          module_function

          def validate_name(name)
            return unless name

            raise Dry::Struct::Error, 'Config rule name cannot be empty' if name.empty?
            raise Dry::Struct::Error, 'Config rule name cannot exceed 128 characters' if name.length > 128

            return if name.match?(NAME_PATTERN)

            raise Dry::Struct::Error, 'Config rule name can only contain alphanumeric characters, hyphens, and underscores'
          end

          def validate_source(source)
            return unless source.is_a?(Hash)

            raise Dry::Struct::Error, 'source.owner is required' unless source[:owner]
            raise Dry::Struct::Error, "source.owner must be one of: #{VALID_OWNERS.join(', ')}" unless VALID_OWNERS.include?(source[:owner])

            validate_source_by_owner(source)
          end

          def validate_source_by_owner(source)
            case source[:owner]
            when 'AWS'
              raise Dry::Struct::Error, 'source.source_identifier is required for AWS managed rules' unless source[:source_identifier]
            when 'CUSTOM_LAMBDA'
              validate_custom_lambda_source(source)
            when 'CUSTOM_POLICY'
              raise Dry::Struct::Error, 'source.source_detail is required for custom policy rules' unless source[:source_detail]&.is_a?(Array)
            end
          end

          def validate_custom_lambda_source(source)
            raise Dry::Struct::Error, 'source.source_identifier (Lambda ARN) is required for custom Lambda rules' unless source[:source_identifier]
            return if source[:source_identifier].match?(LAMBDA_ARN_PATTERN)

            raise Dry::Struct::Error, 'source.source_identifier must be a valid Lambda function ARN for custom Lambda rules'
          end

          def validate_frequency(frequency)
            return unless frequency
            return if VALID_FREQUENCIES.include?(frequency)

            raise Dry::Struct::Error, "maximum_execution_frequency must be one of: #{VALID_FREQUENCIES.join(', ')}"
          end

          def validate_scope(scope)
            return unless scope.is_a?(Hash)

            raise Dry::Struct::Error, 'scope.compliance_resource_types must be an array' if scope[:compliance_resource_types] && !scope[:compliance_resource_types].is_a?(Array)
            raise Dry::Struct::Error, 'scope.tag_key must be a string' if scope[:tag_key] && !scope[:tag_key].is_a?(String)
            raise Dry::Struct::Error, 'scope.tag_value must be a string' if scope[:tag_value] && !scope[:tag_value].is_a?(String)
            raise Dry::Struct::Error, 'scope.compliance_resource_id must be a string' if scope[:compliance_resource_id] && !scope[:compliance_resource_id].is_a?(String)
          end

          def validate_all(attrs)
            validate_name(attrs[:name])
            validate_source(attrs[:source])
            validate_frequency(attrs[:maximum_execution_frequency])
            validate_scope(attrs[:scope])
          end
        end
      end
    end
  end
end
